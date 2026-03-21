from pydantic import BaseModel, ConfigDict, Field
from datetime import date, datetime


class CycleCreate(BaseModel):
    cycle_type: int = Field(default=7, ge=1, le=365)


class CycleResponse(BaseModel):
    id: int
    user_id: int
    cycle_type: int
    start_date: date
    end_date: date
    status: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
