# BusSense AI — Production Readiness Checklist
## Phase H14 Verification & Operational Audit

This document tracks the production readiness status of the BusSense AI platform across configuration, security, reliability, infrastructure, and operational observability.

---

## 1. Production Readiness Matrix

| Domain | Status | Implemented in | Verification Method |
| :--- | :---: | :---: | :--- |
| **Production Secret Key** | **READY** | H14 Step 1 | Pydantic validator rejects default/short (<32)/insecure keys |
| **Dynamic CORS Filtering** | **READY** | H14 Step 1 | Normalizes comma-separated origins, prohibits wildcard with credentials |
| **Demo Account Isolation** | **READY** | H14 Step 1 | Login rejects demo accounts when `ENVIRONMENT=production` or `DEMO_MODE=False` |
| **Environment Templates** | **READY** | H14 Step 1 | `.env.production.example` created with variable documentation |
| **Liveness Probe** | **READY** | H14 Step 2 | `GET /health/live` returns HTTP 200 without external dependencies |
| **Readiness Probe** | **READY** | H14 Step 2 | `GET /health/ready` returns HTTP 200/503 with bounded 2.0s DB ping |
| **Exception Sanitization** | **READY** | H14 Step 2 | Centralized 500 handler returns sanitized JSON with `X-Request-ID` |
| **Structured Logging** | **READY** | H14 Step 2 | Python `logging` with standard format, severity, and module names |
| **RPC Permission Resolution** | **READY** | H14 Step 2 | Privileged backend execution + database-backed transaction fallback |
| **Containerization & Docker** | **CONFIGURED** | H14 Step 3 | Multi-stage Dockerfiles + Compose verified statically (Runtime Engine Blocked on Host) |
| **Staging Smoke Test Suite** | **READY** | H14 Step 4 | Non-destructive test script in `scripts/staging_smoke_test.py` |
| **Disaster Recovery Runbook** | **READY** | H14 Step 4 | Managed PITR vs logical dump procedures in `docs/DEPLOYMENT_GUIDE.md` |
| **Reverse Proxy & TLS** | **PLANNED** | Staging / Prod | Nginx / Cloudflare edge SSL termination (documented in DEPLOYMENT_GUIDE.md) |
| **Physical APNs / FCM Push** | **DEFERRED** | Post-H14 | Deferred until physical Apple/Google developer accounts configured |

---

## 2. Configuration Variables Specification

The table below documents every environment variable required for production execution:

| Variable | Required in Prod? | Type | Example / Format | Purpose |
| :--- | :---: | :---: | :--- | :--- |
| `ENVIRONMENT` | **YES** | string | `production` | Switches configuration engine to strict mode |
| `DEBUG` | **YES** | boolean | `False` | Disables debug mode and verbose traceback outputs |
| `DEMO_MODE` | **YES** | boolean | `False` | Disables demo accounts, synthetic test passes, and mock sessions |
| `BACKEND_HOST` | **YES** | string | `0.0.0.0` | Host interface for backend server |
| `BACKEND_PORT` | **YES** | integer | `8000` | Port for ASGI application listener |
| `SECRET_KEY` | **YES** | string | `[64-char hex string]` | Cryptographic HMAC secret for JWT signing (min 32 chars) |
| `ALLOWED_ORIGINS` | **YES** | string | `https://bussense.kerala.gov.in` | Comma-separated list of authorized Web origins |
| `SUPABASE_URL` | **YES** | string | `https://[ref].supabase.co` | HTTPS endpoint for Supabase PostgREST and Auth |
| `SUPABASE_ANON_KEY` | **YES** | string | `eyJhbGciOi...` | Public JWT token for client-scoped operations |
| `SUPABASE_SERVICE_ROLE_KEY` | **YES** | string | `eyJhbGciOi...` | Backend-only elevated key for admin/RPC procedures |
| `DATABASE_URL` | Optional | string | `postgresql://...:5432/...` | Direct connection string for migration runners |
| `SIMULATION_INTERVAL_SECONDS`| Optional | integer | `2` | Interval for simulated GPS / occupancy cycle |
| `DEFAULT_TRANSIT_CITY` | Optional | string | `Kochi, Kerala` | Default operational city context |
| `CV_MODE` | Optional | string | `SIMULATION` / `REAL_VIDEO` | Edge computer vision ingestion mode |
| `PAYMENT_GATEWAY_MODE` | Optional | string | `SIMULATED` / `RAZORPAY_LIVE`| Payment gateway driver mode |

---

## 3. Health & Observability Endpoints

### 3.1 Liveness Probe (`GET /health/live`)
- **Target Audience:** Kubernetes kubelet / Docker healthcheck / AWS ECS.
- **Contract:** Returns HTTP 200 with `{ "status": "alive", "timestamp": "...", "version": "1.0.0" }`.
- **Latency:** < 5 milliseconds.
- **Dependencies:** Strictly zero external dependencies. Always succeeds while the Python event loop processes requests.

### 3.2 Readiness Probe (`GET /health/ready`)
- **Target Audience:** Load balancer ingress traffic routing.
- **Contract:**
  - **Healthy:** HTTP 200 `{ "status": "ready", "database": "connected", "timestamp": "...", "version": "1.0.0" }`.
  - **Degraded:** HTTP 503 `{ "status": "unready", "database": "disconnected", "detail": "Critical database dependency unreachable", ... }`.
- **Latency:** Bounded by 2.0-second HTTP client timeout.
- **Security:** Never returns credentials, database URLs, table schemas, or raw stack traces.

### 3.3 Legacy Health Check (`GET /health`)
- **Contract:** Backward-compatible for legacy clients. Returns `healthy` or `degraded`.
- **Security:** Sanitized to remove Supabase project URL exposure.

---

