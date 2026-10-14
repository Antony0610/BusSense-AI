# BusSense AI — Roles & Permissions Matrix

This document defines the Role-Based Access Control (RBAC) matrix and capability boundaries across the three core personas in BusSense AI.

---

## 1. Capability Access Matrix

| System Capability | Passenger | Driver / Conductor | Transport Authority | System Admin |
|---|:---:|:---:|:---:|:---:|
| **View Active Buses & Headways** | YES | YES | YES | YES |
| **View Real-Time Cabin Occupancy**| YES | YES | YES | YES |
| **Search Corridor Routes & Stops** | YES | YES | YES | YES |
| **Access Smart Recommendations** | YES | NO | YES | YES |
| **Book Digital Transit Ticket** | YES | NO | NO | YES |
| **View Own Boarding Passes** | YES | NO | NO | YES |
| **Validate Passenger QR Passes** | NO | YES | YES | YES |
| **View Active Trip Cockpit HUD** | NO | YES | YES | YES |
| **Submit Incident / Hazard Report**| REPORT | CREATE | MANAGE | YES |
| **Resolve & Close Incidents** | NO | NO | YES | YES |
| **Access GIS Command Center Map** | NO | NO | YES | YES |
| **View 60-Min Crowd Predictions** | YES | NO | YES | YES |
| **Manage AI Operational Queue** | NO | NO | YES | YES |
| **Generate Operational Reports** | NO | NO | YES | YES |
| **Query RAG Transit Assistant** | YES (Commuter) | LIMITED (Safety) | YES (Operations) | YES |
| **Modify Corridor & Stop Geometry**| NO | NO | YES | YES |
| **Switch Role for Evaluation** | YES | YES | YES | YES |

---

## 2. Role Definitions & Scopes

### 1. `PASSENGER`
- **Scope:** Commuter and transit consumer endpoints.
- **Allowed Routes:** `/passenger/*`, `/roles`.
- **Database Boundaries:** Can only read published transit schedules, corridors, and telemetry. Can write to `tickets`, `payments`, `favorites`, and `ai_conversations` (scoped to `user_id == auth.uid()`).

### 2. `DRIVER_CONDUCTOR`
- **Scope:** In-vehicle operations and onboard passenger management.
- **Allowed Routes:** `/driver/*`, `/roles`.
- **Database Boundaries:** Can read assigned `buses`, `trips`, and `routes`. Can mutate `gps_positions`, `incidents`, and `ticket_validations`. Strictly barred from editing corridor pricing or fleet registrations.

### 3. `AUTHORITY`
- **Scope:** Regional transit management, corridor dispatch, and safety oversight.
- **Allowed Routes:** `/authority/*`, `/roles`.
- **Database Boundaries:** Full read/write access across `buses`, `routes`, `stops`, `incidents`, `alerts`, `crowd_predictions`, and `reports`. Cannot access private commuter payment credentials.

### 4. `ADMIN`
- **Scope:** Superuser for system debugging, database migrations, and staff provisioning.
- **Allowed Routes:** All routes and API endpoints.
