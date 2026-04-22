import asyncio
import io
import os
from typing import List, Optional

import httpx

from app.config import get_settings

settings = get_settings()


WHISPER_MODEL_SIZE = os.environ.get("WHISPER_MODEL_SIZE", "small")
WHISPER_MODEL_DIR = os.environ.get("WHISPER_MODEL_DIR", "/app/models")
WHISPER_COMPUTE_TYPE = os.environ.get("WHISPER_COMPUTE_TYPE", "int8")


class AIServiceError(RuntimeError):
    pass


_whisper_model = None
_whisper_model_lock = asyncio.Lock()


async def _load_whisper_model():
    """Lazy-load the faster-whisper model once per process."""
    global _whisper_model
    if _whisper_model is not None:
        return _whisper_model
    async with _whisper_model_lock:
        if _whisper_model is not None:
            return _whisper_model
        try:
            from faster_whisper import WhisperModel
        except ImportError as e:
            raise AIServiceError(
                "faster-whisper 尚未安裝，請確認後端相依套件"
            ) from e
        loop = asyncio.get_running_loop()
        _whisper_model = await loop.run_in_executor(
            None,
            lambda: WhisperModel(
                WHISPER_MODEL_SIZE,
                device="cpu",
                compute_type=WHISPER_COMPUTE_TYPE,
                download_root=WHISPER_MODEL_DIR,
            ),
        )
    return _whisper_model


async def call_ai(prompt: str, system_prompt: str = "") -> str:
    """Call the AI API (量界智算) for literary assistance."""
    messages = []
    if system_prompt:
        messages.append({"role": "system", "content": system_prompt})
    messages.append({"role": "user", "content": prompt})

    if not settings.AI_API_KEY:
        raise AIServiceError("AI_API_KEY 尚未設定")

    async with httpx.AsyncClient(timeout=60.0) as client:
        try:
            response = await client.post(
                f"{settings.AI_API_URL}/chat/completions",
                headers={
                    "Authorization": f"Bearer {settings.AI_API_KEY}",
                    "Content-Type": "application/json",
                },
                json={
                    "model": settings.AI_MODEL,
                    "messages": messages,
                    "temperature": 0.8,
                    "max_tokens": 2000,
                },
            )
            response.raise_for_status()
            data = response.json()
            if "choices" not in data or not data["choices"]:
                raise AIServiceError("AI 服務回傳格式不正確")
            return data["choices"][0]["message"]["content"]
        except AIServiceError:
            raise
        except Exception as e:
            raise AIServiceError(f"AI 服務暫時無法使用：{str(e)}") from e


LITERARY_SYSTEM_PROMPT = """你是一位溫柔而富有詩意的文學助手，名為「拾字」。
你的任務是幫助使用者將日常生活中的片段、感受、靈感，轉化成優美的文學作品。
你不會直接代替使用者創作，而是提供引導、建議和潤飾。
請使用繁體中文回覆。語調溫暖、富有文學性。"""


async def analyze_inspirations(inspirations: List[dict]) -> dict:
    """Analyze a collection of inspirations for themes, keywords, emotions."""
    texts = []
    for i, insp in enumerate(inspirations, 1):
        texts.append(
            f"第 {i} 筆：\n"
            f"  時間：{insp.get('event_time', '')}\n"
            f"  地點：{insp.get('location', '')}\n"
            f"  事件：{insp.get('object_or_event', '')}\n"
            f"  細節：{insp.get('detail_text', '')}\n"
            f"  感受：{insp.get('feeling', '')}\n"
            f"  關鍵字：{insp.get('keywords', '')}"
        )

    prompt = f"""以下是使用者在一段時間內記錄的生活靈感片段：

{chr(10).join(texts)}

請幫我分析這些靈感，回傳以下內容（請用 JSON 格式）：
1. "themes"：重複出現的主題（列出 3-5 個）
2. "keywords"：高頻關鍵字（列出 5-8 個）
3. "emotions"：常見情緒（列出 3-5 個）
4. "recommended_genre"：推薦的文體（散文、新詩、短札記、微小說、書信體，選一個最適合的）
5. "title_suggestions"：3 個題目建議
6. "opening_suggestions"：2 個開頭句建議
"""

    result = await call_ai(prompt, LITERARY_SYSTEM_PROMPT)
    return {"analysis": result}


async def get_writing_help(help_type: str, context: str) -> str:
    """Get specific writing assistance."""
    prompts = {
        "title": f"請根據以下內容，提供 3 個富有文學性的標題建議：\n\n{context}",
        "opening": f"請根據以下內容，提供 2 個優美的開頭句：\n\n{context}",
        "polish": f"請幫我潤飾以下文字，讓它更有文學性，但保留原意：\n\n{context}",
        "structure": f"請根據以下靈感片段，建議一個段落架構：\n\n{context}",
    }

    prompt = prompts.get(help_type, f"請提供文學創作建議：\n\n{context}")
    return await call_ai(prompt, LITERARY_SYSTEM_PROMPT)


def _run_whisper_transcribe(model, audio_bytes: bytes) -> str:
    """Blocking transcription — run in an executor."""
    audio_io = io.BytesIO(audio_bytes)
    segments, _ = model.transcribe(
        audio_io,
        language="zh",
        beam_size=5,
        vad_filter=True,
    )
    text = "".join(segment.text for segment in segments).strip()
    return text


async def transcribe_audio(audio_bytes: bytes, filename: str) -> str:
    """Transcribe audio bytes to text using the local faster-whisper model."""
    if not audio_bytes:
        raise AIServiceError("音訊內容為空")
    try:
        model = await _load_whisper_model()
        loop = asyncio.get_running_loop()
        text = await loop.run_in_executor(
            None, _run_whisper_transcribe, model, audio_bytes
        )
    except AIServiceError:
        raise
    except Exception as e:
        raise AIServiceError(f"語音轉文字失敗：{str(e)}") from e
    if not text:
        raise AIServiceError("語音轉文字失敗：結果為空")
    return text


async def summarize_inspiration_title(transcript: str) -> str:
    """Generate a short Chinese title (6-12 chars) summarizing the inspiration."""
    system_prompt = (
        "你是靈感筆記助手，專門為使用者的口述內容擬定簡潔標題。"
        "請只輸出標題本身，不要加上引號、標點符號或任何額外說明。"
    )
    prompt = (
        "請為下列口述內容擬一個 6 到 12 個中文字的精簡標題，"
        "聚焦在核心的事件或物品上，不要使用句號：\n\n"
        f"{transcript}"
    )
    raw = await call_ai(prompt, system_prompt)
    title = raw.strip().splitlines()[0] if raw else ""
    title = title.strip().strip("「」\"'。，、 ")
    if not title:
        raise AIServiceError("AI 無法產生標題")
    return title[:20]
