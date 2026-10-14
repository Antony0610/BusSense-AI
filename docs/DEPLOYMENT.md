# BusSense AI — Deployment Architecture & Topology

This document details the target production deployment topology, cloud infrastructure components, and current hosting status of BusSense AI.

---

## 1. Target Production Infrastructure Topology

```
┌────────────────────────────────────────────────────────────────────────┐
│                        COMMUTER & STAFF CLIENTS                        │
├─────────────────────────┬─────────────────────────┬────────────────────┤
│   PASSENGER MOBILE APP  │  DRIVER COCKPIT TABLET  │ AUTHORITY CONSOLE  │
│  (Flutter / App Stores) │  (Flutter / Kiosk Mode) │  (Vercel Next.js)  │
└────────────┬────────────┴────────────┬────────────┴──────────┬─────────┘
             │                         │                       │
             │ HTTPS / WSS             │ HTTPS / WSS           │ HTTPS
             ▼                         ▼                       ▼
┌────────────────────────────────────────────────────────────────────────┐
│                     APPLICATION GATEWAY & REVERSE PROXY                │
│                        (Cloudflare CDN + SSL / WAF)                    │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        FASTAPI BACKEND CONTAINER                       │
│                       (Render / Railway / AWS ECS)                     │
│               • Uvicorn ASGI Multi-Worker Container                    │
│               • WebSocket Connection Manager                           │
│               • Background Telemetry Physics Worker                    │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
         ┌──────────────────────────┴──────────────────────────┐
         │ PostgREST / TLS 1.3                                 │ Direct SQL
         ▼                                                     ▼
┌────────────────────────────────────────────────────────────────────────┐
│                   SUPABASE MANAGED CLOUD PLATFORM                      │
│                  (PostgreSQL 15, Region: ap-south-1)                   │
├────────────────────────────────────────────────────────────────────────┤
│ • 26 Relational Tables with Row-Level Security (RLS)                   │
│ • Realtime Change Data Capture (CDC) Replication                       │
│ • Supabase Storage Buckets (System Assets & Transit Shapefiles)        │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Component Deployment Status

| Component | Target Platform | Current Status | Notes |
|---|---|---|---|
| **Database & Auth** | Supabase Cloud (`ap-south-1`) | **LIVE / DEPLOYED** | Connected to project `https://lqegmqgkymstycpzplld.supabase.co`. Migrations applied. |
| **Backend API** | Render / Railway / Docker | **LOCAL DEVELOPMENT** | Runs locally via `uvicorn backend.app.main:app` on port 8000. Dockerfile planned. |
| **Authority Console**| Vercel | **LOCAL DEVELOPMENT** | Next.js 14 App Router ready for zero-config Vercel deployment. |
| **Passenger Shell** | Web App / Flutter build | **LOCAL DEVELOPMENT** | Running responsive Next.js mobile web shell on port 3000. |
| **Driver Shell** | Web App / Flutter build | **LOCAL DEVELOPMENT** | Running responsive Next.js cockpit shell on port 3000. |

---

## 3. Production Deployment Checklist

Before moving to public production deployment:
- [ ] Transition `DEMO_MODE=False` in `.env`.
- [ ] Connect physical GPS telematics feeds from KSRTC fleet.
- [ ] Configure production Razorpay API keys and verify automated webhook callbacks.
- [ ] Tighten CORS origin list to registered domain names.
- [ ] Deploy containerized FastAPI application with multiple Uvicorn worker threads.
- [ ] Establish automated database backups on Supabase.
