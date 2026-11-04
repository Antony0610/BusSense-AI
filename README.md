# BusSense AI — Climate-Smart Public Bus Intelligence Platform

[![Release](https://img.shields.io/badge/Release-v1.1.1--h23-006c49.svg)](https://github.com/Antony0610/BusSense-AI/releases)
[![Architecture](https://img.shields.io/badge/Architecture-Supabase--Native%20%2B%20Vercel-123c35.svg)](docs/ARCHITECTURE.md)
[![Status](https://img.shields.io/badge/Status-CONTROLLED%20PILOT%20READY-006c49.svg)](docs/PHASE_H23_REPORT.md)
[![Tests](https://img.shields.io/badge/Tests-430%20Passing-brightgreen.svg)](docs/TESTING_REPORT.md)

BusSense AI is an intelligent, climate-smart public transit intelligence platform engineered for the Greater Kochi metropolitan bus network in Kerala, India. It combines real-time GPS tracking, computer-vision passenger density estimation, multi-horizon Ridge demand forecasting, and explainable journey recommendations to balance fleet load and reduce commuter wait times.

---

## 🏛️ Target Cloud Architecture

BusSense AI operates on a modern, cost-effective serverless cloud architecture:

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                                CLIENT WORKSPACES                                 │
├─────────────────────────┬─────────────────────────┬──────────────────────────────┤
│      PASSENGER APP      │   DRIVER COCKPIT HUD    │   AUTHORITY COMMAND CENTER   │
│  (Flutter Mobile Client │  (Flutter Mobile Client │ (Next.js 14 App Router on    │
│    53.4 MB Release APK) │    53.4 MB Release APK) │      Vercel Edge Network)    │
└────────────┬────────────┴────────────┬────────────┴──────────────┬───────────────┘
             │                         │                           │
             │ HTTPS / WSS             │ HTTPS / WSS               │ HTTPS / WSS
             ▼                         ▼                           ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                      SUPABASE CLOUD INFRASTRUCTURE                               │
│                   (Project: lqegmqgkymstycpzplld, Region: ap-south-1)            │
├──────────────────────────────────────────────────────────────────────────────────┤
│  • Supabase Auth: Role-Based Access Control (PASSENGER, CONDUCTOR, AUTHORITY)    │
│  • Supabase Edge Functions: Deno / TypeScript serverless functions               │
│      - Unified API Gateway Router (/functions/v1/api/*)                         │
│      - Multi-Factor Explainable Journey Recommendations                          │
│      - In-Edge TypeScript Ridge Demand Forecasting                               │
│      - Defensive Telemetry Boundary Ingestion (/ingest/gps, /ingest/cctv)        │
│      - Grounded RAG Transit Assistant                                            │
│  • Supabase PostgREST: Direct relational queries with Row-Level Security (RLS)   │
│  • Supabase Realtime: Phoenix WebSocket channels (wss://.../realtime/v1)         │
│  • Supabase Storage: Secure private storage buckets                              │
└──────────────────────────────────────────────────────────────────────────────────┘
```

---

## 🚀 Key Modules & Applications

### 1. Authority Command Center (`frontend/`)
- Built with **Next.js 14**, TypeScript, and Tailwind CSS using the **Google Stitch Design System**.
- Live corridor map with vehicle tracking, crowd indicators, and disruption triage.
- 4-horizon demand forecasting curves and operational compliance metrics.
- 22/22 routes pre-rendered and optimized for Vercel deployment.

### 2. Unified Mobile Application (`apps/mobile/`)
- Built with **Flutter** (Android SDK 34, Kotlin JVM 17).
- **Passenger Experience:** Route discovery, crowd-aware bus recommendations, atomic QR ticket booking.
- **Driver / Conductor Cockpit:** Shift check-in, bus pairing, anti-replay QR ticket validator.
- Verified 53.4 MB release APK: `apps/mobile/build/app/outputs/flutter-apk/app-release.apk`.

### 3. Edge Intelligence & Telemetry Ingestion (`supabase/functions/`)
- **Ridge Demand Forecasting:** Real-time crowd forecasting across +15m, +30m, and +60m horizons.
- **Privacy-Preserving Headcount:** Strict zero-biometrics validation (`PERSON_COUNTING_ONLY_NO_BIOMETRICS`).
- **Defensive Ingestion Boundary:** Geofence bounding box, impossible velocity rejection, and clock skew guards.

---

## 📊 Verification & Empirical Benchmarks

```
========================================================================================
BUSSENSE AI — COMPREHENSIVE AUTOMATED VERIFICATION AUDIT (PHASE H23)
========================================================================================
[PASS] Backend Pytest Suite:           308 / 308 passed (100%)
[PASS] Next.js Authority Frontend:      22 / 22 passed across 13 test suites (100%)
[PASS] Next.js Route Compilation:       22 / 22 routes compiled (0 errors)
[PASS] Flutter Mobile Test Suite:      100 / 100 passed (100%)
[PASS] Live Supabase Read Latency:     119.32 ms mean across 7 core queries
[PASS] Realtime WebSocket Handshake:   Phoenix channel join & heartbeat ACK verified
[PASS] Security & Penetration Tests:   Invalid/expired JWTs reliably rejected (HTTP 401)
----------------------------------------------------------------------------------------
TOTAL AUTOMATED CHECKS:                430 / 430 PASSED (100% SUCCESS RATE)
========================================================================================
```

---

## 📖 Documentation Suite

Comprehensive engineering documentation is available in the [`docs/`](docs/README.md) directory:

- [Phase H23 Cloud Deployment Report](docs/PHASE_H23_REPORT.md)
- [Endpoint Migration Inventory & Reconciliation](docs/ENDPOINT_MIGRATION_INVENTORY.md)
- [Supabase Deployment Guide](docs/SUPABASE_DEPLOYMENT_GUIDE.md)
- [Vercel Deployment Guide](docs/VERCEL_DEPLOYMENT_GUIDE.md)
- [Flutter Release Guide](docs/FLUTTER_RELEASE_GUIDE.md)
- [Security & Privacy Audit Report](docs/SECURITY_AUDIT_REPORT.md)
- [Known Limitations & Disclosures](docs/KNOWN_LIMITATIONS.md)
- [System Architecture](docs/ARCHITECTURE.md)
- [Changelog](docs/CHANGELOG.md)

---

## 🔒 Security & Privacy Guarantees

1. **Zero Biometrics:** Person/head counting only. Face recognition, demographic profiling, and passenger tracking are architecturally prohibited.
2. **Advisory Mode:** Algorithmic fleet balance recommendations are strictly advisory (`advisory_mode_enforced = True`) requiring human operator approval.
3. **Secret Protection:** Zero private keys or service-role secrets are bundled in client applications or version control.

---

## 📜 License

BusSense AI is proprietary software engineered for the Kerala State Road Transport Corporation (KSRTC) and Kochi Metro Rail Limited (KMRL) transit corridors.
