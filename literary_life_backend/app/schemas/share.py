from pydantic import BaseModel, ConfigDict, Field
from typing import Optional
from datetime import datetime


class ShareCreate(BaseModel):
    work_id: int
    target_type: str  # friend, group, public
    target_id: Optional[int] = None
    target_ids: list[int] = Field(default_factory=list)
    message: Optional[str] = ""


class ShareResponse(BaseModel):
    id: int
    work_id: int
    target_type: str
    target_id: Optional[int]
    message: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class ShareFeedItem(BaseModel):
    id: int
    work_id: int
    target_type: str
    target_id: Optional[int]
    message: str
    created_at: datetime
    # Embedded work details
    work_title: str
    work_content: str
    work_genre: str
    work_is_published: bool
    author_id: int
    author_nickname: str
    response_count: int = 0
