from pydantic import BaseModel, ConfigDict
from datetime import datetime
from typing import Optional


class MaintenanceStatusResponse(BaseModel):
    is_active: bool
    message: str = ""
    starts_at: Optional[datetime] = None
    ends_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)

