# BusSense AI — Vercel Deployment & Verification Guide
## Complete Guide for Deploying the Authority Command Center on Vercel

**Document Version:** 1.1.1-H23  
**Target Platform:** Vercel Edge Network  
**Application:** Next.js 14 Authority Command Center (`frontend/`)  
**Target Domains:** `admin.bussense.ai` / `bussense-ai.vercel.app`  
**Date:** November 2026  
**Build Status:** 22/22 ROUTES COMPILED (0 Errors)  

---

## 1. Prerequisites
- Vercel account ([https://vercel.com](https://vercel.com)).
- GitHub repository access: `https://github.com/Antony0610/BusSense-AI.git`.
- Active Supabase Cloud Project: `https://lqegmqgkymstycpzplld.supabase.co`.

---

## 2. Step-by-Step Vercel Setup

### Method A: Web Console (Recommended for Continuous Deployment)
1. Log in to your Vercel Dashboard at [vercel.com](https://vercel.com).
2. Click **Add New...** ➔ **Project**.
3. Import the Git repository `Antony0610/BusSense-AI`.
4. Select the default branch: `master`.
5. Set **Root Directory** to `frontend`.
6. Add the following production environment variables:

| Variable Name | Environment | Value | Description |
| :--- | :---: | :--- | :--- |
| `NEXT_PUBLIC_SUPABASE_URL` | Production / Preview | `https://lqegmqgkymstycpzplld.supabase.co` | Supabase Cloud API host |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Production / Preview | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` | Public client anon key |
| `NEXT_PUBLIC_API_URL` | Production / Preview | `https://lqegmqgkymstycpzplld.supabase.co/functions/v1/api` | Supabase Edge Function Gateway |
| `NEXT_PUBLIC_WS_URL` | Production / Preview | `wss://lqegmqgkymstycpzplld.supabase.co/realtime/v1/websocket?apikey=...&vsn=1.0.0` | Realtime WebSocket Ingress |

7. Click **Deploy**.

### Method B: Vercel CLI Deployment
```bash
# 1. Log in to Vercel via CLI
npx vercel login

# 2. Deploy frontend directory directly to production
npx vercel --prod --cwd frontend
```

---

## 3. Verified Build Verification (Phase H23)

The production build was compiled and validated locally prior to cloud deployment:
- **Build Output:**
  - 22 / 22 static pages generated.
  - Zero webpack errors or TypeScript typecheck errors.
  - Total shared First Load JS: 87.3 kB.
- **Route Inventory:**
  - `/` (Role selector)
  - `/authority/command` (Fleet Commander HUD)
  - `/authority/fleet` (Vehicle Inspector)
  - `/authority/routes` (Corridor Management)
  - `/authority/forecast` (Ridge Demand Curves)
  - `/authority/alerts` (Disruption Triage)
  - `/authority/reports` (Punctuality & Carbon Offsets)
  - `/authority/ai-ops` (Advisory Decision Queue)
  - `/passenger/*` (Explore, Journey, Tickets, Profile, Assistant)
  - `/driver/*` (Cockpit, Validator, Layover, Incident)

---

## 4. Custom Domain & DNS Setup

To assign the production custom domain `admin.bussense.ai`:
1. In Vercel Project Settings ➔ **Domains**, add `admin.bussense.ai`.
2. Configure your DNS provider:
   - **CNAME:** `admin.bussense.ai` ➔ `cname.vercel-dns.com`
   - Or **A Record:** `@` ➔ `76.76.21.21`
3. Wait for automatic TLS certificate issuance.

---

## 5. Supabase Auth Redirect URLs

In the Supabase Dashboard:
1. Navigate to **Authentication** ➔ **URL Configuration**.
2. Set **Site URL** to your verified Vercel production URL (e.g. `https://admin.bussense.ai` or `https://bussense-ai.vercel.app`).
3. Add **Redirect URLs**:
   - `https://admin.bussense.ai/**`
   - `https://bussense-ai.vercel.app/**`

---
*BusSense AI Vercel Deployment Guide — Version 1.1.1-H23*
