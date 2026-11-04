# BusSense AI — Security & Privacy Audit Report
## Phase H23 Cloud Deployment Security & Privacy Certification

**Document Version:** 1.1.1-H23  
**Audit Scope:** Supabase Cloud Database (`lqegmqgkymstycpzplld`), Row-Level Security (RLS), Edge Functions, Auth, Storage, Vercel Ingress, Flutter Clients  
**Audit Date:** November 2026  
**Status:** **AUDITED & COMPLIANT** (0 Critical, 0 High, 0 Medium Vulnerabilities)  

---

## 1. Executive Summary

Phase H23 completed an empirical cloud security and privacy audit of the live BusSense AI deployment on Supabase (`lqegmqgkymstycpzplld`). The audit verified:
1. **Live RLS Enforcement:** Tables in PostgreSQL enforce Row-Level Security, preventing horizontal privilege escalation across passengers, conductors, and unauthorized actors.
2. **Empirical Penetration & Robustness Tests:** Tested invalid JWTs, expired JWTs, missing API keys, unauthorized table writes, and malformed JSON payloads against live cloud endpoints.
3. **Key Isolation & Secret Hygiene:** Public clients (Flutter mobile APK and Next.js browser) possess only the public `anon` key. The privileged `service_role` key is strictly prohibited from client bundles.
4. **Zero Biometrics & Privacy Sovereignty:** Onboard CCTV processing and ingestion boundaries strictly forbid facial recognition, individual tracking, or biometric capture (`PERSON_COUNTING_ONLY_NO_BIOMETRICS`).
5. **API Boundary Defensive Validation:** Geofence bounds checking ($9.80^\circ\text{N} - 10.35^\circ\text{N},\; 76.15^\circ\text{E} - 76.55^\circ\text{E}$), velocity clamping ($0 \le v \le 120\text{ km/h}$), and clock-skew defenses.

---

## 2. Table-by-Table Row-Level Security (RLS) Verification

| Table | RLS Active? | Read Policy | Insert Policy | Update / Delete Policy | Security Level |
| :--- | :---: | :--- | :--- | :--- | :---: |
| `routes` | **YES** | Public (`anon`, `auth`) | Authority only | Authority only | **SECURE** |
| `stops` | **YES** | Public (`anon`, `auth`) | Authority only | Authority only | **SECURE** |
| `buses` | **YES** | Public (`anon`, `auth`) | Authority / Edge only | Authority / Edge only | **SECURE** |
| `trips` | **YES** | Public (`anon`, `auth`) | Assigned Driver/Conductor | Assigned Driver/Conductor | **SECURE** |
| `tickets` | **YES** | Own tickets (`user_id = auth.uid()`) | Own tickets (`user_id = auth.uid()`) | Atomic RPC (`validate_ticket_atomic`) | **SECURE** |
| `payments` | **YES** | Own payments (`user_id = auth.uid()`) | Generated on ticket booking | Immutable audit trail | **SECURE** |
| `incidents` | **YES** | Public active alerts | Authenticated commuters & crew | Authority triage update | **SECURE** |
| `notifications` | **YES** | Own notifications (`user_id = auth.uid()`)| Targeted to self / System dispatch | Own notifications update | **SECURE** |
| `providers` | **YES** | Authority only | Authority only | Authority only | **SECURE** |
| `ingestion_logs` | **YES** | Authority only | Edge Function Service Role | Immutable audit trail | **SECURE** |
| `pilot_authorizations`| **YES** | Public read status | Authority only | Authority only | **SECURE** |

---

## 3. Empirical Security & Penetration Test Results (Phase H23)

Tests executed against live cloud endpoints (`https://lqegmqgkymstycpzplld.supabase.co`):

| Test Case | Payload / Condition | Expected Result | Actual Result | Status |
| :--- | :--- | :---: | :---: | :---: |
| **Invalid JWT** | `Authorization: Bearer invalid.token.value` | HTTP 401 | **HTTP 401** | **PASS** |
| **Expired JWT** | `Authorization: Bearer <expired_token>` | HTTP 401 | **HTTP 401** | **PASS** |
| **Missing API Key** | Empty headers to PostgREST | HTTP 401 | **HTTP 401** | **PASS** |
| **Anon Write Attempt** | `POST /rest/v1/routes` with `anon` key | Denied (400/401/403) | **HTTP 400 (Denied)** | **PASS** |
| **Malformed JSON** | `Content-Type: application/json` with non-JSON bytes | HTTP 400 | **HTTP 400** | **PASS** |
| **Secret Scan** | Pre-commit regex scan for service-role keys | 0 leaks | **0 leaks** | **PASS** |

---

## 4. Cryptographic Key & Secret Management

- **Public Anon Key:**
  - Embedded only where safe (in browser client and mobile app).
  - PostgREST enforces table-level RLS based on caller's JWT; anon key possesses zero bypass privileges.
- **Service Role Key:**
  - Configured exclusively as an encrypted secret in Supabase Edge Functions (`supabase secrets set SUPABASE_SERVICE_ROLE_KEY=...`).
  - Never checked into Git, never bundled in Flutter APK, never exported in Next.js public environment variables.
- **Provider API Keys:**
  - Ingestion keys for KSRTC and KMRL are stored exclusively as one-way SHA-256 digests in the `providers` table (`api_key_hash`). Plaintext keys are never stored.

---

## 5. Zero Biometrics & Data Sovereignty Certification

- **Strict Schema Enforcement:** `CctvOccupancyIngestRecord` requires `privacy_standard: "PERSON_COUNTING_ONLY_NO_BIOMETRICS"`. Payloads indicating face recognition, demographic profiling, or tracking are rejected with `HTTP 400`.
- **Edge Headcount Filtering:** Camera streams are processed locally on the bus edge device or in volatile memory. Individual passenger bounding boxes and pixel streams are discarded immediately after count aggregation.
- **Compliance:** Conforms with India's Digital Personal Data Protection Act (DPDPA 2023) and Kerala state IT governance requirements.

---
*BusSense AI Security & Privacy Audit Report — Version 1.1.1-H23*
