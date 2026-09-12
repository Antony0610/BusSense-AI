"""FastAPI application entry point for BusSense AI 2.0."""
from __future__ import annotations

from contextlib import asynccontextmanager
from datetime import datetime, timezone

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from backend.config import settings
from backend.routers import analytics, dispatch, sos, telemetry, ticketing


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup sequence
    print("[BusSense AI 2.0] FastAPI Backend and ML Engine initialized.")
    yield
    # Teardown sequence
    print("[BusSense AI 2.0] Shutting down services.")


app = FastAPI(
    title="BusSense AI 2.0 - Transit Intelligence Platform",
    description=(
        "Production-grade intelligent transit backend connecting edge YOLOv8 computer vision, "
        "Supabase PostGIS spatial telemetry, dynamic QR ticketing, and autonomous fleet rebalancing."
    ),
    version="2.0.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)

# CORS Middleware configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount API Routers
app.include_router(telemetry.router)
app.include_router(ticketing.router)
app.include_router(dispatch.router)
app.include_router(sos.router)
app.include_router(analytics.router)


@app.get("/api/health", tags=["System"])
async def health_check():
    """System health check and uptime probe."""
    return JSONResponse(
        content={
            "status": "healthy",
            "version": "2.0.0",
            "environment": settings.ENVIRONMENT,
            "supabase_endpoint": settings.SUPABASE_URL,
            "ml_engine": "online",
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }
    )


@app.get("/", tags=["System"])
async def root():
    return {
        "name": "BusSense AI 2.0 Transit Intelligence API",
        "docs": "/docs",
        "health": "/api/health",
        "version": "2.0.0",
    }
