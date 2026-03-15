from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, func

from app.database import Base


class WorkShare(Base):
    __tablename__ = "work_shares"

    id = Column(Integer, primary_key=True, index=True)
    work_id = Column(Integer, ForeignKey("literary_works.id"), nullable=False, index=True)
    target_type = Column(String(20), nullable=False)  # friend, group, public
    target_id = Column(Integer, nullable=True)  # user_id or group_id (null for public)
    message = Column(String(500), default="")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
