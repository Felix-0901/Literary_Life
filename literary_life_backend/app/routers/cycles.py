from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import date, timedelta

from app.database import get_db
from app.models.user import User
from app.models.cycle import WritingCycle
from app.models.inspiration import InspirationLog
from app.schemas.cycle import CycleCreate, CycleResponse
from app.utils.security import get_current_user

router = APIRouter(prefix="/api/cycles", tags=["創作週期"])


@router.post("/", response_model=CycleResponse, status_code=201)
def create_cycle(
    data: CycleCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if data.cycle_type not in (3, 7):
        raise HTTPException(status_code=400, detail="週期只能是 3 天或 7 天")

    # Check if there's already an active cycle
    active = db.query(WritingCycle).filter(
        WritingCycle.user_id == current_user.id,
        WritingCycle.status == "active",
    ).first()
    if active:
        raise HTTPException(status_code=400, detail="你已經有一個進行中的週期")

    today = date.today()
    cycle = WritingCycle(
        user_id=current_user.id,
        cycle_type=data.cycle_type,
        start_date=today,
        end_date=today + timedelta(days=data.cycle_type),
        status="active",
    )
    db.add(cycle)
    db.commit()
    db.refresh(cycle)
    return cycle


@router.get("/current", response_model=CycleResponse)
def get_current_cycle(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    cycle = db.query(WritingCycle).filter(
        WritingCycle.user_id == current_user.id,
        WritingCycle.status == "active",
    ).first()
    if not cycle:
        raise HTTPException(status_code=404, detail="目前沒有進行中的週期")

    # Auto-complete if past end date
    if date.today() > cycle.end_date:
        cycle.status = "completed"
        db.commit()
        db.refresh(cycle)

    return cycle


@router.get("/", response_model=List[CycleResponse])
def list_cycles(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return (
        db.query(WritingCycle)
        .filter(WritingCycle.user_id == current_user.id)
        .order_by(WritingCycle.created_at.desc())
        .all()
    )


@router.put("/{cycle_id}/end", response_model=CycleResponse)
def end_cycle(
    cycle_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    cycle = db.query(WritingCycle).filter(
        WritingCycle.id == cycle_id,
        WritingCycle.user_id == current_user.id,
    ).first()
    if not cycle:
        raise HTTPException(status_code=404, detail="找不到此週期")
    if cycle.status != "active":
        raise HTTPException(status_code=400, detail="此週期已結束")

    cycle.status = "completed"
    cycle.end_date = date.today()
    db.commit()
    db.refresh(cycle)
    return cycle
