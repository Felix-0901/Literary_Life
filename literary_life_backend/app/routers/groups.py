from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func
from sqlalchemy.orm import Session
from pydantic import BaseModel
import secrets
import string

from app.database import get_db
from app.models.user import User
from app.models.group import Group, GroupMember
from app.models.work import LiteraryWork
from app.models.share import WorkShare
from app.models.response import Response
from app.schemas.group import GroupCreate, GroupMemberAdd, GroupResponse
from app.schemas.work import WorkResponse
from app.utils.security import get_current_user

router = APIRouter(prefix="/api/groups", tags=["群組"])


@router.post("/", response_model=GroupResponse, status_code=201)
def create_group(
    data: GroupCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    invite_code = ''.join(secrets.choice(string.ascii_uppercase + string.digits) for _ in range(6))
    
    group = Group(
        name=data.name,
        description=data.description or "",
        invite_code=invite_code,
        owner_id=current_user.id,
    )
    db.add(group)
    db.commit()
    db.refresh(group)

    # Add owner as member
    member = GroupMember(group_id=group.id, user_id=current_user.id, role="owner")
    db.add(member)
    db.commit()

    resp = GroupResponse.model_validate(group)
    resp.member_count = 1
    return resp


@router.get("/", response_model=List[GroupResponse])
def list_groups(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    member_counts = (
        db.query(
            GroupMember.group_id.label("group_id"),
            func.count(GroupMember.id).label("member_count"),
        )
        .group_by(GroupMember.group_id)
        .subquery()
    )

    rows = (
        db.query(Group, func.coalesce(member_counts.c.member_count, 0).label("member_count"))
        .join(GroupMember, GroupMember.group_id == Group.id)
        .outerjoin(member_counts, member_counts.c.group_id == Group.id)
        .filter(GroupMember.user_id == current_user.id)
        .order_by(Group.created_at.desc())
        .all()
    )

    result = []
    for group, member_count in rows:
        resp = GroupResponse.model_validate(group)
        resp.member_count = int(member_count)
        result.append(resp)
    return result


@router.post("/{group_id}/members", status_code=201)
def add_member(
    group_id: int,
    data: GroupMemberAdd,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    group = db.query(Group).filter(Group.id == group_id).first()
    if not group:
        raise HTTPException(status_code=404, detail="找不到此群組")
    if group.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="只有群組擁有者可以新增成員")

    existing = db.query(GroupMember).filter(
        GroupMember.group_id == group_id,
        GroupMember.user_id == data.user_id,
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="已經是群組成員")

    member = GroupMember(group_id=group_id, user_id=data.user_id, role="member")
    db.add(member)
    db.commit()
    return {"message": "成員已新增"}


@router.get("/{group_id}/members")
def get_group_members(
    group_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    members = db.query(GroupMember).filter(GroupMember.group_id == group_id).all()
    user_ids = [member.user_id for member in members]
    user_map = {
        user.id: user.nickname
        for user in db.query(User).filter(User.id.in_(user_ids)).all()
    }
    result = []
    for m in members:
        result.append({
            "user_id": m.user_id,
            "nickname": user_map.get(m.user_id, "未知"),
            "role": m.role,
        })
    return result

class GroupJoinRequest(BaseModel):
    invite_code: str

@router.post("/join", status_code=201)
def join_group_by_code(
    data: GroupJoinRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    group = db.query(Group).filter(Group.invite_code == data.invite_code).first()
    if not group:
        raise HTTPException(status_code=404, detail="無效的群組代碼")
        
    existing = db.query(GroupMember).filter(
        GroupMember.group_id == group.id,
        GroupMember.user_id == current_user.id,
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="您已經是群組成員")
        
    member = GroupMember(group_id=group.id, user_id=current_user.id, role="member")
    db.add(member)
    db.commit()
    return {"message": "成功加入群組", "group_id": group.id}


@router.get("/{group_id}/works", response_model=List[WorkResponse])
def get_group_works(
    group_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # Verify the user is a member of the group
    is_member = db.query(GroupMember).filter(
        GroupMember.group_id == group_id,
        GroupMember.user_id == current_user.id,
    ).first()
    if not is_member:
        raise HTTPException(status_code=403, detail="您不是此群組的成員")

    # Find works shared to this group that are still published
    shares = (
        db.query(WorkShare)
        .join(LiteraryWork, LiteraryWork.id == WorkShare.work_id)
        .filter(
            WorkShare.target_type == "group",
            WorkShare.target_id == group_id,
            LiteraryWork.is_published == True,
        )
        .all()
    )
    work_ids = [s.work_id for s in shares]

    # Include public works by any group members? Requirement: "那群組頁面有點像是社群頁面，一樣會有文章列表...點擊群組來到群組列表...除非該篇文章是以發佈的文章"
    # Wait, the user said "unless it's a published article" for the share button. 
    # Let's just return works that are explicitly shared to this group by someone.
    
    works = []
    if work_ids:
        # Fetch the works, sorted by latest
        db_works = db.query(LiteraryWork).filter(
            LiteraryWork.id.in_(work_ids)
        ).order_by(LiteraryWork.created_at.desc()).all()

        author_ids = [work.user_id for work in db_works]
        author_map = {
            user.id: user.nickname
            for user in db.query(User).filter(User.id.in_(author_ids)).all()
        }
        response_counts = {
            work_id: count
            for work_id, count in (
                db.query(Response.work_id, func.count(Response.id))
                .filter(Response.work_id.in_(work_ids))
                .group_by(Response.work_id)
                .all()
            )
        }

        for w in db_works:
            resp = WorkResponse.model_validate(w)
            resp.author_nickname = author_map.get(w.user_id, "未知")
            resp.response_count = int(response_counts.get(w.id, 0))
            works.append(resp)

    return works
