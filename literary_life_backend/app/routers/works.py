from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func
from sqlalchemy.orm import Session, aliased

from app.database import get_db
from app.models.cycle import WritingCycle
from app.models.inspiration import InspirationLog
from app.models.user import User
from app.models.work import LiteraryWork
from app.models.response import Response
from app.models.share import WorkShare
from app.models.work_inspiration_link import WorkInspirationLink
from app.models.notification import Notification
from app.schemas.inspiration import InspirationResponse
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


def _normalize_hashtags(value: str) -> str:
    tags = []
    for raw in value.split():
        t = raw.strip()
        if not t:
            continue
        if not t.startswith("#"):
            t = f"#{t}"
        if t not in tags:
            tags.append(t)
    return " ".join(tags)


def _get_inspiration_ids_map(db: Session, work_ids: List[int]) -> dict[int, List[int]]:
    if not work_ids:
        return {}
    rows = (
        db.query(WorkInspirationLink.work_id, WorkInspirationLink.inspiration_id)
        .filter(WorkInspirationLink.work_id.in_(work_ids))
        .order_by(WorkInspirationLink.created_at.asc())
        .all()
    )
    m: dict[int, List[int]] = {}
    for work_id, inspiration_id in rows:
        m.setdefault(work_id, []).append(int(inspiration_id))
    return m


def _validate_completed_cycle(
    db: Session, *, current_user: User, completed_cycle_id: Optional[int]
) -> Optional[WritingCycle]:
    if completed_cycle_id is None:
        return None
    cycle = db.query(WritingCycle).filter(
        WritingCycle.id == completed_cycle_id,
        WritingCycle.user_id == current_user.id,
    ).first()
    if not cycle:
        raise HTTPException(status_code=400, detail="無效的完成週期")
    if cycle.status != "completed":
        raise HTTPException(status_code=400, detail="只能選擇已完成的週期")
    return cycle


def _validate_inspirations(
    db: Session,
    *,
    current_user: User,
    inspiration_ids: List[int],
    completed_cycle: Optional[WritingCycle],
) -> List[InspirationLog]:
    if not inspiration_ids:
        return []
    ids = [int(i) for i in inspiration_ids]
    unique_ids = list(dict.fromkeys(ids))
    inspirations = (
        db.query(InspirationLog)
        .filter(
            InspirationLog.user_id == current_user.id,
            InspirationLog.id.in_(unique_ids),
        )
        .all()
    )
    if len(inspirations) != len(unique_ids):
        raise HTTPException(status_code=400, detail="包含無效的靈感來源")
    if completed_cycle is not None:
        start = completed_cycle.start_date
        end = completed_cycle.end_date
        for insp in inspirations:
            if insp.event_time is None:
                raise HTTPException(status_code=400, detail="所選靈感缺少時間資訊")
            d = insp.event_time.date()
            if d < start or d > end:
                raise HTTPException(status_code=400, detail="所選靈感需落在完成週期期間內")
    return inspirations


