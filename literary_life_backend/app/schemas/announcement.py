from pydantic import BaseModel, ConfigDict
from datetime import datetime
from typing import Optional


class AnnouncementResponse(BaseModel):
    id: int
    title: str
    content: str
    is_active: bool
    starts_at: Optional[datetime] = None
    ends_at: Optional[datetime] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)

