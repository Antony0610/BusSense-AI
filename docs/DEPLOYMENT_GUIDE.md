# BusSense AI — Deployment Operations & Recovery Guide
## Phase H14: Production Operations, Disaster Recovery & Staging Verification

This guide is the authoritative operational runbook for deploying, configuring, monitoring, backing up, and recovering BusSense AI services across local, staging, and production environments.

---

## 1. System Architecture & Topology

The containerized deployment consists of two primary services communicating over an unexposed bridge network (`bussense-network`) alongside external TLS connections to the managed Supabase PostgreSQL instance:

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
> **Database Isolation:** Supabase PostgreSQL runs as a managed cloud service in `ap-south-1`. It is intentionally NOT containerized inside Docker. The backend container communicates with Supabase over secure HTTPS/WSS protocols.

---

## 2. Prerequisites & Supported Environment

### 2.1 Hardware & OS Requirements
- **Operating Systems:**
  - Linux: Ubuntu 22.04 LTS / Debian 12 (Recommended for staging & production hosts).
  - Windows: Windows 10/11 Pro or Enterprise with WSL2 enabled.
  - macOS: macOS 13+ (Apple Silicon or Intel).
- **Compute:** Minimum 2 CPU cores, 4GB RAM allocated to Docker.
- **Disk:** 10GB free SSD storage for container images and layer caches.

### 2.2 Software Toolchain
- **Docker Engine:** Version 24.0.0 or higher.
- **Docker Compose:** Compose V2 (version 2.20.0 or higher, `docker compose`).
- **Python:** 3.11+ (for running the staging verification smoke tests).
- **Node.js:** 20.x LTS (for local Next.js client development outside Docker).

---

## 3. Safe Environment File Creation

Never commit actual `.env` files containing production secrets to git. The repository enforces this via `.gitignore`.

### 3.1 Generating Configuration from Templates
On the deployment host, create the local `.env` using `.env.production.example` or `.env.example`:

```powershell
# In Windows PowerShell:
Copy-Item .env.production.example .env

# On Linux / macOS:
cp .env.production.example .env
```

### 3.2 Generating Cryptographic Secrets
Generate a secure, random 32+ character hex key for JWT signing:

```powershell
# Using OpenSSL (PowerShell / Linux):
openssl rand -hex 32

# Or using Python:
python -c "import secrets; print(secrets.token_hex(32))"
```

Insert this value into `.env` as `SECRET_KEY`.

---

## 4. Environment Variables Specification

The table below explains every mandatory and optional environment variable across services:

| Variable | Required in Prod? | Service | Example / Default | Purpose |
| :--- | :---: | :---: | :--- | :--- |
| `ENVIRONMENT` | **YES** | Backend | `staging` / `production` | Enforces production security checks when set to `production` |
| `DEBUG` | **YES** | Backend | `False` | Disables debug endpoints and verbose tracebacks |
| `DEMO_MODE` | **YES** | Backend | `False` | Locks commuter demo accounts (`DEV_ACCOUNTS`) |
| `BACKEND_HOST` | **YES** | Backend | `0.0.0.0` | Container bind address |
| `BACKEND_PORT` | **YES** | Backend | `8000` | Port listening for incoming HTTP/WebSocket traffic |
| `SECRET_KEY` | **YES** | Backend | `[32+ hex string]` | HMAC secret for JWT token issuance and verification |
| `ALLOWED_ORIGINS` | **YES** | Backend | `https://admin.bussense.kerala.gov.in` | Comma-separated list of authorized Web origins |
| `SUPABASE_URL` | **YES** | Backend | `https://lqegmqgkymstycpzplld.supabase.co` | HTTPS endpoint for Supabase PostgREST |
| `SUPABASE_ANON_KEY` | **YES** | Backend | `eyJhbGciOi...` | Public client key for user-scoped operations |
| `SUPABASE_SERVICE_ROLE_KEY` | **YES** | Backend | `eyJhbGciOi...` | Elevated backend key for atomic ticket validation RPC |
| `DATABASE_URL` | Optional | Backend | `postgresql://...:5432/postgres` | Direct connection string for migration runners |
| `SIMULATION_INTERVAL_SECONDS`| Optional | Backend | `2` | Interval for simulated GPS and crowd physics loop |
| `DEFAULT_TRANSIT_CITY` | Optional | Backend | `Kochi, Kerala` | Default operational city context |
| `CV_MODE` | Optional | Backend | `SIMULATION` | Computer vision ingestion (`SIMULATION` / `REAL_VIDEO`) |
| `NEXT_PUBLIC_API_URL` | **YES** | Frontend | `http://localhost:8000/api` | Browser-accessible base URL for backend API |
| `NEXT_PUBLIC_WS_URL` | **YES** | Frontend | `ws://localhost:8000/ws/telemetry` | Browser-accessible WebSocket endpoint |

