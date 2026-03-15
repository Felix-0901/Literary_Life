from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User
from app.models.work import LiteraryWork
from app.models.response import Response
from app.models.share import WorkShare
from app.schemas.work import WorkCreate, WorkUpdate, WorkResponse
from app.services.work_access import ensure_can_access_work
from app.utils.security import get_current_user

router = APIRouter(prefix="/api/works", tags=["文學作品"])


def _response_count_subquery(db: Session):
    return (
        db.query(
            Response.work_id.label("work_id"),
            func.count(Response.id).label("response_count"),
        )
        .group_by(Response.work_id)
        .subquery()
    )


def _serialize_work(work: LiteraryWork, author_nickname: str, response_count: int = 0) -> WorkResponse:
    resp = WorkResponse.model_validate(work)
    resp.author_nickname = author_nickname
    resp.response_count = int(response_count)
    return resp


@router.post("/", response_model=WorkResponse, status_code=201)
def create_work(
    data: WorkCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    work = LiteraryWork(
        user_id=current_user.id,
        cycle_id=data.cycle_id,
        title=data.title,
        genre=data.genre,
        content=data.content,
        visibility=data.visibility,
    )
    db.add(work)
    db.commit()
    db.refresh(work)
    resp = WorkResponse.model_validate(work)
    resp.author_nickname = current_user.nickname
    return resp


@router.get("/", response_model=List[WorkResponse])
def list_works(
    cycle_id: Optional[int] = Query(None),
    genre: Optional[str] = Query(None),
    public: Optional[bool] = Query(False),
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    response_counts = _response_count_subquery(db)
    query = (
        db.query(
            LiteraryWork,
            User.nickname.label("author_nickname"),
            func.coalesce(response_counts.c.response_count, 0).label("response_count"),
        )
        .join(User, User.id == LiteraryWork.user_id)
        .outerjoin(response_counts, response_counts.c.work_id == LiteraryWork.id)
    )
    if public:
        query = query.filter(LiteraryWork.is_published.is_(True))
    else:
        query = query.filter(LiteraryWork.user_id == current_user.id)
        if cycle_id:
            query = query.filter(LiteraryWork.cycle_id == cycle_id)
            
    if genre:
        query = query.filter(LiteraryWork.genre == genre)
        
    rows = query.order_by(LiteraryWork.created_at.desc()).offset(skip).limit(limit).all()
    return [
        _serialize_work(work, author_nickname or "未知", response_count)
        for work, author_nickname, response_count in rows
    ]


@router.get("/{work_id}", response_model=WorkResponse)
def get_work(
    work_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    response_counts = _response_count_subquery(db)
    row = (
        db.query(
            LiteraryWork,
            User.nickname.label("author_nickname"),
            func.coalesce(response_counts.c.response_count, 0).label("response_count"),
        )
        .join(User, User.id == LiteraryWork.user_id)
        .outerjoin(response_counts, response_counts.c.work_id == LiteraryWork.id)
        .filter(LiteraryWork.id == work_id)
        .first()
    )
    if not row:
        raise HTTPException(status_code=404, detail="找不到此作品")

    work, author_nickname, response_count = row
    ensure_can_access_work(db, work, current_user.id)
    return _serialize_work(work, author_nickname or "未知", response_count)


@router.put("/{work_id}", response_model=WorkResponse)
def update_work(
    work_id: int,
    data: WorkUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    work = db.query(LiteraryWork).filter(
        LiteraryWork.id == work_id,
        LiteraryWork.user_id == current_user.id,
    ).first()
    if not work:
        raise HTTPException(status_code=404, detail="找不到此作品")

    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(work, field, value)
    db.commit()
    db.refresh(work)
    resp = WorkResponse.model_validate(work)
    resp.author_nickname = current_user.nickname
    return resp


@router.post("/{work_id}/publish", response_model=WorkResponse)
def publish_work(
    work_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    work = db.query(LiteraryWork).filter(
        LiteraryWork.id == work_id,
        LiteraryWork.user_id == current_user.id,
    ).first()
    if not work:
        raise HTTPException(status_code=404, detail="找不到此作品")

    work.is_published = True
    work.visibility = "public"

    # Auto-create or refresh a public share record so it appears at the top of the community feed
    db.query(WorkShare).filter(
        WorkShare.work_id == work.id,
        WorkShare.target_type == "public",
    ).delete()
    
    db.add(WorkShare(
        work_id=work.id,
        target_type="public",
        target_id=None,
        message="",
    ))

    db.commit()
    db.refresh(work)
    resp = WorkResponse.model_validate(work)
    resp.author_nickname = current_user.nickname
    return resp


@router.post("/{work_id}/unpublish", response_model=WorkResponse)
def unpublish_work(
    work_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    work = db.query(LiteraryWork).filter(
        LiteraryWork.id == work_id,
        LiteraryWork.user_id == current_user.id,
    ).first()
    if not work:
        raise HTTPException(status_code=404, detail="找不到此作品")

    work.is_published = False
    if work.visibility == "public":
        work.visibility = "private"

    # Remove public share record
    db.query(WorkShare).filter(
        WorkShare.work_id == work.id,
        WorkShare.target_type == "public",
    ).delete()

    db.commit()
    db.refresh(work)
    resp = WorkResponse.model_validate(work)
    resp.author_nickname = current_user.nickname
    return resp
