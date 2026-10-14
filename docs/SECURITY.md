# BusSense AI — Security, Privacy & Threat Modeling

This document outlines the security controls, privacy safeguards, and threat modeling principles enforced across the BusSense AI architecture.

---

## 1. Authentication & Session Security (Hardened in Phase H1)

- **Native Cryptographic Hashing:** Passwords and credentials are authenticated strictly using native `bcrypt` (`backend/app/core/security.py`). The former insecure plaintext password fallback (`demo1234`) has been removed. All development accounts use salted, work-factored `$2b$12$` bcrypt hashes configured in `DEV_ACCOUNTS`.
- **Stateless JWTs with Revocation:** Sessions utilize signed JSON Web Tokens (`HS256`) containing `sub`, `email`, `role`, and `full_name`. An active token revocation blacklist (`REVOKED_TOKENS`) is enforced in memory via `POST /api/auth/logout`.
- **Strict Role-Based Access Control (RBAC):** Every protected endpoint is guarded using `require_roles([...])`:
  - `PASSENGER`: Access to trip planning, ticket booking, own ticket history, and conversational AI assistant. Access to driver validator or authority endpoints is rejected with `403 Forbidden`.
  - `DRIVER_CONDUCTOR`: Access to live cockpit, incident dispatch, layover timer, and onboard QR ticket validation. Access to incident resolution, corridor provisioning, and authority command telemetry is rejected with `403 Forbidden`.
  - `AUTHORITY`: Full administrative access to corridor provisioning, operational reports, AI decision queue, and incident resolution.
- **Unauthenticated Access:** Missing, expired, malformed, or revoked tokens are rejected with `401 Unauthorized`. The legacy demo-mode auto-login bypass has been completely eliminated.

---

## 2. API Security, CORS & Injection Prevention

- **Restricted CORS Policy:** Replaced legacy wildcard `allow_origins=["*"]` with an explicit origin whitelist defined in `settings.ALLOWED_ORIGINS` (defaults to `http://localhost:3000` and `http://127.0.0.1:3000`). Preflight and requests from unauthorized origins are rejected with `400 Bad Request` without CORS headers.
- **Parameterized Supabase Queries:** Supabase REST interactions in `backend/app/core/supabase.py` use structured HTTP query parameter dictionaries (`params={filter_col: f"eq.{filter_val}"}`) rather than string concatenation, neutralizing query and URL injection vectors.
- **Pydantic v2 Type Enforcement:** All incoming HTTP payloads are validated against strict Pydantic schemas in `backend/app/schemas/`. Unexpected or malicious properties are automatically rejected with `422 Unprocessable Entity`.
- **Production Debug Safeguard:** `DEBUG` mode is configured to default to `False` outside explicit development flags, disabling verbose traceback disclosure to end users.

---

## 3. Privacy-First Computer Vision Safeguards

- **Zero Biometric Retention:** The onboard vision service (`cv_occupancy.py`) operates exclusively on generic bounding boxes for person/head counting.
- **No Face Detection Models:** No facial detection or identity recognition models exist in the repository.
- **RAM-Only Frame Processing:** Video frames downsampled from CCTV are processed in volatile memory and immediately de-allocated. No raw images or video recordings are saved to local disks or uploaded to cloud storage.
- **Commuter Transparency:** The Commuter Profile view (`/passenger/profile`) provides a dedicated Privacy & Data Hub explaining how occupancy data is processed.

---

## 4. Digital Boarding Pass (QR) Security

- **Cryptographic Signing:** QR codes encode an HMAC-SHA256 signature generated using the system secret key and ticket metadata.
- **Anti-Replay Verification:** Scans are verified against previous validations. Re-scanning an already validated pass returns an `ALREADY_USED` status, preventing duplicate boarding.
- **Tamper Evidence:** Any modification to the ticket number or validity timestamp in the QR payload invalidates the signature, causing the conductor terminal to flag the pass as `INVALID`.

---

## 5. Secret Management & Environment Security

- **Zero Hardcoded Secrets:** All private keys, database URLs, and service tokens are read exclusively from environment variables (`.env`).
- **Git Safeguards:** `.env` is strictly ignored by Git (`.gitignore:52:.env`). Only `.env.example` containing redacted placeholder values is tracked in source control.
- **Frontend Isolation:** Client bundles in `frontend/` have zero access to backend service role keys, JWT secret keys, or database administrative credentials.

---

## 6. Database Transaction Security & Concurrency Defense (Hardened in Phase H2)

- **Atomic Validation Stored Procedure:** QR validation concurrency is protected against double-use race conditions using the PostgreSQL PL/pgSQL function `validate_ticket_atomic(p_qr_hash, p_conductor_id, p_bus_id)`.
  - Employs `SELECT ... FOR UPDATE` row-level exclusive locking on `tickets`.
  - Serializes concurrent scan requests: the first transaction successfully mutates the ticket status from `BOOKED`/`VALID` to `USED` and records an audit entry in `ticket_validations`.
  - Any simultaneous validation thread waiting on the lock immediately reads the updated `USED` status and safely rejects the duplicate scan with `ALREADY_USED`.
- **Database Row Level Security (RLS):**
  - Sensitive transactional tables (`tickets`, `payments`, `ticket_validations`, `incidents`, `alerts`, `crowd_predictions`, `reports`) have RLS enabled in Supabase PostgreSQL via Migration 003 (`backend/migrations/003_persistence_transactions.sql`).
  - Backend operations utilize authenticated PostgREST calls with parameterized headers.
  - Multi-tenant data isolation: `GET /api/tickets/my` strictly filters by authenticated JWT `user_id`. Passenger A cannot access Passenger B's tickets.
- **Simulated Payment Sandbox Integrity:**
  - Prototype payment records are persisted to `payments` with `provider: "SANDBOX"` and `status: "SUCCESS"`.
  - Sandboxed payment transaction records are never misrepresented as live production gateway captures.

