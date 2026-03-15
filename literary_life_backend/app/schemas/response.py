from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import datetime


class ResponseCreate(BaseModel):
    work_id: int
    content: str


class ResponseOut(BaseModel):
    id: int
    work_id: int
    user_id: int
    content: str
    created_at: datetime
    author_nickname: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)
