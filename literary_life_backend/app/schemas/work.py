from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import datetime


class WorkCreate(BaseModel):
    cycle_id: Optional[int] = None
    title: str
    genre: str = "散文"
    content: str
    visibility: str = "private"


class WorkUpdate(BaseModel):
    title: Optional[str] = None
    genre: Optional[str] = None
    content: Optional[str] = None
    visibility: Optional[str] = None


class WorkResponse(BaseModel):
    id: int
    user_id: int
    cycle_id: Optional[int]
    title: str
    genre: str
    content: str
    is_published: bool
    visibility: str
    created_at: datetime
    updated_at: datetime
    author_nickname: Optional[str] = None
    response_count: int = 0

    model_config = ConfigDict(from_attributes=True)
