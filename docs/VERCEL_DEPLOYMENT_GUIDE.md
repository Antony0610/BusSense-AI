# BusSense AI — Vercel Deployment Guide
## Complete Guide for Deploying the Authority Command Center on Vercel

**Document Version:** 1.0.0-H22  
**Target Platform:** Vercel Edge Network  
**Application:** Next.js 14 Authority Command Center (`frontend/`)  
**Target Domains:** `admin.bussense.ai` / `bussense-ai.vercel.app`  
**Date:** November 2026

---

## 1. Prerequisites
- Vercel account ([https://vercel.com](https://vercel.com)).
- GitHub repository access: `https://github.com/Antony0610/BusSense-AI.git`.
- Active Supabase Cloud Project: `https://lqegmqgkymstycpzplld.supabase.co`.

---

## 2. Step-by-Step Vercel Setup

### Step 1: Connect GitHub Repository
1. Log in to your Vercel Dashboard.
2. Click **Add New...** ➔ **Project**.
3. Import the Git repository `Antony0610/BusSense-AI`.
4. Select the default branch: `master`.

### Step 2: Configure Project Root Directory
1. In the **Configure Project** screen, locate **Root Directory**.
2. Click **Edit** and set Root Directory to:
   ```text
   frontend
   ```
3. Vercel automatically detects Next.js framework defaults.

### Step 3: Framework & Build Settings
Verify the build configuration:
- **Framework Preset:** Next.js
- **Build Command:** `npm run build` (or default `next build`)
- **Output Directory:** `.next`
- **Install Command:** `npm ci --prefer-offline --no-audit`
- **Node.js Version:** 18.x or 20.x

### Step 4: Environment Variables Configuration
Under **Environment Variables**, add the following production variables:

| Variable Name | Environment | Value | Description |
| :--- | :---: | :--- | :--- |
| `NEXT_PUBLIC_SUPABASE_URL` | Production / Preview | `https://lqegmqgkymstycpzplld.supabase.co` | Supabase Cloud API host |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Production / Preview | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` | Public client anon key |
| `NEXT_PUBLIC_API_URL` | Production / Preview | `https://lqegmqgkymstycpzplld.supabase.co/functions/v1/api` | Supabase Edge Function Gateway |
| `NEXT_PUBLIC_WS_URL` | Production / Preview | `wss://lqegmqgkymstycpzplld.supabase.co/realtime/v1/websocket?apikey=...&vsn=1.0.0` | Realtime WebSocket Ingress |

*(Values are documented in `frontend/.env.example`).*

### Step 5: Configure Supabase Auth Redirect URLs
In the Supabase Dashboard:
1. Navigate to **Authentication** ➔ **URL Configuration**.
2. Set **Site URL** to your Vercel production URL (e.g. `https://admin.bussense.ai`).
3. Add **Redirect URLs**:
   - `https://admin.bussense.ai/**`
   - `https://*.vercel.app/**`
   - `http://localhost:3000/**` (for local development)

### Step 6: Deploy Project
1. Click **Deploy**.
2. Vercel compiles all 22 static and dynamic App Router routes.
3. Build completes in approximately 45–60 seconds.

---

## 3. Production Custom Domain Configuration

To connect a custom government or authority domain (e.g., `admin.bussense.ai`):
1. Navigate to **Settings** ➔ **Domains** in your Vercel project.
2. Enter `admin.bussense.ai` and click **Add**.
3. In your DNS provider (e.g. Cloudflare / Route 53):
   - Add a `CNAME` record: `admin` pointing to `cname.vercel-dns.com`.
4. Vercel automatically issues an SSL certificate with automatic TLS 1.3 renewal.

---

## 4. Post-Deployment Verification Checklist

Verify the deployed dashboard:
- [ ] **Homepage & Login:** Visit root URL `/` and verify sign-in modal loads.
- [ ] **Fleet Command Center:** Visit `/authority/command` and confirm live leaflet map renders Route 205 and 14A corridor overlays.
- [ ] **Fleet Telemetry:** Confirm vehicle markers render current crowd tiers (`LOW`, `MODERATE`, `CROWDED`).
- [ ] **AI Operations Queue:** Visit `/authority/ai-ops` and verify headway recommendations display explainability text.
- [ ] **Pilot Monitoring HUD:** Visit `/authority/reports` and confirm data freshness and live vs simulated badges render accurately.
- [ ] **Responsive Navigation:** Verify desktop and tablet sidebars collapse smoothly.

---

## 5. Instant Rollback Procedure

If a deployed version causes runtime issues or regressions:
1. Go to **Deployments** in your Vercel project.
2. Locate the previous healthy deployment.
3. Click the **...** menu ➔ **Promote to Production** (or **Rollback**).
4. Vercel instantly routes 100% of incoming production traffic to the previous deployment without downtime.

---
*BusSense AI Vercel Deployment Guide — Version 1.0.0-H22*