> [!CAUTION]
> **Secret Hygiene:** `SUPABASE_SERVICE_ROLE_KEY` must **never** be prefixed with `NEXT_PUBLIC_` or provided to the frontend container build arguments. It is strictly confidential to the backend.

---

## 5. Build, Startup, and Shutdown Procedures

### 5.1 Pre-Flight Compose Validation
Before building or launching, validate the syntax of the compose specification:

```powershell
docker compose config
```

### 5.2 Building Images & Launching Services
Build multi-stage images and start containers in detached mode:

```powershell
# Build and start all services
docker compose up -d --build

# Verify container runtime states
docker compose ps
```

Expected output:
```
NAME                 IMAGE                       COMMAND                  SERVICE    STATUS
bussense-backend     bussense-ai-backend:latest   "uvicorn app.main:ap…"   backend    Up (healthy)
bussense-authority   bussense-ai-frontend:latest  "node server.js"         frontend   Up (healthy)
```

### 5.3 Service Logs Inspection
Inspect operational output and verify no sensitive credentials are leaked:

```powershell
# Stream all unified logs
docker compose logs -f

# Follow backend logs specifically
docker compose logs -f backend

# Follow authority console logs
docker compose logs -f frontend
```

### 5.4 Graceful Shutdown
To stop services while allowing running tasks to terminate cleanly:

```powershell
# Gracefully stop containers (sends SIGTERM, waits 10s before SIGKILL)
docker compose stop

# Stop and remove containers and bridge network
docker compose down
```

### 5.5 Recreating Services After Configuration Edits
When modifying environment variables in `.env`:

```powershell
# Recreate backend with updated configuration without stopping frontend
docker compose up -d --no-deps backend

# Rebuild frontend if NEXT_PUBLIC_* variables changed
docker compose up -d --no-deps --build frontend
```

---

## 6. Health Checks & Service Monitoring

Both containers feature automated health checks configured with bounded timeouts to prevent unready traffic ingestion:

| Service | Endpoint Probe | Interval | Timeout | Retries | Start Period |
| :--- | :--- | :---: | :---: | :---: | :---: |
| **Backend** | `curl -f http://localhost:8000/health/live` | 30s | 5s | 3 | 10s |
| **Frontend** | `wget -q --spider http://127.0.0.1:3000/` | 30s | 5s | 3 | 15s |

### Manual Health Verification Commands
Test probes directly from the host shell:

```powershell
# 1. Test Backend Liveness (Process alive, zero external dependencies)
Invoke-RestMethod -Uri "http://localhost:8000/health/live"
# Returns: { "status": "alive", "timestamp": "...", "version": "1.0.0" }

# 2. Test Backend Readiness (Supabase dependency alive)
Invoke-RestMethod -Uri "http://localhost:8000/health/ready"
# Returns: { "status": "ready", "database": "connected", "timestamp": "...", "version": "1.0.0" }

# 3. Test Authority Frontend
Invoke-WebRequest -Uri "http://localhost:3000" -Method Head
# Returns: StatusCode 200
```

---

## 7. Staging Smoke Verification Runbook

BusSense AI includes an automated, non-destructive staging smoke-test script in `scripts/staging_smoke_test.py`. It uses standard Python libraries (no pip dependencies needed).

### Running the Smoke Test Suite
```powershell
# Run against standard local/staging container ports:
python scripts/staging_smoke_test.py

# Or specify custom host URLs via environment variables:
$env:BACKEND_URL="http://localhost:8000"
$env:FRONTEND_URL="http://localhost:3000"
$env:TEST_ENVIRONMENT="staging"
python scripts/staging_smoke_test.py
```

