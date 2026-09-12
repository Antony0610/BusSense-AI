# 🏛️ BusSense AI 2.0: System Architecture & Technical Specifications

> **System Topology, Data Pipelines, PostGIS Models & Security Specifications**

---

## 🏗️ 1. End-to-End System Topology

```mermaid
flowchart TD
    subgraph EdgeLayer["🚍 Vehicle & Edge IoT Layer"]
        CCTV["Bus CCTV Camera (RTSP / Video Stream)"]
        GPS["GPS Telematics Tracker"]
        YOLO["YOLOv8 Edge AI\n(Person-Class Ingestion & Face/Plate Blurring)"]
        Scanner["Conductor QR Validator App"]
        Transmitter["Edge Ingest Client (HTTPS + API Key)"]
        
        CCTV --> YOLO
        GPS --> Transmitter
        YOLO -->|Passenger Count Delta| Transmitter
        Scanner -->|Validate QR Ticket| Transmitter
    end

    subgraph SupabaseCloud["⚡ Supabase Core Platform"]
        Auth["Supabase Auth (JWT)\nRoles: passenger | authority_admin"]
        Postgres[("PostgreSQL 16 + PostGIS\nSpatial Tables & Geometries")]
        RLS["Row Level Security Engine"]
        Realtime["Supabase Realtime\n(PostgreSQL CDC WebSockets)"]
        
        Transmitter -->|Ingest Telemetry| Postgres
        Postgres <--> RLS <--> Auth
        Postgres -->|Change Data Capture| Realtime
    end

    subgraph AIEngine["🧠 FastAPI AI & Analytics Engine"]
        ML_Forecaster["Pre-Trained ML Demand Forecaster\n(Random Forest, <15ms Inference)"]
        Rebalance_AI["Autonomous Fleet Rebalancer\n(Route Supply/Demand Balancing)"]
        Telemetry_Sim["Physics-Based Telemetry & Dwell Simulator"]
        
        Postgres <--> ML_Forecaster
        Postgres <--> Rebalance_AI
        Telemetry_Sim -->|Live Pings| Postgres
    end

    subgraph ClientLayer["✨ Client Applications (Anti-AI-Slop UI/UX)"]
        AdminHUD["🏢 Authority Command Center\n(Obsidian Glassmorphism HUD + SVG Bus Sprites)"]
        PassengerApp["📱 Passenger Mobile App\n(Flutter 3 Native + Mobile Web PWA)"]
        
        Realtime <==>|Live Telemetry WebSockets| AdminHUD
        Realtime <==>|Live Crowd Radar WebSockets| PassengerApp
        Auth <--> AdminHUD
        Auth <--> PassengerApp
    end
```

---

## 🗄️ 2. PostGIS Spatial Architecture & Data Flow

### A. Route Geometries (`public.routes`)
Routes are stored as spatial `GEOMETRY(LineString, 4326)` representing the exact vehicular road corridor across Kerala (e.g. Route R1: Thampanoor ➔ Technopark via MG Road & NH 66).

```sql
-- Spatial Query: Find nearest bus stop to commuter within 500 meters
SELECT stop_name, route_number, 
       ST_Distance(location::geography, ST_SetSRID(ST_MakePoint(76.9366, 8.5241), 4326)::geography) AS distance_meters
FROM public.bus_stops
WHERE ST_DWithin(location::geography, ST_SetSRID(ST_MakePoint(76.9366, 8.5241), 4326)::geography, 500)
ORDER BY distance_meters ASC
LIMIT 1;
```

### B. Live Telemetry & 60fps Spline Interpolation
Each ping in `public.occupancy_telemetry` stores:
- `location`: PostGIS `Point(longitude, latitude)` with SRID 4326.
- `speed_kmh`: Current vehicle velocity used to calculate wheel rotation animation speeds.
- `heading_deg`: Gyroscopic azimuth (0–360°) used to rotate the SVG bus sprite along the driving direction.
- `crowd_tier`: Stored generated column (`GREEN` for &lt;50%, `YELLOW` for 50–80%, `RED` for &gt;80%).

---

## 🔐 3. Dual-Role Security & Row-Level Security (RLS) Model

Security is enforced at the database level using PostgreSQL Row-Level Security (RLS):

```mermaid
flowchart LR
    User["Client Request + Supabase JWT"] --> RLS{"PostgreSQL RLS Engine"}
    RLS -->|role = 'authority_admin'| AdminAllowed["Full Write / Dispatch / Fleet Control"]
    RLS -->|role = 'passenger'| PassengerAllowed["Book Own Tickets / View Live Radar / Trigger SOS"]
    RLS -->|Anon Public| PublicAllowed["Read Active Buses & Stops"]
```

### Access Control Matrix:
1. **`public.buses` & `public.routes`**:
   - `SELECT`: Open to everyone (commuters and dispatchers).
   - `INSERT / UPDATE / DELETE`: Strictly restricted to `authority_admin`.
2. **`public.tickets`**:
   - `INSERT`: Commuters can book tickets assigned to their own `user_id`.
   - `SELECT`: Commuters view their own tickets; authority dispatchers/conductors can view all tickets on a bus route for ticket validation.
   - `UPDATE`: Only `authority_admin` can mark tickets as `'used'` or `'cancelled'`.
3. **`public.sos_alerts`**:
   - `INSERT`: Any authenticated or unauthenticated emergency caller can broadcast SOS.
   - `SELECT`: Broadcasts live to `authority_admin` and the creator.
   - `UPDATE`: Only `authority_admin` can mark alerts as `'investigating'` or `'resolved'`.

---

## ⚡ 4. Real-Time Telemetry Pipeline (Supabase Realtime CDC)

BusSense AI 2.0 completely eliminates inefficient HTTP polling.
1. When an edge YOLOv8 camera detects passenger changes or GPS updates, it inserts into `public.occupancy_telemetry`.
2. PostgreSQL writes to the Write-Ahead Log (WAL).
3. Supabase Realtime detects the Change Data Capture (CDC) event and broadcasts it over WebSockets to channel:
   ```javascript
   supabase
     .channel('fleet-radar')
     .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'occupancy_telemetry' }, payload => {
       updateBusMarkerSmoothly(payload.new);
     })
     .subscribe();
   ```
4. Connected Authority Dashboards and Passenger Mobile Apps update their visual SVG markers, radial occupancy dials, and alert banners in sub-100ms.
