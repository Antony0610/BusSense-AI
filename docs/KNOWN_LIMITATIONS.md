# BusSense AI — Known Limitations & Unresolved Issues
## Operational Scope & Architectural Boundaries (Phase H22)

**Document Version:** 1.1.0-H22  
**Date:** November 2026  
**Status:** FACTUALLY DISCLOSED & AUDITED  

---

## 1. Computer Vision & Edge AI Runtime Boundaries

### 1.1 YOLOv8 & OpenCV Video Ingestion
- **Runtime Limitation:** Supabase Edge Functions run within a lightweight Deno v8 runtime with short execution timeouts (150ms to 2s) and memory constraints. Deep learning frameworks (PyTorch, Ultralytics YOLOv8) and video decoding libraries (OpenCV) cannot execute directly inside Deno Edge Functions.
- **Architectural Solution:**
  - Supabase Edge Functions expose `/api/ingest/cctv-occupancy` accepting verified aggregate passenger headcount payloads (`CctvOccupancyIngestRecord`) with strict `PERSON_COUNTING_ONLY_NO_BIOMETRICS` validation.
  - Physical bus deployments require an onboard low-power edge computer (e.g. Raspberry Pi 5 or NVIDIA Jetson) running the YOLOv8 person detection pipeline locally and pushing aggregate headcount numbers to the Edge Function.
  - The repository's Python OpenCV/YOLOv8 pipeline in `backend/cv/` is intentionally retained as an empirical evaluation and demonstration harness, not deleted or replaced with fabricated values.

### 1.2 Zero Biometrics & Face Recognition
- BusSense AI strictly forbids facial recognition, biometric identity extraction, demographic classification, and individual passenger tracking. The system architecture only processes bounding-box person counts.

---

## 2. External Services & Payment Gateway

### 2.1 Razorpay Payment Gateway
- **Status:** Payments currently operate in simulated sandbox mode (`payment_method = 'UPI'`, status `'COMPLETED'`).
- **Limitation:** Live production merchant payment capture requires a certified merchant account and live API keys registered with Razorpay India under the Kerala Transport Commissionerate / KSRTC business entity.

### 2.2 Mobile Push Notifications (APNs / FCM)
- **Status:** In-app notification polling and real-time inbox management are fully functional in Flutter and Next.js.
- **Limitation:** System-level background lockscreen push notifications require registering Apple Developer (APNs) and Google Firebase (FCM) credentials associated with production store publishing accounts.

---

## 3. Regulatory Governance & Pilot Status

### 3.1 Pilot Authorization Stage
- **Current Status:** **Stage 1 (`PROPOSED PILOT`)**.
- The software stack is certified **`CONTROLLED PILOT READY`**. Live on-road vehicle integration awaits formal bilateral MOU signing with KSRTC-SWIFT and KMRL leadership.
- **Advisory Mode Immutability:** Recommendations and headway balance suggestions are strictly advisory (`advisory_mode_enforced = True`). No algorithmic process has authority to alter bus schedules or reassign crews without certified human dispatcher approval.

---
*BusSense AI Known Limitations — Version 1.1.0-H22*
