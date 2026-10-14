# BusSense AI — GPS & Real-Time Tracking Architecture

This document describes the location tracking, waypoint interpolation, arrival time estimation, and real-time synchronization pipelines in BusSense AI.

---

## 1. Implemented vs. Planned Capabilities

| Capability | Current Prototype Status | Production Architecture |
|---|---|---|
| **Vehicle Positioning** | **Implemented (Corridor Simulator)** | Hardware GNSS/GPS receivers emitting NMEA 0183 / GPRMC sent over MQTT. |
| **Corridor Coordinate Paths**| **Implemented** (Kochi transit arteries) | Spatial GeoJSON line strings along National Highways and bypasses. |
| **Arrival ETA Calculation** | **Implemented** (Haversine + Circuity) | Real-time traffic layer speed matrix (Google Maps Platform / Openrouteservice). |
| **Telemetry WebSockets** | **Implemented** (`/ws/telemetry`) | Scaled Redis Pub/Sub cluster + FastAPI WebSockets. |
| **Database Sync** | **Implemented** (Supabase PostgREST) | Supabase Realtime PostgreSQL Change Data Capture (CDC). |
| **Offline Drift Tolerance** | **Implemented** (Local extrapolation) | Conductor device SQLite queue with background re-sync. |

---

## 2. Kerala Transit Corridors & Waypoint Engine

The simulator (`backend/app/services/gps_simulator.py`) models authentic transit corridors in the Greater Kochi metropolitan area:

```
[Aluva Regional Terminal]
           │ (NH 544 Corridor)
           ▼
[Kalamassery Premier Jn]
           │
           ▼
[Edappally Toll / Jn] ─────────┐
           │                   │
           ▼                   ▼ (Civil Line Road)
[Palarivattom Jn]        [Kakkanad Infopark Phase 1 & 2]
           │
           ▼
[Kaloor Central Stand]
           │ (MG Road Corridor)
           ▼
[Vyttila Mobility Hub] (Intermodal Metro/Water Metro Interchange)
```

### Motion Physics Rules:
- **Corridor Cruising:** 32–48 km/h along arterial bypass corridors.
- **Approach Deceleration:** Smooth cubic damping as distance to approaching stop drops under 200 meters.
- **Stop Dwell Time:** Fixed 30–60 second halt simulating passenger passenger door boarding cycles.

---

## 3. Dynamic ETA Calculation

The expected arrival time at an upcoming stop is computed using the spherical Haversine formula adjusted for urban road circuity:

$$\Delta\sigma = 2 \arcsin \left( \sqrt{\sin^2\left(\frac{\Delta\phi}{2}\right) + \cos(\phi_1)\cos(\phi_2)\sin^2\left(\frac{\Delta\lambda}{2}\right)} \right)$$

$$\text{distance\_km} = R \times \Delta\sigma \times 1.25 \quad (\text{where } R = 6371 \text{ km})$$

$$\text{ETA\_minutes} = \max\left(1, \text{round}\left(\frac{\text{distance\_km}}{\max(15, \text{current\_speed\_kmh})} \times 60\right)\right)$$

---

## 4. Real-Time Synchronization Hierarchy

To ensure uninterrupted service under fluctuating mobile network connectivity (e.g., under flyovers or dense trees):

1. **Tier 1 (Active WebSocket Stream):** The client maintains a persistent connection to `ws://localhost:8000/ws/telemetry`. New vehicle coordinate vectors are pushed every 2.0 seconds.
2. **Tier 2 (HTTP Polling Fallback):** If WebSocket handshakes drop due to corporate proxies or firewall policies, the frontend client falls back to 5.0-second HTTP polling against `GET /api/buses`.
3. **Tier 3 (Client-side Dead Reckoning):** During brief 10–15 second disconnections, the client HUD smoothly advances the bus icon along the corridor vector using its last known velocity.
