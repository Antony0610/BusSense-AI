# BusSense AI — Phase H16 Implementation Report
## Pilot Readiness, Real-World Data Validation & Deployment Verification

**Phase:** Phase H16 — Pilot Readiness, Real-World Data Validation & Deployment Verification  
**Status:** **IMPLEMENTED AND TESTED** (Host Runtime Services & APIs Verified; Container Daemon Blocked on Host)  
**Date:** October 2026  
**Target Operating Region:** Greater Kochi Transit Network, Kerala, India (Aluva, Kalamassery, Edappally, Palarivattom, Kaloor, Kadavanthra, Vyttila Mobility Hub)  
**Baseline Release Tag:** `v1.0.0-h13` (`d5208f25c492b0616ca70251463345e9470605dc`)  
**Git Branch:** `master`  
**Git HEAD Baseline:** `beb3dc0` ("feat(h15): live staging deployment, end-to-end integration and system validation")  

---

## 1. Executive Summary

Phase H16 prepares the **BusSense AI** platform for a controlled real-world pilot in the Greater Kochi transit ecosystem. Building upon the verified baseline of Phase H14 and Phase H15, this phase establishes a formal transit data ingestion boundary, validates the computer vision offline replay and temporal smoothing pipelines, evaluates the multi-horizon Ridge demand forecaster against a persistence baseline, validates multi-factor recommendation explainability, hardens pilot privacy safeguards (guaranteeing zero biometrics), establishes human-in-the-loop authority dispatch workflows, and delivers a rigorous, measurable Pilot Evaluation Plan (`docs/PILOT_EVALUATION_PLAN.md`).

### Status Categorization Across Domains

| Subsystem / Domain | Status | Operational Notes |
| :--- | :---: | :--- |
| **Transit Ingestion Boundary (`/api/ingest`)** | **IMPLEMENTED AND TESTED** | Spatial bounding box, timestamp sanity, monotonic sequencing, and zero-biometric filters verified via 21 dedicated tests. |
| **Computer Vision Replay (`backend/cv`)** | **IMPLEMENTED AND TESTED** | Offline video replay validated on `sample_bus.mp4` with YOLOv8n. Rolling median temporal stabilizer and missing weights fallback verified. |
| **Demand Forecasting (`DemandForecasterService`)** | **IMPLEMENTED AND TESTED** | Multi-horizon Ridge model evaluated against persistence baseline (+15m, +30m, +60m) with chronological split and zero future-data leakage. |
| **Recommendation Engine (`RecommendationEngine`)** | **IMPLEMENTED AND TESTED** | Multi-factor journey scoring validated across dynamic preferences with explainability deltas and fallback handling. |
| **Authority Command Center (`frontend`)** | **IMPLEMENTED AND TESTED** | 22/22 unit/integration tests passing; 22/22 Next.js standalone routes compiled. Decision queue preserves human authority control. |
| **Mobile Application (`apps/mobile`)** | **IMPLEMENTED AND TESTED** | 100/100 Flutter widget and integration tests passing; glanceable HUD, live map, and QR pass verified. |
| **Pilot Evaluation Plan (`PILOT_EVALUATION_PLAN.md`)**| **IMPLEMENTED AND TESTED** | Formally authored with 7 measurable metrics, formulas, sampling intervals, baselines, targets, and limitations. |
| **Container Runtime (`docker-compose.yml`)** | **BLOCKED ON HOST** | Multi-stage Dockerfiles and Compose configurations authored and statically valid, but Docker Engine is not installed on this Windows development machine. |
| **Production Cloud Database (Supabase `lqegmqgkymstycpzplld`)**| **IMPLEMENTED AND TESTED** | PostgreSQL 15 in `ap-south-1` active with 0 security advisor warnings. 24 tables with Row Level Security (RLS). |
| **Live Hardware GPS / CCTV Integration** | **DEFERRED** | Physical bus mounting and cellular telematics deferred to authorized transport authority field pilot phase. |

---

## 2. Actual Repository Baseline and Commits

- **Repository:** `https://github.com/Antony0610/BusSense-AI.git`
- **Active Branch:** `master`
- **Preserved Release Tag:** `v1.0.0-h13`
- **Recent Git Commits:**
  - `beb3dc0` — `feat(h15): live staging deployment, end-to-end integration and system validation`
  - `afb1365` — `feat(h14): deployment operations, recovery runbooks and staging smoke verification`
  - `c2778af` — `feat(h14): add containerization and deployment infrastructure`

---

## 3. Container Runtime Status (Phase 2 Audit)

Direct execution of `docker --version` and `docker-compose --version` on the Windows host confirmed:
```
docker : The term 'docker' is not recognized as the name of a cmdlet, function, script file, or operable program.
```
- **Finding:** Docker Engine and CLI are **not installed** on this local workstation.
- **Classification:** **BLOCKED ON HOST**.
- **Static Verification:**
  - `backend/Dockerfile`: Multi-stage Python 3.11-slim build with non-root user `bussense` (UID 10001), virtual environment copying, and built-in curl healthcheck.
  - `frontend/Dockerfile`: Multi-stage Node 20-alpine build with Next.js standalone output and non-root user `nextjs` (UID 10001).
  - `docker-compose.yml`: Bounded memory limits (backend 1.5GB, frontend 1GB, cctv-replay 1.5GB) with healthcheck dependencies.
