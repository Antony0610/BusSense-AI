# BusSense AI — Database Dictionary

This document provides a comprehensive data dictionary for all 26 tables deployed to the project's Supabase PostgreSQL 15 database (`https://lqegmqgkymstycpzplld.supabase.co`).

---

## 1. System Enums & Types

| Enum Name | Allowed Values |
|---|---|
| `user_role` | `'PASSENGER'`, `'DRIVER_CONDUCTOR'`, `'AUTHORITY'`, `'ADMIN'` |
| `bus_status` | `'ACTIVE'`, `'MAINTENANCE'`, `'IDLE'`, `'OUT_OF_SERVICE'` |
| `operator_type` | `'KSRTC'`, `'PRIVATE'`, `'KURTC'` |
| `crowd_level` | `'LOW'`, `'MODERATE'`, `'CROWDED'` |
| `trip_status` | `'SCHEDULED'`, `'IN_TRANSIT'`, `'COMPLETED'`, `'CANCELLED'`, `'DELAYED'` |
| `ticket_status` | `'BOOKED'`, `'VALID'`, `'USED'`, `'EXPIRED'`, `'CANCELLED'` |
| `validation_result` | `'VALID'`, `'INVALID'`, `'ALREADY_USED'`, `'EXPIRED'` |
| `payment_status` | `'PENDING'`, `'COMPLETED'`, `'FAILED'`, `'REFUNDED'` |
| `incident_category` | `'VEHICLE_ISSUE'`, `'ROUTE_OBSTRUCTION'`, `'OVERCROWDING'`, `'DELAY'`, `'SAFETY_MEDICAL'`, `'OTHER'` |
| `incident_status` | `'REPORTED'`, `'ACKNOWLEDGED'`, `'INVESTIGATING'`, `'RESOLVED'` |
| `alert_severity` | `'INFO'`, `'LOW'`, `'WARNING'`, `'CRITICAL'` |
| `data_origin` | `'LIVE'`, `'SIMULATED'`, `'PREDICTION'`, `'RECOMMENDATION'`, `'HUMAN_DECISION'`, `'CV_REPLAY'`, `'ESTIMATE'` |

---

## 2. Table Specifications

### 2.1 `roles`
- **Purpose:** System permission levels and access scopes.
- **Primary Key:** `id: UUID`
- **Columns:**
  - `id`: `UUID PRIMARY KEY DEFAULT gen_random_uuid()`
  - `role_name`: `VARCHAR(50) UNIQUE NOT NULL`
  - `description`: `TEXT`
  - `created_at`: `TIMESTAMPTZ DEFAULT NOW()`
- **Status:** `IMPLEMENTED`

### 2.2 `users`
- **Purpose:** Core identity accounts for passengers, drivers, and authority personnel.
- **Primary Key:** `id: UUID`
- **Columns:**
  - `id`: `UUID PRIMARY KEY DEFAULT gen_random_uuid()`
  - `phone_number`: `VARCHAR(20) UNIQUE NOT NULL`
  - `email`: `VARCHAR(255) UNIQUE`
  - `password_hash`: `VARCHAR(255)`
  - `full_name`: `VARCHAR(100)`
  - `role`: `user_role NOT NULL DEFAULT 'PASSENGER'`
  - `role_id`: `UUID REFERENCES roles(id) ON DELETE SET NULL`
  - `preferred_language`: `VARCHAR(10) DEFAULT 'en'`
  - `is_verified`: `BOOLEAN DEFAULT FALSE`
  - `is_active`: `BOOLEAN DEFAULT TRUE`
  - `created_at`, `updated_at`: `TIMESTAMPTZ`
- **Indexes:** `idx_users_phone`, `idx_users_role`
- **Status:** `IMPLEMENTED`

### 2.3 `passengers`
- **Purpose:** Passenger-specific profile attributes, disability accommodations, and commuter preferences.
- **Primary Key:** `id: UUID`
- **Foreign Keys:** `user_id -> users(id) ON DELETE CASCADE`
- **Columns:** `id`, `user_id`, `preferred_seat_type`, `accessibility_needs: BOOLEAN`, `emergency_contact_phone`, `created_at`
- **Status:** `IMPLEMENTED`

