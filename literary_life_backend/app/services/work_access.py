from fastapi import HTTPException
from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.models.friend import Friend
from app.models.group import GroupMember
from app.models.share import WorkShare
from app.models.work import LiteraryWork


def can_access_work(db: Session, work: LiteraryWork, viewer_id: int) -> bool:
    if work.user_id == viewer_id:
        return True

    # Check if explicitly shared to this user (friend)
    is_shared_to_friend = db.query(WorkShare).filter(
        WorkShare.work_id == work.id,
        WorkShare.target_type == "friend",
        WorkShare.target_id == viewer_id,
    ).first()
    if is_shared_to_friend:
        return True

    # Check if explicitly shared to a group the user is in
    group_ids = [
        group_id for (group_id,) in db.query(GroupMember.group_id).filter(
            GroupMember.user_id == viewer_id
        ).all()
    ]
    if group_ids:
        is_shared_to_group = db.query(WorkShare).filter(
            WorkShare.work_id == work.id,
            WorkShare.target_type == "group",
            WorkShare.target_id.in_(group_ids),
        ).first()
        if is_shared_to_group:
            return True

    # If the work is not published and not shared to the user, deny access.
    if not work.is_published:
        return False

    # For published works, anyone can access
    return True


def ensure_can_access_work(db: Session, work: LiteraryWork, viewer_id: int) -> None:
    if can_access_work(db, work, viewer_id):
        return
    raise HTTPException(status_code=403, detail="無權閱讀此作品")
