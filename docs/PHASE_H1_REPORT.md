# Phase H1 — Security + Authentication Hardening Verification Report

**Date:** September 26, 2026  
**Auditor / Engineer:** Lead Full-Stack Security Engineer  
**Status:** **VERIFIED**

---

## 1. Executive Summary

Phase H1 (Security + Authentication Hardening) has been fully implemented, verified, and audited against live endpoints and automated test suites. 

All 14 requirements specified for Phase H1 have been satisfied:
1. `require_roles()` enforced on every protected domain endpoint.
2. Distinct permissions defined and enforced for `PASSENGER`, `DRIVER_CONDUCTOR`, and `AUTHORITY`.
3. Unauthenticated access rejected with `401 Unauthorized`.
4. Unauthorized roles rejected with `403 Forbidden`.
5. Sensitive operations protected (ticket validation, incident reporting & resolution, authority command telemetry, route provisioning, AI chat).
6. Session logout and JWT revocation implemented at `POST /api/auth/logout`.
7. Hardcoded plaintext password fallback (`demo1234`) completely removed from `backend/app/core/security.py`.
8. Demo credentials moved into controlled development configuration with salted `$2b$12$` bcrypt hashes (`DEV_ACCOUNTS`).
9. Wildcard CORS (`allow_origins=["*"]`) replaced with an explicit origin whitelist (`settings.ALLOWED_ORIGINS`).
10. `DEBUG` mode set to default `False` outside development.
11. Supabase REST query construction refactored to dictionary-based parameterization.
12. Secrets verified unexposed to frontend client code.
13. `.env` verified excluded from Git tracking via `.gitignore`.
14. Security and authorization documentation updated.

---

## 2. Changes Implemented

