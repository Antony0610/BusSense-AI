"""Physics-based GPS movement simulator with velocity, heading, and stop dwell dynamics."""
from __future__ import annotations

import math
import time
from typing import NamedTuple

from backend.database import update_bus_telemetry


class Waypoint(NamedTuple):
    lat: float
    lon: float
    name: str


KERALA_CORRIDORS: dict[str, list[Waypoint]] = {
    "R1": [
        Waypoint(8.5241, 76.9366, "Thampanoor Central Stop"),
        Waypoint(8.5020, 76.9510, "Palayam Connemara Market"),
        Waypoint(8.5280, 76.9420, "Pattom Junction Stop"),
        Waypoint(8.5360, 76.9310, "Ulloor Bridge Stop"),
        Waypoint(8.5480, 76.9180, "Sreekaryam Junction"),
        Waypoint(8.5580, 76.8840, "Technopark Main Gate"),
    ],
    "R2": [
        Waypoint(8.4830, 76.9440, "East Fort Bus Terminal"),
        Waypoint(8.4720, 76.9520, "Attukal Temple Junction"),
        Waypoint(8.4480, 76.9610, "Thiruvallam Bridge"),
        Waypoint(8.4000, 76.9800, "Kovalam Light House"),
    ],
    "R3": [
        Waypoint(8.5280, 76.9420, "Pattom Junction"),
        Waypoint(8.5350, 76.9380, "Kesavadasapuram"),
        Waypoint(8.5500, 76.9200, "Paruthippara"),
        Waypoint(8.5680, 76.8710, "Kazhakkoottam Junction"),
    ],
    "R4": [
        Waypoint(8.5240, 76.9370, "Central Railway Station"),
        Waypoint(8.5150, 76.9480, "Bakery Junction"),
        Waypoint(8.5250, 76.9320, "Museum Road"),
        Waypoint(8.5260, 76.9240, "Government Medical College"),
    ],
}


def calculate_bearing(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculate geographic heading angle between two coordinates in degrees (0-360)."""
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    delta_lambda = math.radians(lon2 - lon1)
    y = math.sin(delta_lambda) * math.cos(phi2)
    x = math.cos(phi1) * math.sin(phi2) - math.sin(phi1) * math.cos(phi2) * math.cos(delta_lambda)
    initial_bearing = math.atan2(y, x)
    degrees = (math.degrees(initial_bearing) + 360) % 360
    return round(degrees, 1)


def interpolate_route(waypoints: list[Waypoint], progress: float) -> tuple[float, float, float, float]:
    """Interpolate coordinates, velocity, and bearing along a waypoint sequence.

    Returns: (latitude, longitude, speed_kmh, heading_deg)
    """
    total_segments = len(waypoints) - 1
    if total_segments <= 0:
        return waypoints[0].lat, waypoints[0].lon, 0.0, 0.0

    progress = progress % 1.0
    seg_float = progress * total_segments
    seg_idx = min(math.floor(seg_float), total_segments - 1)
    local_p = seg_float - seg_idx

    p1 = waypoints[seg_idx]
    p2 = waypoints[seg_idx + 1]

    # Stop dwell simulation: when close to a stop (first 5% of segment), vehicle slows down
    if local_p < 0.08 or local_p > 0.92:
        speed = 12.0 + (local_p * 10)  # Near stop slowing
    else:
        speed = 36.0 + (math.sin(local_p * math.pi) * 12.0)  # Cruising speed

    lat = round(p1.lat + (p2.lat - p1.lat) * local_p, 6)
    lon = round(p1.lon + (p2.lon - p1.lon) * local_p, 6)
    bearing = calculate_bearing(p1.lat, p1.lon, p2.lat, p2.lon)

    return lat, lon, round(speed, 1), bearing


def step_simulation() -> list[dict]:
    """Advance all buses one physics step and update database telemetry."""
    now_secs = time.time()
    updates = []

    fleet_assignments = [
        ("KSRTC-101", "R1", 0.15, 22),
        ("KSRTC-102", "R1", 0.65, 46),
        ("PVT-201", "R1", 0.40, 24),
        ("KSRTC-103", "R2", 0.20, 18),
        ("PVT-202", "R2", 0.70, 14),
        ("KSRTC-104", "R3", 0.30, 48),
        ("PVT-203", "R3", 0.85, 20),
        ("KSRTC-105", "R4", 0.10, 12),
        ("PVT-204", "R4", 0.55, 10),
    ]

    for bus_id, route, offset, passenger_count in fleet_assignments:
        waypoints = KERALA_CORRIDORS.get(route, KERALA_CORRIDORS["R1"])
        # Complete full route cycle every 15 minutes (900 seconds)
        cycle_progress = ((now_secs / 900.0) + offset) % 1.0
        lat, lon, speed, heading = interpolate_route(waypoints, cycle_progress)

        record = update_bus_telemetry(
            bus_id=bus_id,
            route_number=route,
            latitude=lat,
            longitude=lon,
            passenger_count=passenger_count,
            capacity=50 if "KSRTC" in bus_id else 40,
            speed_kmh=speed,
            heading_deg=heading,
            source="physics_sim",
        )
        updates.append(record)

    return updates
