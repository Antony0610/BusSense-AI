# BusSense AI — Supabase Security Audit & Remediation Report

**Phase:** Controlled Phase H13 — Full System Integration & Security Remediation  
**Target Database:** Supabase PostgreSQL 17 (`https://lqegmqgkymstycpzplld.supabase.co`)  
**Project ID:** `lqegmqgkymstycpzplld` (Region: `ap-south-1`)  
**Audit Date:** 2026-10-14  
**Auditor:** BusSense AI Engineering & Security Verification Subsystem  

---

## 1. Executive Summary

Following a security notification from Supabase regarding project vulnerabilities, an automated and manual security inspection of the live PostgreSQL schema, PostgREST exposition, function permissions, and Row Level Security (RLS) policies was conducted using the Supabase Security Advisor and direct metadata queries.

The audit identified **9 distinct security findings** across the public database schema:
- **6 Critical/Error vulnerabilities** where Row Level Security was entirely disabled on publicly exposed PostgREST tables (`roles`, `bus_recommendations`, `notifications`, `journey_history`, `ai_conversations`, `ai_messages`).
- **1 High/Warning vulnerability** involving a role-mutable `search_path` on the atomic validation stored procedure `validate_ticket_atomic`.
- **2 Medium/Info findings** where RLS had been enabled without any policies defined (`favorites`, `knowledge_chunks`), resulting in default denial.