### 2.4 `drivers`
- **Purpose:** Commercial driver licenses, safety ratings, and shift rosters.
- **Primary Key:** `id: UUID`
- **Foreign Keys:** `user_id -> users(id) ON DELETE CASCADE`
- **Columns:** `id`, `user_id`, `license_number: VARCHAR(50) UNIQUE`, `license_expiry_date: DATE`, `operator: operator_type`, `safety_score: NUMERIC(3,2)`, `total_trips_completed: INTEGER`, `is_on_duty: BOOLEAN`
- **Status:** `IMPLEMENTED`

### 2.5 `conductors`
- **Purpose:** Onboard ticket validation crew profiles.
- **Primary Key:** `id: UUID`
- **Foreign Keys:** `user_id -> users(id) ON DELETE CASCADE`
- **Columns:** `id`, `user_id`, `badge_number: VARCHAR(50) UNIQUE`, `operator: operator_type`, `is_on_duty: BOOLEAN`, `created_at`
- **Status:** `IMPLEMENTED`

### 2.6 `buses`
- **Purpose:** Public transit vehicle registry, seating capacities, and equipment flags.
- **Primary Key:** `id: UUID`
- **Columns:**
  - `id`: `UUID PRIMARY KEY DEFAULT gen_random_uuid()`
  - `registration_number`: `VARCHAR(30) UNIQUE NOT NULL` (e.g., `KL-07-CE-8821`)
  - `bus_code`: `VARCHAR(20) NOT NULL` (e.g., `Bus 205`)
  - `operator`: `operator_type NOT NULL DEFAULT 'KSRTC'`
  - `bus_type`: `VARCHAR(50) DEFAULT 'Fast Passenger'`
  - `total_capacity`: `INTEGER NOT NULL DEFAULT 55`
  - `seated_capacity`: `INTEGER NOT NULL DEFAULT 42`
  - `status`: `bus_status NOT NULL DEFAULT 'ACTIVE'`
  - `has_cctv`, `has_gps`, `has_ac`, `has_wheelchair_ramp`: `BOOLEAN`
  - `current_driver_id`: `UUID REFERENCES drivers(id)`
  - `current_conductor_id`: `UUID REFERENCES conductors(id)`
  - `created_at`, `updated_at`: `TIMESTAMPTZ`
- **Indexes:** `idx_buses_bus_code`, `idx_buses_status`
- **Status:** `IMPLEMENTED`

### 2.7 `routes`
- **Purpose:** Fixed public transit corridors (e.g., Kaloor to Infopark Phase 2).
- **Primary Key:** `id: UUID`
- **Columns:** `id`, `route_number: VARCHAR(20) UNIQUE`, `route_name: VARCHAR(150)`, `origin_name`, `destination_name`, `total_distance_km`, `estimated_duration_min`, `corridor_zone`, `is_active: BOOLEAN`
- **Indexes:** `idx_routes_number`
- **Status:** `IMPLEMENTED`

### 2.8 `stops`
- **Purpose:** Physical transit stations and shelters with WGS84 geographic coordinates.
- **Primary Key:** `id: UUID`
- **Columns:** `id`, `stop_name: VARCHAR(100)`, `stop_code: VARCHAR(20) UNIQUE`, `latitude: NUMERIC(10,8)`, `longitude: NUMERIC(11,8)`, `has_shelter`, `is_metro_interchange`, `is_active`
- **Indexes:** `idx_stops_code`, `idx_stops_lat_lon`
- **Status:** `IMPLEMENTED`

### 2.9 `route_stops`
- **Purpose:** Ordered stop sequences along routes with distance and travel offsets.
- **Primary Key:** `id: UUID`
- **Foreign Keys:** `route_id -> routes(id)`, `stop_id -> stops(id)`
- **Columns:** `id`, `route_id`, `stop_id`, `stop_sequence: INTEGER`, `distance_from_origin_km`, `minutes_from_origin`, `created_at`
- **Constraint:** `UNIQUE (route_id, stop_sequence)`
- **Indexes:** `idx_route_stops_route_seq`
- **Status:** `IMPLEMENTED`

