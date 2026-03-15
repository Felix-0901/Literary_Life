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

    # If the work is not published, only the author can access it.
    if not work.is_published:
        return False

    # For published works, anyone can access (since it's public)
    # However, we still check shares for friend/group context if needed,
    # but since is_published is True, it's effectively public.
    return True


def ensure_can_access_work(db: Session, work: LiteraryWork, viewer_id: int) -> None:
    if can_access_work(db, work, viewer_id):
        return
    raise HTTPException(status_code=403, detail="無權閱讀此作品")
