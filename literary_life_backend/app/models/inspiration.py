from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey, func

from app.database import Base


class InspirationLog(Base):
    __tablename__ = "inspiration_logs"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    cycle_id = Column(Integer, ForeignKey("writing_cycles.id"), nullable=True, index=True)
    event_time = Column(DateTime(timezone=True), server_default=func.now())
    location = Column(String(200), default="")
    object_or_event = Column(String(500), default="")
    detail_text = Column(Text, default="")
    feeling = Column(String(200), default="")
    keywords = Column(String(500), default="")  # comma-separated
    created_at = Column(DateTime(timezone=True), server_default=func.now())
