from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import or_, desc
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.announcement import Announcement
from app.schemas.announcement import AnnouncementResponse

router = APIRouter(prefix="/api/announcements", tags=["公告"])


@router.get("/active", response_model=AnnouncementResponse)
def get_active_announcement(db: Session = Depends(get_db)):
    now = datetime.now(timezone.utc)

    announcement = (
        db.query(Announcement)
        .filter(Announcement.is_active.is_(True))
        .filter(or_(Announcement.starts_at.is_(None), Announcement.starts_at <= now))
        .filter(or_(Announcement.ends_at.is_(None), Announcement.ends_at >= now))
        .order_by(desc(Announcement.updated_at), desc(Announcement.created_at))
        .first()
    )

    if not announcement:
        raise HTTPException(status_code=404, detail="目前沒有公告")

    return announcement

