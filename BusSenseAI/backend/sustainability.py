"""Fuel, CO₂ and utilization calculations for BusSense AI."""
from __future__ import annotations

DIESEL_CO2_KG_PER_LITRE = 2.68
TARGET_OCCUPANCY_PERCENT = 85.0


def bus_utilization_score(occupancy_percentage: float, target: float = TARGET_OCCUPANCY_PERCENT) -> float:
    """Return a 0-100 score where the target occupancy is considered fully utilized."""
    if target <= 0:
        return 0.0
    return round(max(0.0, min((occupancy_percentage / target) * 100, 100.0)), 2)


def estimate_savings(records: list[dict]) -> dict:
    """Estimate operational savings from balancing crowded and underused services.

    This is a demonstrator formula, not an official emissions inventory: each
    underutilized service that can be consolidated is assumed to save 1.8 litres,
    while each balanced service is credited with 0.9 litres from reduced idling
    and smoother passenger distribution.
    """
    underused = sum(1 for r in records if float(r.get("occupancy_percentage", 0)) < 40)
    balanced = sum(1 for r in records if 55 <= float(r.get("occupancy_percentage", 0)) <= 85)
    fuel_litres = round((underused * 1.8) + (balanced * 0.9), 2)
    return {
        "underutilized_trip_count": underused,
        "balanced_trip_count": balanced,
        "estimated_fuel_savings_litres": fuel_litres,
        "estimated_co2_reduction_kg": round(fuel_litres * DIESEL_CO2_KG_PER_LITRE, 2),
    }
