from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import datetime


class QuoteResponse(BaseModel):
    id: int
    content: str
    author: str
    source: str
    category: str

    model_config = ConfigDict(from_attributes=True)