### 2.10 `trips`
- **Purpose:** Scheduled and active corridor journeys undertaken by assigned buses.
- **Primary Key:** `id: UUID`
- **Foreign Keys:** `bus_id -> buses(id)`, `route_id -> routes(id)`, `driver_id -> drivers(id)`, `conductor_id -> conductors(id)`
- **Columns:** `id`, `bus_id`, `route_id`, `driver_id`, `conductor_id`, `status: trip_status`, `scheduled_departure`, `actual_departure`, `scheduled_arrival`, `actual_arrival`, `current_stop_id`, `origin_type: data_origin`
- **Indexes:** `idx_trips_bus_status`, `idx_trips_route`
- **Status:** `IMPLEMENTED`

### 2.11 `gps_positions`
- **Purpose:** Time-series telemetry logging latitude, longitude, instantaneous speed, and heading.
- **Primary Key:** `id: UUID`
- **Foreign Keys:** `bus_id -> buses(id)`, `trip_id -> trips(id)`
- **Columns:** `id`, `bus_id`, `trip_id`, `latitude`, `longitude`, `speed_kmh`, `heading_degrees`, `accuracy_meters`, `data_origin`, `recorded_at`
- **Indexes:** `idx_gps_bus_recorded`
- **Status:** `IMPLEMENTED`

### 2.12 `occupancy_readings`
- **Purpose:** Computer vision edge-inferred passenger head count, seating tally, and crowd tier.
- **Primary Key:** `id: UUID`
- **Foreign Keys:** `bus_id -> buses(id)`, `trip_id -> trips(id)`
- **Columns:** `id`, `bus_id`, `trip_id`, `passenger_count`, `seated_count`, `standing_count`, `occupancy_percentage`, `crowd_level`, `detection_source`, `model_confidence`, `data_origin`, `recorded_at`
- **Indexes:** `idx_occupancy_bus_time`
- **Status:** `IMPLEMENTED`

### 2.13 `crowd_predictions`
- **Purpose:** Machine learning demand forecasts for future horizons (+15, +30, +60 mins) produced by the Phase H9 Ridge demand forecasting engine (`ridge-demand-v2-corridor`). Strictly segregated from observed `occupancy_readings`.
- **Primary Key:** `id: UUID`
- **Foreign Keys:** `bus_id -> buses(id)`, `route_id -> routes(id)`, `stop_id -> stops(id)`
- **Columns:** `id`, `bus_id`, `route_id`, `stop_id`, `time_horizon_mins`, `predicted_occupancy_pct`, `predicted_crowd_level`, `confidence_score`, `contributing_factors: JSONB`, `model_version`, `data_origin: DEFAULT 'PREDICTION'`, `generated_at: TIMESTAMPTZ DEFAULT NOW()`
- **Persistence Pattern:** Asynchronously snapshotted on demand during `/api/predictions/{bus_number}` invocations without blocking client responses.
- **Indexes:** `idx_predictions_bus_time`
- **Status:** `IMPLEMENTED (Phase H9)`

### 2.14 `bus_recommendations`
- **Purpose:** Computed recommendations comparing candidate buses by composite journey score.
- **Primary Key:** `id: UUID`
- **Foreign Keys:** `user_id -> users(id)`, `recommended_bus_id -> buses(id)`
- **Columns:** `id`, `user_id`, `origin_stop_id`, `destination_stop_id`, `recommended_bus_id`, `alternative_bus_id`, `recommendation_score`, `seat_probability_pct`, `travel_time_saved_min`, `reason_summary`, `data_origin`, `generated_at`
- **Status:** `IMPLEMENTED`

