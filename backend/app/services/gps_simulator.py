"""
BusSense AI - GPS Corridors & Movement Simulation Engine
Simulates realistic movement of buses along Kerala road corridors with waypoint interpolation,
live speed variance, stop arrival events, and passenger flux.
"""
import math
import random
from typing import Dict, List, Any
from app.schemas.common import DataOrigin, CrowdLevel
from app.services.cv_occupancy import cv_occupancy_service

# Predefined waypoints along Kerala Corridors
CORRIDORS = {
    "R12_205": {
        "route_number": "205",
        "route_name": "Aluva Metro ➔ Vyttila Mobility Hub via Kaloor",
        "waypoints": [
            {"stop": "Aluva Metro Station", "lat": 10.1076, "lng": 76.3533},
            {"stop": "En route Kalamassery", "lat": 10.0810, "lng": 76.3365},
            {"stop": "Kalamassery Premier Junction", "lat": 10.0544, "lng": 76.3197},
            {"stop": "Edappally Toll & Lulu Terminal", "lat": 10.0261, "lng": 76.3086},
            {"stop": "Palarivattom Bypass Junction", "lat": 10.0075, "lng": 76.3115},
            {"stop": "Kaloor Metro Station & Bus Stand", "lat": 9.9922, "lng": 76.2974},
            {"stop": "En route Kadavanthra", "lat": 9.9780, "lng": 76.3050},
            {"stop": "Vyttila Mobility Hub", "lat": 9.9678, "lng": 76.3182}
        ]
    },
    "R12_14A": {
        "route_number": "14A",
        "route_name": "Fort Kochi ➔ Infopark Phase 1 via Kaloor",
        "waypoints": [
            {"stop": "Fort Kochi Boat Jetty", "lat": 9.9675, "lng": 76.2425},
            {"stop": "MG Road North", "lat": 9.9865, "lng": 76.2842},
            {"stop": "Kaloor Metro Station & Bus Stand", "lat": 9.9922, "lng": 76.2974},
            {"stop": "Palarivattom Bypass Junction", "lat": 10.0075, "lng": 76.3115},
            {"stop": "Kakkanad Civil Station", "lat": 10.0159, "lng": 76.3456},
            {"stop": "Infopark Phase 1 Express Bay", "lat": 10.0102, "lng": 76.3618}
        ]
    }
}

