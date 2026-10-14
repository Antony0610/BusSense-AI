# BusSense AI — Independent Implementation Audit Report

**Date of Audit:** September 26, 2026  
**Auditor:** Lead Full-Stack Engineer (Independent Automated & Runtime Verification)  
**Target Repository:** `d:\Bus_Sense_Ai`  
**Execution Environment:** Windows (PowerShell / Command Prompt), Python 3.14.6 (`backend/.venv`), Next.js 14.2.35 (`frontend/`), Supabase PostgreSQL (`lqegmqgkymstycpzplld.supabase.co`)  
**Audit Mandate:** Verify every phase against actual code, running processes, live database queries, network responses, and security controls. No claims without evidence.

---

## Hardened Implementation Roadmap Status (H1 – H14)

Following the initial audit, remediation proceeds strictly in dependency order:

| Hardened Phase | Title | Status | Verification Date | Summary |
|:---|:---|:---|:---|:---|
| **PHASE H1** | **Security + Authentication Hardening** | **VERIFIED** | 2026-09-26 | Enforced `require_roles()` on all protected endpoints; strict 401/403 rejections; `POST /api/auth/logout` with JWT blacklist revocation; native bcrypt hashing; eliminated plaintext `demo1234` fallback; restricted CORS whitelist; parameterized Supabase queries; 13/13 backend pytest suite passing; live security audit suite 10/10 passing. |
| **PHASE H2** | **Persistent Database Transactions** | **VERIFIED** | 2026-09-26 | Eliminated authoritative in-memory storage; migrated `tickets`, `payments`, `ticket_validations`, `incidents`, `alerts`, `crowd_predictions`, and `reports` to Supabase PostgreSQL; created PL/pgSQL atomic validation procedure `validate_ticket_atomic` with `FOR UPDATE` row locking; 19/19 pytest suite passing; cold restart persistence test passed with 100% data survival. |
| **PHASE H4** | **Unified Flutter Mobile Foundation** | **VERIFIED** | 2026-09-27 | Unified mobile codebase in `apps/mobile/` supporting PASSENGER and DRIVER_CONDUCTOR roles; Authority routed to Next.js web portal; Riverpod state management; unified ApiClient with H3 FastAPI contract alignment; secure token storage abstraction; shared models with JSON serialization; Stitch design tokens + typography + shared components; 33/33 Flutter tests passing; flutter analyze 0 issues; backend 25/25 passing; Next.js 22/22 routes building. |
| **PHASE H5** | **Unified Flutter Passenger Experience** | **PENDING** | - | Implement Passenger screens (Home, Explore, Tickets, AI Assistant, Profile) in apps/mobile. |
| **PHASE H6** | **Unified Flutter Conductor Cockpit** | **PENDING** | - | Implement Conductor screens (Trip, Scan, Bus, Alerts, Profile) in apps/mobile. |
| **PHASE H7** | Real Computer Vision | **PENDING** | - | OpenCV/YOLO video inference pipeline. |
| **PHASE H8** | Real Demand Prediction | **PENDING** | - | Dynamic scikit-learn Ridge model without Route 205 hardcoded override. |
| **PHASE H9** | Dynamic Recommendation Engine | **PENDING** | - | Live multi-candidate scoring. |
| **PHASE H10** | Real RAG AI | **PENDING** | - | Vector retrieval + Gemini LLM integration. |
| **PHASE H11** | Notifications + Alert Automation | **PENDING** | - | Real push / WebSocket alert dispatch. |
| **PHASE H12** | End-to-End Integration | **PENDING** | - | Cross-persona flows and data synchronization. |
| **PHASE H13** | Testing | **PENDING** | - | Integration and E2E regression suites. |
| **PHASE H14** | Deployment | **PENDING** | - | Docker, CI/CD, staging deployment. |

---

## Executive Summary & Phase Classification Table (Historical Prototype Audit)

