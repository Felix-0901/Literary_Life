from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import datetime


class InspirationCreate(BaseModel):
    cycle_id: Optional[int] = None
    event_time: Optional[datetime] = None
    location: Optional[str] = ""
    object_or_event: Optional[str] = ""
    detail_text: Optional[str] = ""
    feeling: Optional[str] = ""
    keywords: Optional[str] = ""


class InspirationUpdate(BaseModel):
    location: Optional[str] = None
    object_or_event: Optional[str] = None
    detail_text: Optional[str] = None
    feeling: Optional[str] = None
    keywords: Optional[str] = None


class InspirationResponse(BaseModel):
    id: int
    user_id: int
    cycle_id: Optional[int]
    event_time: datetime
    location: str
    object_or_event: str
    detail_text: str
    feeling: str
    keywords: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
