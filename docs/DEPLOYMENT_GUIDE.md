# BusSense AI — Containerized Deployment & Operations Guide
## Phase H14 Step 3: Local, Staging & Production Container Orchestration

This guide provides operational runbooks for orchestrating the BusSense AI platform using Docker and Docker Compose. It outlines container architectures, environment configurations, health check protocols, backup routines, and rollback strategies.

---

## 1. Architecture & Container Topology

The containerized deployment consists of two primary services communicating over a private bridge network (`bussense-network`) alongside an external connection to the managed Supabase PostgreSQL instance:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        HOST / INGRESS ENVIRONMENT                      │
├───────────────────────────────────┬────────────────────────────────────┤
│   COMMUTER BROWSER / AUTHORITY    │   FLUTTER MOBILE CLIENTS (DEVICE)  │
│      (http://localhost:3000)      │     (http://<HOST_IP>:8000/api)    │
└─────────────────┬─────────────────┴──────────────────┬─────────────────┘
                  │                                    │
                  ▼                                    ▼
       ┌──────────────────────┐             ┌──────────────────────┐
       │  bussense-authority  │             │   bussense-backend   │
       │  (Port 3000:3000)    │             │   (Port 8000:8000)   │
       │  Next.js Standalone  │             │   FastAPI Python 3.12│
       └──────────┬───────────┘             └──────────┬───────────┘
                  │                                    │
                  │   bussense-network (bridge)        │
                  └─────────────────┬──────────────────┘
                                    │
                                    │ TLS 1.3 / HTTPS (Port 5432/443)
                                    ▼
       ┌───────────────────────────────────────────────────────────┐
       │             SUPABASE MANAGED CLOUD PLATFORM               │
       │             PostgreSQL 15 / PostgREST REST API            │
       │             Project ID: lqegmqgkymstycpzplld              │
       └───────────────────────────────────────────────────────────┘
```

> [!IMPORTANT]
> **Database Isolation:** Supabase PostgreSQL runs as a managed cloud service in `ap-south-1`. It is intentionally NOT run inside Docker. The backend container communicates with Supabase over secure HTTPS/WSS protocols.

---

## 2. Prerequisites & Environment Setup

### 2.1 Host System Requirements
- **OS:** Windows 10/11 (with WSL2), macOS, or modern Linux (Ubuntu 22.04 LTS recommended).
- **Docker Engine:** Version 24.0+ with Docker Compose v2.20+.
- **Memory:** Minimum 4GB RAM allocated to Docker.
- **Disk:** 5GB free storage for container images and layer caches.

### 2.2 Local Environment File Configuration
Before launching containers, create a dedicated `.env` file from the provided templates:

```powershell
# In Windows PowerShell at repository root:
Copy-Item .env.example .env
```

Ensure the following variables are configured in `.env` (using placeholders for documentation):

```ini
# Application Mode
ENVIRONMENT=staging
DEBUG=False
DEMO_MODE=False

# Backend Network
BACKEND_HOST=0.0.0.0
BACKEND_PORT=8000
SECRET_KEY=[REQUIRED_GENERATE_MINIMUM_32_CHAR_RANDOM_SECRET]
ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000

# Supabase Cloud Integration (ap-south-1)
SUPABASE_URL=https://[YOUR_PROJECT_REF].supabase.co
SUPABASE_ANON_KEY=[YOUR_SUPABASE_ANON_KEY]
SUPABASE_SERVICE_ROLE_KEY=[YOUR_SUPABASE_SERVICE_ROLE_KEY]

# Frontend Public Bindings
NEXT_PUBLIC_API_URL=http://localhost:8000/api
NEXT_PUBLIC_WS_URL=ws://localhost:8000/ws/telemetry
```

> [!WARNING]
> **Browser vs Container Networking:** When the Authority console is accessed from a desktop browser outside the Docker bridge network, client-side requests must resolve `NEXT_PUBLIC_API_URL` through the host port (`http://localhost:8000/api`), NOT the internal Docker hostname (`http://backend:8000/api`).

---

## 3. Image Build & Lifecycle Runbook

### 3.1 Individual Image Builds
To build services independently using Docker:

```powershell
# Build Backend Service
docker build -t bussense-backend:1.0.0 -f backend/Dockerfile ./backend

# Build Authority Frontend Service (with build args)
docker build -t bussense-authority:1.0.0 `
  --build-arg NEXT_PUBLIC_API_URL="http://localhost:8000/api" `
  --build-arg NEXT_PUBLIC_WS_URL="ws://localhost:8000/ws/telemetry" `
  -f frontend/Dockerfile ./frontend
```

### 3.2 Docker Compose Orchestration

```powershell
# Validate compose configuration without launching
docker compose config

# Build images and start services in detached mode
docker compose up -d --build

# Inspect container status and health states
docker compose ps

# Follow unified operational logs
docker compose logs -f

# Follow specific service logs
docker compose logs -f backend
docker compose logs -f frontend

# Gracefully stop containers
docker compose stop

# Stop and remove containers and bridge network
docker compose down
```

---

## 4. Health Check & Observability Verification

Both containers implement dedicated, automated health check probes with bounded timeouts:

| Container | Probe Command | Interval | Timeout | Retries | Evaluates |
| :--- | :--- | :---: | :---: | :---: | :--- |
| **`bussense-backend`** | `curl -f http://localhost:8000/health/live` | 30s | 5s | 3 | FastAPI ASGI process responsiveness |
| **`bussense-authority`** | `wget -q --spider http://127.0.0.1:3000/` | 30s | 5s | 3 | Next.js Node.js server route response |

### Verification via Host Shell
Once containers are running, test endpoints directly from PowerShell:

```powershell
# 1. Test Backend Liveness (Process alive)
Invoke-RestMethod -Uri "http://localhost:8000/health/live"

# Expected Output:
# status    timestamp                        version
# ------    ---------                        -------
# alive     2026-10-17T...                   1.0.0

# 2. Test Backend Readiness (Supabase dependency alive)
Invoke-RestMethod -Uri "http://localhost:8000/health/ready"

# Expected Output:
# status    database     timestamp           version
# ------    --------     ---------           -------
# ready     connected    2026-10-17T...      1.0.0

# 3. Test Authority Frontend Root
Invoke-WebRequest -Uri "http://localhost:3000" -Method Head
```

---

## 5. Model Weights & Video Asset Handling

1. **YOLOv8 Detection Weights (`yolov8n.pt`):**
   - The lightweight model file (`yolov8n.pt`, 6.5MB) is mounted as a read-only volume in `docker-compose.yml`:
     ```yaml
     volumes:
       - ./yolov8n.pt:/app/yolov8n.pt:ro
     ```
   - When running in headless environments without physical camera feeds, the system defaults to high-fidelity simulation (`CV_MODE=SIMULATION`), generating occupancy telemetry compliant with person-counting guidelines.
2. **Video Ingestion Assets:**
   - In physical bus test installations (`CV_MODE=REAL_VIDEO`), video sources are streamed via RTSP or mapped from `/data/cctv` host volumes.

---

## 6. Environment Boundaries: Local vs Staging vs Production

| Feature | Local Development | Staging (Docker Compose) | Production |
| :--- | :--- | :--- | :--- |
| **Execution** | `uvicorn` & `next dev` | `docker compose up -d` | Kubernetes / ECS Cluster |
| **`ENVIRONMENT`** | `development` | `staging` | `production` |
| **`DEBUG`** | `True` or `False` | `False` | `False` (Enforced) |
| **`DEMO_MODE`** | `True` | `False` | `False` (Enforced) |
| **`SECRET_KEY`** | Dev fallback permitted | Minimum 32 chars | Cryptographically generated (RNG) |
| **`ALLOWED_ORIGINS`** | `localhost:3000` | Staging domain / IPs | Registered production FQDN |
| **SSL / TLS** | HTTP | HTTP / Self-signed | Managed TLS via Reverse Proxy (Nginx/Cloudflare) |
| **Database** | Supabase Dev Project | Supabase Staging Project | Supabase High-Availability Instance |

---

## 7. Rollback & Disaster Recovery Procedures

### 7.1 Image Rollback
If a newly deployed image exhibits degraded performance:
```powershell
# 1. Revert compose image tag to prior stable checkpoint (e.g. v1.0.0-h13)
docker compose stop backend
docker compose rm -f backend
# Update docker-compose.yml or tag reference
docker compose up -d backend
```

### 7.2 Database State Preservation
- Supabase provides point-in-time recovery (PITR) and daily automated snapshots.
- Prior to staging migrations, operators should execute a schema backup via pg_dump:
  ```powershell
  pg_dump --clean --if-exists --no-owner -h db.[PROJECT_REF].supabase.co -U postgres -d postgres > backup_pre_release.sql
  ```

---

## 8. Current Deployment Status & Blockers

- [x] **Backend Multi-Stage Dockerfile:** Implemented with non-root security.
- [x] **Frontend Standalone Dockerfile:** Implemented with Next.js 14 standalone runner.
- [x] **Docker Compose Architecture:** Root `docker-compose.yml` validated.
- [x] **Static Configuration Validation:** Passed 100%.
- [x] **Automated Test Regressions:** 203 backend tests, 22 authority tests, 100 mobile tests passing.
- [ ] **Docker Engine Availability:** **BLOCKED ON HOST** (Docker is not installed on this local Windows environment).
- [ ] **Public Production Deployment:** Deferred per release protocol. Staging verification pending on host with Docker installed.
