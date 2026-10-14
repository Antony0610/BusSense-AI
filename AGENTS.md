# BusSense AI — Agent Instructions

This document governs the behavior, standards, and workflow expectations for any AI coding agent working in the BusSense AI repository.

---

## 1. Golden Rules for AI Agents

1. **Read Before Writing:** Always read [MEMORY.md](file:///d:/Bus_Sense_Ai/MEMORY.md) and the relevant documents in `/docs/` before making architectural or code edits.
2. **Preserve the Stitch Visual Language:** The UI was designed in Google Stitch (Project `14259704318600090723`). Do NOT redesign screens, do not switch themes to neon/cyberpunk, and do not introduce generic SaaS dashboard cards.
3. **Never Invent Integrations:** Do not claim real KSRTC, Kerala Police, or Razorpay live production integration exists unless active API keys and production endpoints are configured. Label simulated systems honestly.
4. **Enforce Truth Labels:** Every UI card displaying non-hardware data must be stamped with `SIMULATED DATA`, `PREDICTION`, `ESTIMATE`, or `RECOMMENDATION`.
5. **No AI Slop:** Keep copywriting crisp, factual, and free of hype. Avoid cartoon robot icons, fake pulsing halos, and meaningless statistics.
6. **Zero Biometrics in CV:** The computer vision pipeline only counts bodies/heads for occupancy estimation. Never add facial recognition, demographic classification, or passenger tracking.

---

## 2. Agent Workflow

### Phase A: Context & Inspection
- Check `MEMORY.md` and `/docs/KNOWN_LIMITATIONS.md`.
- Inspect existing files before editing: check [backend/app/main.py](file:///d:/Bus_Sense_Ai/backend/app/main.py), [backend/app/services](file:///d:/Bus_Sense_Ai/backend/app/services), [backend/migrations](file:///d:/Bus_Sense_Ai/backend/migrations), and [frontend/app](file:///d:/Bus_Sense_Ai/frontend/app).
- Verify which port services run on:
  - Backend FastAPI: `http://localhost:8000`
  - Frontend Next.js: `http://localhost:3000`
  - Supabase Database: `https://lqegmqgkymstycpzplld.supabase.co`

### Phase B: Implementation
- **Backend:**
  - Python code must be typed with Pydantic v2 schemas in `backend/app/schemas/`.
  - Service functions must be modular and documented in `backend/app/services/`.
  - Maintain security with `backend/app/core/security.py` (JWT + bcrypt).
  - Enforce role-based access control (`PASSENGER`, `DRIVER_CONDUCTOR`, `AUTHORITY`).
- **Frontend:**
  - Next.js App Router with TypeScript.
  - Tailwind CSS utilizing the exact Stitch palette tokens (`primary: #002620`, `primary-container: #123c35`, `secondary: #006c49`, `surface: #f3fbf7`, etc.).
  - Use tabular numerals (`tnum`) for all ETAs, stop countdowns, and passenger counters.
  - Ensure loading, empty, and error states are styled consistently.
  - Windows command execution: Always run `npm.cmd` and `npx.cmd` instead of `.ps1` wrappers due to Windows PowerShell ExecutionPolicy.

### Phase C: Verification
- **Automated Tests:**
  - Run backend test suite:
    ```powershell
    & "backend/.venv/Scripts/python.exe" -m pytest backend/tests/ -v
    ```
- **Type Checking & Build:**
  - Verify Next.js compilation:
    ```powershell
    npm.cmd --prefix frontend run build
    ```
- **Lint & Syntax:**
  - Ensure zero unresolved syntax errors or missing imports.

### Phase D: Synchronization & Documentation
- Update `/docs/CHANGELOG.md` with every significant change.
- If an API changes, update `/docs/API.md` and `frontend/lib/api.ts`.
- If a database schema changes, add a new migration script in `backend/migrations/` and update `/docs/DATABASE.md` and `/docs/DATA_MODEL.md`.
- If an architectural decision is taken, document it as an ADR in `/docs/DECISIONS.md`.

---

## 3. Checklist Before Completing Any Agent Turn

- [ ] Does the code run without runtime crashes?
- [ ] Are all backend tests in `backend/tests/` passing?
- [ ] Are all secrets safely kept in `.env` and excluded from git?
- [ ] Is simulated telemetry clearly badged?
- [ ] Has documentation in `/docs` been kept in sync?
- [ ] Are all responses concise, professional, and accompanied by clickable file links?
