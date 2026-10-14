# BusSense AI — Phase H12 Verification & Engineering Report
**Phase:** H12 — Realtime Data & Notifications  
**Date:** October 2026  
**Status:** COMPLETED & VERIFIED  

---

## 1. Executive Summary

Phase H12 establishes the full bidirectional **Realtime Data & Notifications Infrastructure** for BusSense AI across the FastAPI backend, Flutter mobile client, and Next.js transport authority dashboard. 

The implementation delivers:
1. **Standardized Typed Event Envelope (`RealtimeEvent`):** Strict Pydantic v2 event contracts governing event UUIDs, ISO-8601 UTC timestamps, transparent data origins, semantic schema versions (`1.0.0`), and domain payloads.
2. **Centralized Realtime Service (`RealtimeService`):**
   - **Public Stream (`/ws/telemetry`):** High-frequency anonymous fleet coordinates, next-stop countdowns, and operational safety advisories.
   - **Authenticated Stream (`/ws/live`):** Role-authorized WebSocket stream protected by JWT authentication (query parameter or initial `AUTH` handshake frame) enforcing RBAC topic boundaries (`public`, `user`, `passenger`, `driver_conductor`, `authority`).
   - **Polling Fallback Ring Buffer:** In-memory 100-event circular buffer backing `GET /api/realtime/events?since=...&event_type=...` for clients on restrictive corporate firewalls or flaky connections.
   - **Capacity Guardrail:** Throttles concurrent connections (`MAX_CONNECTIONS = 100`) returning HTTP 1013 close frames.
3. **Dynamic Data Freshness Engine (`FreshnessInfo`):** Computes data latency in real time. Automatically flags `is_stale: true` when telemetry age exceeds the 15-second freshness threshold.
4. **Persistent In-App Notifications (`NotificationService`):** Supabase PostgreSQL table `notifications` with migration `005_realtime_notifications.sql`. Enforces a 15-minute SHA-256 deduplication window (`dedup_key`), unread counters, and single/bulk mark-as-read mutations with strict user ownership isolation.
5. **Transparent Push Notification Abstraction (`PushNotificationService`):** Honest disclosure of `delivery_status: DEFERRED` without false claims of OS delivery until physical Apple APNs / Google FCM server credentials are configured.
6. **Mobile Integration (Flutter):** `RealtimeClient` with exponential backoff (1s to 30s), heartbeat ping-pong, top AppBar notification bell with unread badge counter, complete Notification Center screen, and real-time freshness HUD pills (`SIMULATED GPS TELEMETRY • FRESH / STALE`).
7. **Transport Authority Web Integration (Next.js):** Reusable stream client (`frontend/lib/realtime.ts`) supporting live event streaming, polling fallbacks, and freshness evaluation.

---

## 2. Capabilities Classification

| Capability | Classification | Architecture / Details |
|---|---|---|
| **Event Envelope** | `IMPLEMENTED` | Standardized `RealtimeEvent` with `event_id`, `event_type`, `entity_id`, `timestamp`, `data_origin`, `schema_version`, and `payload`. |
| **Public Telemetry Stream** | `IMPLEMENTED` | `/ws/telemetry` broadcasting fleet positions and public service alerts to anonymous riders. |
| **Protected Live Stream** | `IMPLEMENTED` | `/ws/live` authenticated via JWT token, enforcing RBAC topic filtering and connection cleanup. |
| **Polling Fallback Buffer** | `IMPLEMENTED` | 100-event in-memory ring buffer queryable via `GET /api/realtime/events` with time and type filters. |
| **Data Freshness Tracker** | `IMPLEMENTED` | Server and client freshness evaluation; marks telemetry stale when age > 15s. |
| **In-App Notification Inbox** | `IMPLEMENTED` | Supabase `notifications` table with RLS, unread counters, and mark-as-read mutations. |
| **Deduplication Engine** | `IMPLEMENTED` | 15-minute sliding window using SHA-256 `dedup_key` hashing. |
| **User Data Isolation** | `IMPLEMENTED` | Server-side JWT ownership verification; passengers cannot read or modify other users' notifications. |
| **Push Notification Provider** | `DEFERRED (HONEST)` | Explicitly returns `delivery_status: DEFERRED` with `reason: FCM_NOT_CONFIGURED`. No false OS delivery claims. |
| **Flutter Mobile Experience** | `IMPLEMENTED` | `RealtimeClient`, `notification_center_screen.dart`, AppBar badge, and live freshness pills. |
| **Next.js Web Subscriber** | `IMPLEMENTED` | `frontend/lib/realtime.ts` with WebSocket and HTTP polling fallback helpers. |