### Verification Checks Performed
1. **Backend Liveness:** Validates `GET /health/live` returns HTTP 200 `status: alive`.
2. **Backend Readiness:** Validates `GET /health/ready` returns HTTP 200 `database: connected`.
3. **Correlation Tracking:** Validates response headers contain `X-Request-ID`.
4. **Authority Console:** Validates `GET /` returns HTTP 200.
5. **Dynamic CORS:** Validates preflight headers disallow wildcard with credentials.
6. **Authentication RBAC:** Validates unauthenticated `GET /api/auth/me` returns HTTP 401.
7. **Conductor Role Barrier:** Validates unauthorized ticket scans return HTTP 401/403.
8. **Realtime Polling Fallback:** Validates `GET /api/realtime/events?limit=5` returns HTTP 200.
9. **Corridor Routes API:** Validates `GET /api/routes` returns active transit routes.

All test output is sanitized; access tokens and passwords are never printed to stdout.

---

## 8. Database Migrations & Schema Management

All database schemas, stored procedures, and Row-Level Security (RLS) policies are version-controlled in `backend/migrations/`:

| Migration | Scope | Description |
| :--- | :--- | :--- |
| `001_initial_schema.sql` | Core Schema | Initial 26 transit tables, users, routes, buses |
| `002_security_rls.sql` | Security | Initial Row-Level Security definitions |
| `003_knowledge_chunks.sql` | AI / RAG | Vector knowledge tables for transit assistant |
| `004_atomic_ticket_validation.sql` | Conductor | Stored procedure `validate_ticket_atomic` |
| `005_realtime_notifications.sql` | Realtime | Deduplicated notification tables |
| `006_supabase_security_remediation.sql` | Hardening | Remediated 9 advisor findings; enforced search_path |

### 8.1 Applying Migrations
1. **Via Supabase Dashboard (Recommended for Managed Cloud):**
   - Navigate to **SQL Editor** in the Supabase Dashboard (`https://supabase.com/dashboard/project/lqegmqgkymstycpzplld/sql`).
   - Open and execute the migration file in sequential numerical order.
2. **Via Direct PostgreSQL Connection (Host Operator):**
   ```powershell
   psql -h db.lqegmqgkymstycpzplld.supabase.co -U postgres -d postgres -f backend/migrations/006_supabase_security_remediation.sql
   ```

---

## 9. Backup, Disaster Recovery & Rollback Strategy

A reliable disaster recovery strategy requires clearly delineating automated managed services, manual logical backups, and application rollback responsibilities.

### 9.1 Disaster Recovery Responsibilities Matrix

| Failure Domain | Responsible Component | Recovery Mechanism | Target RTO / RPO |
| :--- | :--- | :--- | :--- |
| **Application Crash** | Docker Engine | Restart policy: `unless-stopped` | RTO < 10 seconds |
| **Bad Container Release** | Operations Team | Image rollback via tag / git revert | RTO < 5 minutes |
| **Database Corruption** | Supabase Managed PITR | Point-in-Time Recovery to timestamp | RTO < 30 mins / RPO < 1 min |
| **Accidental Table Drop** | Supabase Daily Backup | Restore daily cloud snapshot | RTO < 1 hour / RPO < 24 hours |
| **Migration Syntax Error** | Operator | Execute corresponding rollback script | RTO < 15 minutes |

### 9.2 Pre-Release Logical Backup (Manual Safeguard)
Prior to applying major database migrations or production releases, operators must execute a logical schema and data export:

```powershell
# In PowerShell (requires PostgreSQL client tools installed):
pg_dump --clean --if-exists --no-owner `
  -h db.lqegmqgkymstycpzplld.supabase.co `
  -U postgres -d postgres > "backup_pre_release_$(Get-Date -Format 'yyyyMMdd_HHmmss').sql"
```

> [!WARNING]
> **Operator Authorization Required:** Restoring a database from a logical dump or initiating a Supabase PITR rewind overwrites live transit ledgers and invalidates recent QR validations. This action requires explicit operational sign-off from the Transit Authority Release Manager.

### 9.3 Application Image Rollback Procedure
If a container release introduces a regression:

```powershell
# 1. Stop the degraded container
docker compose stop backend

# 2. Revert the repository to the protected release tag (e.g., v1.0.0-h13)
git checkout v1.0.0-h13

# 3. Rebuild and launch the verified container image
docker compose up -d --build backend

# 4. Verify backend health
Invoke-RestMethod -Uri "http://localhost:8000/health/live"
```

