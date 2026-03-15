from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import date, datetime


class CycleCreate(BaseModel):
    cycle_type: int = 7  # 3 or 7


class CycleResponse(BaseModel):
    id: int
    user_id: int
    cycle_type: int
    start_date: date
    end_date: date
    status: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
