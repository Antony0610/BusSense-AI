"""Application configuration loaded from environment variables."""
from __future__ import annotations

import os
from pathlib import Path
from pydantic_settings import BaseSettings, SettingsConfigDict

ROOT_DIR = Path(__file__).resolve().parents[1]


class Settings(BaseSettings):
    SUPABASE_URL: str = "https://kxeixcnqoudxicorxlxs.supabase.co"
    SUPABASE_ANON_KEY: str = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt4ZWl4Y25xb3VkeGljb3J4bHhzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODkxODg4NzcsImV4cCI6MjEwNDc2NDg3N30.sUDQb197hrem3nkiP0nGqXw-6Kh4AOOOMPePTw8VcWM"
    SUPABASE_SERVICE_ROLE_KEY: str = ""
    BACKEND_HOST: str = "0.0.0.0"
    BACKEND_PORT: int = 8000
    ENVIRONMENT: str = "development"
    CORS_ORIGINS: str = "http://localhost:3000,http://localhost:3001,http://localhost:5173,http://localhost:8000,http://127.0.0.1:3000,http://127.0.0.1:3001"
    EDGE_API_KEY: str = "bussense_edge_secret_key_2026"
    YOLO_MODEL_PATH: str = "yolov8n.pt"
    ENABLE_FACE_BLURRING: bool = True
    CONFIDENCE_THRESHOLD: float = 0.35

    model_config = SettingsConfigDict(
        env_file=str(ROOT_DIR / ".env"),
        env_file_encoding="utf-8",
        extra="ignore",
    )

    @property
    def cors_origin_list(self) -> list[str]:
        return [origin.strip() for origin in self.CORS_ORIGINS.split(",") if origin.strip()]


settings = Settings()
