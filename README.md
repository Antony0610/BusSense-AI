# 🚍 BusSense AI: Next-Gen Intelligent Transit Platform

> **Autonomous AI-Driven Transit Rebalancing, Direct Supabase Cloud Backend, and PetConnect AI Glassmorphic Architecture for Kerala Public & Private Mobility**

[![Supabase Cloud](https://img.shields.io/badge/Supabase%20Cloud-PostgreSQL%2016%20%2B%20PostGIS-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![Flutter Native](https://img.shields.io/badge/Flutter-3.x%20ARM64%20Release-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Vercel Deployment](https://img.shields.io/badge/Vercel-Zero--Build%20Ready-black?logo=vercel&logoColor=white)](https://vercel.com)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Zero Local Daemons](https://img.shields.io/badge/Backend-100%25%20Serverless%20Cloud-00F0FF)](https://supabase.com)
[![Security Hardened](https://img.shields.io/badge/Supabase%20Security-RLS%20%26%20RPC%20Hardened-00FF9D)](https://supabase.com)

**BusSense AI** is a cyber-transit mobility ecosystem designed for the high-density public transport corridors of Kerala (Thiruvananthapuram, Technopark, Kochi, and Kozhikode). Built with a **100% Direct Supabase Cloud Backend** (zero local server daemons) and an ultra-premium **PetConnect AI Glassmorphic Interface**, it unifies everyday commuter ticketing, autonomous electric fleet congestion rebalancing, and conductor cryptographic QR validation into a single platform.

---

## 🏗️ System Architecture (100% Direct Supabase Cloud)

```mermaid
flowchart TD
    subgraph Clients["📱 Modern Client Applications (PetConnect AI Design)"]
        Flutter["Flutter Mobile App (mobile_app_flutter/)\nNative Android ARM64 APK & iOS\nObsidian Bottom Dock & Provider State"]
        Web["Web PWA (app/)\nDeclarative Hash Router & Web Audio Synth\nDirect @supabase/supabase-js v2 Client"]
    end

    subgraph SupabaseCloud["☁️ Supabase Cloud (ap-south-1) - Zero Local Daemons"]
        direction TB
        RPC1["fn_get_live_fleet()\nPostGIS Realtime Fleet Telemetry"]
        RPC2["fn_book_ticket(...)\nAtomic 2x2 Seat Booking & 20% Green Discount"]
        RPC3["fn_verify_ticket(...)\nConductor Cryptographic QR Hash Validation"]
        RPC4["fn_dispatch_relief_bus(...)\nAutonomous AI Congestion Relief Dispatch"]
        RPC5["fn_broadcast_sos(...)\n1-Tap Emergency Distress Beacon to Police 112"]
        Tables[("PostgreSQL 16 Tables:\nbuses, routes, tickets, dispatch_logs, sos_alerts, profiles")]
        Auth["Supabase GoTrue Auth\nCommuter & Dispatcher Role Management"]
    end

    subgraph EdgeAI["📹 On-Bus Edge Computer Vision"]
        YOLO["YOLOv8 Edge Computer\nCounts passengers & automatically blurs faces for privacy"]
    end

    Flutter -->|HTTPS REST & Realtime WS| SupabaseCloud
    Web -->|HTTPS REST & Realtime WS| SupabaseCloud
    EdgeAI -->|Automated Telemetry Feed| SupabaseCloud
```

---

## 🧭 PetConnect AI Screen & Routing Flow

The platform utilizes a dual-portal architecture separating everyday passengers from transit authorities:

```mermaid
graph TD
    Gateway["/ (Root Gateway Portal)\nSplit Welcome Cards: Commuter vs Dispatcher"]
    
    Gateway -->|Commuter Access| PassAuth["/auth/passenger\nDedicated Passenger Login & Profile Setup"]
    Gateway -->|Authority Access| AdminAuth["/auth/admin\nDedicated High-Security Dispatcher Terminal"]
    
    PassAuth -->|Authenticate| Radar["/passenger\nLive Kerala Bus Radar & PostGIS Map"]
    AdminAuth -->|Authenticate| Command["/authority/command\nIn-App Fleet Command HUD"]
    
    subgraph CommuterExperience["Commuter Portal (Obsidian Bottom Dock)"]
        Radar -->|Select Bus| Booking["/passenger/book/:busId\nInteractive 2x2 40-Seat Reservation"]
        Booking -->|Confirm Booking| Pass["/passenger/ticket\nSmart Holographic Boarding Pass"]
        Radar --> Wallet["/passenger/wallet\nEcoPass CO₂ Wallet & Green Perks"]
        Radar --> PassSettings["/passenger/settings\nBilingual, Geofence Alarm & Sound FX"]
        Radar --> SOS["/sos\n1-Tap Emergency Distress Beacon"]
    end

    subgraph AuthorityExperience["Authority Dispatcher Portal (Obsidian Bottom Dock)"]
        Command --> Scanner["/authority/verify\nConductor Laser QR Ticket Validator"]
        Command --> AdminSettings["/authority/settings\nSurge Threshold Slider & CCTV Privacy Blur"]
        Command --> ExitToGateway["Exit to Gateway /"]
    end
```

---

## 🌟 Core Features & Modules

### 1. 100% Direct Supabase Cloud Backend (Zero Local Daemons)
- **Zero Local Python Backend**: No local FastAPI or uvicorn servers required. All operations run directly against Supabase Cloud PostgreSQL 16 (`kxeixcnqoudxicorxlxs.supabase.co`).
- **5 Atomic Stored RPC Functions**:
  1. `fn_get_live_fleet()`: Real-time bus telemetry with PostGIS coordinates, Malayalam LED text, occupancy percentage, and speed.
  2. `fn_book_ticket(...)`: Atomically reserves seats, calculates 20% off-peak green discounts, updates capacity, and outputs cryptographic QR hashes.
  3. `fn_verify_ticket(...)`: Conductor QR verification marking tickets as `used` with instant anti-fraud duplicate scan rejection.
  4. `fn_dispatch_relief_bus(...)`: Stages and logs electric relief buses in `dispatch_logs` during corridor crowding surges (>85%).
  5. `fn_broadcast_sos(...)`: Records emergency alerts and streams coordinates to Kerala Police 112.

### 2. PetConnect-Style Dedicated Settings Screens
- **Commuter Profile Card**: Tier badges (*Silver Eco-Commuter • BusSense Kerala*), EcoPass points counter, and lifetime CO₂ savings.
- **Bilingual Interface Switcher**: English and Malayalam (`മലയാളം`) toggle across all cards, markers, and buttons.
- **Procedural Web Audio API Synthesizer**: Procedurally synthesizes retro-futuristic acoustic waveforms for the Wake-Up Chime, Ticket Validation Beep, and SOS Siren without downloading external audio files.
- **Smart Geofence Wake-Up Alarm**: Radial distance selector chips (`300m`, `500m`, `1.0 km`) triggering proximity alerts before reaching destination stops.
- **Cloud Engine Diagnostics**: Real-time ping gauge (`🟢 Connected to Supabase Cloud, Latency: 24ms`).

### 3. EcoPass CO₂ Carbon Wallet (`/passenger/wallet`)
- **Carbon Offset Metrics**: Tracks kilograms of CO₂ avoided by choosing buses over private cars (e.g. 18.2 kg CO₂ saved, equivalent to 1.4 trees planted).
- **Redeemable Transit Perks**:
  - **20% Off-Peak Voucher** (50 pts): Generates instant discount vouchers (`ECO-XXXXXX`).
  - **1 Free Electric City Hop** (100 pts): Free travel on Thiruvananthapuram City Electric Swift buses.
  - **KSRTC Swift Priority Pass** (250 pts): Advance boarding guarantee on peak IT corridor routes.
- **Carbon Reduction Ledger**: Complete transaction history of trip-by-trip green savings.

### 4. Conductor Smart QR Validator (`/authority/verify`)
- **Laser Viewfinder HUD**: Viewfinder frame with cyber alignment brackets and animated laser scanning beam.
- **One-Tap Verification**: `📋 Paste Latest Booked Ticket` button for rapid testing and conductor verification.
- **Live Boarding Receipt Hologram**: Displays **`AUTHORIZED BOARDING`** or **`TICKET ALREADY USED`** stamps with seat number, bus ID, corridor, and conductor badge.

### 5. Floating Frosted Navigation Dock (`ObsidianBottomDock`)
- Glassmorphic navigation dock with active glowing pill indicator:
  - **Commuter Mode**: `Radar`, `Pass`, `EcoPass`, `Settings`, `SOS`.
  - **Authority Mode**: `HUD`, `Verify QR`, `Config`, `Exit`.

---

## 📱 Screen & Route Matrix

| Route (Web & Flutter) | Screen Component | Key Capabilities |
| :--- | :--- | :--- |
| `#/` / `/` | `GatewayScreen` | Split gateway portal (Commuter vs Dispatcher) with live cloud network status. |
| `#/auth/passenger` / `/auth/passenger` | `PassengerLoginScreen` | Commuter sign-in, preference corridor picker, +50 EcoPoints welcome bonus. |
| `#/auth/admin` / `/auth/admin` | `AuthorityLoginScreen` | Dispatcher terminal, passkey verification, depot badge selector, demo 1-click access. |
| `#/passenger` / `/passenger` | `PassengerScreen` | Live bus tracking radar, corridor filters, crowd badges, ETA, and `ObsidianBottomDock`. |
| `#/passenger/book/:busId` / `/passenger/book` | `SeatBookingScreen` | 40-seat interactive 2x2 layout, 20% off-peak green discount, atomic booking via `fn_book_ticket`. |
| `#/passenger/ticket/:ticketId` / `/passenger/ticket` | `TicketPassScreen` | Holographic digital boarding pass with cryptographic QR code (`qr_flutter` / `qrcodejs`). |
| `#/passenger/wallet` / `/passenger/wallet` | `EcoWalletScreen` | EcoPass green points (170 pts), CO₂ offset metrics (18.2 kg), redeemable perks, and carbon ledger. |
| `#/passenger/settings` / `/passenger/settings` | `PassengerSettingsScreen` | Commuter preferences, audio synth audition, bilingual toggle, geofence radius. |
| `#/authority/command` / `/authority/command` | `AuthorityDashboardScreen` | Dispatcher HUD, live fleet telemetry via `fn_get_live_fleet`, 1-tap relief bus deployment via `fn_dispatch_relief_bus`. |
| `#/authority/verify` / `/authority/verify` | `ConductorVerifyScreen` | Laser QR ticket verification viewfinder calling Supabase RPC `fn_verify_ticket`. |
| `#/authority/settings` / `/authority/settings` | `AuthoritySettingsScreen` | Surge threshold slider, autonomous backup rules, privacy CCTV blurring toggle. |
| `#/sos` / `/sos` | `SosBeaconScreen` | Emergency distress beacon with procedural audio siren broadcasting to `fn_broadcast_sos`. |

---

## 🛠️ Build, Run & Deployment

### A. Mobile Application (Flutter Native)

```powershell
cd mobile_app_flutter

# 1. Fetch dependencies
flutter pub get

# 2. Analyze code (0 errors, 0 warnings enforced)
flutter analyze

# 3. Run unit & widget smoke tests
flutter test

# 4. Build Production Release APK
flutter build apk --release
```
- **Generated Release APK**: `mobile_app_flutter/build/app/outputs/flutter-apk/app-release.apk`

### B. Web PWA (Zero-Build Cloud Ready)

```powershell
# Local testing
python -m http.server 3000 --directory app --bind 127.0.0.1
```
- Open `http://127.0.0.1:3000/#/` in your browser.
- **Vercel Cloud Deployment**: Pre-configured via `vercel.json`. Push to GitHub and deploy in 1-click on [vercel.com/new](https://vercel.com/new) with zero build configuration needed.

---

## 🛡️ Database & Security Hardening

- **Supabase Cloud Project**: `kxeixcnqoudxicorxlxs` (Region: `ap-south-1` Mumbai)
- **Immutable Search Paths**: All stored procedures explicitly enforce `SET search_path = public, pg_temp;` to prevent security definer hijacking.
- **Covering Foreign Key Indexes**: Covering B-tree indexes added to `dispatch_logs`, `passenger_reports`, `sos_alerts`, and `tickets`.
- **Subselect RLS Optimization**: All Row-Level Security policies evaluate `(select auth.uid())` once per statement for optimal query performance at scale.

---

## 📄 License
This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
