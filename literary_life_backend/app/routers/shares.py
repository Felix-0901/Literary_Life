from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.friend import Friend
from app.models.group import Group, GroupMember
from app.models.notification import Notification
from app.models.share import WorkShare
from app.models.user import User
from app.models.work import LiteraryWork
from app.schemas.share import ShareCreate, ShareResponse, ShareFeedItem
from app.utils.security import get_current_user

router = APIRouter(prefix="/api/shares", tags=["分享"])


@router.post("/", response_model=ShareResponse, status_code=201)
def share_work(
    data: ShareCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # 先找出作品，不限定作者
    work = db.query(LiteraryWork).filter(LiteraryWork.id == data.work_id).first()
    if not work:
        raise HTTPException(status_code=404, detail="找不到此作品")

    # 權限檢查：只有作者可以分享未發佈的作品；其他用戶只能分享已發佈的作品
    is_author = (work.user_id == current_user.id)
    if not is_author and not work.is_published:
        raise HTTPException(status_code=404, detail="找不到此作品")

    if data.target_type not in {"public", "friend", "group"}:
        raise HTTPException(status_code=400, detail="不支援的分享類型")

    # 如果是作者且分享到公開，則更新發佈狀態
    if is_author and data.target_type == "public":
        work.is_published = True
        work.visibility = "public"
    elif not is_author and data.target_type == "public":
        # 非作者不能改變文章狀態，但既然已經進入到這裡，代表 work.is_published 已經是 True
        pass
    elif is_author:
        # 作者分享給好友或群組，維持原本 visibility 或設為 private (視現有邏輯)
        # 這裡維持原邏輯：非公開分享則設為 private
        work.visibility = "private" if work.visibility != "public" else "public"

    targets: list[int] = []
    if data.target_type == "friend":
        friendships = (
            db.query(Friend)
            .filter(
                Friend.status == "accepted",
                or_(
                    Friend.requester_id == current_user.id,
                    Friend.addressee_id == current_user.id,
                ),
            )
            .all()
        )
        friend_ids = [
            friendship.addressee_id
            if friendship.requester_id == current_user.id
            else friendship.requester_id
            for friendship in friendships
        ]
        allowed_friend_ids = set(friend_ids)

        if data.target_ids:
            targets = list(dict.fromkeys(data.target_ids))
        elif data.target_id is not None:
            targets = [data.target_id]
        else:
            targets = friend_ids

        invalid_targets = [
            target_id for target_id in targets if target_id not in allowed_friend_ids
        ]
        if invalid_targets:
            raise HTTPException(status_code=400, detail="只能分享給你的好友")

    if data.target_type == "group":
        member_group_ids = {
            group_id
            for (group_id,) in db.query(GroupMember.group_id).filter(
                GroupMember.user_id == current_user.id
            ).all()
        }

        if data.target_ids:
            targets = list(dict.fromkeys(data.target_ids))
        elif data.target_id is not None:
            targets = [data.target_id]
        else:
            targets = list(member_group_ids)

        invalid_group_ids = [
            target_id for target_id in targets if target_id not in member_group_ids
        ]
        if invalid_group_ids:
            raise HTTPException(status_code=400, detail="只能分享到你已加入的群組")

    if data.target_type != "public" and not targets:
        raise HTTPException(status_code=400, detail="沒有可分享的目標")

    created_shares: list[WorkShare] = []
    for target_id in targets:
        share = WorkShare(
            work_id=data.work_id,
            target_type=data.target_type,
            target_id=target_id,
            message=data.message or "",
        )
        db.add(share)
        created_shares.append(share)

        if data.target_type == "friend":
            db.add(
                Notification(
                    user_id=target_id,
                    type="share",
                    title="收到文章分享",
                    body=f"{current_user.nickname} 分享了「{work.title}」給你",
                    related_work_id=work.id,
                )
            )

        if data.target_type == "group":
            group = db.query(Group).filter(Group.id == target_id).first()
            member_ids = [
                user_id
                for (user_id,) in db.query(GroupMember.user_id).filter(
                    GroupMember.group_id == target_id,
                    GroupMember.user_id != current_user.id,
                ).all()
            ]
            for member_id in member_ids:
                db.add(
                    Notification(
                        user_id=member_id,
                        type="share",
                        title="群組有新文章分享",
                        body=f"{current_user.nickname} 在「{group.name if group else '群組'}」分享了「{work.title}」",
                        related_work_id=work.id,
                    )
                )

    if data.target_type == "public":
        share = WorkShare(
            work_id=data.work_id,
            target_type=data.target_type,
            target_id=None,
            message=data.message or "",
        )
        db.add(share)
        created_shares.append(share)

    db.commit()
    share = created_shares[0]
    db.refresh(share)
    return share


@router.get("/feed", response_model=List[ShareFeedItem])
def get_shared_feed(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    from sqlalchemy import func as sa_func
    from app.models.response import Response

    group_ids = [
        group_id
        for (group_id,) in db.query(GroupMember.group_id).filter(
            GroupMember.user_id == current_user.id
        ).all()
    ]

    filters = (
        (
            (LiteraryWork.is_published == True) & (WorkShare.target_type == "public")
        )
        | (
            (WorkShare.target_type == "friend")
            & (WorkShare.target_id == current_user.id)
        )
        | (
            (WorkShare.target_type == "group")
            & (WorkShare.target_id.in_(group_ids) if group_ids else False)
        )
    )

    response_counts = (
        db.query(
            Response.work_id.label("work_id"),
            sa_func.count(Response.id).label("response_count"),
        )
        .group_by(Response.work_id)
        .subquery()
    )

    rows = (
        db.query(
            WorkShare,
            LiteraryWork.title.label("work_title"),
            LiteraryWork.content.label("work_content"),
            LiteraryWork.genre.label("work_genre"),
            LiteraryWork.is_published.label("work_is_published"),
            LiteraryWork.user_id.label("author_id"),
            User.nickname.label("author_nickname"),
            sa_func.coalesce(response_counts.c.response_count, 0).label("response_count"),
        )
        .join(LiteraryWork, LiteraryWork.id == WorkShare.work_id)
        .join(User, User.id == LiteraryWork.user_id)
        .outerjoin(response_counts, response_counts.c.work_id == WorkShare.work_id)
        .filter(filters)
        .order_by(WorkShare.created_at.desc(), WorkShare.id.desc())
        .limit(50)
        .all()
    )

    seen_work_ids: set[int] = set()
    items: list[ShareFeedItem] = []
    for share, work_title, work_content, work_genre, work_is_published, author_id, author_nickname, resp_count in rows:
        if share.work_id in seen_work_ids:
            continue
        seen_work_ids.add(share.work_id)
        items.append(ShareFeedItem(
            id=share.id,
            work_id=share.work_id,
            target_type=share.target_type,
            target_id=share.target_id,
            message=share.message,
            created_at=share.created_at,
            work_title=work_title,
            work_content=work_content,
            work_genre=work_genre,
            work_is_published=work_is_published,
            author_id=author_id,
            author_nickname=author_nickname or "未知",
            response_count=int(resp_count),
        ))
    return items