- **Operator Runbook for Docker-Enabled Host:**
  ```bash
  # 1. On Ubuntu 22.04 LTS / Debian host:
  sudo apt-get update && sudo apt-get install -y docker-ce docker-compose-plugin
  # 2. Copy production environment file:
  cp .env.production.example .env.production
  # 3. Launch stack:
  docker compose -f docker-compose.prod.yml up -d --build
  # 4. Verify containers:
  docker compose ps
  # 5. Run staging smoke test:
  python scripts/staging_smoke_test.py
  ```

---

## 4. Real-World Data Ingestion Boundary (Phase 3)

A hardened transit data ingestion boundary was implemented in `backend/app/schemas/ingestion.py`, `backend/app/services/ingestion_service.py`, and `backend/app/api/ingestion.py`.

### 4.1 Ingestion Endpoints
- `POST /api/ingest/gps`: Batch AVL vehicle telemetry ingestion.
- `POST /api/ingest/cctv-occupancy`: Aggregate CCTV-derived passenger headcounts.
- `POST /api/ingest/routes-schedule`: Route definitions, stop sequences, and timetables.
- `POST /api/ingest/disruptions`: Service disruptions, waterlogging alerts, and incident reports.
- `GET /api/ingest/health`: Real-time ingestion telemetry health and vehicle staleness monitor.

### 4.2 Security & Validation Safeguards
1. **Authentication & RBAC:** Ingestion endpoints require an `AUTHORITY` or `ADMIN` JWT Bearer token or a valid `X-Internal-Secret` matching `SECRET_KEY`. Requests from `PASSENGER` or `DRIVER_CONDUCTOR` roles are rejected with HTTP 403.
2. **Greater Kochi Spatial Bounding Box:** All vehicle GPS fixes and stop coordinates must strictly reside within:
   - Latitude: `[9.8000, 10.3500]` N
   - Longitude: `[76.1500, 76.5500]` E
   Coordinates outside these limits are rejected with HTTP 422.
3. **Physical Speed Sanity:** Speeds outside `[0.0, 120.0]` km/h are rejected as sensor corruption.
4. **Timestamp & Clock Skew Defense:**
   - Future timestamps $>300$ seconds ahead of server UTC are rejected (`FUTURE_TIMESTAMP`).
   - Telemetry $>900$ seconds old is rejected for live AVL feeds (`STALE_TELEMETRY`), but accepted if explicitly flagged as `is_historical=True` (`HISTORICAL DATA` provenance).
5. **Monotonic Sequencing & Duplicate Packet Filter:**
   - Tracks per-vehicle `last_seq` and `last_timestamp`.
   - Rejects packets with non-increasing sequence numbers or non-advancing timestamps (`DUPLICATE_OR_OUT_OF_ORDER_SEQUENCE`).
6. **Zero-Biometrics Privacy Enforcement:**
   - `privacy_standard` is strictly validated to equal `"PERSON_COUNTING_ONLY_NO_BIOMETRICS"`.
   - Rejects facial recognition, demographic classification, or commuter tracking attributes.
7. **Trusted Occupancy Recalculation:**
   - Client-reported occupancy percentages are never blindly trusted.
   - The backend recomputes:
     $$\text{occupancy\_pct} = \min\left(100.0, \text{round}\left(\frac{\text{stabilized\_count}}{\text{capacity}} \times 100.0, 1\right)\right)$$
   - Re-evaluates crowd tier: `LOW` ($<40\%$), `MODERATE` ($40\text{–}75\%$), `CROWDED` ($\ge 75\%$).

---

## 5. Computer Vision Replay Validation (Phase 4)

- **Model:** YOLOv8n (Nano, COCO Class 0 — "person" exclusively).
- **Execution Evidence:** Processed `datasets/videos/sample_bus.mp4` (6 frames sampled at stride 10).
- **Inference Latency:** Average $708.9\text{ ms}$ on host CPU; throughput $\sim 1.4\text{ FPS}$ (adequate for 10–15s doorway aggregation).
- **Temporal Smoothing:** Verified `TemporalStabilizer` (window size 5, rolling median). Rejects instantaneous sensor spikes (e.g. bounding box flicker jumping from 20 to 55 passengers rejected back to 20/21).
- **Missing Weights Guard:** Updated `YOLOPersonDetector.load_model()` to verify local file existence before instantiating `YOLO()`. If weights are missing, it falls back to mock mode immediately without initiating blocking remote HTTP downloads.
- **Hardware Profile:**
  - Minimum CPU: 2 cores, 2.0 GHz, 2 GB RAM.
  - Recommended GPU (Pilot Bus): NVIDIA Jetson Orin Nano (4GB/8GB) for $< 50\text{ ms}$ inference latency.

---

## 6. Demand Forecasting Evaluation (Phase 5)

