from fastapi import FastAPI

from .config import settings
from .ffmpeg import ffmpeg_version

app = FastAPI(title="TikTok Series Cutter — worker vidéo", version="0.1.0")


@app.get("/health")
def health() -> dict:
    ffmpeg = ffmpeg_version()
    return {
        "status": "ok" if ffmpeg else "degraded",
        "ffmpeg": ffmpeg,
        "supabase": "connected" if settings.supabase_url and settings.supabase_service_role_key else "missing",
        "llm": settings.llm_provider or "missing",
    }