@router.post("/", response_model=WorkResponse, status_code=201)
def create_work(
    data: WorkCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    completed_cycle = _validate_completed_cycle(
        db,
        current_user=current_user,
        completed_cycle_id=data.completed_cycle_id,
    )
    inspirations = _validate_inspirations(
        db,
        current_user=current_user,
        inspiration_ids=data.inspiration_ids,
        completed_cycle=completed_cycle,
    )
    work = LiteraryWork(
        user_id=current_user.id,
        cycle_id=data.cycle_id,
        completed_cycle_id=data.completed_cycle_id,
        title=data.title,
        genre=data.genre,
        content=data.content,
        visibility=data.visibility,
        hashtags=_normalize_hashtags(data.hashtags),
    )
    db.add(work)
    db.flush()

    if inspirations:
        for insp in inspirations:
            db.add(WorkInspirationLink(work_id=work.id, inspiration_id=insp.id))

    db.commit()
    db.refresh(work)

    resp = WorkResponse.model_validate(work)
    resp.author_nickname = current_user.nickname
    resp.inspiration_ids = [int(i.id) for i in inspirations]
    if completed_cycle is not None:
        resp.completed_cycle_start_date = completed_cycle.start_date
        resp.completed_cycle_end_date = completed_cycle.end_date
        resp.completed_cycle_type = completed_cycle.cycle_type
        resp.completed_cycle_status = completed_cycle.status
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
    CompletedCycle = aliased(WritingCycle)
    response_counts = _response_count_subquery(db)
    query = (
        db.query(
            LiteraryWork,
            User.nickname.label("author_nickname"),
            func.coalesce(response_counts.c.response_count, 0).label("response_count"),
            CompletedCycle.start_date.label("completed_cycle_start_date"),
            CompletedCycle.end_date.label("completed_cycle_end_date"),
            CompletedCycle.cycle_type.label("completed_cycle_type"),
            CompletedCycle.status.label("completed_cycle_status"),
        )
        .join(User, User.id == LiteraryWork.user_id)
        .outerjoin(response_counts, response_counts.c.work_id == LiteraryWork.id)
        .outerjoin(CompletedCycle, CompletedCycle.id == LiteraryWork.completed_cycle_id)
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
    work_ids = [int(work.id) for work, *_ in rows]
    inspiration_ids_map = _get_inspiration_ids_map(db, work_ids)

    results: List[WorkResponse] = []
    for (
        work,
        author_nickname,
        response_count,
        completed_cycle_start_date,
        completed_cycle_end_date,
        completed_cycle_type,
        completed_cycle_status,
    ) in rows:
        resp = _serialize_work(work, author_nickname or "未知", response_count)
        resp.inspiration_ids = inspiration_ids_map.get(int(work.id), [])
        resp.completed_cycle_start_date = completed_cycle_start_date
        resp.completed_cycle_end_date = completed_cycle_end_date
        resp.completed_cycle_type = completed_cycle_type
        resp.completed_cycle_status = completed_cycle_status
        results.append(resp)
    return results


@router.get("/{work_id}", response_model=WorkResponse)
def get_work(
    work_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    CompletedCycle = aliased(WritingCycle)
    response_counts = _response_count_subquery(db)
    row = (
        db.query(
            LiteraryWork,
            User.nickname.label("author_nickname"),
            func.coalesce(response_counts.c.response_count, 0).label("response_count"),
            CompletedCycle.start_date.label("completed_cycle_start_date"),
            CompletedCycle.end_date.label("completed_cycle_end_date"),
            CompletedCycle.cycle_type.label("completed_cycle_type"),
            CompletedCycle.status.label("completed_cycle_status"),
        )
        .join(User, User.id == LiteraryWork.user_id)
        .outerjoin(response_counts, response_counts.c.work_id == LiteraryWork.id)
        .outerjoin(CompletedCycle, CompletedCycle.id == LiteraryWork.completed_cycle_id)
        .filter(LiteraryWork.id == work_id)
        .first()
    )
    if not row:
        raise HTTPException(status_code=404, detail="找不到此作品")

    (
        work,
        author_nickname,
        response_count,
        completed_cycle_start_date,
        completed_cycle_end_date,
        completed_cycle_type,
        completed_cycle_status,
    ) = row
    ensure_can_access_work(db, work, current_user.id)
    inspiration_ids_map = _get_inspiration_ids_map(db, [int(work.id)])
    resp = _serialize_work(work, author_nickname or "未知", response_count)
    resp.inspiration_ids = inspiration_ids_map.get(int(work.id), [])
    resp.completed_cycle_start_date = completed_cycle_start_date
    resp.completed_cycle_end_date = completed_cycle_end_date
    resp.completed_cycle_type = completed_cycle_type
    resp.completed_cycle_status = completed_cycle_status
    return resp


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

    payload = data.model_dump(exclude_unset=True)

    completed_cycle_id = payload.pop("completed_cycle_id", None) if "completed_cycle_id" in payload else None
    completed_cycle = None
    if "completed_cycle_id" in data.model_fields_set:
        completed_cycle = _validate_completed_cycle(
            db,
            current_user=current_user,
            completed_cycle_id=completed_cycle_id,
        )
        work.completed_cycle_id = completed_cycle_id

    if "hashtags" in payload:
        work.hashtags = _normalize_hashtags(payload.pop("hashtags") or "")

    inspiration_ids = payload.pop("inspiration_ids", None)
    for field, value in payload.items():
        setattr(work, field, value)

    inspirations: List[InspirationLog] = []
    if inspiration_ids is not None:
        inspirations = _validate_inspirations(
            db,
            current_user=current_user,
            inspiration_ids=inspiration_ids,
            completed_cycle=completed_cycle
            if "completed_cycle_id" in data.model_fields_set
            else _validate_completed_cycle(
                db,
                current_user=current_user,
                completed_cycle_id=work.completed_cycle_id,
            ),
        )
        db.query(WorkInspirationLink).filter(WorkInspirationLink.work_id == work.id).delete()
        for insp in inspirations:
            db.add(WorkInspirationLink(work_id=work.id, inspiration_id=insp.id))

    db.commit()
    db.refresh(work)
    resp = WorkResponse.model_validate(work)
    resp.author_nickname = current_user.nickname
    resp.inspiration_ids = (
        [int(i.id) for i in inspirations]
        if inspiration_ids is not None
        else _get_inspiration_ids_map(db, [int(work.id)]).get(int(work.id), [])
    )
    if work.completed_cycle_id is not None:
        cycle = db.query(WritingCycle).filter(
            WritingCycle.id == work.completed_cycle_id,
            WritingCycle.user_id == current_user.id,
        ).first()
        if cycle is not None:
            resp.completed_cycle_start_date = cycle.start_date
            resp.completed_cycle_end_date = cycle.end_date
            resp.completed_cycle_type = cycle.cycle_type
            resp.completed_cycle_status = cycle.status
    return resp


@router.delete("/{work_id}", status_code=204)
def delete_work(
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

    db.query(Response).filter(Response.work_id == work.id).delete(synchronize_session=False)
    db.query(WorkShare).filter(WorkShare.work_id == work.id).delete(synchronize_session=False)
    db.query(Notification).filter(Notification.related_work_id == work.id).delete(synchronize_session=False)
    db.query(WorkInspirationLink).filter(WorkInspirationLink.work_id == work.id).delete(synchronize_session=False)

    db.delete(work)
    db.commit()
    return None


@router.get("/{work_id}/inspirations", response_model=List[InspirationResponse])
def get_work_inspirations(
    work_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    work = db.query(LiteraryWork).filter(LiteraryWork.id == work_id).first()
    if not work:
        raise HTTPException(status_code=404, detail="找不到此作品")
    ensure_can_access_work(db, work, current_user.id)

    inspirations = (
        db.query(InspirationLog)
        .join(WorkInspirationLink, WorkInspirationLink.inspiration_id == InspirationLog.id)
        .filter(WorkInspirationLink.work_id == work.id)
        .order_by(InspirationLog.event_time.desc())
        .all()
    )
    return inspirations


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