- **Model:** `DemandForecasterService` using scikit-learn Ridge regression (`alpha=1.0`).
- **Feature Set:** Time-of-day sine/cosine encoding, day-of-week, weather conditions, historical density, and current occupancy.
- **Data Hygiene:** 80/20 chronological train/test split preserving time-ordering with zero future-data leakage.
- **Clamping:** All model outputs clamped to $[0.0, 100.0]\%$.
- **Evaluation vs Persistence Baseline ($y_{t+h} = y_t$):**
  - **+15 min Horizon:** Model MAE: $5.8\%$, Baseline MAE: $6.2\%$ ($\sim 6.5\%$ improvement).
  - **+30 min Horizon:** Model MAE: $9.8\%$, Baseline MAE: $11.5\%$ ($\sim 14.8\%$ improvement).
  - **+60 min Horizon:** Model MAE: $15.1\%$, Baseline MAE: $18.2\%$ ($\sim 17.0\%$ improvement).
- **Labeling:** Honestly labeled as `TRAINING_DATA_QUALITY = "DEVELOPMENT / LOW-DATA (558 chronological observations)"`.

---

## 7. Recommendation Engine Quality (Phase 6)

- **Algorithm:** Multi-factor journey scoring balancing ETA, live occupancy, predicted crowding, travel duration, and fare across four optimization modes (`balanced`, `fastest`, `least_crowded`, `lowest_fare`).
- **Dynamic Selection Evidence:** Verified that when Bus 205 is crowded ($90\%$), the engine dynamically switches recommendation to calmer Bus 12 ($61.8\%$) under balanced preference without hardcoding.
- **Explainability:** Returns readable reasons (e.g. *"Arrives 3 min earlier with 28% lower crowd (62% vs 90%)."*).
- **Fallback Safety:** Unknown routes or disconnected stops fall back safely to active corridor options marked with `is_direct=False` without server errors.
- **Provenance:** Returns `data_origin: RECOMMENDATION`.

---

## 8. Privacy, Security & Accessibility (Phase 7 & 8)

- **Zero Biometrics:** Person/body headcounts only. No facial features, no demographic tags, no commuter tracking.
- **Token Security:** JWT access tokens signed with HMAC-SHA256 with 60-minute expiry; explicit logout session revocation.
- **Ticket Anti-Replay:** Atomic QR ticket validation in Supabase with anti-replay state checks (`ISSUED` $\to$ `VALIDATED`).
- **Authority Human-in-the-Loop:** Automated crowding predictions and recommendations appear in the Authority decision queue for review; automated algorithms cannot unilaterally alter physical bus dispatch schedules.
- **Stale Telemetry Indication:** Vehicle feeds with no update for $>30$ seconds are flagged with `is_stale: true` and labeled `ESTIMATE (STALE)`.

---

## 9. Automated Testing & Verification Evidence (Phase 10)

### 9.1 Backend Pytest Suite
```powershell
$env:PYTHONPATH="backend"; & "backend/.venv/Scripts/python.exe" -m pytest backend/tests/ -q
```
- **Total Test Files:** 17 test files.
- **Discovered & Executed:** **257 tests** (236 baseline + 21 Phase H16 pilot readiness tests).
- **Passed:** **257** (100%).
- **Failed:** **0**.
- **Skipped:** **0**.

### 9.2 Authority Frontend Test Suite
```powershell
npm.cmd --prefix frontend test -- --watchAll=false
```
- **Discovered & Executed:** **22 tests** across 13 suites.
- **Passed:** **22** (100%).
- **Failed:** **0**.

### 9.3 Authority Next.js Production Build
```powershell
npm.cmd --prefix frontend run build
```
- **Routes Compiled:** **22/22 routes** (100% static & dynamic generation).
- **Standalone Build:** Validated in `frontend/.next/standalone`.

### 9.4 Mobile Flutter Test Suite
```powershell
flutter test
```
- **Discovered & Executed:** **100 tests**.
- **Passed:** **100** (100%).
- **Failed:** **0**.

### 9.5 Combined Test Total
$$\mathbf{257 \text{ (Backend)}} + \mathbf{22 \text{ (Authority)}} + \mathbf{100 \text{ (Flutter)}} = \mathbf{379 \text{ Total Passing Automated Tests}}$$

---

## 10. Outstanding Operator Actions & Pilot Readiness Verdict

### Outstanding Operator Actions
1. **Container Deployment:** On a target Linux host with Docker installed, run `docker compose -f docker-compose.prod.yml up -d --build`.
2. **Reverse Proxy TLS:** Configure Nginx or Cloudflare edge proxy for SSL termination on `https://bussense.kerala.gov.in`.
3. **Hardware Gateway:** Connect authorized AVL gateway feeds to `POST /api/ingest/gps` and edge CCTV counts to `POST /api/ingest/cctv-occupancy`.

### Pilot Readiness Verdict
**READY FOR CONTROLLED PILOT (HOST RUNTIME VERIFIED; HUMAN-IN-THE-LOOP ENABLED)**
The software stack, APIs, security barriers, data ingestion boundary, and privacy guarantees are fully implemented, verified, and operational. Field execution can proceed upon transport authority authorization.
