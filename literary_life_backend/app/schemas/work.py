from pydantic import BaseModel, ConfigDict
from typing import Optional, List
from datetime import datetime, date


class WorkCreate(BaseModel):
    cycle_id: Optional[int] = None
    completed_cycle_id: Optional[int] = None
    title: str
    work_type: str = "literary"
    genre: str = "散文"
    content: str
    visibility: str = "private"
    hashtags: str = ""
    inspiration_ids: List[int] = []


class WorkUpdate(BaseModel):
    title: Optional[str] = None
    work_type: Optional[str] = None
    genre: Optional[str] = None
    content: Optional[str] = None
    visibility: Optional[str] = None
    completed_cycle_id: Optional[int] = None
    hashtags: Optional[str] = None
    inspiration_ids: Optional[List[int]] = None


class WorkResponse(BaseModel):
    id: int
    user_id: int
    cycle_id: Optional[int]
    completed_cycle_id: Optional[int] = None
    title: str
    work_type: str = "literary"
    genre: str
    content: str
    is_published: bool
    visibility: str
    hashtags: str = ""
    created_at: datetime
    updated_at: datetime
    author_nickname: Optional[str] = None
    response_count: int = 0
    completed_cycle_start_date: Optional[date] = None
    completed_cycle_end_date: Optional[date] = None
    completed_cycle_type: Optional[int] = None
    completed_cycle_status: Optional[str] = None
    inspiration_ids: List[int] = []

    model_config = ConfigDict(from_attributes=True)