### 2.15 `tickets`
- **Purpose:** Passenger digital transit passes, Base64 QR code data URIs, and validity windows.
- **Primary Key:** `id: UUID`
- **Foreign Keys:** `user_id -> users(id)`, `trip_id -> trips(id)`, `origin_stop_id -> stops(id)`, `destination_stop_id -> stops(id)`
- **Columns:** `id`, `ticket_number: VARCHAR(40) UNIQUE`, `user_id`, `trip_id`, `origin_stop_id`, `destination_stop_id`, `fare_amount: NUMERIC(8,2)`, `status: ticket_status`, `qr_code_payload: TEXT`, `qr_code_base64: TEXT`, `valid_until: TIMESTAMPTZ`, `created_at`
- **Indexes:** `idx_tickets_user`, `idx_tickets_number`, `idx_tickets_status`
- **Status:** `IMPLEMENTED`

### 2.16 `ticket_validations`
- **Purpose:** Conductor scanning audit trail recording scan timestamps and duplicate scan attempts.
- **Primary Key:** `id: UUID`
- **Foreign Keys:** `ticket_id -> tickets(id)`, `conductor_id -> conductors(id)`, `bus_id -> buses(id)`
- **Columns:** `id`, `ticket_id`, `conductor_id`, `bus_id`, `validation_result`, `scanned_at: TIMESTAMPTZ`, `notes: TEXT`
- **Indexes:** `idx_validations_ticket`
- **Status:** `IMPLEMENTED`

### 2.17 `payments`
- **Purpose:** Payment transaction ledger tracking fare amounts, status, and sandbox IDs.
- **Primary Key:** `id: UUID`
- **Foreign Keys:** `user_id -> users(id)`, `ticket_id -> tickets(id)`
- **Columns:** `id`, `ticket_id`, `user_id`, `amount: NUMERIC(8,2)`, `currency: VARCHAR(5) DEFAULT 'INR'`, `status: payment_status`, `payment_gateway: VARCHAR(30)`, `transaction_reference: VARCHAR(100)`, `payment_mode: VARCHAR(30)`, `paid_at: TIMESTAMPTZ`
- **Status:** `IMPLEMENTED`

### 2.18 `incidents`
- **Purpose:** Operational hazards, breakdowns, and detours reported from vehicle cockpits.
- **Primary Key:** `id: UUID`
- **Foreign Keys:** `reported_by -> users(id)`, `bus_id -> buses(id)`, `trip_id -> trips(id)`
- **Columns:** `id`, `bus_id`, `trip_id`, `reported_by`, `category: incident_category`, `status: incident_status`, `severity: alert_severity`, `title: VARCHAR(150)`, `description: TEXT`, `latitude`, `longitude`, `resolution_notes`, `reported_at`, `resolved_at`
- **Indexes:** `idx_incidents_status`
- **Status:** `IMPLEMENTED`

### 2.19 `alerts`
- **Purpose:** Passenger and operational notifications generated by incidents or delay conditions.
- **Primary Key:** `id: UUID`
- **Foreign Keys:** `route_id -> routes(id)`, `incident_id -> incidents(id)`
- **Columns:** `id`, `incident_id`, `route_id`, `severity: alert_severity`, `alert_title`, `alert_message`, `is_broadcast_to_passengers`, `is_active`, `starts_at`, `expires_at`
- **Status:** `IMPLEMENTED`

### 2.20 `notifications`
- **Purpose:** Commuter in-app message inbox and push dispatch history with deduplication and truth labeling.
- **Primary Key:** `id: UUID`
- **Foreign Keys:** `user_id -> users(id)`
- **Columns:** `id`, `user_id`, `title`, `body`, `notification_type`, `severity: VARCHAR(20) DEFAULT 'INFO'`, `is_read: BOOLEAN DEFAULT FALSE`, `action_url: TEXT`, `metadata: JSONB DEFAULT '{}'`, `dedup_key: VARCHAR(255)`, `data_origin: VARCHAR(50) DEFAULT 'SIMULATED DATA'`, `created_at: TIMESTAMPTZ`
- **Indexes:** `idx_notifications_user_unread (user_id, is_read, created_at DESC)`, `idx_notifications_dedup (user_id, dedup_key, created_at DESC)`
- **RLS:** Users SELECT and UPDATE only their own rows (`auth.uid() = user_id`); service role / authorities INSERT system notices.
- **Status:** `IMPLEMENTED (Migration 005_realtime_notifications.sql)`

