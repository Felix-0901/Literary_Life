from sqlalchemy import Column, Integer, String, DateTime, func

from app.database import Base


class Quote(Base):
    __tablename__ = "quotes"

    id = Column(Integer, primary_key=True, index=True)
    content = Column(String(1000), nullable=False)
    author = Column(String(100), default="佚名")
    source = Column(String(200), default="")
    category = Column(String(50), default="文學")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
