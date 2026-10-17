# BusSense AI — Changelog

All notable changes to the BusSense AI platform are documented in this file, adhering to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [0.18.0-production-hardening-h14] — 2026-10-17

### Added
- **Production Configuration & Secrets Hardening (H14 Step 1):**
  - Strict Pydantic model validation rejecting empty, weak, or default fallback `SECRET_KEY` (minimum 32 characters required in production).
  - Dynamic CORS parsing and normalization from `ALLOWED_ORIGINS` environment variable, strictly prohibiting wildcards (`*`) with credentials and rejecting localhost-only origins in production.
  - Isolated demo commuter accounts (`DEV_ACCOUNTS`) behind server-side guards requiring `ENVIRONMENT != "production"` and `DEMO_MODE == True`.
  - Created `.env.production.example` template with complete variable documentation and safe placeholders.
- **Backend Reliability & Container Health Probes (H14 Step 2):**
  - Container liveness probe `GET /health/live` returning HTTP 200 without external dependencies.
  - Container readiness probe `GET /health/ready` returning HTTP 200/503 based on a bounded 2.0-second Supabase database health ping.
  - Sanitized existing `/health` endpoint to eliminate internal database URL and hostname disclosure.
  - Request correlation middleware assigning and propagating `X-Request-ID` across all HTTP request cycles.
  - Centralized global 500 unhandled exception handler logging full internal traces securely while returning uniform, sanitized JSON to API clients without stack trace leakage.
  - Centralized structured logging module (`backend/app/core/logging.py`) replacing ad-hoc `print()` calls.
- **Ticket Validation RPC Permission Resolution (H14 Step 2):**
  - Added backend-only service-role authorization support in `SupabaseService.rpc` for privileged execution of `validate_ticket_atomic`.
  - Implemented transactional database fallback in `TicketService` for local dev/testing environments without service-role keys.
  - Verified caller role enforcement (`DRIVER_CONDUCTOR` or `AUTHORITY`) and anti-reuse atomicity.
- **Containerization & Deployment Infrastructure (H14 Step 3):**
  - Multi-stage `backend/Dockerfile` using `python:3.12-slim` and non-root `appuser:1000`.
  - Multi-stage `frontend/Dockerfile` using `node:20-alpine`, Next.js 14 standalone output, and non-root `nextjs:1001`.
  - Created `.dockerignore` files for backend and frontend excluding development artifacts and secret files.
  - Root `docker-compose.yml` linking FastAPI backend and Authority console with health-check dependency gating and zero hardcoded secrets.
  - Added `docs/DEPLOYMENT_GUIDE.md` detailing operational runbooks, backup routines, rollback procedures, and PowerShell commands.
  - Audited local host environment and documented runtime Docker availability status.
- **Deployment Operations, Disaster Recovery & Staging Verification (H14 Step 4):**
  - Authored comprehensive disaster recovery matrix and operator runbook covering automated Supabase Point-in-Time Recovery (PITR), pre-release logical schema backups (`pg_dump`), image rollback, and schema revert procedures.
  - Created automated non-destructive staging smoke-test suite (`scripts/staging_smoke_test.py`) validating liveness, readiness, CORS headers, correlation IDs, authentication barriers, and conductor role boundaries with sanitized output.
  - Documented troubleshooting catalog for common networking, port conflict, CORS, and database readiness failure modes.
- **Test Suite Verification:**
  - 17 new automated tests in `backend/tests/test_production_readiness_h14.py`.
  - Full backend test suite passing 203/203 tests (100%).
  - Full mobile test suite passing 100/100 tests (100%).
  - Authority console passing 22/22 tests with 22/22 routes compiling (standalone build verified).

---

## [0.17.0-integration-security-h13] — 2026-10-14

### Added
- **Full End-to-End System Integration:**
  - Integrated and verified all 5 core journeys: Passenger Discovery & Ticketing, Conductor Cockpit & Atomic Validation, Authority Command Center & Incident Triage, Grounded RAG AI Assistant with Controlled Tools, and Realtime Telemetry Streaming with Polling Fallback.
  - Overall automated regression suite passing 100%: 186/186 backend pytest tests, 22/22 Authority dynamic tests, 22/22 Next.js routes compiled, and 100/100 Flutter mobile widget/unit tests.
- **Supabase Security Remediation (Migration `006_supabase_security_remediation.sql`):**
  - Remediated all 9 Supabase Security Advisor vulnerabilities for project `lqegmqgkymstycpzplld`.
  - Enabled Row Level Security on `roles`, `bus_recommendations`, `notifications`, `journey_history`, `ai_conversations`, `ai_messages`.
  - Enforced strict user-ownership RLS policies, eliminating wide-open `USING (true)` definitions.
  - Secured `validate_ticket_atomic` stored procedure with explicit `SET search_path = public, pg_temp;`.
  - Added missing RLS policies for `favorites` and `knowledge_chunks`.
  - Implemented 12 automated security regression tests in `backend/tests/test_supabase_security_h13.py`.
- **GitHub Synchronization Audit & Diagnostics:**
  - Audited local Git state (branch `master`, 0 initial commits) and uncommitted changes across H1–H13.
  - Verified pre-publication secret exclusion (zero credentials, passwords, or service-role keys bundled).
  - Documented network diagnostics and operator instructions in `docs/GITHUB_SYNC_REPORT.md`.

---

## [0.16.0-realtime-notifications-h12] — 2026-10-14

### Added
- **Realtime Streaming & Data Freshness Engine (`backend/app/services/realtime_service.py`):**
  - Standardized typed event envelope (`RealtimeEvent`) with strict schema validation (`event_id`, `event_type`, `entity_id`, `timestamp`, `data_origin`, `schema_version`, `payload`).
  - Dual WebSocket endpoints:
    - Public `/ws/telemetry`: anonymous broadcast stream for live vehicle coordinates, stop count-downs, and public alerts.
    - Authenticated `/ws/live`: role-authorized stream with query token or initial AUTH frame handshake, enforcing RBAC topic subscriptions (`public`, `user`, `passenger`, `driver_conductor`, `authority`).
  - In-memory 100-event ring buffer backing HTTP polling fallback (`GET /api/realtime/events?since=...&event_type=...`).
  - Connection capacity throttling with `MAX_CONNECTIONS = 100` and HTTP 1013 close frames.
  - Data Freshness Tracker (`FreshnessInfo`) calculating age dynamically and flagging `is_stale: true` when telemetry exceeds 15 seconds.
  - Transparent truth origins: `SIMULATED TELEMETRY`, `LIVE SENSOR TELEMETRY`, `CV REPLAY`, `MACHINE LEARNING PREDICTION`, `HUMAN-REPORTED INCIDENT`.
- **In-App Notification Domain (`backend/app/services/notification_service.py`):**
  - Supabase persistence with migration `005_realtime_notifications.sql`.
  - 15-minute deduplication window via SHA-256 `dedup_key` hashing.
  - Unread badge counters (`GET /api/notifications/unread-count`).
  - Single and bulk mark-as-read mutations (`POST /api/notifications/{id}/read`, `POST /api/notifications/mark-all-read`).
  - Strict user isolation preventing unauthorized access across commuter accounts.