### Backend Configuration & Dependencies
- [backend/requirements.txt](file:///d:/Bus_Sense_Ai/backend/requirements.txt): Added `bcrypt>=4.0.0` and installed in `backend/.venv` to resolve `passlib` deprecation conflicts.
- [backend/app/core/config.py](file:///d:/Bus_Sense_Ai/backend/app/core/config.py):
  - Added `ALLOWED_ORIGINS: list[str] = Field(default=["http://localhost:3000", "http://127.0.0.1:3000"])`.
  - Configured `DEBUG: bool = Field(default=False)`.
  - Added structured dictionary `DEV_ACCOUNTS` storing precomputed bcrypt salted hashes (`$2b$12$...`) for development logins.

### Core Security Module
- [backend/app/core/security.py](file:///d:/Bus_Sense_Ai/backend/app/core/security.py):
  - Switched from buggy `passlib.context.CryptContext` to native `bcrypt.checkpw()` and `bcrypt.hashpw()`, resolving the Python 3.14 / bcrypt 5.x incompatibility.
  - Removed plaintext password fallback.
  - Removed the silent demo auto-login bypass from `get_current_user`; unauthenticated requests strictly raise `HTTP 401 UNAUTHORIZED`.
  - Implemented in-memory JWT revocation store `REVOKED_TOKENS`, `revoke_token(token: str)`, and `is_token_revoked(token: str)`.
  - Implemented `require_roles(allowed_roles: List[str])` dependency checking role claims and raising `HTTP 403 FORBIDDEN` when unauthorized.
  - Added `email: Optional[str] = None` to `TokenPayload`.

### Database Query Parameterization
- [backend/app/core/supabase.py](file:///d:/Bus_Sense_Ai/backend/app/core/supabase.py):
  - Refactored `patch` method to use HTTP query parameter dictionaries (`params={filter_col: f"eq.{filter_val}"}`) rather than string concatenation.
  - Implemented live `ping()` method querying Supabase REST endpoint (`/rest/v1/routes?select=id&limit=1`) to replace mock health flags.

### Authentication Endpoints
- [backend/app/api/auth.py](file:///d:/Bus_Sense_Ai/backend/app/api/auth.py):
  - `POST /api/auth/login`: Authenticates strictly against bcrypt hashes in `DEV_ACCOUNTS` (in development mode) or Supabase `users` table.
  - `POST /api/auth/logout`: Revokes active JWT and adds it to the token revocation store.
  - `GET /api/auth/me`: Returns verified token payload profile (id, email, role, full_name).
  - `POST /api/auth/switch-demo-role`: Guarded with `if not settings.DEMO_MODE: raise 403`.

### Endpoint Role Protection
- [backend/app/api/tickets.py](file:///d:/Bus_Sense_Ai/backend/app/api/tickets.py):
  - `POST /api/tickets/validate`: Protected with `require_roles(["DRIVER_CONDUCTOR", "AUTHORITY"])`.
  - `POST /api/tickets/book` & `GET /api/tickets/my`: Protected with `Depends(get_current_user)`.
- [backend/app/api/incidents.py](file:///d:/Bus_Sense_Ai/backend/app/api/incidents.py):
  - `POST /api/incidents/report`: Protected with `require_roles(["DRIVER_CONDUCTOR", "AUTHORITY"])`.
  - `POST /api/incidents/{incident_id}/resolve`: Protected with `require_roles(["AUTHORITY"])`.
  - `GET /api/incidents/`: Protected with `Depends(get_current_user)`.
- [backend/app/api/analytics.py](file:///d:/Bus_Sense_Ai/backend/app/api/analytics.py):
  - `GET /api/analytics/command-overview`: Protected with `require_roles(["AUTHORITY"])`.
  - `GET /api/analytics/ai-decision-queue`: Protected with `require_roles(["AUTHORITY"])`.
  - `GET /api/analytics/reports`: Protected with `require_roles(["AUTHORITY"])`.
- [backend/app/api/routes.py](file:///d:/Bus_Sense_Ai/backend/app/api/routes.py):
  - `POST /api/routes`: Protected with `require_roles(["AUTHORITY"])`.
- [backend/app/api/ai.py](file:///d:/Bus_Sense_Ai/backend/app/api/ai.py):
  - `POST /api/ai/chat`: Protected with `Depends(get_current_user)`.

### CORS & Application Entry Point
- [backend/app/main.py](file:///d:/Bus_Sense_Ai/backend/app/main.py):
  - Replaced `allow_origins=["*"]` with `allow_origins=settings.ALLOWED_ORIGINS`.
  - Wired `/health` endpoint to `await supabase_client.ping()`.

---

## 3. Test Verification & Results

### 3.1 Live Security Audit Probe (10/10 Passed)
Executed against running ASGI server on `http://127.0.0.1:8000`:

| Probe ID | Description | HTTP Status | Detail / Result | Status |
|:---|:---|:---|:---|:---|
| **1** | No token → `/api/tickets/validate` | `401 Unauthorized` | `"Authentication credentials were not provided"` | **PASSED** |
| **1b** | No token → `/api/auth/me` | `401 Unauthorized` | `"Authentication credentials were not provided"` | **PASSED** |
| **2** | Passenger → Conductor validator endpoint | `403 Forbidden` | `"Access denied. Requires one of roles: ['DRIVER_CONDUCTOR', 'AUTHORITY']. Current role: PASSENGER"` | **PASSED** |
| **3** | Passenger → Authority command overview | `403 Forbidden` | `"Access denied. Requires one of roles: ['AUTHORITY']. Current role: PASSENGER"` | **PASSED** |
| **4** | Driver → Authority incident resolution | `403 Forbidden` | `"Access denied. Requires one of roles: ['AUTHORITY']. Current role: DRIVER_CONDUCTOR"` | **PASSED** |
| **5** | Authority → Authority command overview | `200 OK` | `{"success": true, "message": "Authority command overview telemetry retrieved"}` | **PASSED** |
| **6** | Invalid / forged token signature | `401 Unauthorized` | `"Could not validate credentials"` | **PASSED** |
| **7a** | Logout call (`POST /api/auth/logout`) | `200 OK` | `{"success": true, "message": "Successfully logged out and session revoked"}` | **PASSED** |
| **7b** | Token re-use after logout | `401 Unauthorized` | `"Token has been revoked. Please log in again."` | **PASSED** |
| **8** | CORS request with allowed origin (`http://localhost:3000`) | `200 OK` | `Access-Control-Allow-Origin: http://localhost:3000` header returned | **PASSED** |
| **9** | CORS request with unauthorized origin (`http://malicious.com`) | `400 Bad Request` | CORS headers omitted, request rejected | **PASSED** |
| **10** | Supabase health ping (`GET /health`) | `200 OK` | `"supabase_connected": true` verified via live PostgREST probe | **PASSED** |

### 3.2 Automated Pytest Suite (13/13 Passed)
Executed via `pytest backend/tests/ -v`:
- `backend/tests/test_backend.py::test_root_endpoint` — **PASSED**
- `backend/tests/test_backend.py::test_health_endpoint` — **PASSED**
- `backend/tests/test_backend.py::test_buses_telemetry` — **PASSED**
- `backend/tests/test_backend.py::test_crowd_forecasting` — **PASSED**
- `backend/tests/test_backend.py::test_smart_recommendations` — **PASSED**
- `backend/tests/test_backend.py::test_ticket_booking_and_qr_validation` — **PASSED**
- `backend/tests/test_backend.py::test_rag_ai_assistant` — **PASSED**
- `backend/tests/test_security_rbac.py::test_unauthenticated_request_rejected` — **PASSED**
- `backend/tests/test_security_rbac.py::test_invalid_token_rejected` — **PASSED**
- `backend/tests/test_security_rbac.py::test_passenger_role_boundaries` — **PASSED**
- `backend/tests/test_security_rbac.py::test_driver_conductor_role_boundaries` — **PASSED**
- `backend/tests/test_security_rbac.py::test_authority_role_access` — **PASSED**
- `backend/tests/test_security_rbac.py::test_logout_and_token_revocation` — **PASSED**

### 3.3 Frontend Build Verification
Executed via `npm.cmd --prefix frontend run build`:
- Next.js 14.2.35 production build compiled successfully.
- Type checking: Zero TypeScript errors.
- 22/22 static pages generated successfully.

### 3.4 Git & Secret Exposure Audit
- `.gitignore:52:.env` verified with `git check-ignore -v .env`.
- No `.env` or sensitive secret keys staged in source control.

---

## 4. Failures & Resolutions Encountered During H1

1. **Passlib / Bcrypt Incompatibility:**
   - *Problem:* `passlib.context.CryptContext` threw `AttributeError: module 'bcrypt' has no attribute '__about__'` due to changes in bcrypt 5.x under Python 3.14.
   - *Resolution:* Replaced `passlib` with native `bcrypt.checkpw()` and `bcrypt.hashpw()` in `backend/app/core/security.py`.
2. **Pytest Unauthenticated Failures:**
   - *Problem:* `test_backend.py` failed with `401 Unauthorized` for ticket booking and AI chat once the demo auto-login bypass was removed.
   - *Resolution:* Updated `test_backend.py` with `get_auth_headers()` to issue valid test tokens, establishing proper authenticated test flows.
3. **Token Payload Email Missing:**
   - *Problem:* `get_current_user` did not extract `email` from decoded claims into `TokenPayload`.
   - *Resolution:* Added `email: Optional[str] = None` to `TokenPayload` and populated it from the decoded token claims.

---

## 5. Remaining Issues (Deferred to Subsequent Phases)

The following areas are intentionally out of scope for Phase H1 and will be addressed in their respective phases:
- **Phase H2 (Persistent Database Transactions):** Ticket booking, validations, and incident logging currently update in-memory stores; they must be wired to write transactions in Supabase tables `tickets`, `ticket_validations`, and `incidents`.
- **Phase H3 (Backend API Completion):** Address endpoint aliases (`/api/locations`, `/api/trips`, `/api/alerts`) that returned 404 in the initial audit.
- **Phase H4–H6 (Dynamic Applications):** Bind hardcoded Next.js frontend components to live authenticated backend APIs.

---

## 6. Phase Classification Update

- **PHASE H1:** **VERIFIED**
- Execution halted. Awaiting instructions for **PHASE H2**.
