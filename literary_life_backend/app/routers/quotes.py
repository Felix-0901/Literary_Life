from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy.sql.expression import func as sql_func

from app.database import get_db
from app.models.quote import Quote
from app.schemas.quote import QuoteResponse

router = APIRouter(prefix="/api/quotes", tags=["每日一句"])


@router.get("/daily", response_model=QuoteResponse)
def get_daily_quote(db: Session = Depends(get_db)):
    quote = db.query(Quote).order_by(sql_func.random()).first()
    if not quote:
        raise HTTPException(status_code=404, detail="目前沒有句子")
    return quote


@router.get("/random", response_model=QuoteResponse)
def get_random_quote(db: Session = Depends(get_db)):
    quote = db.query(Quote).order_by(sql_func.random()).first()
    if not quote:
        raise HTTPException(status_code=404, detail="目前沒有句子")
    return quote