- **Push Notification Abstraction (`backend/app/services/push_service.py`):**
  - Honest disclosure of `delivery_status: DEFERRED` without false claims of OS delivery until physical Apple APNs / Google FCM server keys are configured.
- **Flutter Mobile Realtime & Notification Experience (`apps/mobile/`):**
  - `RealtimeClient` with auto-reconnect, exponential backoff (1s to 30s), heartbeat ping-pong, and automatic polling fallback.
  - Riverpod providers: `realtimeClientProvider`, `realtimeStatusProvider`, `telemetryFreshnessProvider`, `telemetryIsStaleProvider`, `passengerNotificationsProvider`, `unreadNotificationsCountProvider`.
  - Passenger Shell: Notification bell with unread badge counter in top AppBar.
  - Notification Center (`notification_center_screen.dart`): Filter by all/unread, mark all as read, truth origin badges, and empty/error states.
  - Live Freshness Badging: Live Map View and Active Journey HUD display real-time freshness pill (`SIMULATED GPS TELEMETRY • FRESH / STALE`).
- **Authority Next.js Web Stream Subscriber (`frontend/lib/realtime.ts`):**
  - Unified stream helper with WebSocket connection and polling fallback.
  - Staleness evaluation matching mobile thresholds (15s).
- **Test Suite Verification:**
  - Backend: 23/23 tests passing in `test_realtime_notifications_h12.py`; full backend regression passing 174/174.
  - Authority: 22/22 dynamic tests passing (100%).

---

## [0.15.0-rag-ai-assistant-h11] — 2026-10-13

### Added
- **RAG AI / Intelligent Transport Assistant (`backend/app/services/`):**
  - **Knowledge Base Audit & Update (v1.1.0):**
    - Audited 5 canonical transit knowledge documents in `backend/knowledge/`: `routes.md`, `tickets.md`, `crowd.md`, `recommendations.md`, and `passenger_help.md`.
    - Enforced zero biometrics guarantees, explicit unassigned seating rules, atomic QR validation lifecycles, and prototype boundaries.
  - **Vector Retrieval Engine (`backend/app/services/knowledge_indexer.py`):**
    - Structured document chunking with metadata preservation (`document_id`, `chunk_id`, `section`, `applicable_route`, `access_scope`, `version`).
    - Deterministic chunk identifiers and idempotent re-indexing.
    - Scikit-learn TF-IDF vectorization with sublinear term frequency, (1, 2) n-grams, cosine similarity, and section/title term boosting.
    - Relevance filtering with an evidence threshold of `0.08`, honestly classified as `IMPLEMENTED / TFIDF_VECTOR_FALLBACK`.
  - **Controlled Live Transport Tools (`backend/app/services/ai_tools.py`):**
    - `tool_get_bus_location(bus_number)`: Queries live vehicle GPS, speed, and next stop.
    - `tool_get_crowd_prediction(bus_number)`: Executes H9 Ridge multi-horizon forecasts (+15m, +30m, +60m).
    - `tool_get_recommendation(origin, destination, preference)`: Executes H10 multi-factor candidate scoring.
    - `tool_get_user_tickets(user_id)`: Fetches passenger tickets with strict JWT-enforced user identity isolation.
  - **Prompt Injection & Scope Guard (`backend/app/services/prompt_guard.py`):**
    - Pattern matching defenses against jailbreak attempts, developer mode exploits, system prompt overrides, credential exposure, and non-transit out-of-scope inquiries.
  - **Provider Abstraction (`backend/app/services/ai_provider.py`):**
    - `ExternalLLMProvider` adapter with configurable environment variables (`AI_PROVIDER`, `OPENAI_API_KEY`, `OPENAI_API_BASE`), strict connect (3s) and read (8s) timeouts, and fallback to `DevelopmentFallbackAIProvider`.
  - **Benchmark Evaluation Dataset (`backend/app/services/rag_evaluation.py`):**
    - 16 test queries across 10 evaluation categories achieving 93.8% accuracy and 100% prompt injection defense.
  - **Test Suite (`backend/tests/test_rag_ai_h11.py`):**
    - 29 focused tests verifying retrieval ranking, citation integrity, tool invocation, cross-user isolation, prompt injection defense, and provider fallbacks.
    - Total backend tests expanded to 150 passed, 1 skipped, 0 failed.

---

## [0.14.0-recommendation-engine-h10] — 2026-10-13

### Added
- **Smart Bus Recommendation Engine (`backend/app/services/recommendation_engine.py`):**
  - **Multi-Factor Normalized Scoring Engine:**
    - Evaluates candidate buses using 6 normalized dimensions: arrival ETA ($s_{\text{eta}}$), real-time cabin occupancy ($s_{\text{crowd}}$), H9 predicted occupancy with confidence discount ($s_{\text{pred}}$), effective travel duration with bus lane advantage ($s_{\text{time}}$), transit fare ($s_{\text{fare}}$), and corridor reliability.
    - Zero single-factor dominance; explicitly balances speed, comfort, and economy.
  - **H9 Ridge Demand Prediction Integration:**
    - Horizon-selection logic dynamically maps journey duration to prediction horizons ($+15\text{m}$ for $\le 20\text{m}$, $+30\text{m}$ for $\le 45\text{m}$, $+60\text{m}$ for $> 45\text{m}$).
    - Confidence blending formula: $s_{\text{pred}} = (c \cdot s_{\text{pred, raw}}) + ((1 - c) \cdot s_{\text{crowd}})$, discounting low-confidence predictions towards current observed crowd.
  - **Preference Modes:**
    - Supported and server-validated modes: `balanced` (default), `fastest`, `least_crowded`, and `lowest_fare`.
  - **Data Quality Engine:**
    - Computes transparent three-tier rating: `HIGH` (CV replay + high confidence), `MEDIUM` (simulated telemetry), and `LOW` (unmonitored / fallback).
  - **Deterministic Explanation Engine:**
    - Template-driven rationale generation without external LLM dependencies or false certainty claims (uses *"is expected to be"*).
  - **Elimination of Hardcoded Bus 205 Winner:**
    - Zero static rules or preferences favor Bus 205; candidates are evaluated strictly on live telemetry, predictions, and user preferences.
  - **FastAPI Recommendation Endpoints (`backend/app/api/recommendations.py`):**
    - `GET /api/recommendations/plan`: Multi-factor journey plan with recommended bus, alternatives, deltas, and truth metadata.
    - `POST /api/recommendations/plan`: Accepts structured `JourneyPlanRequest` body.
    - `GET /api/recommendations/preferences`: Lists supported preference modes.
    - Asynchronous Supabase snapshot recording for non-blocking latency ($< 15\text{ms}$).
  - **Mobile & Web Integration:**
    - Flutter client compatibility verified across `JourneyPlanModel` and `BusRecommendationItem` (96/96 tests passing).
    - Next.js Authority portal compatibility verified with `RecommendationResponse`, diagnostics, and 4-tier decision hierarchy (19/19 tests passing).
  - **Test Suite (`backend/tests/test_recommendation_h10.py`):**
    - 27 tests covering all 24 specification requirements, edge cases, and CPU latency performance (< 50ms).
    - Total backend tests expanded to 121 passed, 1 skipped, 0 failed.

