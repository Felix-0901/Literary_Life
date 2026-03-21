from sqlalchemy import Column, Integer, Text, Boolean, DateTime, func

from app.database import Base


class MaintenanceConfig(Base):
    __tablename__ = "maintenance_configs"

    id = Column(Integer, primary_key=True, index=True)
    is_active = Column(Boolean, nullable=False, default=False)
    message = Column(Text, nullable=False, default="")
    starts_at = Column(DateTime(timezone=True), nullable=True)
    ends_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