### 2.21 `favorites`
- **Purpose:** Commuter saved routes and bus stops for rapid 1-tap departure access.
- **Primary Key:** `id: UUID`
- **Foreign Keys:** `user_id -> users(id)`, `route_id -> routes(id)`, `stop_id -> stops(id)`
- **Columns:** `id`, `user_id`, `route_id`, `stop_id`, `custom_label`, `created_at`
- **Status:** `IMPLEMENTED`

### 2.22 `journey_history`
- **Purpose:** Commuter historical trip log, boarding/alighting timestamps, and carbon offset tracking.
- **Primary Key:** `id: UUID`
- **Foreign Keys:** `user_id -> users(id)`, `ticket_id -> tickets(id)`, `trip_id -> trips(id)`
- **Columns:** `id`, `user_id`, `ticket_id`, `trip_id`, `boarding_time`, `alighting_time`, `carbon_saved_kg`, `created_at`
- **Status:** `IMPLEMENTED`

### 2.23 `knowledge_documents`
- **Purpose:** RAG corpus documentation root (Kerala transit tariffs, student concessions, safety policies).
- **Primary Key:** `id: UUID`
- **Columns:** `id`, `title: VARCHAR(200)`, `document_type: VARCHAR(50)`, `source_url: TEXT`, `created_at`
- **Status:** `IMPLEMENTED`

### 2.24 `knowledge_chunks`
- **Purpose:** Semantic text chunks with vector embeddings for conversational assistant retrieval.
- **Primary Key:** `id: UUID`
- **Foreign Keys:** `document_id -> knowledge_documents(id)`
- **Columns:** `id`, `document_id`, `chunk_index: INTEGER`, `content: TEXT`, `metadata: JSONB`, `created_at`
- **Indexes:** `idx_knowledge_chunks_meta` (GIN)
- **Status:** `IMPLEMENTED`

### 2.25 `ai_conversations`
- **Purpose:** Audit ledger of user RAG queries, assistant responses, and cited knowledge sources.
- **Primary Key:** `id: UUID`
- **Foreign Keys:** `user_id -> users(id)`
- **Columns:** `id`, `user_id`, `session_id`, `user_query: TEXT`, `ai_response: TEXT`, `sources_cited: JSONB`, `created_at`
- **Status:** `IMPLEMENTED`

### 2.26 `reports`
- **Purpose:** Transport Authority weekly and monthly corridor intelligence summaries.
- **Primary Key:** `id: UUID`
- **Columns:** `id`, `report_type: VARCHAR(50)`, `title: VARCHAR(200)`, `period_start: TIMESTAMPTZ`, `period_end: TIMESTAMPTZ`, `summary_metrics: JSONB`, `generated_by: UUID REFERENCES users(id)`, `created_at: TIMESTAMPTZ`
- **Status:** `IMPLEMENTED (Database-backed)`

---

## 3. Phase H2 Persistence Architecture & Migrations

### Migration `003_persistence_transactions.sql`
De-isolated in-memory prototypes and established database-level transaction guarantees on Supabase:

1. **Row-Level Security Policies:**
   - Enabled RLS on `payments` with permissive prototype check policies (`CREATE POLICY "Allow public all payments" ON payments FOR ALL USING (true) WITH CHECK (true)`).
   - Replaced select-only policies on `alerts`, `reports`, and `crowd_predictions` with complete insert/update policies (`FOR ALL USING (true) WITH CHECK (true)`).
2. **Concurrency-Safe Atomic QR Validation (`validate_ticket_atomic`):**
   - Implemented PostgreSQL PL/pgSQL stored procedure with row-level locking (`SELECT * FROM tickets WHERE qr_code_hash = p_qr_hash FOR UPDATE;`).
   - Guarantees anti-replay protection: two concurrent validation scans of the same digital boarding pass cannot both succeed.
   - Automatically transitions ticket status (`VALID -> USED` or `EXPIRED`) and creates validation audit rows in `ticket_validations` within a single atomic database transaction.