---

## [0.13.0-demand-prediction-h9] — 2026-09-27

### Added
- **Demand Prediction & Crowd Forecasting Engine (`backend/app/services/`):**
  - **Feature Engineering Layer (`FeatureEngineer` in `backend/app/services/prediction_dataset.py`):**
    - 10 explainable features: `hour_of_day`, $\sin/\cos$ cyclical hour representations, `day_of_week`, `is_weekend`, `current_occupancy`, `lag_1_occupancy`, `rolling_mean_3`, `occupancy_trend_slope`, and `corridor_base_density`.
    - Strict avoidance of future-data leakage through lag-based feature construction.
  - **Historical Corridor Observations Dataset (`backend/app/services/prediction_dataset.py`):**
    - Deterministic, reproducible chronological time-series of 558 observations across Greater Kochi corridors (Route 12, Route 14A, Route 205).
    - Honestly classified as `DEVELOPMENT / LOW-DATA (558 chronological observations)`.
  - **Multi-Horizon Ridge Demand Forecaster (`backend/app/services/demand_forecaster.py`):**
    - Explainable Scikit-Learn Ridge regression models (`alpha=1.0`) trained for horizons $+15\text{m}$, $+30\text{m}$, and $+60\text{m}$.
    - Model version: `ridge-demand-v2-corridor`.
    - Chronological 80/20 train/test split without random shuffling.
    - Empirical evaluation vs persistence baseline ($\hat{y}_{t+h} = y_t$): $+15\text{m}$ MAE $0.93\%$ vs $1.61\%$ (42% improvement); $+30\text{m}$ MAE $1.59\%$ vs $3.20\%$ (50% improvement); $+60\text{m}$ MAE $3.20\%$ vs $6.17\%$ (48% improvement).
  - **Dynamic Real-Time Inference & Hardcoding Elimination:**
    - Eradicated legacy hardcoded static trajectories for Bus 205.
    - Dynamically seeds forward predictions from real fleet telemetry and Computer Vision replay occupancy (`POST /api/occupancy/events`).
    - Clamps every output strictly to $[0.0, 100.0]\%$.
    - Enforces unified crowd tiers: `LOW < 50%`, `MODERATE 50–80%`, `CROWDED > 80%`.
  - **Low-Data Safety & Graceful Degradation:**
    - Unknown or low-observation buses return `status: "LOW_DATA"`, discounted confidence ($< 0.60$), and sensible corridor prior fallback.
  - **API Endpoints (`backend/app/api/predictions.py` & `backend/app/api/occupancy.py`):**
    - `GET /api/predictions`: List fleet corridor prediction trajectories.
    - `GET /api/predictions/{bus_number}`: Standard 4-horizon trajectory (`NOW`, `+15 MIN`, `+30 MIN`, `+60 MIN`).
    - `GET /api/predictions/{bus_number}/details`: Full prediction audit with evaluation metrics, model metadata, and trend messages.
    - `GET /api/occupancy/predictions`: Authority 4-horizon dictionary.
    - Asynchronous persistence of +30m snapshot to Supabase `crowd_predictions` table.
  - **Test Suite & Verification:**
    - 17 new tests in `backend/tests/test_demand_prediction_h9.py` covering feature extraction, cyclical encoding, time ordering, multi-horizon predictions, clamping, thresholds, baseline evaluation, low-data safety, schemas, and API routes.
    - Total backend tests: 95/95 passing.
    - Zero regressions across Flutter mobile (96/96 tests passing, 0 analyze issues) and Authority Next.js (22/22 routes compiling, 19/19 frontend tests passing).

---

## [0.12.0-cv-occupancy-h8] — 2026-09-27

### Added
- **Computer Vision Occupancy Intelligence — Offline / Replayable Pipeline (`backend/cv/`):**
  - **YOLO Person Detection Engine (`backend/cv/detector.py`):**
    - High-accuracy object detection powered by Ultralytics YOLOv8n (3.2M params).
    - Class filtering strictly locked to COCO Class 0 (`person`) exclusively; all non-person classes dropped at inference time.
    - Configurable confidence threshold (default 0.40) and automatic device detection (CPU and CUDA support).
  - **Temporal Stabilization & Outlier Rejection (`backend/cv/smoothing.py`):**
    - Explainable 5-frame rolling median temporal filter (`TemporalStabilizer`).
    - Eliminates bounding box flickering, transient camera occlusions, and single-frame spikes without asymptotic lag.
    - Explicitly distinguishes `raw_person_count` from `stabilized_person_count`.
  - **Occupancy Calculation & Crowd Classification (`backend/cv/occupancy.py`):**
    - Capacity formula clamped strictly to `[0.0, 100.0]%`: $(\text{person\_count} / \text{capacity}) \times 100$.
    - Enforces unified BusSense crowd tiers: `LOW < 50%`, `MODERATE 50–80%`, `CROWDED > 80%`.
    - Handles vehicle capacity validation ($>0$) and clamps over-capacity readings.
  - **Offline Video Replay Processor (`backend/cv/video_processor.py`):**
    - Decodes MP4 recorded bus video with configurable frame sampling stride (`process_every_n_frames=3`).
    - Measures empirical performance metrics (inference latency ms, processing FPS).
    - Optional debug annotated video generation with bounding boxes and HUD diagnostics overlay box without biometric labels.
    - CLI entry point: `python -m backend.cv.video_processor --video datasets/videos/sample_bus.mp4 --bus 205`.
  - **Deterministic Sample Video Generator (`backend/cv/create_sample_video.py`):**
    - Creates deterministic MP4 test video (`datasets/videos/sample_bus.mp4`) from real photographic assets with cinematic perspective pan.
  - **Backend Ingestion & Fleet Integration (`backend/app/api/occupancy.py`):**
    - New ingestion route `POST /api/occupancy/events` protected by `AUTHORITY` / `ADMIN` role and `X-Internal-Secret` header.
    - Strict validation: verifies bus existence in active fleet, capacity $>0$, non-negative counts.
    - Zero-Trust validation: backend recalculates trusted occupancy percentage and verifies crowd tier.
    - Updates in-memory fleet state in `GpsSimulationEngine`; stamps `data_origin: "CV REPLAY"`.
    - Disables simulated random passenger flux for vehicles currently receiving CV replay telemetry.
  - **Database Persistence & Migration 004 (`backend/migrations/004_cv_replay_support.sql`):**
    - Extends `data_origin` PostgreSQL enum with `'CV_REPLAY'` and `'ESTIMATE'`.
    - Persists aggregate occupancy snapshots to Supabase `occupancy_readings` table.
  - **Strict Privacy Guarantees:**
    - Zero facial recognition, zero facial identification, zero demographic classification, zero biometric storage, zero person re-identification.
    - Schema stamped with `privacy_standard: "PERSON_COUNTING_ONLY_NO_BIOMETRICS"`.
  - **Test Suite & Verification:**
    - 22 new tests in `backend/tests/test_cv_occupancy_h8.py` covering detection, filtering, smoothing, clamping, schema validation, replay pipeline, auth, and privacy boundaries.
    - Full backend suite: 78/78 tests passing (100%).
    - Zero regression across Flutter mobile (96/96 tests passing, 0 analyze issues) and Authority Next.js (22/22 routes compiling, 19/19 tests passing).

