"""Deterministic GPS simulation for demo buses."""
from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
import math


@dataclass(frozen=True)
class RoutePath:
    route_number: str
    points: tuple[tuple[float, float], ...]


ROUTES = {
    "R1": RoutePath("R1", ((8.5241, 76.9366), (8.5300, 76.9400), (8.5350, 76.9450), (8.5410, 76.9520))),
    "R2": RoutePath("R2", ((8.4800, 76.9100), (8.4820, 76.9120), (8.4880, 76.9200), (8.4940, 76.9280))),
    "R3": RoutePath("R3", ((8.5600, 76.9700), (8.5620, 76.9720), (8.5680, 76.9800), (8.5750, 76.9890))),
    "R4": RoutePath("R4", ((8.5000, 76.9500), (8.5050, 76.9550), (8.5110, 76.9600), (8.5180, 76.9650))),
}


def interpolate(points: tuple[tuple[float, float], ...], progress: float) -> tuple[float, float]:
    progress = progress % 1.0
    segment_float = progress * (len(points) - 1)
    index = min(math.floor(segment_float), len(points) - 2)
    local = segment_float - index
    lat1, lon1 = points[index]
    lat2, lon2 = points[index + 1]
    return round(lat1 + (lat2 - lat1) * local, 6), round(lon1 + (lon2 - lon1) * local, 6)


def simulate_location(route_number: str, bus_id: str, when: datetime | None = None) -> dict:
    when = when or datetime.now(timezone.utc)
    path = ROUTES.get(route_number, ROUTES["R1"])
    bus_offset = (sum(ord(char) for char in bus_id) % 300) / 300
    time_progress = ((when.timestamp() / 60) % 30) / 30
    lat, lon = interpolate(path.points, time_progress + bus_offset)
    return {"bus_id": bus_id, "route_number": route_number, "latitude": lat, "longitude": lon, "timestamp": when.isoformat()}
