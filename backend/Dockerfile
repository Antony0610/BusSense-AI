# ==============================================================================
# BusSense AI - Production Backend Dockerfile (Multi-stage Python 3.12)
# ==============================================================================
# Security & Hygiene:
# - Multi-stage build minimizing attack surface and image footprint
# - Dedicated non-root system user (appuser:appgroup / UID:GID 1000:1000)
# - No secrets, virtual environments, or development caches copied into image
# - Bounded healthcheck probe against GET /health/live
# ==============================================================================

# ------------------------------------------------------------------------------
# Stage 1: Dependencies Builder
# ------------------------------------------------------------------------------
FROM python:3.12-slim AS builder

WORKDIR /build

# Install build toolchain for native C extension compilation if required
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

# Install dependencies into user directory
RUN pip install --no-cache-dir --user -r requirements.txt

# ------------------------------------------------------------------------------
# Stage 2: Final Minimal Runtime
# ------------------------------------------------------------------------------
FROM python:3.12-slim AS runner

# Install curl strictly for container healthchecks
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create dedicated non-root user and group
RUN groupadd -g 1000 appgroup && \
    useradd -u 1000 -g appgroup -s /bin/bash -m appuser

WORKDIR /app

# Copy compiled Python packages from builder stage
COPY --from=builder /root/.local /home/appuser/.local

# Copy application source code with non-root ownership
COPY --chown=appuser:appgroup app /app/app
COPY --chown=appuser:appgroup cv /app/cv
COPY --chown=appuser:appgroup knowledge /app/knowledge
COPY --chown=appuser:appgroup migrations /app/migrations

# Set runtime environment
ENV PATH=/home/appuser/.local/bin:$PATH \
    PYTHONPATH=/app \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PORT=8000

# Switch to dedicated non-root user
USER appuser

EXPOSE 8000

# Container liveness health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8000/health/live || exit 1

# Start production ASGI server with graceful termination handling
ENTRYPOINT ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
