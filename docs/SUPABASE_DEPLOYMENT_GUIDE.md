# BusSense AI — Supabase Deployment & Configuration Guide
## Complete Setup Guide for Supabase-Native Backend Architecture

**System Version:** 1.1.1-H23  
**Target Environment:** Supabase Cloud (PostgreSQL 15+, Auth, Edge Functions, Realtime, Storage)  
**Supabase Instance URL:** `https://lqegmqgkymstycpzplld.supabase.co`  
**Connection Pooler Host:** `aws-0-ap-south-1.pooler.supabase.com:6543`  
**Region:** `ap-south-1` (Mumbai, India)  
**Date:** November 2026  
**Status:** RUNTIME VERIFIED & DEPLOYMENT READY  

---

## 1. Architecture Overview

BusSense AI operates on a completely serverless **Supabase-Native Architecture**:
- **Relational Data & Transactions:** Supabase PostgreSQL with PostgREST direct access and Row-Level Security (RLS). Verified at 119.32 ms mean read latency.
- **Serverless Business Logic:** Supabase Edge Functions (Deno / TypeScript) serving API endpoints, Ridge demand forecasting, and multi-factor recommendation calculations.
- **Client Authentication:** Supabase Auth (GoTrue) with role claims (`PASSENGER`, `DRIVER_CONDUCTOR`, `AUTHORITY`).
- **Real-Time Fleet Streams:** Supabase Realtime WebSockets (`wss://lqegmqgkymstycpzplld.supabase.co/realtime/v1/websocket`). Verified with Phoenix channel joins and heartbeat ACKs.
- **Media & Document Storage:** Supabase Storage private buckets (`bussense-reports`, `bussense-cctv-replays`, `bussense-incidents`).

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
# 1. Login to Supabase CLI (or set SUPABASE_ACCESS_TOKEN)
npx supabase login

# 2. Push migrations to remote database
# If using direct IPv4 connection pooler:
npx supabase db push --remote=lqegmqgkymstycpzplld
```

> **Note on IPv6 vs IPv4:** If connecting from an IPv4-only ISP network, pass the connection pooler URL or use the Supabase Dashboard SQL Editor to execute `supabase/migrations/20261103000000_h22_supabase_backend.sql`.

---

## 3. Row-Level Security (RLS) Policy Verification

All tables enforce Row-Level Security:
```sql
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';
```
All tables must report `rowsecurity = true`.

### Role Permissions Matrix:

| Table | Anonymous / Public | Passenger (`auth.uid() = id`) | Driver / Conductor | Transit Authority |
| :--- | :---: | :---: | :---: | :---: |
| `routes` | `SELECT` | `SELECT` | `SELECT` | `ALL` |
| `stops` | `SELECT` | `SELECT` | `SELECT` | `ALL` |
| `buses` | `SELECT` | `SELECT` | `SELECT`, `UPDATE` (status) | `ALL` |
| `occupancy_readings` | `SELECT` | `SELECT` | `SELECT`, `INSERT` | `ALL` |
| `gps_positions` | `SELECT` | `SELECT` | `SELECT`, `INSERT` | `ALL` |
| `tickets` | None | `SELECT`, `INSERT` (own) | `SELECT`, `UPDATE` (validate) | `ALL` |
| `users` | None | `SELECT`, `UPDATE` (own) | `SELECT` (own) | `ALL` |
| `incidents` | `SELECT` (active) | `SELECT`, `INSERT` | `SELECT`, `INSERT` | `ALL` |
| `alerts` | `SELECT` (active) | `SELECT` (active) | `SELECT` (active) | `ALL` |
| `reports` | None | None | None | `ALL` |
| `providers` | None | None | None | `ALL` |
| `pilot_authorizations`| `SELECT` | `SELECT` | `SELECT` | `ALL` |

---

## 4. Deploying Supabase Edge Functions

BusSense AI includes 6 dedicated Edge Functions located in `supabase/functions/`:

```bash
# Deploy unified API gateway
npx supabase functions deploy api --project-ref lqegmqgkymstycpzplld

# Deploy specialized intelligence & operational functions
npx supabase functions deploy recommendations --project-ref lqegmqgkymstycpzplld
npx supabase functions deploy demand-forecast --project-ref lqegmqgkymstycpzplld
npx supabase functions deploy ingest-telemetry --project-ref lqegmqgkymstycpzplld
npx supabase functions deploy validate-ticket --project-ref lqegmqgkymstycpzplld
npx supabase functions deploy ai-assistant --project-ref lqegmqgkymstycpzplld
```

### JWT Verification Strategy
- **Public Endpoints (`api`, `recommendations`, `demand-forecast`):** JWT verification is handled inside application logic to allow anonymous journey browsing while authenticating passenger tokens when present.
- **Privileged Endpoints (`ingest-telemetry`, `validate-ticket`):** Require cryptographic API keys or conductor session JWTs.

---

## 5. Storage Buckets Configuration

Ensure private buckets are provisioned:
1. `bussense-reports` — PDF/JSON operational audit reports (Authority only).
2. `bussense-cctv-replays` — Benchmark CCTV video replay samples.
3. `bussense-incidents` — Commuter/driver submitted hazard photos.

All buckets require signed URLs for downloads (3600-second expiration).

---

## 6. Live Verification & Benchmark Summary (Phase H23)

- **PostgREST Read Latency:** 119.32 ms mean across 7 core queries.
- **WebSocket Protocol:** Phoenix channels over TLS 1.3 runtime verified with heartbeat frames.
- **Security Rejection:** Invalid/expired tokens reliably rejected with HTTP 401.

---
*BusSense AI Supabase Deployment Guide — Version 1.1.1-H23*