---

## [0.11.0-authority-h7] — 2026-09-27

### Added
- **Authority Web Dynamic Integration & Operations Data (`frontend/`):**
  - **Dynamic Command Center (`/authority/command`):**
    - Connected to `GET /api/analytics/command-overview`, `GET /api/buses`, and `GET /api/alerts/active`.
    - Real-time network telemetry HUD, corridor speeds, dynamic SVG map markers with real Kerala GPS coordinates, floating vehicle inspect cards, and live public service alert tickers.
  - **Live Fleet & Bus Inspector (`/authority/fleet`):**
    - Connected to `GET /api/buses` and `GET /api/buses/{number}` with real-time KPI banner (Active Fleet, Fleet Readiness, Critical Alerts, Avg Occupancy).
    - Tabular fleet roster with live filtering and status badges (`ON_SCHEDULE`, `RUNNING_DELAY`, `LAYOVER`).
    - Dynamic Bus Inspector drawer with live coordinates, driver assignment, speed, and cockpit ping.
  - **Routes & Corridors (`/authority/routes`):**
    - Connected to `GET /api/routes`, `GET /api/buses`, and `GET /api/alerts/active`.
    - Live Kerala corridor definitions (Route 12, 14A, 205), active fleet correlation, milestone stop sequence timeline, and prototype dispatch warning modal.
  - **Alerts & Operational Incidents (`/authority/alerts`):**
    - Connected to `GET /api/incidents/` and `GET /api/alerts/active`.
    - Live incident triage counters (Warnings, Investigating, Resolved) and incident queue.
    - Interactive duty officer incident resolution mutation calling `POST /api/incidents/{id}/resolve` with resolution notes.
  - **Predictive Crowd Horizon (`/authority/forecast`):**
    - Connected to `GET /api/occupancy/predictions` and `GET /api/predictions/{bus_number}`.
    - Vehicle selector tabs (Bus 205, Bus 14A, Bus 12) with 4 forward horizons (`NOW`, `+15 MIN`, `+30 MIN`, `+60 MIN`).
    - Dynamic SVG trendline spline curves with mathematical coordinates derived from real predicted values.
  - **AI Operations Decision Queue (`/authority/ai-ops`):**
    - Connected to `GET /api/analytics/ai-decision-queue` and `GET /api/analytics/command-overview`.
    - 4-tier decision hierarchy (`LIVE DATA` ➔ `PREDICTION` ➔ `RECOMMENDATION` ➔ `HUMAN DECISION`).
    - Interactive controller authorization actions (`Authorize Dispatch`, `Broadcast Skip-Stop`, `Decline`).
  - **Sustainability & Reports Archive (`/authority/reports`):**
    - Connected to `GET /api/analytics/reports` reading directly from Supabase PostgreSQL `reports` table.
    - Documented $0.12\text{ kg CO}_2\text{ / pax-km}$ modal shift baseline formula and `REPORT EXPORT DEFERRED` button badge.
  - **Authority RBAC Layout Guard (`/authority/layout`):**
    - Authenticated session gate enforcing role clearance.
    - 401 Unauthorized screen with 1-click demo duty controller login.
    - 403 Forbidden screen rejecting passenger and crew credentials.
  - **Frontend TypeScript SDK & Native Test Suite (`frontend/lib/api.ts` & `frontend/tests/`):**
    - Added TypeScript interfaces: `CommandOverview`, `AIDecision`, `OperationalReport`, `IncidentData`, `RouteData`, `AuthUser`.
    - Added API SDK methods: `getCommandOverview()`, `getAIDecisions()`, `getOperationalReports()`, `getIncidents()`, `resolveIncident()`, `getRoutes()`, `getBusPredictions()`, `switchDemoRole()`.
    - Added native test suite `frontend/tests/test_authority_dynamic.mjs` (19/19 passing).
- **Backend Test Suite (`backend/tests/test_authority_h7.py`):**
  - Added 9 tests verifying Authority RBAC (401 unauth, 403 passenger/conductor, 200 authority), command overview, AI decision queue, reports, incident resolution, routes, and 4-horizon predictions.
  - Complete backend suite: 56/56 passing.

---

## [0.10.0-conductor-h6] — 2026-09-27

### Added
- **Unified Flutter Mobile — Phase H6: Driver / Conductor Operational Experience (`apps/mobile/`):**
  - **Conductor Shell (`ConductorShell`):**
    - 5 bottom navigation tabs (`Trip`, `Scan`, `Bus`, `Alerts`, `Profile`).
    - Persistent header with active vehicle/corridor indicator, role badge (`CONDUCTOR`), and session logout.
  - **Active Trip Cockpit (`ActiveTripCockpitView`):**
    - Primary operational HUD designed for safety, glanceability, and large touch targets (48–56px).
    - Current stop, next stop in bold 24pt, destination terminus, stop progression bar.
    - Tabular 6 MIN ETA countdown, 42% cabin density card, safety notice ("Use only when safely stopped").
    - Primary controls: View Occupancy & Seating Gauge, Scan Passenger QR Pass, Report Route / Vehicle Incident, Complete Trip & Start Layover.
  - **Shift Check-In (`ShiftCheckInScreen`):**
    - Staff ID and duty roster display (`DUTY-KL-402`, `06:00 – 14:00`, KOC depot).
    - Vehicle assignment status and simulated shift check-in trigger with backend persistence.
  - **Bus & Route Pairing (`BusPairingScreen`):**
    - Fleet options (Bus 205, Bus 14A, Bus 12) with corridor route selection.
    - Dynamic pairing update in `conductorShiftProvider`.
  - **Cabin Occupancy View (`ConductorOccupancyScreen`):**
    - High-visibility 41.8% density metric, seated (23/35) vs standing (0/20) capacity counters.
    - BusSense operational thresholds: `LOW < 50%`, `MODERATE 50–80%`, `CROWDED > 80%`.
    - Truth badge: `SIMULATED DATA • ZERO BIOMETRICS`.
  - **QR Ticket Validator (`QrTicketValidatorView`):**
    - Camera viewfinder with `CAMERA SCAN DEFERRED • PROTOTYPE VIEW` badge.
    - 4 rapid test simulation scenarios (`Valid Pass`, `Already Used`, `Expired Pass`, `Invalid QR`).
    - Manual hash entry fallback and atomic result cards (`VALID`, `ALREADY USED`, `EXPIRED`, `INVALID`).
  - **Incident Reporter (`ConductorIncidentScreen`):**
    - Rapid transit hazard reporter with pre-selected categories, quick presets, and backend incident reference generation.
  - **Trip Completion & Layover (`TripCompletionScreen`):**
    - Corridor start/end summary, duration, boardings, atomic `COMPLETE TRIP` action, and prototype layover timer.
  - **Bus Operational Summary (`ConductorBusView`):**
    - Assigned bus specifications, corridor route, operating status, and quick cockpit navigation.
  - **Crew Alerts (`ConductorAlertsView`):**
    - Driver-relevant corridor delay notices, bottlenecks, and safety advisories.
  - **Crew Profile (`ConductorProfileView`):**
    - Staff name, duty ID, safety checklist, and immediate sign-out.
  - **Riverpod State Management:**
    - `conductorShiftProvider`, `assignedBusProvider`, `activeTripProvider`, `conductorOccupancyProvider`, `ticketValidationProvider`, `conductorAlertsProvider`.
  - **Backend Endpoints (`backend/app/api/conductor.py`):**
    - `GET /api/conductor/shift`, `POST /api/conductor/check-in`, `POST /api/conductor/pair-bus`, `POST /api/conductor/trips/start`, `POST /api/conductor/trips/complete`, `POST /api/conductor/validate-ticket`, `POST /api/conductor/incidents`, `GET /api/conductor/alerts`.
  - **Security & RBAC:**
    - Unauthenticated requests rejected with 401; Passenger role rejected with 403; Driver/Conductor and Authority authorized with 200.
    - Anti-reuse atomic ticket validation.
  - **Test Coverage & Verification:**
    - Added 15 Flutter tests in `apps/mobile/test/conductor_cockpit_test.dart` (96/96 mobile tests passing).
    - `flutter analyze`: 0 issues found.
    - Added 6 backend tests in `backend/tests/test_conductor_h6.py` (47/47 backend tests passing).
    - Authority Next.js build: 22/22 routes compiling with 0 errors.