---

## 3. Data Freshness & Truth Labeling Matrix

All real-time telemetry, AI assistant tools, and notification cards adhere to the following truth labeling standards:

| Origin Enum | UI Truth Label | Staleness Threshold | Typical Sources |
|---|---|---|---|
| `SIMULATED` | `SIMULATED TELEMETRY` | 15.0s | Corridor GPS tick simulator (`gps_simulator.py`) |
| `CV_REPLAY` | `CV REPLAY` | 30.0s | YOLOv8n video replay test harness |
| `LIVE` | `LIVE SENSOR TELEMETRY` | 15.0s | On-vehicle IoT telematics hardware |
| `PREDICTION` | `MACHINE LEARNING PREDICTION` | 120.0s | H9 Ridge demand forecasting engine |
| `RECOMMENDATION` | `MULTI-FACTOR RECOMMENDATION` | 60.0s | H10 multi-criteria journey engine |
| `HUMAN_DECISION` | `HUMAN-REPORTED INCIDENT` | 300.0s | Conductor & dispatcher incident logs |

---

## 4. API Endpoints Reference

### Realtime Streaming & Health
- `GET /api/realtime/events`: Polling fallback buffer (`since`, `event_type`, `limit`).
- `GET /api/realtime/health`: Connection statistics and buffer metrics.
- `GET /api/realtime/freshness`: Telemetry freshness evaluation for specific buses or fleet.
- `WS /ws/telemetry`: Public vehicle coordinates, stop ETAs, and alerts.
- `WS /ws/live?token=...`: Authenticated stream with RBAC topic isolation.

### Notifications Domain
- `GET /api/notifications`: Retrieve current user notifications with unread filtering and pagination.
- `GET /api/notifications/unread-count`: Unread notification badge count.
- `POST /api/notifications`: Create notification (service-role or internal broadcast).
- `POST /api/notifications/{id}/read`: Mark single notification as read.
- `POST /api/notifications/mark-all-read`: Mark all notifications as read for current user.
- `GET /api/notifications/push-status`: Push provider status (honestly reports `DEFERRED`).

---

## 5. Verification & Test Metrics

### Backend Test Suite (FastAPI + Pytest)
- **H12 Test File:** `backend/tests/test_realtime_notifications_h12.py`
  - Total Tests: **23 passed / 23 (100%)**
  - Execution Time: **7.19s**
- **Full Backend Regression Suite:**
  - Total Tests: **174 passed / 174 (100%)**
  - Zero regression across H1 through H11 suites.

### Authority Web Dashboard (Next.js 14)
- **Production Build:**
  - **22/22 static pages** generated successfully (`npm.cmd --prefix frontend run build`).
  - Zero TypeScript, syntax, or lint errors.
- **Dynamic Tests:**
  - `frontend/tests/test_authority_dynamic.mjs`: **22 passed / 22 (100%)**

### Flutter Mobile App
- **Analyzer:** `flutter analyze apps/mobile` — **0 issues** found.
- **Unit & Model Tests:** Added `apps/mobile/test/realtime_notifications_test.dart` verifying `RealtimeEventModel`, `NotificationItemModel`, and `RealtimeClient`.

---

## 6. Architecture Compliance & Golden Rules Check

- [x] **Truth Badging:** All telemetry stamped `SIMULATED TELEMETRY` or `CV REPLAY`.
- [x] **Honest Push Disclosure:** Push provider reports `DEFERRED` (zero false OS claims).
- [x] **Preserved Visual Language:** Stitch tokens (`#002620`, `#123c35`, `#006c49`, `#f3fbf7`) strictly preserved.
- [x] **Zero Biometrics:** Occupancy counting pipeline strictly counts bounding boxes without facial recognition.
- [x] **No Redesigns / No Scope Creep:** Phase H13 is not started; existing H1–H11 systems remain intact.