3. **Database as Source of Truth:**
   - Tickets (`tickets`), payments (`payments`), validation attempts (`ticket_validations`), incident hazards (`incidents`), service alerts (`alerts`), and corridor crowd predictions (`crowd_predictions`) are persisted directly to Supabase.
   - All transactional state survives backend service restarts without data loss.

### Migration `004_cv_replay_support.sql`
Adds support for computer vision recorded-video replay telemetry:
1. **Enum Expansion:**
   - Extends PostgreSQL `data_origin` enum type with `'CV_REPLAY'` and `'ESTIMATE'`.
2. **Occupancy Ingestion Target:**
   - Persists aggregate `OccupancyEvent` snapshots from the CV replay pipeline into the existing `occupancy_readings` table with `data_origin = 'CV_REPLAY'`.
   - Preserves privacy: only records aggregate headcount, capacity, clamped occupancy percentage, and crowd tier without biometrics or facial templates.

### Phase H10 Recommendation Snapshot Integration
- **Asynchronous Horizon Snapshotting:**
  - Journey recommendations generated via `GET/POST /api/recommendations/plan` trigger non-blocking asynchronous snapshot writes to Supabase `crowd_predictions` table.
  - Candidate bus +30m predicted load points are logged with `bus_id`, `route_id`, `prediction_horizon_minutes = 30`, `predicted_occupancy_percentage`, and `crowd_level` under `data_origin = 'PREDICTION'`.
  - Non-blocking execution prevents external database latency from slowing down interactive passenger journey planning (< 15ms CPU).

---

## 3.5 Phase H11 RAG Vector Retrieval Architecture

### Vector Index & Embedding Status
- **Vector Extension Status:** `DEFERRED / TFIDF_VECTOR_FALLBACK`
  - Supabase PostgreSQL currently does not have `pgvector` enabled.
  - In accordance with Phase H11 guidelines, BusSense AI avoids assuming external vector extensions or unconfigured embedding API keys.
  - Vector indexing is implemented locally via `KnowledgeIndexer` (`backend/app/services/knowledge_indexer.py`) using scikit-learn's `TfidfVectorizer(ngram_range=(1, 2), sublinear_tf=True)` with cosine similarity and lexical section boosting.

### In-Memory Knowledge Chunk Schema
Knowledge documents are chunked and preserved with deterministic identifiers:

| Attribute | Type | Description |
|---|---|---|
| `document_id` | `VARCHAR(64)` | Canonical document key (`routes`, `tickets`, `crowd`, `recommendations`, `passenger_help`) |
| `document_title` | `VARCHAR(128)` | Human-readable document title |
| `section` | `VARCHAR(128)` | Extracted markdown heading section |
| `chunk_id` | `VARCHAR(128)` | Deterministic identifier formatted as `{document_id}-chunk-{idx:03d}` |
| `content` | `TEXT` | Raw chunk text content with whitespace normalization |
| `source_type` | `VARCHAR(32)` | Classified source type (`DOCUMENTATION`, `POLICY`, `SYSTEM_SPEC`) |
| `applicable_route`| `VARCHAR(32)` | Applicable transit corridor identifier (or `ALL`) |
| `access_scope` | `VARCHAR(32)` | Security classification (`PUBLIC_PASSENGER`, `CONDUCTOR`, `AUTHORITY`) |
| `version` | `VARCHAR(16)` | Knowledge document version (`1.1.0`) |
| `updated_at` | `TIMESTAMPTZ` | Timestamp of last document update |

### User Data Isolation & RLS Boundary
- Passenger tickets are **NEVER** indexed into the shared knowledge base or vector store.
- Ticket queries are resolved exclusively at query time via `tool_get_user_tickets` using the validated JWT `user_id` from the server-side authentication context.
- Cross-user access is strictly prevented by Supabase Row-Level Security policies on the `tickets` table and server-side authorization enforcement.