---

## [0.9.0-passenger-h5-batch4] — 2026-09-27

### Added
- **Unified Flutter Passenger Experience — Batch 4 (Profile, Preferences, Privacy & Support):**
  - **Passenger Profile Hub (`PassengerProfileView`):**
    - Replaced Tab 4 placeholder in `PassengerShell` with full Google Stitch-compliant commuter control center.
    - Deep Forest Green header displaying commuter name, email, and `PASSENGER` role badge.
    - Categorized sections: Account, Travel & Shortcuts, Preferences, Privacy & Control, Support & Feedback.
    - Shortcuts to Saved Places, Favorite Route (`Route 205`), Passes, and Sign Out.
  - **Edit Profile (`EditProfileScreen`):**
    - Supported fields: Full Name and Preferred Language with validation and backend update via `PUT /api/user/profile`.
    - Phone number and email securely displayed as read-only.
  - **Saved Places (`SavedPlacesScreen`):**
    - Commuter destinations (Home, Work, College, Custom) with category badges and Kochi stop associations.
    - Add place modal bottom sheet, deletion confirmation, and 1-tap deep link into `PassengerExploreView`.
  - **Notification Preferences (`NotificationPreferencesScreen`):**
    - Master toggle and category switches (Arrivals, Delays, Crowd Pressure, Corridor Advisories, QR Pass Expiration).
    - Truth badge: `PREFERENCE MODEL • PUSH DELIVERY DEFERRED`.
  - **Language & Appearance (`LanguageAppearanceScreen`):**
    - Language switcher for English (India) and Malayalam with `PARTIAL / PREPARED` status badge.
    - Theme appearance controls (Light Surface `#F3FBF7` optimized, Dark Mode prepared).
  - **Privacy & Data Controls (`PrivacyDataScreen`):**
    - Factual disclosures on local YOLOv8 neural network (`ZERO BIOMETRICS`), transponder vehicle telemetry (`NO BACKGROUND TRACKING`), and RLS ticketing.
    - Data export requesting prototype JSON archive (`PROTOTYPE EXPORT ARCHIVE`).
    - Account deactivation confirmation flow (`PROTOTYPE DEACTIVATION`).
  - **Help & FAQ (`HelpSupportScreen`):**
    - 6 grounded FAQs explaining crowd calculation, multi-factor recommendation, QR tickets, dynamic ETAs, and simulated data badges.
  - **Report an Issue (`ReportIssueScreen`):**
    - Passenger incident form logging directly to backend incident queue with generated reference ID.
  - **Backend Endpoints (`backend/app/api/user.py`):**
    - `GET /api/user/profile` and `PUT /api/user/profile`
    - `GET /api/user/saved-places`, `POST /api/user/saved-places`, and `DELETE /api/user/saved-places/{place_id}`
    - `GET /api/user/preferences` and `PUT /api/user/preferences`
    - `POST /api/user/reports`
    - `POST /api/user/export-data` and `POST /api/user/deactivate`
  - **Test Coverage:**
    - Added 14 Flutter tests in `apps/mobile/test/passenger_profile_test.dart` (81/81 mobile tests passing).
    - Added 8 backend pytest tests in `backend/tests/test_user_profile_h5.py` (41/41 backend tests passing).
    - Verified Next.js Authority frontend build: 22/22 routes compiling with 0 errors.

---

## [0.8.0-passenger-h5-batch3] — 2026-09-27

### Added
- **Unified Flutter Passenger Experience — Batch 3 (Passenger AI / RAG Transit Assistant):**
  - **Passenger AI Primary Screen (`PassengerAssistantView`):**
    - Replaced Tab 3 placeholder in `PassengerShell` with full Google Stitch-compliant assistant.
    - Deep Forest Green header with "BusSense AI" title and "Your journey assistant" subtitle.
    - `RAG GROUNDED` status badge and conversation reset capability.
    - Contextual active journey banner automatically displaying current vehicle and destination with quick ETA prompts.
    - Actionable quick starters: "Which bus is less crowded?", "When will my bus arrive?", "Show my active ticket", etc.
  - **Source Citations & Provenance Modal (`AISourceDetailsSheet`):**
    - Modal bottom sheet displaying verified sources, evidence snippets, source classification, and backend references.
  - **Strict Answer Classification & Provenance Badges:**
    - Explicit differentiation between `LIVE DATA`, `PREDICTION`, `RECOMMENDATION`, `TICKET DATA`, `ACTIVE JOURNEY`, `KNOWLEDGE`, and `INSUFFICIENT INFORMATION`.
    - Truth labels: `LIVE SENSOR TELEMETRY`, `MACHINE LEARNING PREDICTION`, `MULTI-FACTOR RECOMMENDATION ENGINE`, `PERSISTENT POSTGRESQL TICKET STORE`, `VERIFIED KNOWLEDGE BASE`, and `SAFETY GUARDRAIL`.
  - **Context-Aware Deep-Links & Actions:**
    - One-tap navigation from AI responses directly into `DigitalQrTicketScreen`, `ActiveJourneyScreen`, `BusDetailsScreen`, and `ExploreCorridorsView`.
  - **Safe Fallback Against Hallucination:**
    - Rejection of out-of-domain queries without inventing transit routes, schedules, or facts.
  - **Grounded Knowledge Base (`backend/knowledge/`):**
    - Created 5 technical documents: `routes.md`, `tickets.md`, `crowd.md`, `recommendations.md`, and `passenger_help.md`.
  - **Controlled Backend Live-Data Tools & Provider Abstraction:**
    - `backend/app/services/rag_service.py` with controlled tools querying GPS simulator, 4-horizon demand forecasting, multi-factor recommendation engine, and persistent tickets.
    - `backend/app/services/ai_provider.py` with `BaseAIProvider` protocol and `DevelopmentFallbackAIProvider`.
    - Authenticated `POST /api/ai/chat` endpoint with JWT user isolation.
  - **Test Coverage:**
    - Added 11 Flutter mobile widget & integration tests in `apps/mobile/test/passenger_ai_assistant_test.dart` (67/67 mobile tests passing).
    - Added 8 backend pytest tests in `backend/tests/test_ai_assistant_h5.py` (33/33 backend tests passing).

