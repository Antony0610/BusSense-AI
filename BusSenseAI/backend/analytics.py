"""Simple analytics helpers for demand prediction and route optimization."""
from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from statistics import mean


@dataclass
class DemandInsight:
    route_number: str
    predicted_occupancy: float
    peak_hours: list[int]
    recommendation: str


def hour_from_timestamp(value: str) -> int:
    return datetime.fromisoformat(value.replace("Z", "+00:00")).hour


def predict_demand(records: list[dict]) -> list[DemandInsight]:
    """Predict route demand with moving averages grouped by route and hour."""
    by_route: dict[str, list[dict]] = {}
    for record in records:
        by_route.setdefault(record["route_number"], []).append(record)

    insights: list[DemandInsight] = []
    for route, route_records in by_route.items():
        predicted = round(mean(float(r["occupancy_percentage"]) for r in route_records), 2)
        hourly: dict[int, list[float]] = {}
        for record in route_records:
            hourly.setdefault(hour_from_timestamp(record["timestamp"]), []).append(float(record["occupancy_percentage"]))
        peak_hours = [hour for hour, values in hourly.items() if mean(values) >= 75]
        if predicted >= 80:
            recommendation = "Deploy additional buses during peak hours."
        elif predicted <= 35:
            recommendation = "Consider consolidating trips or reallocating buses."
        else:
            recommendation = "Current allocation is balanced."
        insights.append(DemandInsight(route, predicted, sorted(peak_hours), recommendation))
    return insights