| Phase | Status | Evidence | Problems | Next Action |
|:---|:---|:---|:---|:---|
| **Phase 0: Documentation Audit** | **PARTIALLY VERIFIED** | All 23 documents under `/docs/` exist, along with [MEMORY.md](file:///d:/Bus_Sense_Ai/MEMORY.md), [AGENTS.md](file:///d:/Bus_Sense_Ai/AGENTS.md), and [CONTRIBUTING.md](file:///d:/Bus_Sense_Ai/CONTRIBUTING.md). Detailed schemas and known limitations are defined. | Previous report claimed 100% completion of Phases 0–17, directly contradicting [KNOWN_LIMITATIONS.md](file:///d:/Bus_Sense_Ai/docs/KNOWN_LIMITATIONS.md). [COMPUTER_VISION.md](file:///d:/Bus_Sense_Ai/docs/COMPUTER_VISION.md) describes real YOLOv8 inference which is stubbed out in code. Target Flutter architecture has no code presence. | Align documentation to reflect actual prototype boundaries; remove false claims of YOLO inference and native Flutter implementation until built. |
| **Phase 1: Foundation Audit** | **PARTIALLY VERIFIED** | Python 3.14.6 venv active; FastAPI backend running on port 8000; Next.js frontend running on port 3000; `GET /health` returns HTTP 200 `healthy`. | `cv2` (OpenCV) missing from Python environment; Flutter mobile apps are **NOT IMPLEMENTED** (zero Dart/Flutter files in repo); `GET /health` hardcodes `"supabase_connected": true` without active query. | Install missing CV dependencies if video processing is required; update health endpoint to actively query Supabase. |
| **Phase 2: Database Audit** | **PARTIALLY VERIFIED** | Direct PostgREST queries confirmed 24 tables live and seeded with Kerala transit data (Aluva, Kaloor, Infopark, etc.) on Supabase PostgreSQL. | Separate tables `passengers`, `drivers`, `conductors` do not exist (unified in `users` with `role` enum); RLS policies are wide-open prototype policies (`USING (true)`); runtime writes for tickets and incidents do not persist to Supabase. | Enforce production RLS policies; update backend service write operations to persist records into Supabase. |
| **Phase 3: Authentication & RBAC Audit** | **PARTIALLY VERIFIED** | Login for Passenger, Driver, and Authority succeeds with JWT bearer token generation; `GET /api/auth/me` validates token and returns user profile; invalid credentials return 401. | `require_roles` is defined in `security.py` but **NEVER ENFORCED** on any domain API endpoint; unauthenticated/cross-role access is not rejected with 403; `/api/auth/logout` returns 404 (Not Found); fallback password `demo1234` is hardcoded. | Enforce `require_roles` dependencies on domain endpoints; implement `/api/auth/logout`; remove hardcoded password fallback. |
| **Phase 4: Backend API Audit** | **PARTIALLY VERIFIED** | 22 endpoints tested and verified responding HTTP 200 with structured JSON (`/health`, `/buses`, `/routes`, `/stops`, `/occupancy/forecast/{bus}`, `/tickets/book`, etc.). | Checklisted endpoints `/api/trips`, `/api/locations`, `/api/crowd`, `/api/predictions`, `/api/payments`, `/api/alerts`, `/api/notifications` return 404 Not Found; frontend calls `/occupancy/predictions` which 404s. | Implement missing endpoint aliases or align frontend API calls with the existing route paths. |
| **Phase 5: Simulation Audit** | **VERIFIED** | Background simulation loop ticks every 2.0s; GPS coordinates interpolate smoothly along Kerala corridors; bus speeds vary realistically (15–55 km/h); ETAs dynamically decrement; passenger flux occurs at stop events. | Automated threshold breach alert generation (e.g. occupancy > 85%) is not triggered inside the simulation loop. | Hook automated alert triggers to the simulation loop when buses exceed crowding thresholds. |
| **Phase 6: Passenger Audit** | **PARTIALLY VERIFIED** | All 6 Next.js passenger pages exist and render; Live Departures, 60-min crowd forecast, ticket booking, QR generation, and AI chat respond dynamically. | Recommendation banner on Home page is static hardcoded JSX text; Profile page displays hardcoded commuter info without calling `/api/auth/me`; map view is a static Stitch image URL. | Bind Home recommendation banner to `/api/recommendations/plan`; bind Profile to `/api/auth/me`; integrate dynamic Leaflet/MapLibre map. |
| **Phase 7: Driver Audit** | **PARTIALLY VERIFIED** | Cockpit HUD displays approaching stop, live speed, and cabin occupancy gauge; QR validator verifies boarding passes with instant 3-state feedback; incident reporting API responds. | Driver actions (incident creation, ticket validation) do NOT update the Supabase database (in-memory state only); shift login does not verify physical vehicle pairings. | Persist driver incidents and ticket validations to Supabase tables `incidents` and `ticket_validations`. |
| **Phase 8: Authority Audit** | **PARTIALLY VERIFIED** | Command Center, Fleet, Routes, Forecast, AI Ops, Alerts, and Reports pages render Stitch layouts; Fleet table dynamically displays vehicles from `/api/buses`. | Routes, Alerts, AI Ops, and Reports screens are 100% hardcoded in JSX; Forecast page calls a 404 endpoint and falls back to hardcoded metrics; Command Center executive stats (on-time 92.4%, corridor counts) are hardcoded. | Connect Authority screens (`routes`, `alerts`, `ai-ops`, `reports`) to real backend endpoints. |
| **Phase 9: Computer Vision Audit** | **PARTIALLY VERIFIED** | Threshold categorization (LOW < 50%, MODERATE 50–80%, CROWDED > 80%) and strict privacy rules are enforced in code. | YOLO model loading, weight files (`yolov8n.pt`), video input, OpenCV frame decoding, and bounding-box person inference are **NOT IMPLEMENTED** (synthetic count pass-through); `cv2` missing from venv. | Install Ultralytics and OpenCV; implement real YOLOv8 video frame inference pipeline. |
| **Phase 10: GPS + Realtime Audit** | **VERIFIED** | Physics engine updates bus coordinates, speed, and ETAs continuously; WebSocket `/ws/telemetry` connects successfully, broadcasts initial fleet state, pushes updates every 2.0s, and handles ping/pong. | Hardware AVL GPS receiver ingestion is simulated rather than physical hardware. | Provide hardware AVL/NMEA receiver connector specification. |
| **Phase 11: Demand Prediction Audit** | **PARTIALLY VERIFIED** | Ridge regression model is instantiated from scikit-learn and fit on multi-feature arrays; 4-horizon points (NOW, +15m, +30m, +60m) are produced. | Model is trained on an 8-row toy dataset; for primary Route 205, ML predictions are **COMPLETELY OVERWRITTEN** with static hardcoded numbers (`41.8`, `45.2`, `52.0`, `64.5`). | Remove hardcoded override for Route 205; generate a realistic multi-week corridor dataset to train Ridge regression. |
| **Phase 12: Recommendation Audit** | **PARTIALLY VERIFIED** | Multi-factor scoring formula (`(crowd * 0.4) + (eta * 0.3) + (priority_lane * 0.3)`) computes journey scores. | Bus 205 is hardcoded as `is_recommended=True` regardless of query inputs or live crowding; alternatives (14A, 12) are hardcoded; `why_recommended` text is static. | Implement dynamic bus candidate search from database, compute journey scores dynamically, and sort to select the highest-scoring bus. |
| **Phase 13: Ticketing Audit** | **PARTIALLY VERIFIED (SIMULATED PAYMENT)** | Booking creates tickets; QR generation produces valid Base64 PNGs; conductor validator implements state transitions (VALID -> USED), anti-reuse detection (ALREADY_USED), and invalid token rejection. | Payment is simulated sandbox mode; newly booked tickets and validation audit events are kept in memory and NOT persisted to Supabase database. | Insert tickets into Supabase `tickets` table and validations into `ticket_validations` table; connect live Razorpay webhook when ready. |
| **Phase 14: RAG Audit** | **PARTIALLY VERIFIED** | Chat assistant responds with relevant transit guidance, cites sources, interpolates live bus telemetry, and triggers safe fallback for out-of-scope questions. | **NOT REAL RAG**: No vector embeddings, no vector database, and no LLM API calls; implemented as keyword matching against 4 static memory documents with hardcoded string branches. | Implement pgvector or embeddings index on `knowledge_documents` and integrate Google Gemini API using configured `AI_API_KEY`. |
| **Phase 15: Notification & Alert Audit** | **PARTIALLY VERIFIED** | Incident reporting and alert retrieval APIs work in-memory and return structured responses. | Supabase database is not updated when incidents are logged; push notification service (FCM / Web Push) is not implemented; `/api/notifications` returns 404; frontend notification bell is a static icon. | Persist incidents/alerts to Supabase; implement Web Push notifications or WebSocket alert broadcast. |
| **Phase 16: Cross-Platform Audit** | **PARTIALLY VERIFIED** | End-to-end flow from backend simulation -> GPS updates -> passenger booking -> QR generation -> conductor validation functions seamlessly in memory. | Flutter native applications are **NOT IMPLEMENTED** (Next.js web shell only); booking/validation flow does not synchronize back to Authority metrics or database. | Implement Flutter client projects or formalize Next.js PWA as the official multi-device deployment. |
| **Phase 17: Testing & Security Audit** | **PARTIALLY VERIFIED** | 7/7 backend unit tests pass in pytest; `.env` is properly excluded in `.gitignore`. | Shallow test coverage (7 smoke tests; zero auth, RBAC, database, or frontend tests); `require_roles` is never enforced; CORS wildcard `*` with credentials enabled; PostgREST URL filter string concatenation lacks parameter escaping; `DEBUG=True` enabled. | Write comprehensive test suite; enforce RBAC dependencies; restrict CORS origins; sanitize database queries; disable debug mode for production. |
| **Phase 18: Deployment Audit** | **NOT DEPLOYED** | Next.js builds locally without errors. | No Dockerfile; no docker-compose.yml; no CI/CD workflows; no staging/production environment configured; not deployed to any cloud host. | Create Dockerfile for backend and frontend; configure GitHub Actions CI/CD; deploy to containerized staging environment. |

---

## Audit Totals

- **Total Phases Evaluated:** 19 (Phase 0 through Phase 18)
- **Total VERIFIED:** 2 (10.5%)
- **Total PARTIALLY VERIFIED:** 16 (84.2%)
- **Total NOT VERIFIED:** 0 (0.0%)
- **Total NOT IMPLEMENTED:** 0 (Parent phase level; specific features such as Flutter and real YOLO inference are not implemented)
- **Total BLOCKED:** 0 (0.0%)
- **Deployment Status:** **NOT DEPLOYED**

---

## Detailed Gap & Problem Analysis

### 1. Critical Problems
1. **Unenforced RBAC:** Although `require_roles` is defined in [backend/app/core/security.py](file:///d:/Bus_Sense_Ai/backend/app/core/security.py), it is **never applied** to any domain endpoint. Any unauthenticated caller can invoke conductor QR validation, report incidents, or access fleet analytics.
2. **Volatile In-Memory State Bypassing Database:** Ticket booking, QR validations, driver incidents, and public alerts write exclusively to in-memory Python lists and dictionaries (`self.tickets`, `INCIDENTS_STORE`, `ALERTS_STORE`). None of these transactions are written to the live Supabase PostgreSQL database. Server restart wipes all active tickets and incidents.
3. **Hardcoded Overrides in ML Forecasting:** In [demand_forecaster.py](file:///d:/Bus_Sense_Ai/backend/app/services/demand_forecaster.py), the Ridge regression model is completely bypassed for the primary Route 205 via hardcoded `if route_number == "205": pred_val = 41.8 / 45.2 / 52.0 / 64.5`.
4. **Hardcoded Winning Recommendation:** In [recommendation_engine.py](file:///d:/Bus_Sense_Ai/backend/app/services/recommendation_engine.py), Bus 205 is statically assigned `is_recommended=True` with hardcoded text regardless of query origin, destination, or real-time occupancy.

### 2. Hardcoded / Mock Functionality
- **Authority Dashboard Screens:**
  - [routes/page.tsx](file:///d:/Bus_Sense_Ai/frontend/app/authority/routes/page.tsx): Route schedules and stop sequences are 100% hardcoded in JSX; zero API integration.
  - [alerts/page.tsx](file:///d:/Bus_Sense_Ai/frontend/app/authority/alerts/page.tsx): Incident list and severity ratings are 100% hardcoded in JSX; resolve action merely appends to a local React state array.
  - [ai-ops/page.tsx](file:///d:/Bus_Sense_Ai/frontend/app/authority/ai-ops/page.tsx): Dispatch queue and 3-stage decision cards are 100% hardcoded in JSX.
  - [reports/page.tsx](file:///d:/Bus_Sense_Ai/frontend/app/authority/reports/page.tsx): Historical performance and carbon metrics are 100% hardcoded in JSX.
  - [command/page.tsx](file:///d:/Bus_Sense_Ai/frontend/app/authority/command/page.tsx): Corridor counts ("48", "18"), corridor speed ("28.6 km/h"), and on-time performance ("92.4%") are hardcoded.
- **Frontend Fallbacks:**
  - [frontend/lib/api.ts](file:///d:/Bus_Sense_Ai/frontend/lib/api.ts): Calls `/occupancy/predictions` which returns 404, silently dropping to a hardcoded fallback object (`{ now: 42%, plus_15m: 58%, plus_30m: 82%, plus_60m: 49% }`).
- **Passenger Screens:**
  - [passenger/home/page.tsx](file:///d:/Bus_Sense_Ai/frontend/app/passenger/home/page.tsx): The AI recommendation banner ("Bus 205 departs shortly after 14A...") is static hardcoded text.
  - [passenger/profile/page.tsx](file:///d:/Bus_Sense_Ai/frontend/app/passenger/profile/page.tsx): User profile info is hardcoded to Rahul Nair without reading `/api/auth/me`.

### 3. Backend Gaps
- Missing endpoints requested in transit specifications: `/api/trips`, `/api/locations`, `/api/crowd`, `/api/predictions`, `/api/payments`, `/api/alerts`, `/api/notifications`, `/api/auth/logout`.
- Health check endpoint `/health` returns static `"supabase_connected": true` without verifying actual database socket connectivity.
- Absence of background automated alert triggers from telemetry thresholds.

### 4. Database Gaps
- Separate tables for `passengers`, `drivers`, and `conductors` do not exist; all identities reside in `users`.
- Prototype RLS policies (`USING (true)`) leave database tables completely open to any anon key holder.
- Tables `tickets`, `ticket_validations`, `payments`, `incidents`, `alerts`, `crowd_predictions`, and `reports` remain empty or unwritten by active backend service operations.

### 5. Frontend Gaps
- Route maps are static SVG line drawings or Google Stitch background images rather than interactive vector map layers (MapLibre / Leaflet).
- The notification bell icon is static with no notification center modal or real-time badge.
- Zero unit, component, or end-to-end frontend tests exist in the repository.

### 6. AI / RAG Gaps
- **Not Real RAG:** Implemented as a keyword-matching dictionary lookup against 4 memory strings with `if/elif` branches injecting telemetry.
- No vector embeddings generated, no pgvector similarity index, and no LLM API call made (despite `AI_API_KEY` being configured in `.env`).

### 7. Computer Vision Gaps
- YOLOv8 model inference is **not implemented**; `backend/app/services/cv_occupancy.py` simply takes `current_passenger_count` and passes it through.
- OpenCV (`cv2`) is missing from the Python virtual environment.
- No RTSP streaming client or video decoding pipeline exists.

### 8. Realtime Gaps
- Simulated GPS movement works well for prototype demonstration, but no MQTT, AVL, or GTFS-RT ingestion pipeline exists for real vehicle hardware dongles.

### 9. Security Gaps
- `require_roles` is never applied to domain routes; any anonymous client can post incidents or validate tickets.
- CORS is configured with `allow_origins=["*"]` combined with `allow_credentials=True`.
- `DEBUG=True` is enabled in production configuration files.
- `app/core/supabase.py` concatenates URL parameters without URL encoding: `f"{self.base_url}/rest/v1/{table}?{filter_col}=eq.{filter_val}"`.

### 10. Deployment Gaps
- Project is **NOT DEPLOYED**.
- No Dockerfile, docker-compose, or container manifest exists.
- No GitHub Actions CI/CD workflows exist.
- Execution relies entirely on manual local process invocation (`uvicorn` on 8000, `next dev` on 3000).

---

## Conclusion

The BusSense AI codebase represents a functional and visually cohesive prototype: the Next.js frontend delivers a clean implementation of the Google Stitch aesthetic; the FastAPI backend runs stably and serves live telemetry over WebSockets; the in-memory ticket lifecycle and QR validator state machines operate reliably; and the Supabase database is connected and seeded.

However, claims that the project is "COMPLETED" across Phases 0–17 or "READY" for deployment are technically inaccurate. The architecture currently relies on in-memory persistence, keyword-based mock RAG, synthetic occupancy calculations without YOLO neural execution, hardcoded recommendation outputs for Route 205, and hardcoded authority reporting screens.

This audit provides the objective baseline required for systematic, evidence-based hardening.