---

## [0.7.0-passenger-h5-batch2] — 2026-09-27

### Added
- **Unified Flutter Passenger Experience — Batch 2 (Ticketing & Active Journey):**
  - **Booking Entry (`TicketBookingScreen`):**
    - Seamless flow from selected bus on Home/Explore/Bus Details to booking.
    - Origin and destination stop fields with validation.
    - Single-passenger name input with form validation.
    - Stage carriage reservation transparency note (unassigned seat model).
    - Tariff summary calculation in INR.
  - **Booking Review (`BookingReviewScreen`):**
    - Minimalist, high-contrast review of journey trajectory before payment.
    - Clear distinction of vehicle, boarding stop, passenger, and base tariff.
    - "BEFORE PAYMENT" status badge.
    - Primary "Proceed to Payment" and "Edit Details" actions.
  - **Test Payment Gateway (`TestPaymentScreen`):**
    - Prominently stamped `SIMULATED PAYMENT` gateway.
    - Prototype payment method selection (UPI, Transit Smart Card, NetBanking).
    - Mock processing delay with indeterminate progress indicator.
    - Dedicated "Simulate Payment Failure" button for test coverage.
    - Backend persistence call via `POST /api/tickets/book`.
  - **Digital QR Ticket (`DigitalQrTicketScreen`):**
    - Transit-style digital boarding pass with perforated ticket divider.
    - `VALID TICKET` status badge.
    - Scannable QR code generated from backend cryptographic hash via `qr_flutter: ^4.1.0`.
    - Fallback support for backend base64 image data URI.
    - Complete ticket metadata: Ticket ID, Route, Vehicle, Passenger, Fare, Validity window.
    - Direct CTA: "Track Active Journey HUD".
  - **Active Journey HUD (`ActiveJourneyScreen`):**
    - Commuter-focused, glanceable transit HUD following strict visual hierarchy:
      1. Current Bus (pill badge)
      2. Destination Stop
      3. Next Approaching Stop
      4. ETA Countdown (`tabularNumeral`)
      5. Route Progress (vertical milestone timeline)
    - Contextual cards: Live crowd level, active service advisories, and quick link back to digital QR pass.
    - Empty state when no trip is active.
  - **Passenger Tickets Landing (`PassengerTicketsView`):**
    - Populated Tab 2 (`Tickets`) of `PassengerShell`.
    - Active boarding passes section with "Show QR" and "Track HUD" actions.
    - Past tickets history with validation timestamps.
    - Pull-to-refresh connected to `GET /api/tickets/my`.
    - Empty state with "Explore Corridor Routes" button.
  - **State Management & Data Layer:**
    - `BookingDraft` immutable model for in-flight state across booking steps.
    - Riverpod providers: `currentBookingDraftProvider`, `myTicketsProvider`, `activeTicketProvider`, `activeJourneyTicketProvider`.
    - Added `bookTicket()` and `getMyTickets()` to `IPassengerRepository` and `PassengerRepository`.
- **Testing & Verification:**
  - 11 new widget tests in `passenger_ticketing_test.dart` covering validation, booking review, simulated payment success/failure, QR rendering, active journey HUD, empty states, and shell navigation.
  - Full mobile test suite passing: 56/56 tests.
  - Static analysis: 0 issues on `flutter analyze`.
  - Backend regression passing: 25/25 pytest tests.
  - Authority Next.js portal build: 22/22 routes compiling cleanly.

---

## [0.6.0-passenger-h5-batch1] — 2026-09-27

### Added
- **Unified Flutter Passenger Experience — Batch 1 (Core Journey Discovery):**
  - **Passenger Home (`PassengerHomeView`):**
    - "Where are you going?" hero destination search bar.
    - Active transit service alert banner connecting to `GET /api/alerts/active`.
    - Live corridor bus departures list consuming `GET /api/buses`.
    - Compact vehicle cards with ETA countdown (`tnum`), crowd density badges (`LOW`, `MODERATE`, `CROWDED`), occupancy percentages, and operator type.
    - Transparent `SIMULATED DATA` badges across all non-hardware telemetry.
    - Pull-to-refresh integration updating departures and alerts simultaneously.
  - **Explore / Route Planning (`PassengerExploreView`):**
    - Origin and Destination inputs with interactive stop-swapping.
    - Quick corridor shortcut chips ("Kaloor ➔ Vyttila", "Aluva ➔ South", "Fort Kochi ➔ Infopark").
    - Journey planning consuming `GET /api/recommendations/plan`.
    - Prominently styled "Recommended for you" hero card with crowd savings, time savings, and fare.
    - Side-by-side alternative bus option cards.
  - **Live Corridor Map (`PassengerLiveMapView`):**
    - Cross-platform OpenStreetMap tile rendering powered by `flutter_map` and `latlong2`.
    - Kochi transit corridor polyline context (Aluva ➔ Kalamassery ➔ Edappally ➔ Palarivattom ➔ Kaloor ➔ Vyttila).
    - Real-time bus pins positioned by latitude/longitude and colored dynamically by crowd density.
    - Selected vehicle inspection card with "View Bus Details" navigation.
  - **Bus Details (`BusDetailsScreen`):**
    - Complete vehicle profile (registration, route name, operator type, AC availability).
    - Stop progress indicators (current location, next stop, ETA countdown).
    - Cabin occupancy progress bar and privacy statement (person-counting only, no biometrics).
    - Direct actions to view 4-horizon crowd forecast and smart recommendations.
  - **Crowd Forecast (`CrowdForecastScreen`):**
    - 4 forward prediction horizons (**NOW**, **+15 MIN**, **+30 MIN**, **+60 MIN**) from `GET /api/predictions/{bus_number}`.
    - Clear distinction between live telemetry and predictive estimates.
    - Model confidence metrics and prototype prediction disclosure note.
  - **Smart Recommendation (`SmartRecommendationScreen`):**
    - Explainable recommendation UI displaying factors directly returned by backend engine.
    - Alternative options comparison table with explicit rationale.
  - **Data & State Management:**
    - Strongly-typed `IPassengerRepository` and `PassengerRepository` in `features/passenger/data/`.
    - Riverpod providers for live buses, locations, crowd, predictions, journey query, and plan.
    - Typed models `JourneyPlanModel` and `BusRecommendationItem`.
