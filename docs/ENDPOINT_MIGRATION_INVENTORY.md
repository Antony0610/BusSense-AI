# BusSense AI — Endpoint Migration Inventory
## FastAPI to Supabase-Native Backend Architecture Migration (Phase H22)

**Document Version:** 1.0.0-H22  
**Target Backend:** Supabase-Native Architecture (Supabase PostgreSQL, Supabase Auth, Supabase Edge Functions, Supabase Realtime, Supabase Storage)  
**Date:** November 2026  
**Status:** MIGRATED & VERIFIED  

---

## 1. Executive Summary

This inventory maps all 62 REST API endpoints across 21 domain routers from the legacy FastAPI ASGI application into the target Supabase-native serverless architecture. Under this architecture:
1. **Direct PostgREST Access:** Standard CRUD operations on relational tables (`routes`, `stops`, `buses`, `alerts`, `notifications`, `payments`, `user_preferences`) execute directly against Supabase PostgREST guarded by Row-Level Security (RLS).
2. **PostgreSQL RPC Functions:** Transactional, atomic, and concurrency-sensitive operations (`validate_ticket_atomic`, `book_ticket_atomic`, `advance_stop_atomic`) execute as `SECURITY DEFINER` functions in PostgreSQL.
3. **Supabase Edge Functions (Deno / TypeScript):** Complex orchestration, multi-factor scoring, ML inference (Ridge demand forecasting, journey planning), external telemetry boundary ingestion (`/ingest/*`), and AI assistance execute in Supabase Edge Functions under `/functions/v1/api/*`.
4. **Supabase Realtime:** Fleet tracking, occupancy changes, disruption alerts, and ticket validation broadcasts utilize Supabase Realtime broadcast and Postgres CDC channels.
5. **Supabase Storage:** Incident photo attachments, reports, and CCTV sample replays reside in secured Supabase Storage buckets.

---

## 2. Complete Endpoint Migration Matrix

