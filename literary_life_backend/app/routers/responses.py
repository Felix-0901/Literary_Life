from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User
from app.models.response import Response
from app.models.notification import Notification
from app.models.work import LiteraryWork
from app.services.work_access import ensure_can_access_work
from app.schemas.response import ResponseCreate, ResponseOut
from app.utils.security import get_current_user

router = APIRouter(prefix="/api/responses", tags=["文學回應"])


@router.post("/", response_model=ResponseOut, status_code=201)
def create_response(
    data: ResponseCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    work = db.query(LiteraryWork).filter(LiteraryWork.id == data.work_id).first()
    if not work:
        raise HTTPException(status_code=404, detail="找不到此作品")
    ensure_can_access_work(db, work, current_user.id)

    resp = Response(
        work_id=data.work_id,
        user_id=current_user.id,
        content=data.content,
    )
    db.add(resp)

    # Notify the work author (unless the author is the responder)
    if work.user_id != current_user.id:
        db.add(
            Notification(
                user_id=work.user_id,
                type="response",
                title="收到新回應",
                body=f"{current_user.nickname} 回應了你的「{work.title}」",
                related_work_id=work.id,
            )
        )

    db.commit()
    db.refresh(resp)
    out = ResponseOut.model_validate(resp)
    out.author_nickname = current_user.nickname
    return out


@router.get("/work/{work_id}", response_model=List[ResponseOut])
def get_work_responses(
    work_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    work = db.query(LiteraryWork).filter(LiteraryWork.id == work_id).first()
    if not work:
        raise HTTPException(status_code=404, detail="找不到此作品")
    ensure_can_access_work(db, work, current_user.id)

    responses = (
        db.query(Response)
        .filter(Response.work_id == work_id)
        .order_by(Response.created_at.desc())
        .all()
    )

    user_ids = [response.user_id for response in responses]
    user_map = {
        user.id: user.nickname
        for user in db.query(User).filter(User.id.in_(user_ids)).all()
    }

    result = []
    for response in responses:
        out = ResponseOut.model_validate(response)
        out.author_nickname = user_map.get(response.user_id, "未知")
        result.append(out)
    return result