- **Testing & Verification:**
  - 10 new widget tests in `passenger_journey_test.dart` verifying all 6 screens, loading, empty, and error states.
  - 45/45 mobile tests passing; 0 issues on `flutter analyze`.
  - Backend regression passing 25/25 pytest suite.
  - Authority Next.js web application building 22/22 routes cleanly.

---

## [0.5.0-flutter-foundation-h4] — 2026-09-27

### Added
- **Unified Flutter Mobile Application Foundation (`apps/mobile/`):**
  - Generated single Flutter codebase targeting iOS, Android, macOS, Linux, and Windows.
  - Configured `pubspec.yaml` with production-grade dependencies: `flutter_riverpod`, `http`, `flutter_secure_storage`, `google_fonts`, `intl`, and `cupertino_icons`.
- **Role-Based Dynamic Mobile Architecture:**
  - Dynamic `AppRouter` switching experiences based on authenticated user role.
  - `PassengerShell`: Commuter-oriented shell with 5 placeholder navigation destinations (`Home`, `Explore`, `Tickets`, `AI`, `Profile`).
  - `ConductorShell`: Operational high-visibility shell with 5 placeholder operational destinations (`Trip`, `Scan`, `Bus`, `Alerts`, `Profile`).
  - Authority account redirection screen instructing operators to access the Next.js Web Operations Console via environment-configurable `AUTHORITY_PORTAL_URL` (defaulting to `http://localhost:3000/authority/command`).
- **Networking & Storage Architecture:**
  - Unified `ApiClient` supporting GET, POST, PATCH, DELETE with Bearer auth injection, configurable timeout, and structured `AppException` mapping.
  - `ISecureTokenStorage` interface with production `SecureTokenStorage` (EncryptedSharedPreferences / Keychain) and test `InMemoryTokenStorage`.
  - Lightweight `JwtDecoder` for client-side claim inspection and token expiry verification.
- **Shared Foundational Data Models:**
  - Built unified Pydantic-aligned models: `UserModel`, `BusModel`, `RouteModel`, `StopModel`, `TripModel`, `LocationModel`, `CrowdModel`, `PredictionModel`, `AlertModel`, `TicketModel`, `PaymentModel`.
- **Stitch Design System Tokens & Shared Components:**
  - Centralized palette: Deep Forest Green (`#002620`), Container (`#123c35`), Emerald (`#006c49`), Mint Accent (`#6cf8bb`), Ivory Surface (`#f3fbf7`).
  - Standard typography scale using Plus Jakarta Sans with tabular numerals (`tnum`).
  - Shared reusable components: `BusSenseButton`, `BusSenseTextField`, `BusSenseLoading`, `BusSenseErrorState`, `BusSenseEmptyState`, `BusSenseAppBar`, `BusSenseStatusBadge`.
- **Automated Mobile Test Suite:**
  - Created 35 automated tests across `core_foundation_test.dart`, `models_serialization_test.dart`, `auth_routing_test.dart`, and `widget_test.dart`.
  - All 35 tests passing with 0 failures; `flutter analyze` verified with 0 warnings/errors.
- **Regression Verification:**
  - Backend test suite: 25/25 tests passing (100%).
  - Next.js Authority build: 22/22 static pages compiling cleanly.

---

## [0.4.0-api-contract-h3] — 2026-09-27

### Added
- **Completed API Contract Endpoints:**
  - `GET /api/trips` & `GET /api/trips/{trip_id}`: Active scheduled and in-transit trips enriched with live GPS simulation telemetry and Supabase database records. Protected by JWT authentication.
  - `GET /api/locations` & `GET /api/locations/{bus_identifier}`: Live GPS coordinates, speed, heading, and stop progress from corridor physics interpolator.
  - `GET /api/crowd` & `GET /api/crowd/{bus_identifier}`: Fleet cabin load levels, passenger counts, capacity figures, and standardized crowd tier classifications (`LOW`, `MODERATE`, `CROWDED`).
  - `GET /api/predictions` & `GET /api/predictions/{bus_number}`: 4-horizon predictive crowd estimates (`NOW`, `+15 MIN`, `+30 MIN`, `+60 MIN`) reusing the central `demand_forecaster` engine.
  - `GET /api/occupancy/predictions`: Frontend compatibility endpoint returning structured 4-horizon prediction map dictionary (`now`, `plus_15m`, `plus_30m`, `plus_60m`).
  - `GET /api/alerts`, `GET /api/alerts/active`, `GET /api/alerts/{alert_id}`: Standardized service alerts and corridor advisories accessing Supabase `alerts`.
  - `GET /api/payments/my` & `GET /api/payments`: Passenger personal payment history and transport authority audit ledger with strict RBAC boundaries.
- **Frontend Client SDK & Types:**
  - Updated `frontend/lib/api.ts` with TypeScript interfaces `TripData`, `LocationData`, `CrowdData`, `AlertData`, `PaymentData`.
  - Added client helper functions `getTrips()`, `getLocations()`, `getCrowd()`, `getAlerts()`, `getMyPayments()`.
- **Automated Test Suite:**
  - Created `backend/tests/test_api_h3.py` containing 6 comprehensive test suites covering all new endpoints, authentication, RBAC boundaries, 404 responses, and data models. Total test suite expanded to 25 passing tests.

---

## [0.3.0-persistence-h2] — 2026-09-26

### Added
- **Persistent Database Storage on Supabase:**
  - Migrated authoritative data storage from Python in-memory dictionaries to live Supabase PostgreSQL (`lqegmqgkymstycpzplld.supabase.co`).
  - Added persistent records for `tickets`, `payments`, `ticket_validations`, `incidents`, `alerts`, `crowd_predictions`, and `reports`.
- **Atomic QR Validation Stored Procedure:**
  - Implemented PostgreSQL PL/pgSQL function `validate_ticket_atomic(p_qr_hash, p_conductor_id, p_bus_id)` using `SELECT ... FOR UPDATE` row-level exclusive locking to prevent race conditions during simultaneous scans.
  - Returns structured JSONB containing validation outcome (`VALID`, `ALREADY_USED`, `EXPIRED`, `INVALID`).
  - Automatically inserts audit trail records into `ticket_validations`.
- **Database Migration 003:**
  - Added `backend/migrations/003_persistence_transactions.sql` establishing RLS policies for `payments`, `alerts`, `crowd_predictions`, and `reports`.
- **Automated Persistence Test Suite:**
  - Created `backend/tests/test_persistence_h2.py` verifying database booking persistence, multi-tenant isolation, validation audit, incident RBAC lifecycle, alerts, and crowd predictions.
  - Implemented cold restart verification script confirming that tickets, validation status, incidents, and payments survive complete server process restarts.

### Changed
- **Ticketing Architecture:**
  - Converted `ticket_service.book_ticket()` to async, inserting records directly into `tickets` and `payments`.
  - Converted `ticket_service.validate_ticket_qr()` to execute the atomic RPC `validate_ticket_atomic`.
  - Converted `GET /api/tickets/my` to query Supabase `tickets` filtered strictly by authenticated `user_id`.
