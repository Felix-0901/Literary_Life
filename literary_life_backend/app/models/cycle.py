from sqlalchemy import Column, Integer, String, Date, DateTime, ForeignKey, func

from app.database import Base


class WritingCycle(Base):
    __tablename__ = "writing_cycles"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    cycle_type = Column(Integer, nullable=False, default=7)  # 3 or 7 days
    start_date = Column(Date, nullable=False)
    end_date = Column(Date, nullable=False)
    status = Column(String(20), default="active")  # active, completed, cancelled
    created_at = Column(DateTime(timezone=True), server_default=func.now())