## 4. Error Handling & Traceback Protection

- **Request Correlation:** Every incoming request receives an `X-Request-ID` header (preserved if supplied by ingress, generated via UUID4 if absent).
- **Global 500 Handler:** Catches all unhandled exceptions at the FastAPI application root.
- **Client Response:** Uniform JSON with `INTERNAL_SERVER_ERROR`, generic friendly message, timestamp, and the correlation `request_id`.
- **Server Logging:** The full Python stack trace and exception details are logged securely via `logger.error` referencing the `request_id`.

---

## 5. Security & RPC Resolution

- **Stored Procedure:** `validate_ticket_atomic`
- **Issue:** Revocation of `EXECUTE` from `anon` in migration 006 caused 42501 errors when called via standard backend client.
- **Resolution:**
  - Extended Supabase backend client to use `SUPABASE_SERVICE_ROLE_KEY` for server-side RPC executions.
  - Implemented transactional database fallback (`tickets` + `ticket_validations`) for local dev/testing where service role keys are omitted.
  - Client bundles (Next.js and Flutter) **never receive** the service role key.
  - API endpoint `/api/tickets/validate` continues to enforce `DRIVER_CONDUCTOR` or `AUTHORITY` JWT verification before initiating validation.

---

## 6. Verification Status

```
[PASS] Production SECRET_KEY validation (Length >= 32, no fallback, no weak phrases)
[PASS] Dynamic CORS configuration (Comma-separated, normalized, no wildcards with credentials)
[PASS] Demo account isolation (Login blocked when ENVIRONMENT=production or DEMO_MODE=False)
[PASS] Liveness probe (HTTP 200, zero external calls)
[PASS] Readiness probe (HTTP 200 on healthy DB, HTTP 503 on degraded DB)
[PASS] Exception sanitization (500 error hides tracebacks, returns correlation ID)
[PASS] Structured logging (Timestamped, leveled, modular logging)
[PASS] Ticket validation authorization (403 for unauthorized roles, atomic execution)
[PASS] Staging smoke verification (9/9 checks passed against live running services)
[PASS] End-to-end system integration suite (33/33 tests passed in test_system_integration_h15.py)
[PASS] Computer vision replay validation (YOLOv8n executed on sample_bus.mp4, 708ms avg latency)
[PASS] Supabase Security Advisor (0 vulnerabilities active on live cloud database)
[PASS] Backend test suite (236/236 passed)
[PASS] Authority test suite (22/22 passed)
[PASS] Authority production build (22/22 routes compiled)
[PASS] Mobile test suite (100/100 passed)
```

---

## 7. Operational Deployment Steps (For Host Administrators)

1. Provision Linux VM or container host with Docker & Docker Compose.
2. Copy `.env.production.example` to `.env.production`.
3. Generate a 32+ character random secret:
   ```bash
   openssl rand -hex 32
   ```
4. Insert the production secret and production Supabase keys into `.env.production`.
5. Configure DNS and TLS reverse proxy (Nginx or Cloudflare Tunnel) pointing to port 8000 (backend) and 3000 (authority).
6. Verify `/health/live` and `/health/ready` via external HTTPS requests before opening traffic to commuters.
7. Execute the staging verification suite:
   ```bash
   python scripts/staging_smoke_test.py
   ```

---

## 8. Status Categorization

Per release governance standards, readiness items are categorized across four distinct operational states:

### 8.1 Implemented and Tested (100% Verified)
- Production `SECRET_KEY` validation (Pydantic validator, length >= 32, no placeholder strings).
- Dynamic CORS normalization and wildcard prohibition when credentials are enabled.
- Server-side demo-account lockout (`ENVIRONMENT != "production"` and `DEMO_MODE == True`).
- Container liveness probe (`GET /health/live`) returning HTTP 200 without external dependencies.
- Container readiness probe (`GET /health/ready`) with bounded 2.0s Supabase ping returning 200/503.
- Centralized 500 error handler returning sanitized JSON and correlation `X-Request-ID`.
- Structured Python logging replacing `print()`.
- Elevated backend service-role RPC execution for `validate_ticket_atomic` with database fallback.
- Next.js 14 standalone compilation (22/22 routes compiling to `frontend/.next/standalone`).
- Automated test suites: 236 backend tests, 22 authority tests, 100 mobile flutter tests (358 total passing).
- Staging smoke verification script (`scripts/staging_smoke_test.py`) with 9/9 checks passing against live services.
- Live Supabase cloud database verification (`lqegmqgkymstycpzplld`) with 0 security advisor lints.
- CV replay pipeline executed on `datasets/videos/sample_bus.mp4` with `yolov8n.pt`.

### 8.2 Implemented but Not Runtime-Verified
- Container images in `backend/Dockerfile` and `frontend/Dockerfile` (authored, multi-stage, non-root, but not executed locally due to missing Docker engine).
- Docker Compose orchestration in `docker-compose.yml` (syntax-checked and validated, but blocked from launching).

### 8.3 Blocked by Missing Infrastructure
- Local container runtime verification (`docker build` and `docker compose up`) is **BLOCKED ON HOST** because Docker CLI/daemon is not installed on this Windows environment.
- Containerized deployment verification is deferred until executed on a host with Docker installed.

### 8.4 Deferred Pending Real-World Validation
- Physical on-bus RTSP camera feed ingestion and edge GPU inference (currently verified in high-fidelity `SIMULATION` mode).
- Physical Apple APNs / Google FCM push notification delivery keys (currently using transparent `DEFERRED` in-app notifications).
- External production reverse proxy TLS 1.3 termination (Cloudflare / Nginx configuration deferred to production VM host).
- Point-in-time recovery live exercise on production Supabase instance (deferred to scheduled maintenance window with operator authorization).