class GpsSimulationEngine:
    def __init__(self):
        # In-memory fleet states
        self.fleet_state = {
            "205": {
                "bus_id": "a1111111-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
                "bus_number": "205",
                "registration_number": "KL-15-A-2051",
                "operator_type": "KSRTC",
                "corridor_key": "R12_205",
                "current_waypoint_idx": 4, # Near Kaloor
                "step_progress": 0.3, # 30% between Palarivattom and Kaloor
                "passenger_count": 23, # 41.8% occupancy (featured in Stitch screen)
                "capacity": 55,
                "speed_kmh": 34.0,
                "heading_deg": 195.0,
                "is_ac": False
            },
            "14A": {
                "bus_id": "b2222222-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
                "bus_number": "14A",
                "registration_number": "KL-07-CF-1402",
                "operator_type": "PRIVATE",
                "corridor_key": "R12_14A",
                "current_waypoint_idx": 1,
                "step_progress": 0.7,
                "passenger_count": 39, # 86.7% occupancy (CROWDED)
                "capacity": 45,
                "speed_kmh": 22.0,
                "heading_deg": 85.0,
                "is_ac": False
            },
            "12": {
                "bus_id": "e5555555-eeee-eeee-eeee-eeeeeeeeeeee",
                "bus_number": "12",
                "registration_number": "KL-07-BW-1209",
                "operator_type": "KSRTC",
                "corridor_key": "R12_14A",
                "current_waypoint_idx": 3,
                "step_progress": 0.4,
                "passenger_count": 34, # 61.8% occupancy (MODERATE)
                "capacity": 55,
                "speed_kmh": 38.0,
                "heading_deg": 75.0,
                "is_ac": False
            }
        }

    def tick_simulation(self):
        """Advances buses smoothly along their Kerala corridor route"""
        for bus_key, bus in self.fleet_state.items():
            corridor = CORRIDORS[bus["corridor_key"]]
            wps = corridor["waypoints"]
            
            # Progress increment
            bus["step_progress"] += 0.05
            if bus["step_progress"] >= 1.0:
                bus["step_progress"] = 0.0
                bus["current_waypoint_idx"] = (bus["current_waypoint_idx"] + 1) % (len(wps) - 1)
                
                # Passenger boarding/alighting flux at stops (only apply if bus is not in CV_REPLAY mode)
                if bus.get("data_origin") != DataOrigin.CV_REPLAY:
                    flux = random.randint(-4, 5)
                    bus["passenger_count"] = max(10, min(bus["capacity"], bus["passenger_count"] + flux))

            # Dynamic speed simulation
            bus["speed_kmh"] = round(max(15.0, min(55.0, bus["speed_kmh"] + random.uniform(-2.5, 2.5))), 1)

    def update_from_cv_event(
        self,
        bus_number: str,
        passenger_count: int,
        capacity: int,
        occupancy_pct: float,
        crowd_level: str,
        detection_source: str = "YOLOv8n_CV_Replay"
    ) -> bool:
        """
        Updates in-memory fleet state with validated CV replay occupancy data.
        Stamps data_origin as CV_REPLAY.
        """
        if bus_number in self.fleet_state:
            bus = self.fleet_state[bus_number]
            bus["passenger_count"] = passenger_count
            bus["capacity"] = capacity
            bus["occupancy_pct"] = occupancy_pct
            bus["crowd_level"] = crowd_level
            bus["detection_source"] = detection_source
            bus["data_origin"] = DataOrigin.CV_REPLAY
            return True
        return False

    def get_bus_telemetry(self, bus_number: str) -> Dict[str, Any]:
        """Calculates exact coordinates and ETA for a bus"""
        bus = self.fleet_state.get(bus_number)
        if not bus:
            return {}

        corridor = CORRIDORS[bus["corridor_key"]]
        wps = corridor["waypoints"]
        curr_idx = bus["current_waypoint_idx"]
        next_idx = min(curr_idx + 1, len(wps) - 1)

        p1 = wps[curr_idx]
        p2 = wps[next_idx]

        alpha = bus["step_progress"]
        lat = round(p1["lat"] + (p2["lat"] - p1["lat"]) * alpha, 6)
        lng = round(p1["lng"] + (p2["lng"] - p1["lng"]) * alpha, 6)

        # ETA calculation based on remaining distance and current speed
        if bus.get("override_eta_mins") is not None:
            eta_mins = max(1, int(bus["override_eta_mins"]))
        else:
            dist_km = math.sqrt((p2["lat"] - lat)**2 + (p2["lng"] - lng)**2) * 111.0
            eta_mins = max(1, int(round((dist_km / max(bus["speed_kmh"], 15.0)) * 60)))

        if bus.get("override_occupancy_pct") is not None:
            occupancy_pct = float(bus["override_occupancy_pct"])
            crowd_level = CrowdLevel.CROWDED if occupancy_pct >= 75.0 else (CrowdLevel.MODERATE if occupancy_pct >= 40.0 else CrowdLevel.LOW)
            origin = bus.get("data_origin", DataOrigin.SIMULATED)
            detection_source = bus.get("detection_source", "Simulated_Override")
        elif bus.get("data_origin") == DataOrigin.CV_REPLAY:
            occupancy_pct = bus.get("occupancy_pct", round((bus["passenger_count"] / bus["capacity"]) * 100.0, 1))
            crowd_level = bus.get("crowd_level", "LOW")
            origin = DataOrigin.CV_REPLAY
            detection_source = bus.get("detection_source", "YOLOv8n_CV_Replay")
        else:
            occupancy_info = cv_occupancy_service.process_frame(
                current_passenger_count=bus["passenger_count"]
            )
            occupancy_pct = occupancy_info["occupancy_percentage"]
            crowd_level = occupancy_info["crowd_level"]
            origin = DataOrigin.SIMULATED
            detection_source = "Simulated_Camera_YOLOv8"

        return {
            "bus_id": bus["bus_id"],
            "bus_number": bus["bus_number"],
            "registration_number": bus["registration_number"],
            "operator_type": bus["operator_type"],
            "route_number": corridor["route_number"],
            "route_name": corridor["route_name"],
            "capacity": bus["capacity"],
            "passenger_count": bus["passenger_count"],
            "occupancy_pct": occupancy_pct,
            "crowd_level": crowd_level,
            "speed_kmh": bus["speed_kmh"],
            "heading_deg": bus["heading_deg"],
            "latitude": lat,
            "longitude": lng,
            "current_stop": p1["stop"],
            "next_stop": p2["stop"],
            "eta_next_stop_mins": eta_mins,
            "is_ac": bus["is_ac"],
            "safety_score": 98.8 if bus["bus_number"] == "205" else 96.2,
            "data_origin": origin,
            "detection_source": detection_source
        }

    def get_all_buses(self) -> List[Dict[str, Any]]:
        return [self.get_bus_telemetry(k) for k in self.fleet_state.keys()]

gps_simulator = GpsSimulationEngine()
