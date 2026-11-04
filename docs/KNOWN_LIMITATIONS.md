# BusSense AI — Known Limitations & Unresolved Issues
## Operational Scope & Architectural Boundaries (Phase H23)

**Document Version:** 1.1.1-H23  
**Date:** November 2026  
**Status:** FACTUALLY DISCLOSED & AUDITED  

---

## 1. Cloud Deployment & CLI Boundaries

### 1.1 Supabase CLI Authentication & IPv6 Connectivity
- **Limitation:** Deploying Edge Functions and pushing Migration 007 via the command line (`npx supabase db push` and `npx supabase functions deploy`) requires an operator access token (`SUPABASE_ACCESS_TOKEN`).
- **Network IPv6 Restriction:** On development networks without native IPv6 routing, direct connection to `db.lqegmqgkymstycpzplld.supabase.co:5432` fails with `DbConfigIpv6Error`. Connecting requires using the Supabase transaction pooler IPv4 endpoint (`aws-0-ap-south-1.pooler.supabase.com:6543`) with database credentials, or applying migrations via the Supabase Web SQL Editor.

### 1.2 Vercel Production Deployment
- **Limitation:** Vercel CLI prohibits unauthenticated temporary deployments (`Temporary deployments aren't available for this attempt`). Triggering production deployment requires human operator authentication via `npx vercel login` (OAuth device flow) or linking the GitHub repository directly on `vercel.com`.
- **Domain Verification:** Domain `admin.bussense.ai` is a targeted institutional domain and requires DNS CNAME verification (`cname.vercel-dns.com`) before serving traffic.

---

## 2. Computer Vision & Edge AI Runtime Boundaries

### 2.1 YOLOv8 & OpenCV Video Ingestion
- **Runtime Limitation:** Supabase Edge Functions run within a lightweight Deno v8 isolate with short execution timeouts (150ms to 2s) and memory constraints. Deep learning frameworks (PyTorch, Ultralytics YOLOv8) and video decoding libraries (OpenCV) cannot execute directly inside Deno Edge Functions.
- **Architectural Boundary:**
  - Supabase Edge Functions expose `/api/ingest/cctv-occupancy` accepting verified aggregate passenger headcount payloads (`CctvOccupancyIngestRecord`) with strict `PERSON_COUNTING_ONLY_NO_BIOMETRICS` validation.
  - Physical bus deployments require an onboard low-power edge computer (e.g. Raspberry Pi 5 or NVIDIA Jetson) running the YOLOv8 person detection pipeline locally and pushing aggregate headcount numbers to the Edge Function.
  - The repository's Python OpenCV/YOLOv8 pipeline in `backend/cv/` is intentionally retained as an empirical evaluation and demonstration harness, not deleted or replaced with fabricated values.

### 2.2 Zero Biometrics & Face Recognition
- BusSense AI strictly forbids facial recognition, biometric identity extraction, demographic classification, and individual passenger tracking. The system architecture only processes bounding-box person counts.

---

## 3. Mobile Signing & Store Distribution

### 3.1 Android Release APK Keystore
- **Status:** Release APK (`53.4 MB`) was compiled with full release optimizations (R8, ProGuard, tree-shaking) but is signed using the standard Android debug keystore (`signingConfig = signingConfigs.getByName("debug")`).
- **Limitation:** This APK can be sideloaded onto conductor test devices via ADB, but is **NOT claimed as a Google Play production release** until signed with an institutional transport authority KeyStore.

---

## 4. External Services & Payment Gateway

### 4.1 Razorpay Payment Gateway
- **Status:** Payments currently operate in simulated sandbox mode (`payment_method = 'UPI'`, status `'COMPLETED'`).
- **Limitation:** Live production merchant payment capture requires a certified merchant account and live API keys registered with Razorpay India under the Kerala Transport Commissionerate / KSRTC business entity.

### 4.2 Mobile Push Notifications (APNs / FCM)
- **Status:** In-app notification polling and real-time inbox management are fully functional in Flutter and Next.js.
- **Limitation:** System-level background lockscreen push notifications require registering Apple Developer (APNs) and Google Firebase (FCM) credentials associated with production store publishing accounts.

---

## 5. Regulatory Governance & Pilot Status

### 5.1 Pilot Authorization Stage
- **Current Status:** **Stage 1 (`PROPOSED PILOT`)**.
- The software stack is certified **`CONTROLLED PILOT READY`**. Live on-road vehicle integration awaits formal bilateral MOU signing with KSRTC-SWIFT and KMRL leadership.
- **Advisory Mode Immutability:** Recommendations and headway balance suggestions are strictly advisory (`advisory_mode_enforced = True`). No algorithmic process has authority to alter bus schedules or reassign crews without certified human dispatcher approval.

---
*BusSense AI Known Limitations — Version 1.1.1-H23*
