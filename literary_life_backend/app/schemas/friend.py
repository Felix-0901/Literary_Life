from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import datetime


class FriendRequest(BaseModel):
    addressee_id: int


class FriendResponse(BaseModel):
    id: int
    requester_id: int
    addressee_id: int
    user_id: Optional[int] = None
    friend_id: Optional[int] = None
    status: str
    created_at: datetime
    friend_nickname: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)