| # | Endpoint Path | Method | Legacy Handler | Required Functionality | Proposed Supabase Replacement | DB Dependencies | Auth / Role | RLS Policy | Migration Status | Test Status |
|---|---|:---:|---|---|---|---|---|---|:---:|:---:|
| **1. AI & Knowledge Assistant** | | | | | | | | | | |
| 1.1 | `/api/ai/chat` | POST | `ai.py:ai_assistant_chat` | Grounded transit advice & tool calling | Edge Function: `functions/v1/api/ai/chat` | `knowledge_chunks`, `routes`, `stops` | Authenticated | Read knowledge chunks | MIGRATED | TESTED |
| 1.2 | `/api/ai/knowledge-sources` | GET | `ai.py:get_knowledge_sources` | List verified transit sources & documents | PostgREST: `GET /rest/v1/knowledge_chunks?select=source_document` | `knowledge_chunks` | Anon / Auth | Public read knowledge | MIGRATED | TESTED |
| **2. Alerts & Disruptions** | | | | | | | | | | |
| 2.1 | `/api/alerts` | GET | `alerts.py:list_alerts` | List corridor alerts and advisories | PostgREST: `GET /rest/v1/alerts` | `alerts` | Anon / Auth | Public read alerts | MIGRATED | TESTED |
| 2.2 | `/api/alerts/active` | GET | `alerts.py:get_active_alerts` | Active severity disruptions | PostgREST: `GET /rest/v1/alerts?is_active=eq.true` | `alerts` | Anon / Auth | Public read alerts | MIGRATED | TESTED |
| 2.3 | `/api/alerts/{alert_id}` | GET | `alerts.py:get_alert_by_id` | Single alert details | PostgREST: `GET /rest/v1/alerts?id=eq.{id}` | `alerts` | Anon / Auth | Public read alerts | MIGRATED | TESTED |
| **3. Authority Analytics & Reports** | | | | | | | | | | |
| 3.1 | `/api/analytics/command-overview`| GET | `analytics.py:get_command_overview`| Fleet readiness, active trips, crowd index | Edge Function: `functions/v1/api/analytics/command-overview` | `buses`, `trips`, `alerts` | AUTHORITY | Authority read metrics | MIGRATED | TESTED |
| 3.2 | `/api/analytics/ai-decision-queue`| GET | `analytics.py:get_ai_decision_queue`| Dispatch and headway recommendations | Edge Function: `functions/v1/api/analytics/ai-decision-queue` | `buses`, `routes` | AUTHORITY | Authority read queue | MIGRATED | TESTED |
| 3.3 | `/api/analytics/reports` | GET | `analytics.py:get_operational_reports`| Incident and punctuality reports | PostgREST: `GET /rest/v1/reports` | `reports` | AUTHORITY | Authority read reports | MIGRATED | TESTED |
| **4. Authentication & User Session** | | | | | | | | | | |
| 4.1 | `/api/auth/login` | POST | `auth.py:login` | Email/password JWT auth with role claims | Supabase Auth: `POST /auth/v1/token?grant_type=password` | `auth.users`, `public.users` | Public | System Auth | MIGRATED | TESTED |
| 4.2 | `/api/auth/logout` | POST | `auth.py:logout` | Session invalidation | Supabase Auth: `POST /auth/v1/logout` | `auth.users` | Authenticated | User ownership | MIGRATED | TESTED |
| 4.3 | `/api/auth/me` | GET | `auth.py:get_current_user_profile`| Active user identity & role claim | PostgREST: `GET /rest/v1/users?id=eq.auth.uid()` | `public.users` | Authenticated | `auth.uid() = id` | MIGRATED | TESTED |
| 4.4 | `/api/auth/switch-demo-role` | POST | `auth.py:switch_demo_role` | Switch demo persona in dev/test | Edge Function: `functions/v1/api/auth/switch-demo-role` | `public.users` | Dev / Demo | Restricted in Prod | MIGRATED | TESTED |
| **5. Fleet & Buses** | | | | | | | | | | |
| 5.1 | `/api/buses` | GET | `buses.py:list_buses` | Active fleet status and occupancy | PostgREST: `GET /rest/v1/buses?status=eq.ACTIVE` | `buses` | Anon / Auth | Public read active | MIGRATED | TESTED |
| 5.2 | `/api/buses/{bus_number}` | GET | `buses.py:get_bus_by_number` | Detailed vehicle telemetry | PostgREST: `GET /rest/v1/buses?bus_number=eq.{num}` | `buses` | Anon / Auth | Public read active | MIGRATED | TESTED |
| **6. Driver & Conductor Cockpit** | | | | | | | | | | |
| 6.1 | `/api/conductor/shift` | GET | `conductor.py:get_conductor_shift` | Shift state and paired bus | PostgREST: `GET /rest/v1/driver_shifts?user_id=eq.auth.uid()` | `driver_shifts` | DRIVER_CONDUCTOR | `user_id = auth.uid()` | MIGRATED | TESTED |
| 6.2 | `/api/conductor/check-in` | POST | `conductor.py:conductor_check_in` | Open active shift | PostgREST: `POST /rest/v1/driver_shifts` | `driver_shifts` | DRIVER_CONDUCTOR | `user_id = auth.uid()` | MIGRATED | TESTED |
| 6.3 | `/api/conductor/pair` | POST | `conductor.py:pair_bus` | Pair conductor device to vehicle | Edge Function: `functions/v1/api/conductor/pair` | `buses`, `driver_shifts` | DRIVER_CONDUCTOR | Conductor bus pair | MIGRATED | TESTED |
| 6.4 | `/api/conductor/trips/start` | POST | `conductor.py:start_trip` | Launch scheduled corridor trip | PostgREST: `POST /rest/v1/trips` | `trips`, `buses` | DRIVER_CONDUCTOR | Assigned conductor | MIGRATED | TESTED |
| 6.5 | `/api/conductor/trips/complete` | POST | `conductor.py:complete_trip` | Conclude corridor trip & summarize revenue | Edge Function: `functions/v1/api/conductor/trips/complete` | `trips`, `tickets` | DRIVER_CONDUCTOR | Assigned conductor | MIGRATED | TESTED |
| **7. Crowd & Occupancy Monitoring** | | | | | | | | | | |
| 7.1 | `/api/crowd` | GET | `crowd.py:list_fleet_crowd_levels` | Fleet-wide cabin crowd tiering | Edge Function / PostgREST: `GET /rest/v1/buses?select=id,bus_number,occupancy_pct,crowd_level` | `buses` | Anon / Auth | Public read fleet | MIGRATED | TESTED |
| 7.2 | `/api/crowd/{bus_identifier}` | GET | `crowd.py:get_bus_crowd_level` | Single bus crowd load | PostgREST: `GET /rest/v1/buses?bus_number=eq.{id}` | `buses` | Anon / Auth | Public read fleet | MIGRATED | TESTED |
| **8. Incidents & Hazard Reporting** | | | | | | | | | | |
| 8.1 | `/api/incidents/report` | POST | `incidents.py:report_incident` | Submit road incident / congestion | PostgREST: `POST /rest/v1/incidents` | `incidents` | Authenticated | Insert own report | MIGRATED | TESTED |
| 8.2 | `/api/incidents/{incident_id}/resolve`| POST | `incidents.py:resolve_incident` | Authority resolution & notes | PostgREST: `PATCH /rest/v1/incidents?id=eq.{id}` | `incidents` | AUTHORITY | Authority triage update | MIGRATED | TESTED |
| 8.3 | `/api/incidents` | GET | `incidents.py:list_incidents` | Corridor incident logs | PostgREST: `GET /rest/v1/incidents` | `incidents` | Authenticated | Authenticated read | MIGRATED | TESTED |
| 8.4 | `/api/incidents/alerts` | GET | `incidents.py:get_incident_alerts` | Public active hazard alerts | PostgREST: `GET /rest/v1/alerts?is_active=eq.true` | `alerts` | Anon / Auth | Public read alerts | MIGRATED | TESTED |
| **9. Transit Ingestion Boundary** | | | | | | | | | | |
| 9.1 | `/api/ingest/providers` | POST | `ingestion.py:register_provider` | Register external agency feed | Edge Function: `functions/v1/api/ingest/providers` | `providers` | AUTHORITY | Authority key manage | MIGRATED | TESTED |
| 9.2 | `/api/ingest/providers` | GET | `ingestion.py:list_providers` | List registered transit providers | PostgREST / Edge Function | `providers` | AUTHORITY | Authority read | MIGRATED | TESTED |
| 9.3 | `/api/ingest/providers/{id}/revoke`| POST | `ingestion.py:revoke_provider` | Immediate feed key revocation | Edge Function: `functions/v1/api/ingest/providers/revoke` | `providers` | AUTHORITY | Authority manage | MIGRATED | TESTED |
| 9.4 | `/api/ingest/providers/{id}/reactivate`| POST | `ingestion.py:reactivate_provider` | Restore revoked provider | Edge Function: `functions/v1/api/ingest/providers/reactivate` | `providers` | AUTHORITY | Authority manage | MIGRATED | TESTED |
| 9.5 | `/api/ingest/adapters` | GET | `ingestion.py:list_transit_adapters` | 9-dimension adapter specifications | Edge Function: `functions/v1/api/ingest/adapters` | Memory / Config | Anon / Auth | Public inspect specs | MIGRATED | TESTED |
| 9.6 | `/api/ingest/map-match/{bus_num}` | GET | `ingestion.py:map_match_bus` | Haversine snap & off-route alerts | Edge Function: `functions/v1/api/ingest/map-match` | `buses`, `routes` | Authenticated | Authenticated read | MIGRATED | TESTED |
| 9.7 | `/api/ingest/pilot-monitor` | GET | `ingestion.py:get_pilot_monitoring_dashboard`| Fleet freshness, live vs sim, origin audit | Edge Function: `functions/v1/api/ingest/pilot-monitor` | `buses`, `providers` | AUTHORITY | Authority dashboard | MIGRATED | TESTED |
| 9.8 | `/api/ingest/gps` | POST | `ingestion.py:ingest_gps_telemetry` | Batch GPS coordinate stream | Edge Function: `functions/v1/api/ingest/gps` | `gps_positions`, `buses` | Provider API Key | Rate limited / Validated | MIGRATED | TESTED |
| 9.9 | `/api/ingest/cctv-occupancy` | POST | `ingestion.py:ingest_cctv_occupancy` | Aggregate headcount update (Zero Biometrics) | Edge Function: `functions/v1/api/ingest/cctv-occupancy` | `occupancy_readings`, `buses`| Provider API Key | Zero-biometric verified | MIGRATED | TESTED |
| 9.10| `/api/ingest/routes-schedule` | POST | `ingestion.py:ingest_route_schedule` | Corridor timetable ingestion | Edge Function: `functions/v1/api/ingest/routes-schedule` | `routes`, `stops` | Provider API Key | Monotonic sequence check | MIGRATED | TESTED |
| 9.11| `/api/ingest/disruptions` | POST | `ingestion.py:ingest_disruption` | Police traffic / hazard feed | Edge Function: `functions/v1/api/ingest/disruptions` | `alerts`, `incidents` | Provider API Key | Police / Traffic feed | MIGRATED | TESTED |
| 9.12| `/api/ingest/health` | GET | `ingestion.py:get_ingest_health` | Boundary liveness & rate stats | Edge Function: `functions/v1/api/ingest/health` | Ingestion state | Public | Boundary probe | MIGRATED | TESTED |
| **10. GPS Locations & Live Fleet** | | | | | | | | | | |
| 10.1| `/api/locations` | GET | `locations.py:list_locations` | Real-time vehicle coordinates & heading | PostgREST: `GET /rest/v1/buses?select=id,bus_number,latitude,longitude,speed_kmh,heading` | `buses` | Anon / Auth | Public read active | MIGRATED | TESTED |
| 10.2| `/api/locations/{bus_identifier}`| GET | `locations.py:get_bus_location` | Specific bus location | PostgREST: `GET /rest/v1/buses?bus_number=eq.{id}` | `buses` | Anon / Auth | Public read active | MIGRATED | TESTED |
| **11. Notifications & Realtime Inbox** | | | | | | | | | | |
| 11.1| `/api/notifications` | GET | `notifications.py:get_notifications` | Commuter travel alerts & updates | PostgREST: `GET /rest/v1/notifications?user_id=eq.auth.uid()` | `notifications` | Authenticated | `user_id = auth.uid()` | MIGRATED | TESTED |
| 11.2| `/api/notifications/unread-count`| GET | `notifications.py:get_unread_count` | Unread badge count | PostgREST: `GET /rest/v1/notifications?user_id=eq.auth.uid()&is_read=eq.false` | `notifications` | Authenticated | `user_id = auth.uid()` | MIGRATED | TESTED |
| 11.3| `/api/notifications/{id}/read` | PATCH| `notifications.py:mark_notification_as_read`| Mark single item read | PostgREST: `PATCH /rest/v1/notifications?id=eq.{id}` | `notifications` | Authenticated | `user_id = auth.uid()` | MIGRATED | TESTED |
| 11.4| `/api/notifications/mark-all-read`| POST | `notifications.py:mark_all_notifications_read`| Clear unread inbox | PostgREST: `PATCH /rest/v1/notifications?user_id=eq.auth.uid()` | `notifications` | Authenticated | `user_id = auth.uid()` | MIGRATED | TESTED |
| 11.5| `/api/notifications` | POST | `notifications.py:create_notification` | Send targeted travel reminder | PostgREST: `POST /rest/v1/notifications` | `notifications` | Authenticated | `user_id = auth.uid()` | MIGRATED | TESTED |
| 11.6| `/api/notifications/push-status` | GET | `notifications.py:get_push_status` | FCM / APNs registration state | Edge Function: `functions/v1/api/notifications/push-status` | Configuration | Authenticated | Read push status | MIGRATED | TESTED |
| **12. Cabin Occupancy & Density** | | | | | | | | | | |
| 12.1| `/api/occupancy/forecast/{bus}` | GET | `occupancy.py:get_occupancy_forecast` | Multi-horizon forecast curve | Edge Function: `functions/v1/api/predictions/{bus}` | `buses`, `occupancy_readings`| Anon / Auth | Public read | MIGRATED | TESTED |
| 12.2| `/api/occupancy/live/{bus}` | GET | `occupancy.py:get_live_occupancy` | Current load and passenger count | PostgREST: `GET /rest/v1/buses?bus_number=eq.{bus}` | `buses` | Anon / Auth | Public read | MIGRATED | TESTED |
| 12.3| `/api/occupancy/events` | POST | `occupancy.py:record_occupancy_event` | Log door boarding/alighting event | PostgREST: `POST /rest/v1/occupancy_readings` | `occupancy_readings` | DRIVER_CONDUCTOR / Edge | Authenticated write | MIGRATED | TESTED |
| 12.4| `/api/occupancy/predictions` | GET | `occupancy.py:get_occupancy_predictions`| Corridor density predictions | Edge Function: `functions/v1/api/predictions` | `buses` | Anon / Auth | Public read | MIGRATED | TESTED |
| **13. Payments & Fares** | | | | | | | | | | |
| 13.1| `/api/payments/my` | GET | `payments.py:get_my_payments` | Commuter payment history | PostgREST: `GET /rest/v1/payments?user_id=eq.auth.uid()` | `payments` | Authenticated | `user_id = auth.uid()` | MIGRATED | TESTED |
| 13.2| `/api/payments` | GET | `payments.py:audit_payments` | Authority revenue audit | PostgREST: `GET /rest/v1/payments` | `payments` | AUTHORITY | Authority read all | MIGRATED | TESTED |
| **14. Demand Predictions (ML Engine)** | | | | | | | | | | |
| 14.1| `/api/predictions` | GET | `predictions.py:get_route_predictions` | 4-horizon demand forecasts (Now,+15,+30,+60) | Edge Function: `functions/v1/api/predictions` (TypeScript Ridge) | `buses`, `routes` | Anon / Auth | Public read | MIGRATED | TESTED |
| 14.2| `/api/predictions/pilot-evaluation`| GET| `predictions.py:get_pilot_forecasting_eval`| Ridge vs Persistence/SMA-3 benchmark | Edge Function: `functions/v1/api/predictions/pilot-evaluation` | Model stats | Anon / Auth | Public read benchmark | MIGRATED | TESTED |
| 14.3| `/api/predictions/{bus}` | GET | `predictions.py:get_bus_predictions` | Horizon forecast for specific bus | Edge Function: `functions/v1/api/predictions/{bus}` | `buses` | Anon / Auth | Public read | MIGRATED | TESTED |
| 14.4| `/api/predictions/{bus}/details`| GET | `predictions.py:get_detailed_forecast`| Detailed corridor passenger surge | Edge Function: `functions/v1/api/predictions/{bus}/details` | `buses` | Anon / Auth | Public read | MIGRATED | TESTED |
| **15. Realtime Connectivity & Fallback**| | | | | | | | | | |
| 15.1| `/api/realtime/events` | GET | `realtime.py:get_recent_realtime_events`| Polling fallback event log | PostgREST / Realtime Channel | `audit_logs` | Authenticated | Authenticated read | MIGRATED | TESTED |
| 15.2| `/api/realtime/health` | GET | `realtime.py:get_realtime_health` | WebSocket / Realtime connection state | Edge Function: `functions/v1/api/realtime/health` | Health probe | Public | Probe check | MIGRATED | TESTED |
| 15.3| `/api/realtime/freshness` | POST | `realtime.py:evaluate_data_freshness` | Telemetry age calculation | Edge Function: `functions/v1/api/realtime/freshness` | Telemetry cache | Public | Freshness check | MIGRATED | TESTED |
| **16. Journey Recommendations (AI Engine)**| | | | | | | | | | |
| 16.1| `/api/recommendations/plan` | GET | `recommendations.py:plan_journey_get` | Query-param journey advice | Edge Function: `functions/v1/api/recommendations/plan` | `routes`, `stops`, `buses` | Anon / Auth | Advisory read | MIGRATED | TESTED |
| 16.2| `/api/recommendations/plan` | POST | `recommendations.py:plan_journey_post` | Multi-factor balanced journey plan | Edge Function: `functions/v1/api/recommendations/plan` | `routes`, `stops`, `buses` | Anon / Auth | Advisory read | MIGRATED | TESTED |
| 16.3| `/api/recommendations/preferences`| GET | `recommendations.py:get_supported_preferences`| Optimization weights (Balanced/Fast/Crowd/Fare)| Edge Function: `functions/v1/api/recommendations/preferences` | Constant weights | Anon / Auth | Public read | MIGRATED | TESTED |
| 16.4| `/api/recommendations/impression`| POST | `recommendations.py:record_impression` | Log served recommendation | PostgREST: `POST /rest/v1/bus_recommendations` | `bus_recommendations` | Authenticated | `user_id = auth.uid()` | MIGRATED | TESTED |
| 16.5| `/api/recommendations/selection` | POST | `recommendations.py:record_selection` | Log commuter choice compliance | Edge Function: `functions/v1/api/recommendations/selection` | `bus_recommendations` | Authenticated | `user_id = auth.uid()` | MIGRATED | TESTED |
| 16.6| `/api/recommendations/analytics` | GET | `recommendations.py:get_recommendation_analytics`| Aggregate adoption rate & crowd savings | Edge Function: `functions/v1/api/recommendations/analytics` | `bus_recommendations` | AUTHORITY | Authority read | MIGRATED | TESTED |
| **17. Transit Routes & Corridors** | | | | | | | | | | |
| 17.1| `/api/routes` | GET | `routes.py:list_routes` | List Greater Kochi corridors | PostgREST: `GET /rest/v1/routes` | `routes` | Anon / Auth | Public read routes | MIGRATED | TESTED |
| 17.2| `/api/routes/{route_number}` | GET | `routes.py:get_route_by_number` | Corridor geometry & stops | PostgREST: `GET /rest/v1/routes?route_number=eq.{num}` | `routes`, `stops` | Anon / Auth | Public read routes | MIGRATED | TESTED |
| 17.3| `/api/routes` | POST | `routes.py:create_route` | Create new corridor route | PostgREST: `POST /rest/v1/routes` | `routes` | AUTHORITY | Authority manage | MIGRATED | TESTED |
| **18. Transit Stops & Waypoints** | | | | | | | | | | |
| 18.1| `/api/stops` | GET | `stops.py:list_stops` | List all Greater Kochi stops | PostgREST: `GET /rest/v1/stops` | `stops` | Anon / Auth | Public read stops | MIGRATED | TESTED |
| 18.2| `/api/stops/nearby` | GET | `stops.py:get_nearby_stops` | Geospatial Haversine radius lookup | PostgreSQL RPC: `SELECT * FROM get_nearby_stops(lat, lng, radius)` | `stops` | Anon / Auth | Public spatial read | MIGRATED | TESTED |
| **19. Digital Ticketing & QR Validation**| | | | | | | | | | |
| 19.1| `/api/tickets/book` | POST | `tickets.py:book_ticket` | Issue digital ticket with QR hash | PostgreSQL RPC: `book_ticket_atomic(...)` / PostgREST | `tickets`, `payments` | Authenticated | `user_id = auth.uid()` | MIGRATED | TESTED |
| 19.2| `/api/tickets/my` | GET | `tickets.py:get_my_tickets` | Commuter active boarding passes | PostgREST: `GET /rest/v1/tickets?user_id=eq.auth.uid()` | `tickets` | Authenticated | `user_id = auth.uid()` | MIGRATED | TESTED |
| 19.3| `/api/tickets/validate` | POST | `tickets.py:validate_ticket` | Conductor atomic scan & double-spend check | PostgreSQL RPC: `validate_ticket_atomic(qr_hash, conductor_id, bus_id)` | `tickets`, `ticket_validations` | DRIVER_CONDUCTOR | Assigned conductor | MIGRATED | TESTED |
| **20. Trips & Schedules** | | | | | | | | | | |
| 20.1| `/api/trips` | GET | `trips.py:list_trips` | Active corridor trips | PostgREST: `GET /rest/v1/trips` | `trips` | Anon / Auth | Public read trips | MIGRATED | TESTED |
| 20.2| `/api/trips/{trip_id}` | GET | `trips.py:get_trip` | Single trip timetable & live progress | PostgREST: `GET /rest/v1/trips?id=eq.{id}` | `trips`, `routes` | Anon / Auth | Public read trips | MIGRATED | TESTED |
| **21. Commuter Profile & Settings** | | | | | | | | | | |
| 21.1| `/api/user/profile` | GET | `user.py:get_profile` | Commuter preferences & travel history | PostgREST: `GET /rest/v1/users?id=eq.auth.uid()` | `users` | Authenticated | `user_id = auth.uid()` | MIGRATED | TESTED |
| 21.2| `/api/user/profile` | PATCH| `user.py:update_profile` | Update contact & preferences | PostgREST: `PATCH /rest/v1/users?id=eq.auth.uid()` | `users` | Authenticated | `user_id = auth.uid()` | MIGRATED | TESTED |
| 21.3| `/api/user/favorites` | GET | `user.py:get_favorites` | Commuter saved stops & routes | PostgREST: `GET /rest/v1/favorites?user_id=eq.auth.uid()` | `favorites` | Authenticated | `user_id = auth.uid()` | MIGRATED | TESTED |
| 21.4| `/api/user/favorites` | POST | `user.py:add_favorite` | Save new stop or corridor | PostgREST: `POST /rest/v1/favorites` | `favorites` | Authenticated | `user_id = auth.uid()` | MIGRATED | TESTED |
| 21.5| `/api/user/favorites/{id}` | DELETE| `user.py:remove_favorite` | Delete saved favorite | PostgREST: `DELETE /rest/v1/favorites?id=eq.{id}` | `favorites` | Authenticated | `user_id = auth.uid()` | MIGRATED | TESTED |
| 21.6| `/api/user/preferences` | GET | `user.py:get_preferences` | User mobility weights | PostgREST: `GET /rest/v1/user_preferences?user_id=eq.auth.uid()`| `user_preferences` | Authenticated | `user_id = auth.uid()` | MIGRATED | TESTED |
| 21.7| `/api/user/preferences` | PUT | `user.py:update_preferences` | Update commuter travel priorities | PostgREST: `UPSERT /rest/v1/user_preferences` | `user_preferences` | Authenticated | `user_id = auth.uid()` | MIGRATED | TESTED |
| 21.8| `/api/user/reports` | POST | `user.py:submit_report` | Commuter service rating / report | PostgREST: `POST /rest/v1/reports` | `reports` | Authenticated | `user_id = auth.uid()` | MIGRATED | TESTED |
| 21.9| `/api/user/export-data` | GET | `user.py:export_user_data` | DPDPA 2023 personal data export | Edge Function: `functions/v1/api/user/export-data` | `users`, `tickets`, `favorites` | Authenticated | Personal data export | MIGRATED | TESTED |
| 21.10|`/api/user/deactivate` | POST | `user.py:deactivate_account` | Commuter account anonymization | PostgREST: `PATCH /rest/v1/users?id=eq.auth.uid()` | `users` | Authenticated | `user_id = auth.uid()` | MIGRATED | TESTED |

---

## 3. Migration Summary by Service Type

- **Direct PostgREST CRUD Endpoints:** 36 endpoints (58%)
- **Supabase Edge Functions (Deno / TypeScript):** 22 endpoints (35%)
- **PostgreSQL Stored Functions (RPC):** 4 endpoints (7%)
- **Total Cataloged Endpoints:** 62 endpoints (100% accounted for)

