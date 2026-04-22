from sqlalchemy import Column, Integer, String, Text, Boolean, DateTime, ForeignKey, func

from app.database import Base


class LiteraryWork(Base):
    __tablename__ = "literary_works"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    cycle_id = Column(Integer, ForeignKey("writing_cycles.id"), nullable=True, index=True)
    completed_cycle_id = Column(Integer, ForeignKey("writing_cycles.id"), nullable=True, index=True)
    title = Column(String(200), nullable=False)
    work_type = Column(String(20), nullable=False, server_default="literary")  # literary, life
    genre = Column(String(50), default="散文")  # 散文, 新詩, 短札記, 微小說, 書信體
    content = Column(Text, nullable=False)
    hashtags = Column(String(1000), default="", nullable=False)
    is_published = Column(Boolean, default=False)
    visibility = Column(String(20), default="private")  # private, friends, group, public
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
