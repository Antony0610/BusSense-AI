# BusSense AI — Route & Corridor Knowledge Base
Document ID: KB-ROUTES
Category: ROUTE_AND_SCHEDULE
Version: 1.1.0
Last Verified: October 2026

## 1. Supported Corridor Routes
BusSense AI provides real-time intelligence across three monitored Greater Kochi transit corridors:
- **Corridor Coverage (Where does the bus go):** The monitored corridor routes connect Aluva, Kalamassery, Edappally, Kaloor, Palarivattom, Kakkanad, Fort Kochi, and Vyttila Mobility Hub.

### Route 205 — Fast Passenger Corridor Service
- **Operator:** KSRTC (Kerala State Road Transport Corporation)
- **Service Tier:** Fast Passenger (Limited Stop Express)
- **Origin:** Aluva Metro Station Terminal
- **Destination:** Vyttila Mobility Hub
- **Key Intermediary Stops:**
  1. Aluva Metro Station (0.0 km)
  2. En route Kalamassery (3.2 km)
  3. Kalamassery Premier Junction (6.4 km)
  4. Edappally Toll & Lulu Terminal (12.1 km)
  5. Palarivattom Bypass Junction (15.3 km)
  6. Kaloor Metro Station & Bus Stand (18.2 km)
  7. En route Kadavanthra (22.0 km)
  8. Vyttila Mobility Hub (24.8 km)
- **Corridor Advantage:** Operates via Banerji Road dedicated transit priority lane, yielding an 8 to 12 minute travel saving during peak traffic.
- **Operating Fleet:** 55-seat stage carriage vehicle with onboard occupancy estimation.

### Route 14A — Fort Kochi to Infopark Express Feeder
- **Operator:** Private Bus Consortium
- **Service Tier:** City Feeder Service
- **Origin:** Fort Kochi Boat Jetty
- **Destination:** Infopark Phase 1 Express Bay
- **Key Stops:** Fort Kochi, MG Road North, Kaloor Metro Station, Palarivattom Bypass, Kakkanad Civil Station, Infopark Phase 1.
- **Total Distance:** 26.5 km.
- **Fleet Capacity:** 45 passengers.

### Route 12 — Kaloor to Infopark Direct Corridor
- **Operator:** KSRTC
- **Service Tier:** IT Corridor Shuttle
- **Origin:** Kaloor Metro Station & Bus Stand
- **Destination:** Infopark Phase 1 Express Bay
- **Key Stops:** Kaloor Metro, Palarivattom Bypass, Kakkanad Civil Station, Infopark Phase 1.
- **Total Distance:** 15.9 km.
- **Fleet Capacity:** 55 passengers.

## 2. Route Planning & Corridor Boundaries
- **Supported Region:** Currently limited to Greater Kochi key corridors (Aluva, Kalamassery, Edappally, Kaloor, Palarivattom, Kakkanad, Fort Kochi, and Vyttila).
- **Unsupported Corridors:** Inter-district super-deluxe services, rural feeder routes, and routes outside Ernakulam district are not monitored in this prototype.
- **Directional Sensitivity:** Direct routing requires forward stop progression (e.g. Aluva to Vyttila on Route 205). Reverse journeys require reverse corridor vehicles.

## 3. ETA & Telemetry Limitations
- **ETA Computation:** Arrival countdowns are estimated from simulated GPS waypoint progression and historical corridor speeds.
- **Traffic Unpredictability:** Sudden roadblock diversions, unmonitored protest rallies, or severe waterlogging during monsoon downpours may introduce ETA variances.
- **Truth Labels:** All vehicle telemetry is stamped as `LIVE DATA`, `SIMULATED DATA`, or `ESTIMATE`.
