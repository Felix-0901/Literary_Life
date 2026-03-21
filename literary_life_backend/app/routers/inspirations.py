from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from datetime import datetime, timezone

from app.database import get_db
from app.models.user import User
from app.models.inspiration import InspirationLog
from app.schemas.inspiration import InspirationCreate, InspirationUpdate, InspirationResponse
from app.utils.security import get_current_user

router = APIRouter(prefix="/api/inspirations", tags=["靈感紀錄"])


@router.post("/", response_model=InspirationResponse, status_code=201)
def create_inspiration(
    data: InspirationCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    log = InspirationLog(
        user_id=current_user.id,
        cycle_id=data.cycle_id,
        event_time=data.event_time or datetime.now(timezone.utc),
        location=data.location or "",
        object_or_event=data.object_or_event or "",
        detail_text=data.detail_text or "",
        feeling=data.feeling or "",
        keywords=data.keywords or "",
    )
    db.add(log)
    db.commit()
    db.refresh(log)
    return log


@router.get("/", response_model=List[InspirationResponse])
def list_inspirations(
    cycle_id: Optional[int] = Query(None),
    location: Optional[str] = Query(None),
    feeling: Optional[str] = Query(None),
    object_or_event: Optional[str] = Query(None),
    keywords: Optional[str] = Query(None),
    keyword: Optional[str] = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    query = db.query(InspirationLog).filter(InspirationLog.user_id == current_user.id)
    if cycle_id:
        query = query.filter(InspirationLog.cycle_id == cycle_id)
    if location:
        query = query.filter(InspirationLog.location.ilike(f"%{location}%"))
    if feeling:
        query = query.filter(InspirationLog.feeling.ilike(f"%{feeling}%"))
    if object_or_event:
        query = query.filter(InspirationLog.object_or_event.ilike(f"%{object_or_event}%"))
    if keywords:
        query = query.filter(InspirationLog.keywords.ilike(f"%{keywords}%"))
    if keyword:
        query = query.filter(
            InspirationLog.keywords.ilike(f"%{keyword}%")
            | InspirationLog.detail_text.ilike(f"%{keyword}%")
            | InspirationLog.object_or_event.ilike(f"%{keyword}%")
            | InspirationLog.location.ilike(f"%{keyword}%")
            | InspirationLog.feeling.ilike(f"%{keyword}%")
        )
    return query.order_by(InspirationLog.event_time.desc()).offset(skip).limit(limit).all()


@router.get("/{inspiration_id}", response_model=InspirationResponse)
def get_inspiration(
    inspiration_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    log = db.query(InspirationLog).filter(
        InspirationLog.id == inspiration_id,
        InspirationLog.user_id == current_user.id,
    ).first()
    if not log:
        raise HTTPException(status_code=404, detail="找不到此筆靈感紀錄")
    return log


@router.put("/{inspiration_id}", response_model=InspirationResponse)
def update_inspiration(
    inspiration_id: int,
    data: InspirationUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    log = db.query(InspirationLog).filter(
        InspirationLog.id == inspiration_id,
        InspirationLog.user_id == current_user.id,
    ).first()
    if not log:
        raise HTTPException(status_code=404, detail="找不到此筆靈感紀錄")

    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(log, field, value)
    db.commit()
    db.refresh(log)
    return log


@router.delete("/{inspiration_id}", status_code=204)
def delete_inspiration(
    inspiration_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    log = db.query(InspirationLog).filter(
        InspirationLog.id == inspiration_id,
        InspirationLog.user_id == current_user.id,
    ).first()
    if not log:
        raise HTTPException(status_code=404, detail="找不到此筆靈感紀錄")
    db.delete(log)
    db.commit()