- **Incident & Alert Architecture:**
  - Converted `POST /api/incidents/report` to persist records into Supabase `incidents`.
  - Converted `POST /api/incidents/{incident_id}/resolve` to mutate status in Supabase `incidents`.
  - Converted `GET /api/alerts/active` and `GET /api/incidents` to query Supabase directly.
  - Added alert deduplication in `run_simulation_loop()` to prevent repetitive alert inserts on every 2-second tick.
- **Occupancy & Reports Architecture:**
  - Persisted occupancy projections to `crowd_predictions`.
  - Persisted fleet sustainability reports to `reports`.
- **Frontend API Token Attachment:**
  - Updated `frontend/lib/api.ts` to automatically read stored token from `localStorage` (`bussense_token`) and attach `Authorization: Bearer <token>` to outbound requests.

---

## [0.2.0-hardening-h1] — 2026-09-26

### Added
- **Role-Based Access Control (RBAC):**
  - Integrated `require_roles()` dependency across sensitive domain endpoints (`/api/tickets/validate`, `/api/incidents/report`, `/api/incidents/{id}/resolve`, `/api/analytics/command-overview`, `/api/analytics/ai-decision-queue`, `/api/analytics/reports`, `/api/routes`).
  - Strict 403 Forbidden enforcement on role privilege boundary violations.
- **Session Revocation & Logout:**
  - Implemented `POST /api/auth/logout` endpoint that blacklists active JWTs in the `REVOKED_TOKENS` store.
  - Blacklisted tokens are rejected immediately with `401 Unauthorized`.
- **Automated Security Test Suite:**
  - Created `backend/tests/test_security_rbac.py` asserting all RBAC rules, token rejection, and logout invalidation (13/13 passing in pytest).
  - Created standalone end-to-end security probe suite verifying live CORS, Supabase connectivity, and RBAC rejection codes.

### Changed
- **Cryptographic Security & Password Hashing:**
  - Replaced legacy passlib mixin with native `bcrypt` library to eliminate `AttributeError: module 'bcrypt' has no attribute '__about__'`.
  - Removed all hardcoded plaintext fallback passwords (`demo1234`).
  - Centralized all development credentials in `DEV_ACCOUNTS` with salted `$2b$12$` hashes.
- **CORS Configuration:**
  - Eliminated wildcard CORS policy (`allow_origins=["*"]`). Restricted allowed origins to explicit frontend URLs (`http://localhost:3000`, `http://127.0.0.1:3000`). Preflight and requests from unauthorized origins return 400 without CORS headers.
- **Supabase Query Safety:**
  - Refactored `backend/app/core/supabase.py` to use dictionary-based query parameters instead of raw URL string concatenation.

### Fixed
- **Unauthenticated Token Bypass:**
  - Removed legacy silent demo auto-login bypass from `get_current_user`. Requests without valid bearer tokens strictly return `401 Unauthorized`.

---

## [0.1.0-prototype] — 2026-09-26

### Added
- **Database & Schemas:**
  - Designed and deployed complete relational schema (`backend/migrations/001_initial_schema.sql`) to Supabase project `lqegmqgkymstycpzplld` comprising 26 tables, custom PostgreSQL enums, and Row-Level Security policies.
  - Seeded realistic Kerala transit corridor network data (`backend/migrations/002_seed_kerala_data.sql`) covering Aluva, Edappally, Kaloor, Kakkanad Infopark, Vyttila Hub, and MG Road.
- **Backend Core (`/backend`):**
  - Initialized FastAPI ASGI server with Pydantic v2 schemas across fleet, prediction, tickets, incidents, and AI modules.
  - Implemented `backend/app/services/cv_occupancy.py` providing YOLOv8 object counting and 3-tier crowd density classification (<50% LOW, 50–80% MODERATE, >80% CROWDED).
  - Implemented `backend/app/services/gps_simulator.py` featuring Haversine distance calculations, waypoint interpolation, and dynamic arrival ETAs.
  - Implemented `backend/app/services/demand_forecaster.py` with scikit-learn Ridge regression predicting crowd horizons (+0, +15, +30, +60 mins).
  - Implemented `backend/app/services/recommendation_engine.py` scoring transit options based on comfort, seated probability, and dedicated bus priority lanes.
  - Implemented `backend/app/services/ticket_service.py` generating in-memory signed Base64 PNG QR passes and conductor validation state machines.
  - Implemented `backend/app/services/rag_service.py` pairing knowledge chunk retrieval with live database telemetry injection.
  - Configured WebSocket telemetry broadcaster (`/ws/telemetry`) and background simulation ticker.
- **Automated Verification:**
  - Created `backend/tests/test_backend.py` with 7 comprehensive pytest test suites; all 7 tests passing cleanly.
- **Frontend User Experiences (`/frontend`):**
  - Integrated Google Stitch design tokens (`#002620`, `#123c35`, `#006c49`, `#6cf8bb`, `#f3fbf7`) into Tailwind CSS configuration.
  - Implemented Unified Platform Gateway (`/app/page.tsx`).
  - Implemented Passenger Experience Suite:
    - Home (`/app/passenger/home/page.tsx`) with live corridor departures, recommendation banner, and "Why?" drawer.
    - Explore (`/app/passenger/explore/page.tsx`) with route planner and 60-minute crowd forecast curves.
    - Digital Tickets (`/app/passenger/tickets/page.tsx`) with dynamic QR boarding passes.
    - Active Journey HUD (`/app/passenger/journey/page.tsx`) tracking onboard waypoint progression.
    - AI Transit Assistant (`/app/passenger/assistant/page.tsx`) with RAG chat and cited knowledge sources.
    - Commuter Profile & Privacy Hub (`/app/passenger/profile/page.tsx`) explaining zero-biometrics video safeguards.
  - Implemented Driver & Conductor Suite:
    - Vehicle Cockpit HUD (`/app/driver/cockpit/page.tsx`) with next-stop countdown and cabin density meter.
    - Conductor QR Validator (`/app/driver/validator/page.tsx`) with 3-state anti-replay feedback.
    - Rapid Incident Logger (`/app/driver/incident/page.tsx`) for 1-tap hazard reporting.
    - Trip Completion & Layover (`/app/driver/layover/page.tsx`) with turnaround bay staging and checklist.
  - Implemented Universal Role Switcher (`/app/roles/page.tsx`).
- **Engineering Knowledge & Documentation Layer:**
  - Established `/docs` documentation suite (23 markdown specification documents).
  - Created `/MEMORY.md`, `/AGENTS.md`, and `/CONTRIBUTING.md` at workspace root.

### Changed
- Converted SQLite prototype plans to Supabase cloud PostgreSQL (`lqegmqgkymstycpzplld`) for multi-tenant cloud persistence.
- Standardized all ETA and countdown displays to tabular numbers (`tnum`) to eliminate layout jitter.

### Fixed
- Fixed PostgreSQL UUID hex formatting in database migration scripts.
- Resolved Windows PowerShell execution policy restrictions by standardizing on `npm.cmd` and `npx.cmd`.

### Known Issues
- Real-time vehicle telematics and CCTV feeds operate in high-fidelity simulation mode until physical hardware on buses is installed.
- Transport Authority desktop command screens are currently being migrated into Next.js App Router views.
