"""Demand prediction and route optimization analytics."""
from __future__ import annotations

from dataclasses import dataclass, asdict
from datetime import datetime
from statistics import mean

try:
    from sklearn.ensemble import RandomForestRegressor
except ImportError:  # Allows unit tests and classroom demos to run before dependencies are installed.
    RandomForestRegressor = None


@dataclass
class DemandInsight:
    route_number: str
    predicted_occupancy: float
    peak_hours: list[int]
    recommendation: str
    model: str

    def to_dict(self) -> dict:
        return asdict(self)


def hour_from_timestamp(value: str) -> int:
    return datetime.fromisoformat(value.replace("Z", "+00:00")).hour


def route_feature(route_number: str) -> int:
    return sum(ord(char) for char in route_number) % 100


def predict_demand(records: list[dict]) -> list[DemandInsight]:
    """Predict demand with Random Forest when available, otherwise moving average.

    The fallback keeps the prototype runnable on lab machines before Python
    packages are installed, while `requirements.txt` enables the Random Forest
    path for the full demo.
    """
    by_route: dict[str, list[dict]] = {}
    for record in records:
        by_route.setdefault(record["route_number"], []).append(record)

    model_name = "moving_average"
    predictions: dict[str, float] = {}
    if RandomForestRegressor and len(records) >= 4:
        x_train = [[hour_from_timestamp(r["timestamp"]), route_feature(r["route_number"]), float(r.get("latitude", 0)), float(r.get("longitude", 0))] for r in records]
        y_train = [float(r["occupancy_percentage"]) for r in records]
        model = RandomForestRegressor(n_estimators=50, random_state=42)
        model.fit(x_train, y_train)
        model_name = "random_forest"
        for route, route_records in by_route.items():
            latest = route_records[-1]
            next_hour = (hour_from_timestamp(latest["timestamp"]) + 1) % 24
            pred = model.predict([[next_hour, route_feature(route), float(latest.get("latitude", 0)), float(latest.get("longitude", 0))]])[0]
            predictions[route] = round(max(0, min(float(pred), 120)), 2)

    insights: list[DemandInsight] = []
    for route, route_records in by_route.items():
        predicted = predictions.get(route, round(mean(float(r["occupancy_percentage"]) for r in route_records), 2))
        hourly: dict[int, list[float]] = {}
        for record in route_records:
            hourly.setdefault(hour_from_timestamp(record["timestamp"]), []).append(float(record["occupancy_percentage"]))
        peak_hours = [hour for hour, values in hourly.items() if mean(values) >= 75]
        if predicted >= 80:
            recommendation = "Deploy additional buses or larger vehicles during peak hours."
        elif predicted <= 35:
            recommendation = "Shift underused capacity to crowded routes or reduce off-peak frequency."
        else:
            recommendation = "Maintain current schedule and monitor live demand."
        insights.append(DemandInsight(route, predicted, sorted(peak_hours), recommendation, model_name))
    return insights
