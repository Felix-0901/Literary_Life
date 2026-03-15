from sqlalchemy import Column, Integer, String, DateTime, func

from app.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    nickname = Column(String(50), nullable=False)
    email = Column(String(255), unique=True, index=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    user_code = Column(String(6), unique=True, index=True, nullable=False)
    bio = Column(String(500), default="")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