---

## 10. Troubleshooting Operational Runbook

### Issue 1: Backend Fails Startup with Configuration Error
- **Symptom:** Backend container exits immediately after launch; logs show `ValueError: Production configuration error: SECRET_KEY must be externally configured`.
- **Cause:** `ENVIRONMENT=production` is set but `SECRET_KEY` is missing, under 32 characters, or contains insecure prototype phrases.
- **Resolution:** Open `.env` and configure a strong 32+ character random hex key. Relaunch with `docker compose up -d backend`.

### Issue 2: Frontend Cannot Reach Backend from Browser
- **Symptom:** Authority dashboard loads, but fleet tables show `[BusSense API fallback]` network errors in browser console.
- **Cause:** `NEXT_PUBLIC_API_URL` is set to `http://backend:8000/api`. The browser runs on the host and cannot resolve internal Docker hostnames.
- **Resolution:** Set `NEXT_PUBLIC_API_URL=http://localhost:8000/api` (or the host's public domain). Rebuild frontend: `docker compose up -d --build frontend`.

### Issue 3: Backend Readiness Reports HTTP 503
- **Symptom:** `GET /health/ready` returns `503 Service Unavailable: Critical database dependency unreachable`.
- **Cause:** Network connectivity failure between container and Supabase, or invalid `SUPABASE_URL` / `SUPABASE_ANON_KEY`.
- **Resolution:** Test DNS resolution and HTTPS egress from container:
  ```powershell
  docker compose exec backend curl -I https://lqegmqgkymstycpzplld.supabase.co
  ```
  Verify Supabase project status in the Supabase Cloud dashboard.

### Issue 4: Port Conflict on Port 8000 or 3000
- **Symptom:** `Error response from daemon: Ports are not available: exposing port TCP 0.0.0.0:8000 -> 0.0.0.0:0: bind: address already in use`.
- **Cause:** A local Python or Node process is already bound to port 8000 or 3000.
- **Resolution:** Identify and stop the local process:
  ```powershell
  # Find PID on Windows:
  netstat -ano | findstr :8000
  # Stop the process:
  Stop-Process -Id <PID> -Force
  ```
  Or change `BACKEND_PORT=8001` in `.env` and `docker-compose.yml`.

---

## 11. Environment Differences Matrix

| Parameter | Development | Staging | Production |
| :--- | :--- | :--- | :--- |
| **Server Engine** | `uvicorn --reload` / `next dev` | `docker compose up -d` | Kubernetes / ECS Cluster |
| **`ENVIRONMENT`** | `development` | `staging` | `production` (Strict validation) |
| **`DEBUG`** | `True` | `False` | `False` (Enforced) |
| **`DEMO_MODE`** | `True` | `False` | `False` (Enforced) |
| **`SECRET_KEY`** | Default fallback permitted | 32+ char hex key | Cryptographically random key |
| **`ALLOWED_ORIGINS`** | `http://localhost:3000` | Staging host domain / IP | Registered authority FQDN |
| **Database** | Supabase Cloud (`ap-south-1`) | Supabase Staging Branch | Supabase Cloud Production Instance |
| **SSL / TLS** | HTTP | HTTP / Self-signed | Managed TLS 1.3 via Cloudflare / Nginx |
| **Computer Vision** | Simulated telemetry loop | Simulated / Replay video | Real-time on-bus RTSP camera feed |

---

## 12. Deployment Readiness Status

- [x] **Backend Multi-Stage Dockerfile:** Verified with non-root security and healthcheck probe.
- [x] **Frontend Standalone Dockerfile:** Verified with Next.js 14 standalone compilation (22/22 routes).
- [x] **Docker Compose Architecture:** Root `docker-compose.yml` validated.
- [x] **Staging Smoke Test Suite:** Created in `scripts/staging_smoke_test.py`.
- [x] **Automated Regression Suite:** 203 backend tests, 22 authority tests, 100 mobile tests passing.
- [ ] **Docker Engine Availability:** **BLOCKED ON HOST** (Docker CLI is not installed on this local Windows environment).
- [ ] **Public Production Deployment:** Intentionally deferred pending host staging smoke test execution.
