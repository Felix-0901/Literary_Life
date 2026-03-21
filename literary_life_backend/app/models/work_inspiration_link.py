from sqlalchemy import Column, Integer, DateTime, ForeignKey, UniqueConstraint, func

from app.database import Base


class WorkInspirationLink(Base):
    __tablename__ = "work_inspiration_links"
    __table_args__ = (UniqueConstraint("work_id", "inspiration_id", name="uq_work_inspiration"),)

    id = Column(Integer, primary_key=True, index=True)
    work_id = Column(Integer, ForeignKey("literary_works.id", ondelete="CASCADE"), nullable=False, index=True)
    inspiration_id = Column(
        Integer,
        ForeignKey("inspiration_logs.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    created_at = Column(DateTime(timezone=True), server_default=func.now())
