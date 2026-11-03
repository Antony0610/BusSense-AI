# BusSense AI — Supabase Deployment & Configuration Guide
## Complete Setup Guide for Supabase-Native Backend Architecture

**System Version:** 1.1.0-H22  
**Target Environment:** Supabase Cloud (PostgreSQL 15+, Auth, Edge Functions, Realtime, Storage)  
**Supabase Instance URL:** `https://lqegmqgkymstycpzplld.supabase.co`  
**Region:** `ap-south-1` (Mumbai, India)  
**Date:** November 2026

---

## 1. Architecture Overview

In Phase H22, BusSense AI transitioned from a standalone Python FastAPI server to a completely serverless **Supabase-Native Architecture**:
- **Relational Data & Transactions:** Supabase PostgreSQL with PostgREST direct access and Row-Level Security (RLS).
- **Serverless Business Logic:** Supabase Edge Functions (Deno / TypeScript) serving API endpoints, Ridge demand forecasting, and multi-factor recommendation calculations.
- **Client Authentication:** Supabase Auth (GoTrue) with role claims (`PASSENGER`, `DRIVER_CONDUCTOR`, `AUTHORITY`).
- **Real-Time Fleet Streams:** Supabase Realtime WebSockets (`/realtime/v1`).
- **Media & Document Storage:** Supabase Storage buckets.

---

## 2. Database Migrations & Schema Deployment

All database migrations are located in `supabase/migrations/`:
- `001_initial_schema.sql`: Core relational tables (`users`, `routes`, `stops`, `buses`, `trips`, `tickets`, `payments`).
- `002_seed_kerala_data.sql`: Seed data for Greater Kochi corridors (Route 205 & 14A).
- `003_persistence_transactions.sql`: Atomic ticket validation function `validate_ticket_atomic`.
- `004_cv_replay_support.sql`: Camera stream metadata and replay schemas.
- `005_realtime_notifications.sql`: Notification and inbox schemas.
- `006_supabase_security_remediation.sql`: Hardened least-privilege RLS policies.
- `20261103000000_h22_supabase_backend.sql`: Providers, ingestion logs, pilot authorizations, `book_ticket_atomic`, and `get_nearby_stops`.

### Applying Migrations via Supabase CLI
```bash
# 1. Login to Supabase CLI
supabase login

# 2. Link your local repository to the remote project
supabase link --project-ref lqegmqgkymstycpzplld

# 3. Push migrations to remote database
supabase db push
```

Alternatively, open the Supabase SQL Editor and execute `supabase/migrations/20261103000000_h22_supabase_backend.sql`.

---

## 3. Row-Level Security (RLS) Policy Verification

Ensure RLS is enabled on all exposed public tables:
```sql
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';
```
All tables must report `rowsecurity = true`.

### Role Permissions Matrix:
| Role | Permitted Actions | RLS Enforcement |
| :--- | :--- | :--- |
| **anon** | Read routes, stops, active buses, crowd levels, active disruptions | `USING (true)` on public lookup tables |
| **PASSENGER** | Book tickets, view own tickets, manage own favorites & profile | `USING (user_id = auth.uid())` |
| **DRIVER_CONDUCTOR** | Validate tickets, pair bus, manage shift, report hazards | `USING (conductor_id = auth.uid())` |
| **AUTHORITY** | Resolve incidents, audit payments, monitor fleet telemetry | `EXISTS (SELECT 1 FROM users WHERE role = 'AUTHORITY')` |

---

## 4. Supabase Edge Functions Deployment

Edge Functions are written in Deno / TypeScript located in `supabase/functions/`:

```
supabase/functions/
├── api/                  # Unified Edge Gateway Router (/functions/v1/api/*)
├── recommendations/      # Standalone Multi-Factor Journey Planning
├── demand-forecast/      # Standalone Multi-Horizon Ridge Inference
├── ingest-telemetry/     # Standalone GPS & CCTV Ingestion Boundary
├── validate-ticket/      # Standalone Conductor Atomic Validation
└── ai-assistant/         # Standalone Grounded RAG Assistant
```

### Deploying Edge Functions
```bash
# Deploy all functions
supabase functions deploy api --no-verify-jwt
supabase functions deploy recommendations
supabase functions deploy demand-forecast
supabase functions deploy ingest-telemetry
supabase functions deploy validate-ticket
supabase functions deploy ai-assistant
```

### Setting Environment Secrets
```bash
supabase secrets set \
  SUPABASE_URL="https://lqegmqgkymstycpzplld.supabase.co" \
  SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  SUPABASE_SERVICE_ROLE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

---

## 5. Supabase Realtime Configuration

Enable PostgreSQL Change Data Capture (CDC) and broadcast channels on active operational tables:
```sql
ALTER PUBLICATION supabase_realtime ADD TABLE public.buses;
ALTER PUBLICATION supabase_realtime ADD TABLE public.alerts;
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE public.tickets;
ALTER PUBLICATION supabase_realtime ADD TABLE public.occupancy_readings;
```

Client connection URL:
```text
wss://lqegmqgkymstycpzplld.supabase.co/realtime/v1/websocket?apikey=<SUPABASE_ANON_KEY>&vsn=1.0.0
```

---

## 6. Supabase Storage Buckets

Configure private storage buckets for operational documents and incident attachments:
```sql
INSERT INTO storage.buckets (id, name, public)
VALUES 
    ('bussense-reports', 'bussense-reports', false),
    ('bussense-cctv-replays', 'bussense-cctv-replays', false),
    ('bussense-incidents', 'bussense-incidents', false)
ON CONFLICT (id) DO NOTHING;
```

### Access Policies for Storage:
- **`bussense-incidents`:** Authenticated users can upload photos; Authority users can read.
- **`bussense-reports`:** Authority users have full read/write access.

---

## 7. Verification Smoke Tests

Verify Edge Function endpoints using curl:
```bash
# 1. Health Probe
curl -i https://lqegmqgkymstycpzplld.supabase.co/functions/v1/api/health

# 2. Corridor Routes
curl -i https://lqegmqgkymstycpzplld.supabase.co/functions/v1/api/routes

# 3. Multi-Factor Journey Plan
curl -i -X POST https://lqegmqgkymstycpzplld.supabase.co/functions/v1/api/recommendations/plan \
  -H "Content-Type: application/json" \
  -d '{"origin": "Kaloor Metro Station, Kochi", "destination": "Vyttila Mobility Hub", "preference": "balanced"}'

# 4. Multi-Horizon Demand Predictions
curl -i https://lqegmqgkymstycpzplld.supabase.co/functions/v1/api/predictions
```
All endpoints will return `200 OK` with the standard `ApiResponse` envelope.

---
*BusSense AI Supabase Deployment Guide — Version 1.1.0-H22*
