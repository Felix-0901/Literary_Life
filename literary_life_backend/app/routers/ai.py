from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from pydantic import BaseModel
from typing import Optional, List
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User
from app.models.inspiration import InspirationLog
from app.services.ai_service import (
    AIServiceError,
    analyze_inspirations,
    get_writing_help,
    summarize_inspiration_title,
    transcribe_audio,
)
from app.utils.security import get_current_user

router = APIRouter(prefix="/api/ai", tags=["AI 輔助"])


class AnalyzeRequest(BaseModel):
    cycle_id: int


class WritingHelpRequest(BaseModel):
    help_type: str  # title, opening, polish, structure
    context: str


@router.post("/analyze")
async def analyze_cycle_inspirations(
    data: AnalyzeRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    inspirations = (
        db.query(InspirationLog)
        .filter(
            InspirationLog.user_id == current_user.id,
            InspirationLog.cycle_id == data.cycle_id,
        )
        .all()
    )
    if not inspirations:
        raise HTTPException(status_code=404, detail="此週期沒有靈感紀錄")

    insp_dicts = [
        {
            "event_time": str(i.event_time),
            "location": i.location,
            "object_or_event": i.object_or_event,
            "detail_text": i.detail_text,
            "feeling": i.feeling,
            "keywords": i.keywords,
        }
        for i in inspirations
    ]
    try:
        result = await analyze_inspirations(insp_dicts)
        return result
    except AIServiceError as error:
        raise HTTPException(status_code=502, detail=str(error)) from error


@router.post("/help")
async def writing_assistance(
    data: WritingHelpRequest,
    current_user: User = Depends(get_current_user),
):
    try:
        result = await get_writing_help(data.help_type, data.context)
        return {"result": result}
    except AIServiceError as error:
        raise HTTPException(status_code=502, detail=str(error)) from error


@router.post("/transcribe-inspiration")
async def transcribe_inspiration(
    audio: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
):
    raw = await audio.read()
    if not raw:
        raise HTTPException(status_code=400, detail="未收到音訊內容")
    try:
        transcript = await transcribe_audio(raw, audio.filename or "audio.m4a")
        title = await summarize_inspiration_title(transcript)
        return {"title": title, "transcript": transcript}
    except AIServiceError as error:
        raise HTTPException(status_code=502, detail=str(error)) from error
    finally:
        del raw
