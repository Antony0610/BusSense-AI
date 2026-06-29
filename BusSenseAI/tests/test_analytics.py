import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "backend"))

from analytics import hour_from_timestamp, predict_demand
from gps_simulator import simulate_location
from recommendation import recommend_less_crowded_buses
from sustainability import bus_utilization_score, estimate_savings


def test_utilization_score_caps_at_100():
    assert bus_utilization_score(42.5) == 50.0
    assert bus_utilization_score(100) == 100.0


def test_savings_estimation_counts_underused_and_balanced_records():
    result = estimate_savings([
        {"occupancy_percentage": 20},
        {"occupancy_percentage": 60},
        {"occupancy_percentage": 95},
    ])
    assert result["underutilized_trip_count"] == 1
    assert result["balanced_trip_count"] == 1
    assert result["estimated_co2_reduction_kg"] > 0


def test_recommendation_engine_orders_less_crowded_buses_first():
    buses = [
        {"bus_id": "A", "route_number": "R1", "occupancy_percentage": 90, "seat_availability": 2, "eta_minutes": 4},
        {"bus_id": "B", "route_number": "R1", "occupancy_percentage": 35, "seat_availability": 20, "eta_minutes": 8},
    ]
    assert recommend_less_crowded_buses(buses, "R1")[0]["bus_id"] == "B"


def test_gps_simulator_returns_route_location():
    location = simulate_location("R1", "KSRTC-101")
    assert location["bus_id"] == "KSRTC-101"
    assert 8.4 < location["latitude"] < 8.7
    assert 76.8 < location["longitude"] < 77.1


def test_demand_prediction_returns_insights():
    records = [
        {"route_number": "R1", "timestamp": "2026-06-29T07:30:00Z", "occupancy_percentage": 84, "latitude": 8.52, "longitude": 76.93},
        {"route_number": "R1", "timestamp": "2026-06-29T08:30:00Z", "occupancy_percentage": 92, "latitude": 8.53, "longitude": 76.94},
        {"route_number": "R2", "timestamp": "2026-06-29T09:30:00Z", "occupancy_percentage": 30, "latitude": 8.48, "longitude": 76.91},
        {"route_number": "R2", "timestamp": "2026-06-29T10:30:00Z", "occupancy_percentage": 40, "latitude": 8.49, "longitude": 76.92},
    ]
    insights = predict_demand(records)
    assert len(insights) == 2
    assert hour_from_timestamp("2026-06-29T07:30:00Z") == 7
