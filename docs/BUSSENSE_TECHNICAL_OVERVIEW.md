# BusSense AI — Technical Architecture & Systems Overview
## Intelligent Transit Telemetry, Machine Learning & Operational Infrastructure

**Target Audience:** Transit Authority Chief Technology Officers, ITS Directors, System Architects, Security Auditors  
**System Version:** 1.0.0-H21  
**Operating Region:** Greater Kochi Urban Transit Network ($9.80^\circ\text{N} - 10.20^\circ\text{N},\; 76.15^\circ\text{E} - 76.45^\circ\text{E}$)  
**Repository:** `https://github.com/Antony0610/BusSense-AI.git` (Branch: `master`)

---

## 1. High-Level Architecture Overview

BusSense AI implements a modular, high-throughput service-oriented architecture designed to handle heterogeneous transit feeds while enforcing strict data hygiene and zero-biometric privacy.

```
                           ┌───────────────────────────────────────────────┐
                           │            EXTERNAL TRANSIT FEEDS             │
                           │  - KSRTC-SWIFT AVL (HTTPS / REST)             │
                           │  - KMRL Metro Feeders (GTFS-RT / REST)        │
                           │  - Onboard Bus CCTV (RTSP / Ingestion API)    │
                           │  - Kerala Police / Traffic (GeoJSON Alerts)   │
                           └───────────────────────┬───────────────────────┘
                                                   │
                                                   ▼
┌──────────────────────────────────────────────────────────────────────────────────────────┐
│                   INGRESS REVERSE PROXY & FIREWALL (Nginx 1.22+ / TLS 1.3)               │
│   - Rate Limiting Zones (30r/s API, 15r/s Ingestion, 5r/s Auth)                          │
│   - Strict Security Headers (HSTS, CSP, X-Frame DENY, X-Content-Type nosniff)            │
│   - WebSocket Upgrade Handlers (/api/ws, /realtime)                                      │
└───────────────────────────┬──────────────────────────────────────────────┬───────────────┘
                            │                                              │
                            ▼                                              ▼
┌──────────────────────────────────────────────────────────┐  ┌────────────────────────────┐
│              FASTAPI ASGI BACKEND (Python 3.12+)         │  │ NEXT.JS 14 COMMAND CENTER  │
│  ├── Ingestion Service (Provenance, Freshness, BBox)     │  │  - App Router (React 18)   │
│  ├── Map-Matching Engine (Monotonic Haversine Snapping)  │  │  - Tailwind CSS + Stitch   │
│  ├── CV Headcount Pipeline (YOLOv8 + EMA Filter)         │  │  - Live Leaflet Corridor   │
│  ├── Demand Forecaster (Multi-Horizon Ridge Regression)  │  │  - AI Operations Assistant │
│  ├── Recommendation Engine (Multi-Factor Scoring)        │  │  - Pilot Monitoring HUD    │
│  └── RBAC Security Core (JWT, Bcrypt, SHA-256 API Keys)  │  │  - Truth Stamp Badges      │
└───────────────────────────┬──────────────────────────────┘  └────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────────────────────────────────────┐
│               PERSISTENCE LAYER (PostgreSQL 15+ / Supabase Managed Cloud)                │
│   - Row-Level Security (RLS) policies protecting passenger and conductor data            │
│   - Core Schemas: routes, stops, buses, trips, tickets, incident_reports, audit_logs      │
│   - Automated Non-Destructive JSON Logical Backups (scripts/test_database_backup_recovery)│
└──────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Ingestion Boundary & Telemetry Integrity

External transit data enters through `/api/ingest/` guarded by three layers of defensive verification:

### 2.1 External Provider Authentication
- External transit operators present a secret key via `X-Provider-API-Key`.
- Backend validates the key against a cryptographic SHA-256 digest (`hashlib.sha256(raw_key.encode()).hexdigest()`).
- Revoked providers are rejected with immediate `HTTP 403 INTEGRATION_REVOKED`.
- Rate limiting restricts abusive ingestion floods (15 requests/sec per IP, burst=20).

### 2.2 Boundary Sanitization & Range Validation
- **Spatial Bounding Box:** All coordinates are validated within Greater Kochi bounds:
  $$\text{Latitude} \in [9.80^\circ\text{N}, 10.20^\circ\text{N}], \quad \text{Longitude} \in [76.15^\circ\text{E}, 76.45^\circ\text{E}]$$
- **Velocity Sanity:** $0 \le \text{speed} \le 120\text{ km/h}$. Packets indicating speed $> 120\text{ km/h}$ or spatial jumps $> 500\text{m}$ in $< 2\text{s}$ are flagged with `IMPOSSIBLE_SPEED_OR_GPS_JUMP`.
- **Clock-Skew Defense:** Packets timestamped $> 300\text{s}$ in the future or past are flagged as `CLOCK_SKEW_DETECTED`.

### 2.3 Map-Matching Engine
The spatial engine snaps raw GPS coordinates to corridor paths using the Haversine great-circle formula:
$$d = 2R \arcsin \left( \sqrt{ \sin^2\left(\frac{\Delta \phi}{2}\right) + \cos\phi_1 \cos\phi_2 \sin^2\left(\frac{\Delta \lambda}{2}\right) } \right)$$
- If the perpendicular offset from the designated corridor exceeds $500\text{m}$, the system emits an off-route warning (`WARNING_OFF_ROUTE`), alerting dispatchers to unauthorized detours without interrupting vehicle tracking.

---

## 3. Privacy-First Computer Vision Pipeline

```
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│  IP CCTV Camera │  ──▶  │  YOLOv8 Headless│  ──▶  │  Temporal EMA   │  ──▶  │   Truth Stamp   │
│  Bus Door / Roof│       │  Person Boxes   │       │  Smoothing (10f)│       │   CV_REPLAY     │
└─────────────────┘       └─────────────────┘       └─────────────────┘       └─────────────────┘
                                   │                                                   ▲
                                   ▼                                                   │
                          ┌─────────────────┐                                          │
                          │ Zero Biometrics │ ─────────────────────────────────────────┘
                          │ Strict Guarantee│
                          └─────────────────┘
