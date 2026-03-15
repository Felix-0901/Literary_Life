from contextlib import asynccontextmanager
import json
import logging
import time

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import inspect

from app.config import get_settings
from app.database import engine
from app.models import *  # noqa: F401, F403 — import all models to register them
from app.models.quote import Quote
from app.routers import (
    auth, quotes, inspirations, cycles, works,
    friends, groups, shares, responses, notifications, ai,
)

settings = get_settings()
logger = logging.getLogger("literary_life.api")
logging.basicConfig(level=logging.INFO, format="%(message)s")


def _seed_quotes() -> None:
    """Seed initial quotes if the table is empty."""
    from app.database import SessionLocal

    if not inspect(engine).has_table(Quote.__tablename__):
        return

    db = SessionLocal()
    try:
        count = db.query(Quote).count()
        if count == 0:
            quotes = [
                Quote(content="生活不是我們活過的日子，而是我們記住的日子。", author="乃寒", source="", category="文學"),
                Quote(content="我們用文字，把平凡的日子釀成詩。", author="拾字日常", source="", category="文學"),
                Quote(content="在一切聲音消失之後，文字仍然存在。", author="卡爾維諾", source="《如果在冬夜，一個旅人》", category="文學"),
                Quote(content="寫作是一種旅行，不需要地圖。", author="娥蘇拉·乃 京恩", source="", category="文學"),
                Quote(content="每一個不曾起舞的日子，都是對生命的辜負。", author="尼采", source="", category="哲學"),
                Quote(content="文學使人看見水中的魚，而不只是水面。", author="契訶夫", source="", category="文學"),
                Quote(content="日常中藏著無數故事，只等有心人拾起。", author="拾字日常", source="", category="文學"),
                Quote(content="一個人只要有了足夠的內在之光, 就不怕外在的黑暗。", author="赫曼·赫塞", source="《乃至歸途》", category="文學"),
                Quote(content="生命從來不曾離開過孤獨而獨立存在。", author="村上春樹", source="", category="文學"),
                Quote(content="真正的發現之旅，不在於尋找新風景，而在於擁有新眼光。", author="馬塞爾·普魯斯特", source="《追憶似水年華》", category="文學"),
                Quote(content="文字是靈魂行走留下的腳印。", author="拾字日常", source="", category="文學"),
                Quote(content="世界上任何書籍都不能帶給你好運，但它們能讓你悄悄成為你自己。", author="赫曼·赫塞", source="", category="文學"),
                Quote(content="把每天當成最後一天來過, 總有一天你會發現自己是對的。", author="史蒂夫·賈伯斯", source="", category="人生"),
                Quote(content="我們走得太快了，是時候停下來，等一等靈魂。", author="不詳", source="", category="生活"),
                Quote(content="如果你給我的與給別人的一樣, 那我就不要了。", author="三毛", source="", category="文學"),
                Quote(content="時間會刺破青春的表面，會在美人的額上掘深深的溝渠。", author="莎士比亞", source="", category="文學"),
                Quote(content="生活就像海洋，只有意志堅強的人才能到達彼岸。", author="馬克思", source="", category="哲學"),
                Quote(content="我思故我在。", author="笛卡兒", source="《方法論》", category="哲學"),
                Quote(content="溫柔地記錄每一個值得被文字收藏的瞬間。", author="拾字日常", source="", category="文學"),
                Quote(content="人的一切痛苦，本質上都是對自己無能的憤怒。", author="王小波", source="", category="文學"),
            ]
            db.add_all(quotes)
            db.commit()
    finally:
        db.close()


@asynccontextmanager
async def lifespan(_: FastAPI):
    if settings.is_production and settings.SECRET_KEY == "replace-me":
        raise RuntimeError("SECRET_KEY must be set in production")
    _seed_quotes()
    yield


app = FastAPI(
    title="拾字日常 Literary Life API",
    description="讓文學貼近生活的數位創作平台",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers
app.include_router(auth.router)
app.include_router(quotes.router)
app.include_router(inspirations.router)
app.include_router(cycles.router)
app.include_router(works.router)
app.include_router(friends.router)
app.include_router(groups.router)
app.include_router(shares.router)
app.include_router(responses.router)
app.include_router(notifications.router)
app.include_router(ai.router)


@app.middleware("http")
async def log_requests(request: Request, call_next):
    start = time.perf_counter()
    response = await call_next(request)
    duration_ms = round((time.perf_counter() - start) * 1000, 2)
    logger.info(
        json.dumps(
            {
                "event": "http_request",
                "method": request.method,
                "path": request.url.path,
                "status_code": response.status_code,
                "duration_ms": duration_ms,
            },
            ensure_ascii=True,
        )
    )
    return response


@app.get("/")
def root():
    return {
        "name": "拾字日常 Literary Life",
        "version": "1.0.0",
        "description": "把生活拾起，寫成文字。",
    }


@app.get("/healthz")
def healthz():
    return {
        "status": "ok",
        "environment": settings.ENVIRONMENT,
        "version": app.version,
    }