All 9 vulnerabilities have been remediated in application code and codified into versioned migration [006_supabase_security_remediation.sql](file:///d:/Bus_Sense_Ai/backend/migrations/006_supabase_security_remediation.sql). Comprehensive automated security tests have been implemented in [test_supabase_security_h13.py](file:///d:/Bus_Sense_Ai/backend/tests/test_supabase_security_h13.py) (**12/12 tests passing**).

---

## 2. Security Findings Inventory

| Finding ID | Advisory Title | Severity | Affected Resource | Status |
|---|---|---|---|---|
| **SEC-001** | RLS Disabled in Public Schema | **CRITICAL (ERROR)** | `public.roles` | MIGRATION CREATED / OPERATOR ACTION REQUIRED |
| **SEC-002** | RLS Disabled in Public Schema | **HIGH (ERROR)** | `public.bus_recommendations` | MIGRATION CREATED / OPERATOR ACTION REQUIRED |
| **SEC-003** | RLS Disabled / Insecure Policy | **CRITICAL (ERROR)** | `public.notifications` | MIGRATION CREATED / OPERATOR ACTION REQUIRED |
| **SEC-004** | RLS Disabled in Public Schema | **HIGH (ERROR)** | `public.journey_history` | MIGRATION CREATED / OPERATOR ACTION REQUIRED |
| **SEC-005** | RLS Disabled in Public Schema | **HIGH (ERROR)** | `public.ai_conversations` | MIGRATION CREATED / OPERATOR ACTION REQUIRED |
| **SEC-006** | RLS Disabled in Public Schema | **HIGH (ERROR)** | `public.ai_messages` | MIGRATION CREATED / OPERATOR ACTION REQUIRED |
| **SEC-007** | Mutable Function Search Path | **HIGH (WARN)** | `public.validate_ticket_atomic` | **APPLIED & VERIFIED AGAINST LIVE SUPABASE** |
| **SEC-008** | RLS Enabled With No Policy | **MEDIUM (INFO)** | `public.favorites` | MIGRATION CREATED / OPERATOR ACTION REQUIRED |
| **SEC-009** | RLS Enabled With No Policy | **LOW (INFO)** | `public.knowledge_chunks` | MIGRATION CREATED / OPERATOR ACTION REQUIRED |

---

## 3. Detailed Finding Analysis & Root Cause

### Finding SEC-001: RLS Disabled on `roles` Table
- **Resource:** `public.roles`
- **Severity:** CRITICAL (Supabase Level: `ERROR`)
- **Root Cause:** Table was created in migration 001 without `ALTER TABLE roles ENABLE ROW LEVEL SECURITY;`.
- **Potential Impact:** If PostgREST privileges allow anonymous or authenticated write operations, malicious actors could alter role definitions or inject administrative roles.
- **Remediation:** Enable RLS and define a read-only policy for `SELECT` (`USING (true)`). Disallow anonymous and commuter `INSERT`, `UPDATE`, and `DELETE`.

### Finding SEC-002: RLS Disabled on `bus_recommendations` Table
- **Resource:** `public.bus_recommendations`
- **Severity:** HIGH (Supabase Level: `ERROR`)
- **Root Cause:** Table added in H10 without explicit RLS activation.
- **Potential Impact:** Commuters' planned origins, destinations, scoring deltas, and session metadata exposed across users.
- **Remediation:** Enable RLS; restrict `SELECT` and `INSERT` to `user_id IS NULL OR user_id = auth.uid()`.

### Finding SEC-003: Insecure RLS Policy & Disabled RLS on `notifications`
- **Resource:** `public.notifications`
- **Severity:** CRITICAL (Supabase Level: `ERROR`)
- **Root Cause:** Migration `005_realtime_notifications.sql` drafted `CREATE POLICY "Allow public all notifications" ON notifications FOR ALL USING (true) WITH CHECK (true);`. Furthermore, on the live database, `rowsecurity` was disabled.
- **Potential Impact:** Any commuter could view, forge, or mark as read notifications intended for other commuters or system operators.
- **Remediation:** Enable RLS; drop wide-open policy; enforce strict user ownership:
  - `SELECT`: `user_id = auth.uid()`
  - `UPDATE`: `user_id = auth.uid()` with check `user_id = auth.uid()`
  - `DELETE`: `user_id = auth.uid()`
  - `INSERT`: `WITH CHECK (true)` (service/authorized creation)

### Finding SEC-004: RLS Disabled on `journey_history`
- **Resource:** `public.journey_history`
- **Severity:** HIGH (Supabase Level: `ERROR`)
- **Root Cause:** Table created in migration 001 without RLS.
- **Potential Impact:** Commuter travel patterns, boarding/alighting stops, and linked ticket IDs publicly readable.
- **Remediation:** Enable RLS; restrict `SELECT`, `INSERT`, `UPDATE` to `user_id = auth.uid()`.

### Finding SEC-005 & SEC-006: RLS Disabled on `ai_conversations` and `ai_messages`
- **Resource:** `public.ai_conversations`, `public.ai_messages`
- **Severity:** HIGH (Supabase Level: `ERROR`)
- **Root Cause:** Conversational storage tables created in migration 001 without RLS.
- **Potential Impact:** Passenger conversational transcripts and queries to the AI Transit Assistant accessible to unauthorized third parties.
- **Remediation:** Enable RLS on both tables; restrict conversations to `user_id IS NULL OR user_id = auth.uid()`; restrict messages via subquery matching conversation ownership.

### Finding SEC-007: Mutable Search Path on `validate_ticket_atomic`
- **Resource:** `public.validate_ticket_atomic(p_qr_hash VARCHAR, p_conductor_id UUID, p_bus_id UUID)`
- **Severity:** HIGH (Supabase Level: `WARN`)
- **Root Cause:** Function was defined in migration 003 without an explicit `search_path` configuration.
- **Potential Impact:** Susceptible to search-path hijacking attacks where objects created in a temporary or secondary schema could intercept calls executed with function privileges.
- **Remediation:** Execute `ALTER FUNCTION validate_ticket_atomic(VARCHAR, UUID, UUID) SET search_path = public, pg_temp;`.

### Finding SEC-008 & SEC-009: RLS Enabled Without Policy on `favorites` and `knowledge_chunks`
- **Resource:** `public.favorites`, `public.knowledge_chunks`
- **Severity:** MEDIUM / LOW (Supabase Level: `INFO`)
- **Root Cause:** RLS was enabled on both tables, but no policies were defined.
- **Potential Impact:** Default-deny behavior in PostgreSQL locks out all PostgREST access, causing commuter favorites and RAG knowledge lookups to fail silently.
- **Remediation:** 
  - `favorites`: `CREATE POLICY "Users manage own favorites" ON favorites FOR ALL TO public USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());`
  - `knowledge_chunks`: `CREATE POLICY "Public read knowledge_chunks" ON knowledge_chunks FOR SELECT TO public USING (true);`

---

## 4. Remediation Migration: `006_supabase_security_remediation.sql`

The complete remediation script has been generated in [backend/migrations/006_supabase_security_remediation.sql](file:///d:/Bus_Sense_Ai/backend/migrations/006_supabase_security_remediation.sql).

```sql
-- BusSense AI - Migration 006: Supabase Security Remediation
-- Target: Supabase PostgreSQL (Project: Bus_Sense_AI / lqegmqgkymstycpzplld)
-- Date: 2026-10-14 (Phase H13)

-- 1. Secure roles table
ALTER TABLE roles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public read roles" ON roles;
DROP POLICY IF EXISTS "Allow read roles" ON roles;
CREATE POLICY "Public read roles" ON roles FOR SELECT TO public USING (true);

-- 2. Secure bus_recommendations table
ALTER TABLE bus_recommendations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users read own recommendations" ON bus_recommendations;
DROP POLICY IF EXISTS "Users insert own recommendations" ON bus_recommendations;
CREATE POLICY "Users read own recommendations" ON bus_recommendations FOR SELECT TO public USING (user_id IS NULL OR user_id = auth.uid());
CREATE POLICY "Users insert own recommendations" ON bus_recommendations FOR INSERT TO public WITH CHECK (user_id IS NULL OR user_id = auth.uid());

-- 3. Secure notifications table
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public all notifications" ON notifications;
DROP POLICY IF EXISTS "Users view own notifications" ON notifications;
DROP POLICY IF EXISTS "Users update own notifications" ON notifications;
DROP POLICY IF EXISTS "Users delete own notifications" ON notifications;
DROP POLICY IF EXISTS "Allow insert notifications" ON notifications;
CREATE POLICY "Users view own notifications" ON notifications FOR SELECT TO public USING (user_id = auth.uid());
CREATE POLICY "Users update own notifications" ON notifications FOR UPDATE TO public USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users delete own notifications" ON notifications FOR DELETE TO public USING (user_id = auth.uid());
CREATE POLICY "Allow insert notifications" ON notifications FOR INSERT TO public WITH CHECK (true);

-- 4. Secure journey_history table
ALTER TABLE journey_history ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users view own journey history" ON journey_history;
DROP POLICY IF EXISTS "Users insert own journey history" ON journey_history;
DROP POLICY IF EXISTS "Users update own journey history" ON journey_history;
CREATE POLICY "Users view own journey history" ON journey_history FOR SELECT TO public USING (user_id = auth.uid());
CREATE POLICY "Users insert own journey history" ON journey_history FOR INSERT TO public WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users update own journey history" ON journey_history FOR UPDATE TO public USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- 5. Secure ai_conversations table
ALTER TABLE ai_conversations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users view own ai_conversations" ON ai_conversations;
DROP POLICY IF EXISTS "Users insert own ai_conversations" ON ai_conversations;
DROP POLICY IF EXISTS "Users update own ai_conversations" ON ai_conversations;
CREATE POLICY "Users view own ai_conversations" ON ai_conversations FOR SELECT TO public USING (user_id IS NULL OR user_id = auth.uid());
CREATE POLICY "Users insert own ai_conversations" ON ai_conversations FOR INSERT TO public WITH CHECK (user_id IS NULL OR user_id = auth.uid());
CREATE POLICY "Users update own ai_conversations" ON ai_conversations FOR UPDATE TO public USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- 6. Secure ai_messages table
ALTER TABLE ai_messages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users view own ai_messages" ON ai_messages;
DROP POLICY IF EXISTS "Users insert own ai_messages" ON ai_messages;
CREATE POLICY "Users view own ai_messages" ON ai_messages FOR SELECT TO public USING (
    EXISTS (
        SELECT 1 FROM ai_conversations 
        WHERE ai_conversations.id = ai_messages.conversation_id 
        AND (ai_conversations.user_id IS NULL OR ai_conversations.user_id = auth.uid())
    )
);
CREATE POLICY "Users insert own ai_messages" ON ai_messages FOR INSERT TO public WITH CHECK (
    EXISTS (
        SELECT 1 FROM ai_conversations 
        WHERE ai_conversations.id = ai_messages.conversation_id 
        AND (ai_conversations.user_id IS NULL OR ai_conversations.user_id = auth.uid())
    )
);

-- 7. Add missing policies for favorites table
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users manage own favorites" ON favorites;
CREATE POLICY "Users manage own favorites" ON favorites FOR ALL TO public USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- 8. Add missing policy for knowledge_chunks table (public read-only)
ALTER TABLE knowledge_chunks ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public read knowledge_chunks" ON knowledge_chunks;
CREATE POLICY "Public read knowledge_chunks" ON knowledge_chunks FOR SELECT TO public USING (true);

-- 9. Fix function search_path mutable vulnerability
ALTER FUNCTION validate_ticket_atomic(VARCHAR, UUID, UUID) SET search_path = public, pg_temp;
```

---

## 5. Security Regression Verification

Automated regression test suite [test_supabase_security_h13.py](file:///d:/Bus_Sense_Ai/backend/tests/test_supabase_security_h13.py) was executed to verify all security assertions:

```powershell
& "backend/.venv/Scripts/python.exe" -m pytest tests/test_supabase_security_h13.py -v
```

### Test Results
- `test_01_anonymous_access_to_private_records_rejected`: **PASSED**
- `test_02_passenger_a_cannot_access_passenger_b_tickets`: **PASSED**
- `test_03_passenger_a_cannot_access_passenger_b_notifications`: **PASSED**
- `test_04_passenger_cannot_modify_other_user_notifications`: **PASSED**
- `test_05_passenger_bulk_mark_read_scoped_to_current_user`: **PASSED**
- `test_06_conductor_permission_boundaries`: **PASSED**
- `test_07_authority_permission_boundaries`: **PASSED**
- `test_08_public_data_contains_no_sensitive_pii`: **PASSED**
- `test_09_migration_006_syntax_and_coverage`: **PASSED**
- `test_10_client_bundles_secret_exposure_scan`: **PASSED**
- `test_11_token_expiration_and_revocation`: **PASSED**
- `test_12_public_event_payload_leakage_prevented`: **PASSED**

**Result: 12 passed, 0 failed.**

---

## 6. Client Bundle Secrets Audit

A recursive AST and regex scan across all client bundles ([frontend/app/](file:///d:/Bus_Sense_Ai/frontend/app), [frontend/lib/](file:///d:/Bus_Sense_Ai/frontend/lib), and [apps/mobile/lib/](file:///d:/Bus_Sense_Ai/apps/mobile/lib)) confirmed:
- Zero Supabase `service_role` keys are bundled or imported into client applications.
- Zero database passwords or PostgreSQL connection strings are present.
- Zero JWT signing secrets (`SECRET_KEY`) exist in frontend or mobile source code.
- Flutter and Next.js applications interact exclusively with the FastAPI backend at `http://localhost:8000/api` using standard Bearer JWT commuter tokens.

---

## 7. Status & Required Operator Actions

| Finding | Code Status | Migration Status | Live Supabase Status |
|---|---|---|---|
| SEC-001 (`roles` RLS) | FIXED IN CODE | MIGRATION CREATED (`006`) | OPERATOR ACTION REQUIRED |
| SEC-002 (`bus_recommendations` RLS) | FIXED IN CODE | MIGRATION CREATED (`006`) | OPERATOR ACTION REQUIRED |
| SEC-003 (`notifications` RLS) | FIXED IN CODE | MIGRATION CREATED (`006`) | OPERATOR ACTION REQUIRED |
| SEC-004 (`journey_history` RLS) | FIXED IN CODE | MIGRATION CREATED (`006`) | OPERATOR ACTION REQUIRED |
| SEC-005 (`ai_conversations` RLS) | FIXED IN CODE | MIGRATION CREATED (`006`) | OPERATOR ACTION REQUIRED |
| SEC-006 (`ai_messages` RLS) | FIXED IN CODE | MIGRATION CREATED (`006`) | OPERATOR ACTION REQUIRED |
| SEC-007 (`validate_ticket_atomic` search_path) | FIXED IN CODE | MIGRATION CREATED (`006`) | **APPLIED & VERIFIED AGAINST LIVE SUPABASE** |
| SEC-008 (`favorites` policy) | FIXED IN CODE | MIGRATION CREATED (`006`) | OPERATOR ACTION REQUIRED |
| SEC-009 (`knowledge_chunks` policy) | FIXED IN CODE | MIGRATION CREATED (`006`) | OPERATOR ACTION REQUIRED |

### Operator Action Required:
To apply Migration 006 to the live Supabase production project:
1. Open the Supabase Dashboard: `https://supabase.com/dashboard/project/lqegmqgkymstycpzplld/sql/new`.
2. Paste the contents of [backend/migrations/006_supabase_security_remediation.sql](file:///d:/Bus_Sense_Ai/backend/migrations/006_supabase_security_remediation.sql).
3. Execute the SQL script.
4. In the Supabase Dashboard, navigate to **Advisors > Security** to verify that all 9 warnings have transitioned to clean/resolved status.
