# BusSense AI — Security & Privacy Audit Report
## Phase H22 Supabase-Native & Vercel Security Hardening

**Document Version:** 1.0.0-H22  
**Audit Scope:** Supabase PostgreSQL Database, Row-Level Security (RLS), Edge Functions, Auth, Storage, Vercel Ingress, Flutter Clients  
**Audit Date:** November 2026  
**Status:** **AUDITED & COMPLIANT** (0 Critical, 0 High, 0 Medium Vulnerabilities)

---

## 1. Executive Summary

Phase H22 completed a comprehensive security and privacy re-audit of the BusSense AI platform following the migration to a Supabase-native serverless architecture. The audit evaluated:
1. **Database & Row-Level Security (RLS):** Every exposed table in PostgreSQL has active RLS preventing horizontal privilege escalation.
2. **Key Isolation & Secret Hygiene:** Public client applications (Flutter mobile and Next.js browser) only possess the public `anon` key. The privileged `service_role` key exists exclusively inside serverless Edge Functions environment variables.
3. **Zero Biometrics & Privacy Sovereignty:** Onboard CCTV processing and ingestion boundaries strictly forbid facial recognition, individual tracking, or biometric capture (`PERSON_COUNTING_ONLY_NO_BIOMETRICS`).
4. **API Boundary Defensive Validation:** Geofence bounds checking ($9.80^\circ\text{N} - 10.35^\circ\text{N},\; 76.15^\circ\text{E} - 76.55^\circ\text{E}$), velocity clamping ($0 \le v \le 120\text{ km/h}$), and clock-skew defenses.

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

## 3. Cryptographic Key & Secret Management

- **Public Anon Key:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`
  - Hardcoded or embedded only where safe (in browser client and mobile app).
  - PostgREST enforces table-level RLS based on caller's JWT; anon key possesses zero bypass privileges.
- **Service Role Key:**
  - Configured exclusively as an encrypted secret in Supabase Edge Functions (`supabase secrets set SUPABASE_SERVICE_ROLE_KEY=...`).
  - Never checked into Git, never bundled in Flutter APK, never exported in Next.js public environment variables.
- **Provider API Keys:**
  - Ingestion keys for KSRTC and KMRL are stored exclusively as one-way SHA-256 digests in the `providers` table (`api_key_hash`). Plaintext keys are never stored.

---

## 4. Zero Biometrics & Data Sovereignty Certification

- **Strict Schema Enforcement:** `CctvOccupancyIngestRecord` requires `privacy_standard: "PERSON_COUNTING_ONLY_NO_BIOMETRICS"`. Payloads indicating face recognition, demographic profiling, or tracking are rejected with `HTTP 400`.
- **Edge Headcount Filtering:** Camera streams are processed locally on the bus edge device or in volatile memory. Individual passenger bounding boxes and pixel streams are discarded immediately after count aggregation.
- **Compliance:** Conforms with India's Digital Personal Data Protection Act (DPDPA 2023) and Kerala state IT governance requirements.

---
*BusSense AI Security & Privacy Audit Report — Version 1.0.0-H22*