```

1. **Object Detection:** Employs an optimized YOLOv8 nano model (`yolov8n.pt`) fine-tuned for transit cabin overhead/door perspectives.
2. **Strict Zero-Biometrics Policy:**
   - Filters exclusively for class `person` (COCO class ID 0).
   - Facial feature extraction, face recognition networks, gender/age classifiers, and individual tracking IDs are completely absent by design.
   - Pydantic validator `enforce_zero_biometrics` rejects any ingest payload lacking `privacy_standard: "PERSON_COUNTING_ONLY_NO_BIOMETRICS"`.
3. **Temporal EMA Smoothing:** Rapid occlusions and passenger passing motions are smoothed using an Exponential Moving Average across a 10-frame window ($\alpha = 0.35$):
   $$S_t = \alpha \cdot C_t + (1 - \alpha) \cdot S_{t-1}$$
   - Independent physical benchmarking demonstrates a **+32.5% error reduction** over raw detector counts (Smoothed MAE: 1.41 vs Raw MAE: 2.09).

---

## 4. Multi-Horizon Demand Forecasting

Transit passenger demand is predicted across four forward operational horizons ($t+0\text{m}$, $t+15\text{m}$, $t+30\text{m}$, $t+60\text{m}$) using a regularized Ridge Regression engine.

### 4.1 Feature Vector Specification
The feature vector incorporates temporal, environmental, and spatial covariates:
$$\mathbf{x} = \left[ \text{sin}(\theta_{\text{tod}}), \text{cos}(\theta_{\text{tod}}), \text{dow}, \text{is\_weekend}, \text{is\_peak}, \text{rain\_intensity}, \text{metro\_interchange}, \text{cur\_occ}, \text{cur\_velocity} \right]^T$$

### 4.2 Objective Function
The Ridge model minimizes the L2-regularized mean squared error to prevent overfitting during sparse data regimes:
$$\min_{\mathbf{w}} \|\mathbf{y} - \mathbf{X}\mathbf{w}\|_2^2 + \lambda \|\mathbf{w}\|_2^2, \quad \lambda = 1.0$$

### 4.3 Benchmark Comparison
Evaluated against 558 operational observations using chronological 70/15/15 train/val/test splits:
- **Ridge Model (+30m):** MAE $4.85\%$, RMSE $6.21\%$.
- **Persistence Baseline ($y_{t+h} = y_t$):** MAE $9.78\%$ (Ridge achieves **+50.4% improvement**).
- **Simple Moving Average (SMA-3):** MAE $8.54\%$ (Ridge achieves **+43.2% improvement**).
- **Residual Distribution:** Mean residual $0.16\%$, Skewness $-0.03$ (statistically symmetric Gaussian distribution).

---

## 5. Explainable Recommendation Scoring Engine

Journey planning requests (`POST /api/recommendations/plan`) evaluate all viable corridor routes using an explainable multi-factor scoring formula:

$$\text{Score}(b) = w_{\text{time}} \cdot T(b) + w_{\text{fare}} \cdot F(b) + w_{\text{crowd}} \cdot C(b) + w_{\text{rel}} \cdot R(b)$$

Where:
- $T(b)$: Normalized travel and wait time (0.0 to 1.0).
- $F(b)$: Normalized ticket fare.
- $C(b)$: Predicted cabin occupancy penalty ($C > 0.8 \implies \text{severe penalty}$).
- $R(b)$: Historical on-time arrival reliability factor.

### User Optimization Modes
| Mode | Time Weight ($w_t$) | Fare Weight ($w_f$) | Crowd Weight ($w_c$) | Reliability Weight ($w_r$) |
| :--- | :---: | :---: | :---: | :---: |
| **Balanced** | 0.35 | 0.25 | 0.25 | 0.15 |
| **Fastest** | 0.60 | 0.10 | 0.15 | 0.15 |
| **Least Crowded** | 0.20 | 0.15 | 0.50 | 0.15 |
| **Lowest Fare** | 0.15 | 0.60 | 0.15 | 0.10 |

The recommendation output always provides a human-readable `explanation` string (e.g., *"Recommended Bus 205 arrives in 4 mins with 42% moderate crowd, saving 12 mins over alternative"*).

---

## 6. Security, RBAC & Data Sovereignty

| Control Area | Implementation Mechanism | Validation Standard |
| :--- | :--- | :--- |
| **Role-Based Access Control** | Signed HMAC-SHA256 JWT tokens with role claims (`PASSENGER`, `DRIVER_CONDUCTOR`, `AUTHORITY`). | Expired tokens, invalid signatures, or role mismatches rejected with 401/403. |
| **Data Sovereignty** | PostgreSQL Row-Level Security (RLS) on Supabase. | Commuters only access their own booked tickets; conductors only validate for their paired bus. |
| **Ticket Double-Spend** | Atomic database check-and-update on `tickets` table. | Replay scans immediately return `ALREADY_USED` status with validation timestamp. |
| **Network Hardening** | Nginx TLS 1.3, HSTS ($63072000\text{s}$), Deny Framing, Strict CSP. | Grade A+ SSL Labs equivalent configuration packaged in `deploy/nginx/bussense.conf`. |
| **Process Sandboxing** | Linux systemd service units with `ProtectSystem=full`, `PrivateTmp=true`. | Service isolated from host operating system binaries and root credentials. |

---

## 7. Deployment Topologies

### 7.1 Linux Production Staging (Recommended)
- **Host OS:** Ubuntu 22.04 LTS / Debian 12
- **Backend Service:** Systemd unit `bussense-backend.service` running Uvicorn ASGI with 4 workers.
- **Frontend Service:** Systemd unit `bussense-frontend.service` running Next.js standalone Node server.
- **Reverse Proxy:** Nginx handling HTTPS termination, rate limiting, and static asset caching.
- **Automated Script:** Single-command staging installer: `deploy/scripts/deploy_staging.sh`.

### 7.2 Containerized Topology
- Multi-stage Dockerfiles (`backend/Dockerfile`, `frontend/Dockerfile`) with non-root security context.
- Orchestration via `docker-compose.yml`.

---
*BusSense AI Technical Specification — Version 1.0.0-H21*

