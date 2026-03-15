from typing import List
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import or_

from app.database import get_db
from app.models.user import User
from app.models.friend import Friend
from app.models.notification import Notification
from app.schemas.friend import FriendRequest, FriendResponse
from app.utils.security import get_current_user

router = APIRouter(prefix="/api/friends", tags=["好友"])


@router.post("/request", response_model=FriendResponse, status_code=201)
def send_friend_request(
    data: FriendRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if data.addressee_id == current_user.id:
        raise HTTPException(status_code=400, detail="不能加自己為好友")

    addressee = db.query(User).filter(User.id == data.addressee_id).first()
    if not addressee:
        raise HTTPException(status_code=404, detail="找不到此使用者")

    # Check if already friends or pending
    existing = db.query(Friend).filter(
        or_(
            (Friend.requester_id == current_user.id) & (Friend.addressee_id == data.addressee_id),
            (Friend.requester_id == data.addressee_id) & (Friend.addressee_id == current_user.id),
        )
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="已經是好友或已發送邀請")

    friend = Friend(requester_id=current_user.id, addressee_id=data.addressee_id)
    notification = Notification(
        user_id=data.addressee_id,
        type="friend_request",
        title="新的好友邀請",
        body=f"{current_user.nickname} 想加你為好友",
    )
    db.add(friend)
    db.add(notification)
    db.commit()
    db.refresh(friend)

    resp = FriendResponse.model_validate(friend)
    resp.user_id = current_user.id
    resp.friend_id = data.addressee_id
    resp.friend_nickname = addressee.nickname if addressee else "未知"
    return resp


@router.get("/", response_model=List[FriendResponse])
def list_friends(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    friends = db.query(Friend).filter(
        or_(
            Friend.requester_id == current_user.id,
            Friend.addressee_id == current_user.id,
        ),
        Friend.status == "accepted",
    ).all()

    friend_ids = [
        friend.addressee_id if friend.requester_id == current_user.id else friend.requester_id
        for friend in friends
    ]
    user_map = {
        user.id: user.nickname
        for user in db.query(User).filter(User.id.in_(friend_ids)).all()
    }

    result = []
    for friend in friends:
        friend_id = friend.addressee_id if friend.requester_id == current_user.id else friend.requester_id
        resp = FriendResponse.model_validate(friend)
        resp.user_id = current_user.id
        resp.friend_id = friend_id
        resp.friend_nickname = user_map.get(friend_id, "未知")
        result.append(resp)
    return result


@router.get("/pending", response_model=List[FriendResponse])
def list_pending_requests(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    pending = db.query(Friend).filter(
        Friend.addressee_id == current_user.id,
        Friend.status == "pending",
    ).all()

    requester_ids = [friend.requester_id for friend in pending]
    user_map = {
        user.id: user.nickname
        for user in db.query(User).filter(User.id.in_(requester_ids)).all()
    }

    result = []
    for friend in pending:
        resp = FriendResponse.model_validate(friend)
        resp.user_id = current_user.id
        resp.friend_id = friend.requester_id
        resp.friend_nickname = user_map.get(friend.requester_id, "未知")
        result.append(resp)
    return result


@router.put("/{friend_id}/accept", response_model=FriendResponse)
def accept_friend_request(
    friend_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    friend = db.query(Friend).filter(
        Friend.id == friend_id,
        Friend.addressee_id == current_user.id,
        Friend.status == "pending",
    ).first()
    if not friend:
        raise HTTPException(status_code=404, detail="找不到此好友邀請")

    friend.status = "accepted"
    notification = Notification(
        user_id=friend.requester_id,
        type="friend_accepted",
        title="好友邀請已接受",
        body=f"{current_user.nickname} 已接受你的好友邀請",
    )
    db.add(notification)
    db.commit()
    db.refresh(friend)

    requester = db.query(User).filter(User.id == friend.requester_id).first()
    resp = FriendResponse.model_validate(friend)
    resp.user_id = current_user.id
    resp.friend_id = friend.requester_id
    resp.friend_nickname = requester.nickname if requester else "未知"
    return resp


@router.get("/search", response_model=list)
def search_users(
    q: str = Query(..., min_length=1),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # Check if query looks like a user code (#123456 or 123456)
    clean_q = q.strip()
    is_code_search = False
    
    if clean_q.startswith('#') and len(clean_q) == 7 and clean_q[1:].isdigit():
        clean_q = clean_q[1:]
        is_code_search = True
    elif len(clean_q) == 6 and clean_q.isdigit():
        is_code_search = True
        
    query = db.query(User).filter(User.id != current_user.id)
    
    if is_code_search:
        users = query.filter(User.user_code == clean_q).all()
    else:
        users = query.filter(
            or_(
                User.nickname.ilike(f"%{q}%"),
                User.email.ilike(f"%{q}%"),
            )
        ).limit(10).all()
        
    return [{"id": u.id, "nickname": u.nickname, "email": u.email, "user_code": u.user_code} for u in users]
