from pydantic import BaseModel, ConfigDict
from typing import Optional, List
from datetime import datetime


class GroupCreate(BaseModel):
    name: str
    description: Optional[str] = ""


class GroupMemberAdd(BaseModel):
    user_id: int


class GroupResponse(BaseModel):
    id: int
    name: str
    description: str
    invite_code: str
    owner_id: int
    created_at: datetime
    member_count: Optional[int] = 0

    model_config = ConfigDict(from_attributes=True)
