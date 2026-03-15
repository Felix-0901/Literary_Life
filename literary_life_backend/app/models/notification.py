from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, func

from app.database import Base


class Notification(Base):
    __tablename__ = "notifications"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    type = Column(String(50), nullable=False)  # friend_request, cycle_reminder, response, etc.
    title = Column(String(200), nullable=False)
    body = Column(String(500), default="")
    related_work_id = Column(Integer, ForeignKey("literary_works.id"), nullable=True, index=True)
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
