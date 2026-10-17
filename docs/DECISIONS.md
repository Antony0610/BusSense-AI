# BusSense AI — Architecture Decision Records (ADRs)

This document records the architectural and engineering trade-offs made during the design and implementation of BusSense AI.

---

## ADR-001 — FastAPI for Core Backend Services
- **Status:** Accepted
- **Date:** 2026-09-26
- **Decision:** Utilize FastAPI (Python 3.14) with Uvicorn as the core ASGI application server.
- **Reason:** Python provides seamless, first-class native bindings to machine learning and computer vision libraries (YOLOv8, OpenCV, scikit-learn, NumPy). FastAPI provides high-performance asynchronous request handling, automatic OpenAPI/Swagger documentation, and native WebSocket support.
- **Alternatives Considered:**
  - *Node.js / Express:* High concurrency, but requires awkward subprocess calls or HTTP bridges to execute Python ML models.
  - *Django:* Heavier monolithic framework with unnecessary ORM overhead when paired with Supabase.

---

## ADR-002 — Supabase PostgreSQL for Relational Data & Identity
- **Status:** Accepted
- **Date:** 2026-09-26
- **Decision:** Deploy relational schemas, user identity, and Row-Level Security (RLS) to Supabase (PostgreSQL 15, project `lqegmqgkymstycpzplld` in `ap-south-1`).
- **Reason:** Supabase provides managed PostgreSQL with built-in pgvector for RAG embeddings, native real-time subscriptions (CDC), and robust identity primitives.
- **Alternatives Considered:**
  - *Self-hosted PostgreSQL on Docker:* Higher operational overhead and backup maintenance.
  - *MongoDB / DynamoDB:* Document databases lack relational integrity guarantees necessary for multi-stop transit routes, scheduled trips, and financial ticketing ledgers.

---

## ADR-003 — Preservation of Google Stitch Design System Tokens
- **Status:** Accepted
- **Date:** 2026-09-26
- **Decision:** Preserve and enforce the exact design system tokens from Google Stitch Project `14259704318600090723` (`#002620`, `#123c35`, `#006c49`, `#6cf8bb`, `#f3fbf7`) without redesigning screens from scratch.
- **Reason:** The Stitch design represents a curated, cohesive mobility aesthetic (*"Less UI, More Design"*) designed specifically for Kerala transit corridors. Preserving these tokens maintains visual excellence and avoids generic SaaS styling.
- **Alternatives Considered:**
  - *Generic Tailwind Dashboard Templates:* Tends toward card overload, neon accents, and poor mobile readability.

---

## ADR-004 — Next.js 14 App Router for Multi-Role Web Prototypes
- **Status:** Accepted
- **Date:** 2026-09-26
- **Decision:** Use Next.js 14 with TypeScript and Tailwind CSS to implement both mobile-responsive commuter shells and the desktop Authority Command Center.
- **Reason:** Allows rapid iteration, shared component primitives, server-side rendering, and instant browser testing across Passenger, Driver, and Authority roles while mobile Flutter clients are prepared.
- **Alternatives Considered:**
  - *Pure HTML/Vanilla JS:* Difficult to maintain complex reactive state (e.g. live WebSocket HUDs, QR validation state machines).
  - *Vite SPA:* Lacks built-in server route optimization and metadata streaming.

---

## ADR-005 — YOLOv8 for Privacy-First Edge Occupancy Detection
- **Status:** Accepted
- **Date:** 2026-09-26
- **Decision:** Use YOLOv8n (Nano) purely for anonymous person/head detection, completely forbidding facial recognition.
- **Reason:** YOLOv8n delivers sub-20ms inference on low-power edge accelerators (Raspberry Pi 5 + Hailo-8). By measuring only bounding box counts and discarding video frames in volatile RAM, commuter privacy is preserved by design.
- **Alternatives Considered:**
  - *Infrared Passenger Counting (APC) Beams:* Prone to occlusion errors when multiple passengers board simultaneously.
  - *Facial Recognition Models:* Explicitly rejected due to privacy violations, legal liabilities, and public surveillance concerns.

---

## ADR-006 — scikit-learn Ridge Regression for Demand Forecasting
- **Status:** Accepted
- **Date:** 2026-09-26
- **Decision:** Employ scikit-learn Ridge Regression with cyclical temporal encodings (`sin_hour`, `cos_hour`) for multi-horizon crowding forecasts (+0, +15, +30, +60 mins).
- **Reason:** Highly explainable, extremely fast inference (<1ms), and immune to deep learning hallucination or vanishing gradient instabilities on small regional transit datasets.
- **Alternatives Considered:**
  - *LSTM / Transformers:* Computationally excessive for low-frequency tabular stop arrival logs.
  - *Moving Average:* Fails to capture non-linear morning and evening office rush surges.

