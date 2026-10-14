# BusSense AI — Authentication & Identity Architecture

This document specifies the authentication flows, role-based access controls, session management, and credential safeguards implemented in BusSense AI as hardened during Phase H1.

---

## 1. Role-Based Access Architecture

BusSense AI enforces strict Role-Based Access Control (RBAC) across three principal personas:

```
                      ┌───────────────────────────────────────┐
                      │          UNIVERSAL LOGIN              │
                      │         (POST /api/auth/login)        │
                      └──────────────────┬────────────────────┘
                                         │ Issues JWT (role + email embedded)
                                         ▼
         ┌───────────────────────────────┼───────────────────────────────┐
         │                               │                               │
         ▼                               ▼                               ▼
┌──────────────────┐           ┌──────────────────┐           ┌──────────────────┐
│    PASSENGER     │           │ DRIVER/CONDUCTOR │           │    AUTHORITY     │
├──────────────────┤           ├──────────────────┤           ├──────────────────┤
│ • Route Search   │           │ • Cockpit HUD    │           │ • GIS Command    │
│ • Ticket Booking │           │ • QR Scanner     │           │ • AI Operations  │
│ • RAG Assistant  │           │ • Incident Log   │           │ • Incident Triage│
│ • Active Journey │           │ • Trip Layover   │           │ • Report Archive │
└──────────────────┘           └──────────────────┘           └──────────────────┘
```

### Access Control Matrix

| Endpoint | Method | Required Roles | Unauth Status | Forbidden Status |
|---|---|---|---|---|
| `/api/auth/login` | POST | Public | - | - |
| `/api/auth/logout` | POST | Authenticated (Any) | 401 | - |
| `/api/auth/me` | GET | Authenticated (Any) | 401 | - |
| `/api/auth/switch-demo-role` | POST | Public (Demo Mode only) | - | 403 (if prod) |
| `/api/tickets/book` | POST | Authenticated (Any) | 401 | - |
| `/api/tickets/my` | GET | Authenticated (Any) | 401 | - |
| `/api/tickets/validate` | POST | `DRIVER_CONDUCTOR`, `AUTHORITY` | 401 | 403 |
| `/api/incidents/report` | POST | `DRIVER_CONDUCTOR`, `AUTHORITY` | 401 | 403 |
| `/api/incidents/{id}/resolve` | POST | `AUTHORITY` | 401 | 403 |
| `/api/incidents/` | GET | Authenticated (Any) | 401 | - |
| `/api/analytics/command-overview` | GET | `AUTHORITY` | 401 | 403 |
| `/api/analytics/ai-decision-queue` | GET | `AUTHORITY` | 401 | 403 |
| `/api/analytics/reports` | GET | `AUTHORITY` | 401 | 403 |
| `/api/routes` | POST | `AUTHORITY` | 401 | 403 |
| `/api/ai/chat` | POST | Authenticated (Any) | 401 | - |

---

## 2. Authentication Flows & Development Credentials

### Flow A: Controlled Development Demo Login
During local development and controlled testing (`DEMO_MODE=True`), accounts are defined in `backend/app/core/config.py` under `DEV_ACCOUNTS`.
Passphrases are verified using native `bcrypt.checkpw()`. No hardcoded plaintext passwords exist in code or fallbacks.

| Persona | Controlled Development Email | Password | Role | Default Redirect |
|---|---|---|---|---|
| **Passenger** | `rahul.nair@bussense.kerala.gov.in` | `demo1234` (bcrypt salted) | `PASSENGER` | `/passenger/home` |
| **Driver / Conductor** | `suresh.kumar@bussense.kerala.gov.in` | `demo1234` (bcrypt salted) | `DRIVER_CONDUCTOR` | `/driver/cockpit` |
| **Transport Authority**| `controller.vyttila@bussense.kerala.gov.in` | `demo1234` (bcrypt salted) | `AUTHORITY` | `/authority/command` |

### Flow B: Database-Backed Production Login
When an account is not found in `DEV_ACCOUNTS`, `login()` queries the Supabase `users` table via parameterized REST lookup (`email=eq.<email>`). The stored `hashed_password` is verified using native `bcrypt.checkpw()`.

---

## 3. Session Lifecycle & Token Revocation

1. **JWT Generation:**
   Tokens are minted via `backend/app/core/security.py` using `python-jose` with the `HS256` signing algorithm.
   ```json
   {
     "sub": "11111111-1111-1111-1111-111111111111",
     "email": "rahul.nair@bussense.kerala.gov.in",
     "role": "PASSENGER",
     "full_name": "Rahul Nair",
     "exp": 1758974400
   }
   ```
2. **Token Revocation (`POST /api/auth/logout`):**
   - Active tokens are added to the in-memory `REVOKED_TOKENS` blacklist upon calling `/api/auth/logout`.
   - Any subsequent requests bearing a revoked token are rejected with `HTTP 401 UNAUTHORIZED: Token has been revoked. Please log in again.`
3. **Expiry & Refresh:**
   - Standard access token lifespan: 12 hours (configured via `ACCESS_TOKEN_EXPIRE_MINUTES`).

---

## 4. Protected Route Guards & Dependency Injection

- `get_current_user`: Validates token presence, checks blacklist revocation status, decodes claims, and returns `TokenPayload`.
- `require_roles(["AUTHORITY", ...])`: Reusable FastAPI dependency ensuring `user.role in allowed_roles`, raising `403 Forbidden` with diagnostic role context on violation.
