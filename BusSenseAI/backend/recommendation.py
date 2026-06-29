"""Passenger recommendation engine for less-crowded buses."""
from __future__ import annotations


def crowd_level(occupancy: float) -> str:
    if occupancy >= 80:
        return "Red"
    if occupancy >= 55:
        return "Yellow"
    return "Green"


def recommend_less_crowded_buses(buses: list[dict], route_number: str | None = None, limit: int = 3) -> list[dict]:
    """Return buses ordered by low occupancy, seat availability, and near ETA."""
    candidates = [b for b in buses if route_number is None or b.get("route_number") == route_number]
    ranked = sorted(
        candidates,
        key=lambda b: (
            float(b.get("occupancy_percentage") or 0),
            -(int(b.get("seat_availability") or 0)),
            int(b.get("eta_minutes") or 999),
        ),
    )
    return [
        {
            **bus,
            "crowd_level": crowd_level(float(bus.get("occupancy_percentage") or 0)),
            "recommendation_reason": f"{bus.get('seat_availability', 0)} seats available and {bus.get('occupancy_percentage', 0)}% occupied",
        }
        for bus in ranked[:limit]
    ]