---

## ADR-007 — In-Memory Base64 Cryptographic QR Passes
- **Status:** Accepted
- **Date:** 2026-09-26
- **Decision:** Generate Base64 PNG QR code data URIs in-memory using Python `qrcode` and `Pillow`, embedding an HMAC-SHA256 signature.
- **Reason:** Eliminates disk I/O and cloud storage bucket read costs. Conductor validation achieves sub-second verification with zero image network fetching.
- **Alternatives Considered:**
  - *S3 / Cloud Storage Image Uploads:* Adds network latency, storage fees, and unnecessary complexity.

---

## ADR-008 — Continuous Physics Simulation Engine for Demo Mode
- **Status:** Accepted
- **Date:** 2026-09-26
- **Decision:** Implement autonomous background simulation loops in `backend/app/main.py` executing every 2.0 seconds.
- **Reason:** Enables evaluators to experience real-time map tracking, live stop countdowns, dynamic crowd fluctuations, and ticket scanning without requiring physical vehicles on the road.
- **Alternatives Considered:**
  - *Static Mock JSON:* Fails to demonstrate WebSocket synchronization, ETA countdowns, or reactive state updates.

---

## ADR-009 — Grounded RAG with Telemetry Injection for Transit Assistant
- **Status:** Accepted
- **Date:** 2026-09-26
- **Decision:** Pair vector knowledge retrieval (`knowledge_chunks`) with live SQL tool-calling (`buses`, `occupancy_readings`) for transit assistant queries.
- **Reason:** Allows the assistant to answer both policy questions ("What is the student concession fare?") and real-time operational questions ("Is Bus 205 crowded right now?") while strictly adhering to anti-hallucination fallback rules.
- **Alternatives Considered:**
  - *Pure LLM Prompting:* Inevitably hallucinates bus timings and fares.
  - *Keyword Rules Engine:* Incapable of understanding nuanced natural language inquiries.

---

## ADR-010 — Dual-Tier Realtime Telemetry (WebSockets + HTTP Polling)
- **Status:** Accepted
- **Date:** 2026-09-26
- **Decision:** Implement primary WebSocket streaming (`/ws/telemetry`) with an automated fallback to 5.0-second HTTP polling (`GET /api/buses`).
- **Reason:** Ensures reliable client synchronization even when running behind restrictive institutional firewalls or unstable mobile networks.
- **Alternatives Considered:**
  - *WebSocket Only:* Completely breaks if client proxy forbids persistent socket connections.
  - *HTTP Polling Only:* Higher server overhead and lacks true sub-second reactivity.

---

## ADR-011 — Strict Production Secrets, Dynamic CORS & Demo Account Isolation
- **Status:** Accepted
- **Date:** 2026-10-17
- **Decision:** Enforce production configuration validation at application startup via Pydantic model validators: reject weak/fallback `SECRET_KEY` (< 32 chars, prototype phrases), normalize dynamic `ALLOWED_ORIGINS` (disallow wildcard with credentials), and lock demo accounts behind server-side production checks.
- **Reason:** Prevents accidental deployment of default credentials, unauthorized cross-origin credentialed requests, or prototype authentication bypasses in production environments.
- **Alternatives Considered:**
  - *Runtime Warnings:* Soft warnings allow insecure configurations to continue serving traffic unnoticed.
  - *Static Hardcoded CORS:* Inflexible across varying staging and production hostnames.

---

## ADR-012 — Container Health Probes, Error Sanitization & Backend RPC Permissions
- **Status:** Accepted
- **Date:** 2026-10-17
- **Decision:** Implement decoupled `/health/live` (process alive) and `/health/ready` (dependency check with 2.0s timeout) endpoints; sanitize unhandled 500 errors with `X-Request-ID` correlation; and resolve the `validate_ticket_atomic` RPC permission mismatch using backend-only service-role authorization while maintaining caller RBAC checks.
- **Reason:** Decoupled health probes prevent orchestrators from prematurely killing healthy containers during transient database blips. Sanitized 500 errors prevent internal traceback/credential leaks. Privileged backend RPC execution resolves 42501 permission errors without granting public EXECUTE or weakening database RLS.
- **Alternatives Considered:**
  - *Re-granting EXECUTE to anon/PUBLIC:* Insecure; allows direct unauthenticated execution of atomic stored procedure.
  - *Single Health Check:* Causes orchestrators to restart servers whenever external database has a momentary delay.

