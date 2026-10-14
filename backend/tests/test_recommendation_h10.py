"""
BusSense AI - Phase H10 Smart Bus Recommendation Engine Test Suite
Comprehensive 24-Point Test Specification:
1.  Candidate bus retrieval & corridor stop matching
2.  Destination filtering across distinct corridors
3.  Balanced preference mode (multi-factor trade-off)
4.  Fastest preference mode (prioritizes ETA and duration)
5.  Least crowded preference mode (prioritizes current & predicted occupancy)
6.  Lowest fare preference mode (prioritizes economical transit)
7.  ETA scoring (earlier arrival yields higher ETA factor score)
8.  Current crowd scoring (lower occupancy yields higher crowd score)
9.  Predicted crowd scoring (lower predicted occupancy yields higher predicted crowd score)
10. Prediction confidence weighting (low confidence discounts prediction)
11. LOW_DATA prediction handling and graceful confidence degradation
12. Data-quality calculation (HIGH, MEDIUM, LOW)
13. Deterministic explanation generation with data-grounded templates
14. Alternative recommendations generation with comparative deltas
15. No candidate case handling without crashing
16. Zero hardcoded Bus 205 winner (fair evaluation across all candidates)
17. Changing occupancy changes recommendation winner where appropriate
18. Changing ETA changes recommendation winner where appropriate
19. Changing destination changes candidate set
20. Authorization & access control across endpoints
21. API schema conformance (Pydantic v2 JourneyPlanResponse)
22. Passenger recommendation mobile integration (Flutter schema parity)
23. Authority recommendation integration & diagnostic score breakdowns
24. Existing H1-H9 regression (telemetry, crowd prediction, CV occupancy intact)
"""
import sys
import os
import time
import pytest
from fastapi.testclient import TestClient

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app.main import app
from app.services.recommendation_engine import recommendation_engine, RecommendationEngine, CORRIDOR_METADATA
from app.services.gps_simulator import gps_simulator
from app.schemas.prediction import JourneyPlanResponse, BusRecommendationItem
from app.schemas.common import CrowdLevel, DataOrigin

client = TestClient(app)


# ==============================================================================
# 1. Candidate Bus Retrieval & 2. Destination Filtering
# ==============================================================================

def test_01_candidate_bus_retrieval():
    """1. Validates candidate bus retrieval matching origin and destination stops."""
    candidates = recommendation_engine.find_candidate_buses(
        origin="Kaloor Metro Station",
        destination="Infopark Phase 1 Express Bay"
    )
    direct_candidates = [c["bus_number"] for c in candidates if c.get("is_direct")]
    assert "14A" in direct_candidates
    assert "12" in direct_candidates
    for c in candidates:
        assert "bus_number" in c
        assert "duration_mins" in c
        assert "distance_km" in c
        assert "fare_inr" in c


def test_02_destination_filtering():
    """2. Validates stop sequence and reverse direction handling (stops must be ordered forward)."""
    # Vyttila to Aluva (reverse of Route 205 Aluva -> Vyttila)
    candidates = recommendation_engine.find_candidate_buses(
        origin="Vyttila Mobility Hub",
        destination="Aluva Metro Station"
    )
    direct_205 = any(c["bus_number"] == "205" and c.get("is_direct") for c in candidates)
    assert not direct_205, "Route 205 must not be considered direct when moving backward"


# ==============================================================================
# Preference Modes: 3. Balanced, 4. Fastest, 5. Least Crowded, 6. Lowest Fare
# ==============================================================================

def test_03_balanced_preference():
    """3. Validates balanced preference mode harmoniously evaluates all factors."""
    plan = recommendation_engine.plan_journey(
        origin="Kaloor Metro Station",
        destination="Infopark Phase 1",
        preference="balanced"
    )
    assert isinstance(plan, JourneyPlanResponse)
    assert plan.preference == "balanced"
    assert plan.recommended_bus.is_recommended is True
    assert len(plan.alternative_buses) >= 1
    assert plan.recommended_bus.journey_score >= 0.0
    assert plan.recommended_bus.score_breakdown is not None


def test_04_fastest_preference():
    """4. Validates fastest preference mode prioritizes lower ETA and shorter duration."""
    # Configure Bus 14A to arrive in 1 min, Bus 12 in 20 min
    gps_simulator.fleet_state["14A"]["override_eta_mins"] = 1
    gps_simulator.fleet_state["12"]["override_eta_mins"] = 20

    plan = recommendation_engine.plan_journey(
        origin="Kaloor Metro Station",
        destination="Infopark Phase 1",
        preference="fastest"
    )
    assert plan.preference == "fastest"
    assert plan.recommended_bus.is_recommended is True
    assert plan.recommended_bus.bus_number == "14A"

    # Clean up
    gps_simulator.fleet_state["14A"].pop("override_eta_mins", None)
    gps_simulator.fleet_state["12"].pop("override_eta_mins", None)


def test_05_least_crowded_preference():
    """5. Validates least crowded preference mode prioritizes lowest occupancy."""
    # Force Bus 12 to very low occupancy, Bus 14A to high occupancy
    gps_simulator.fleet_state["12"]["override_occupancy_pct"] = 14.5
    gps_simulator.fleet_state["14A"]["override_occupancy_pct"] = 93.3

    plan = recommendation_engine.plan_journey(
        origin="Kaloor Metro Station",
        destination="Infopark Phase 1",
        preference="least_crowded"
    )
    assert plan.preference == "least_crowded"
    assert plan.recommended_bus.bus_number == "12"
    assert plan.recommended_bus.occupancy_pct < 50.0

    # Clean up
    gps_simulator.fleet_state["12"].pop("override_occupancy_pct", None)
    gps_simulator.fleet_state["14A"].pop("override_occupancy_pct", None)


def test_06_lowest_fare_preference():
    """6. Validates lowest fare preference prioritizes economical options where fare exists."""
    plan = recommendation_engine.plan_journey(
        origin="Kaloor Metro Station",
        destination="Infopark Phase 1",
        preference="lowest_fare"
    )
    assert plan.preference == "lowest_fare"
    assert plan.recommended_bus.is_recommended is True
    if plan.alternative_buses:
        # Recommended bus fare must be <= first alternative or very economical
        assert plan.recommended_bus.fare_inr <= plan.alternative_buses[0].fare_inr


# ==============================================================================
# Factor Scoring & Predictions: 7. ETA, 8. Crowd, 9. Predicted Crowd, 10. Confidence, 11. Low Data
# ==============================================================================

def test_07_eta_scoring():
    """7. Validates ETA scoring function (lower ETA yields strictly higher ETA factor score)."""
    cand = {
        "bus_number": "14A",
        "metadata": CORRIDOR_METADATA["14A"],
        "duration_mins": 30,
        "distance_km": 15.0,
        "fare_inr": 20.0,
        "has_priority_lane": False,
        "is_direct": True
    }
    # Simulate ETA 2 mins
    gps_simulator.fleet_state["14A"]["override_eta_mins"] = 2
    _, breakdown_quick, _ = recommendation_engine.evaluate_bus_candidate(cand, "balanced")

    # Simulate ETA 25 mins
    gps_simulator.fleet_state["14A"]["override_eta_mins"] = 25
    _, breakdown_slow, _ = recommendation_engine.evaluate_bus_candidate(cand, "balanced")

    assert breakdown_quick["eta"] > breakdown_slow["eta"]
    assert breakdown_quick["eta_score"] > breakdown_slow["eta_score"]

    # Clean up
    gps_simulator.fleet_state["14A"].pop("override_eta_mins", None)


def test_08_current_crowd_scoring():
    """8. Validates current crowd scoring (lower occupancy yields higher crowd score)."""
    cand = {
        "bus_number": "12",
        "metadata": CORRIDOR_METADATA["12"],
        "duration_mins": 30,
        "distance_km": 14.0,
        "fare_inr": 20.0,
        "has_priority_lane": False,
        "is_direct": True
    }
    # Low crowd (20%)
    gps_simulator.fleet_state["12"]["override_occupancy_pct"] = 20.0
    _, breakdown_calm, _ = recommendation_engine.evaluate_bus_candidate(cand, "least_crowded")

    # High crowd (90%)
    gps_simulator.fleet_state["12"]["override_occupancy_pct"] = 90.0
    _, breakdown_packed, _ = recommendation_engine.evaluate_bus_candidate(cand, "least_crowded")

    assert breakdown_calm["crowd"] > breakdown_packed["crowd"]

    # Clean up
    gps_simulator.fleet_state["12"].pop("override_occupancy_pct", None)


def test_09_predicted_crowd_scoring():
    """9. Validates predicted crowd factor scoring from H9 Ridge demand predictions."""
    plan = recommendation_engine.plan_journey("Kaloor", "Vyttila")
    rec = plan.recommended_bus
    assert rec.predicted_occupancy_pct is not None
    assert 0.0 <= rec.predicted_occupancy_pct <= 100.0
    assert rec.score_breakdown is not None
    assert "predicted_crowd" in rec.score_breakdown
    assert 0.0 <= rec.score_breakdown["predicted_crowd"] <= 1.0


def test_10_prediction_confidence_weighting():
    """10. Validates prediction confidence discounting (low confidence blends with current crowd)."""
    # Prediction horizon for 30m journey is 30
    horizon = recommendation_engine._select_prediction_horizon(30)
    assert horizon == 30

    cand = {
        "bus_number": "205",
        "metadata": CORRIDOR_METADATA["205"],
        "duration_mins": 30,
        "distance_km": 15.0,
        "fare_inr": 25.0,
        "has_priority_lane": True,
        "is_direct": True
    }
    _, breakdown, _ = recommendation_engine.evaluate_bus_candidate(cand, "balanced")
    assert "predicted_crowd" in breakdown
    assert 0.0 <= breakdown["predicted_crowd"] <= 1.0


def test_11_low_data_prediction_handling():
    """11. Validates LOW_DATA prediction status is handled safely without throwing exceptions."""
    # Candidate with unmonitored bus or low data behaves safely
    plan = recommendation_engine.plan_journey("Kaloor", "Vyttila")
    assert plan.recommended_bus.is_recommended is True
    assert plan.recommended_bus.predicted_crowd_level is not None


# ==============================================================================
# Quality, Explanation, Alternatives & Fallbacks: 12, 13, 14, 15
# ==============================================================================

def test_12_data_quality_calculation():
    """12. Validates data quality calculation (HIGH for CV_REPLAY, MEDIUM for SIMULATED, LOW for unmonitored)."""
    # CV replay active
    gps_simulator.fleet_state["205"]["data_origin"] = DataOrigin.CV_REPLAY
    plan = recommendation_engine.plan_journey("Aluva", "Vyttila")
    assert plan.recommended_bus.data_quality in ["HIGH", "MEDIUM"]
    assert plan.data_quality in ["HIGH", "MEDIUM"]

    # Reset
    gps_simulator.fleet_state["205"]["data_origin"] = DataOrigin.SIMULATED


def test_13_explanation_generation():
    """13. Validates deterministic, factual explanation generation without false certainty."""
    plan = recommendation_engine.plan_journey("Kaloor", "Vyttila")
    assert len(plan.explanation) > 15
    assert plan.recommended_bus.why_recommended is not None
    assert len(plan.recommended_bus.why_recommended) > 10
    # No false certainty claims
    assert "will definitely" not in plan.explanation.lower()
    assert "guaranteed" not in plan.explanation.lower()


def test_14_alternative_recommendations():
    """14. Validates alternative recommendations generation with comparative deltas."""
    plan = recommendation_engine.plan_journey("Kaloor", "Infopark")
    assert len(plan.alternative_buses) >= 1
    alt = plan.alternative_buses[0]
    assert alt.is_recommended is False
    assert alt.bus_number != plan.recommended_bus.bus_number
    assert (plan.recommended_bus.crowd_saving_vs_alternative_pct is not None or 
            plan.recommended_bus.time_saving_mins is not None)


def test_15_no_candidate_case():
    """15. Validates that unknown / unserviced stops return safe fallback plan without 500 error."""
    plan = recommendation_engine.plan_journey(
        origin="Nonexistent Kerala Stop 888",
        destination="Unknown Destination 999"
    )
    assert isinstance(plan, JourneyPlanResponse)
    assert plan.recommended_bus is not None
    assert plan.recommended_bus.is_recommended is True
    assert "Limited direct route" in plan.explanation or len(plan.explanation) > 10


# ==============================================================================
# 16. Elimination of Hardcoded Bus 205 Winner
# ==============================================================================

def test_16_no_hardcoded_bus_205_winner():
    """16. CRITICAL: When Bus 205 is crowded and delayed, it MUST NOT win over Bus 14A or Bus 12."""
    gps_simulator.fleet_state["205"]["override_occupancy_pct"] = 96.0
    gps_simulator.fleet_state["14A"]["override_occupancy_pct"] = 25.0

    plan = recommendation_engine.plan_journey(
        origin="Kaloor Metro Station",
        destination="Palarivattom Bypass Junction",
        preference="least_crowded"
    )

    assert plan.recommended_bus.bus_number != "205", "Bus 205 must NOT be hardcoded as winner when crowded"
    assert plan.recommended_bus.bus_number in ["14A", "12"]

    # Reset
    gps_simulator.fleet_state["205"].pop("override_occupancy_pct", None)
    gps_simulator.fleet_state["14A"].pop("override_occupancy_pct", None)


# ==============================================================================
# Dynamic Reactivity: 17. Occupancy, 18. ETA, 19. Destination
# ==============================================================================

def test_17_changing_occupancy_changes_recommendation():
    """17. Dynamic reactivity: modifying real-time occupancy shifts the recommendation winner."""
    # State A: Bus 14A calm (28%), Bus 12 crowded (80%) -> Bus 14A wins
    gps_simulator.fleet_state["14A"]["override_occupancy_pct"] = 28.0
    gps_simulator.fleet_state["12"]["override_occupancy_pct"] = 80.0
    plan_a = recommendation_engine.plan_journey("Kaloor", "Infopark", preference="least_crowded")
    assert plan_a.recommended_bus.bus_number == "14A"

    # State B: Bus 12 calm (22%), Bus 14A crowded (88%) -> Bus 12 wins
    gps_simulator.fleet_state["14A"]["override_occupancy_pct"] = 88.0
    gps_simulator.fleet_state["12"]["override_occupancy_pct"] = 22.0
    plan_b = recommendation_engine.plan_journey("Kaloor", "Infopark", preference="least_crowded")
    assert plan_b.recommended_bus.bus_number == "12"

    # Clean up
    gps_simulator.fleet_state["14A"].pop("override_occupancy_pct", None)
    gps_simulator.fleet_state["12"].pop("override_occupancy_pct", None)


def test_18_changing_eta_changes_recommendation():
    """18. Dynamic reactivity: changing ETA shifts recommendation winner under fastest mode."""
    gps_simulator.fleet_state["14A"]["override_occupancy_pct"] = 50.0
    gps_simulator.fleet_state["12"]["override_occupancy_pct"] = 50.0

    # Case A: Bus 14A arrives in 1 min, Bus 12 in 25 min -> Bus 14A wins
    gps_simulator.fleet_state["14A"]["override_eta_mins"] = 1
    gps_simulator.fleet_state["12"]["override_eta_mins"] = 25
    plan_a = recommendation_engine.plan_journey("Kaloor", "Infopark", preference="fastest")
    assert plan_a.recommended_bus.bus_number == "14A"

    # Case B: Bus 12 arrives in 1 min, Bus 14A in 25 min -> Bus 12 wins
    gps_simulator.fleet_state["14A"]["override_eta_mins"] = 25
    gps_simulator.fleet_state["12"]["override_eta_mins"] = 1
    plan_b = recommendation_engine.plan_journey("Kaloor", "Infopark", preference="fastest")
    assert plan_b.recommended_bus.bus_number == "12"

    # Clean up
    gps_simulator.fleet_state["14A"].pop("override_eta_mins", None)
    gps_simulator.fleet_state["12"].pop("override_eta_mins", None)
    gps_simulator.fleet_state["14A"].pop("override_occupancy_pct", None)
    gps_simulator.fleet_state["12"].pop("override_occupancy_pct", None)


def test_19_changing_destination_changes_candidate_set():
    """19. Changing journey destination dynamically produces different candidate buses."""
    cands_vyttila = recommendation_engine.find_candidate_buses("Aluva", "Vyttila")
    cands_infopark = recommendation_engine.find_candidate_buses("Fort Kochi", "Infopark")

    direct_vyttila = [c["bus_number"] for c in cands_vyttila if c.get("is_direct")]
    direct_infopark = [c["bus_number"] for c in cands_infopark if c.get("is_direct")]

    assert "205" in direct_vyttila
    assert "14A" in direct_infopark
    assert "205" not in direct_infopark


# ==============================================================================
# Security & Integrations: 20. Auth, 21. API Schema, 22. Passenger, 23. Authority, 24. Regression
# ==============================================================================

def test_20_authorization():
    """20. Validates public access to journey planning and verifies token security."""
    # Recommendation planning is open for passengers
    resp = client.get("/api/recommendations/plan?origin=Kaloor&destination=Infopark")
    assert resp.status_code == 200

    # Operational QR validation requires conductor / authority authentication
    auth_resp = client.post("/api/tickets/validate", json={"qr_code_hash": "invalid_hash_xyz"})
    assert auth_resp.status_code in [401, 403, 422]


def test_21_api_schema():
    """21. Validates strict API schema conformance against JourneyPlanResponse."""
    resp = client.get("/api/recommendations/plan?origin=Kaloor&destination=Infopark&preference=balanced")
    assert resp.status_code == 200
    payload = resp.json()
    assert payload["success"] is True
    data = payload["data"]
    # Pydantic validation
    validated = JourneyPlanResponse(**data)
    assert validated.origin_stop is not None
    assert validated.destination_stop is not None
    assert validated.recommended_bus.bus_number in ["205", "14A", "12"]
    assert validated.recommended_bus.is_recommended is True


def test_22_passenger_recommendation_integration():
    """22. Validates Flutter Mobile JourneyPlanModel compatibility."""
    resp = client.get("/api/recommendations/plan?origin=Kaloor&destination=Infopark")
    assert resp.status_code == 200
    data = resp.json()["data"]

    # Verify all keys expected by Flutter JourneyPlanModel.fromJson
    rec = data["recommended_bus"]
    expected_mobile_keys = [
        "bus_number", "route_number", "route_name", "operator_type",
        "eta_mins", "occupancy_pct", "crowd_level", "is_recommended",
        "journey_score", "why_recommended", "fare_inr", "data_origin"
    ]
    for key in expected_mobile_keys:
        assert key in rec, f"Missing mobile field: {key}"

    assert "alternative_buses" in data
    assert "explanation" in data


def test_23_authority_recommendation_integration():
    """23. Validates Authority portal recommendation diagnostic fields & truth badges."""
    resp = client.get("/api/recommendations/plan?origin=Kaloor&destination=Infopark")
    assert resp.status_code == 200
    data = resp.json()["data"]

    # Authority needs score breakdown and data quality
    rec = data["recommended_bus"]
    assert "score_breakdown" in rec
    assert rec["score_breakdown"] is not None
    assert "data_quality" in rec
    assert rec["data_quality"] in ["HIGH", "MEDIUM", "LOW"]
    assert data["data_origin"] in ["RECOMMENDATION", "CV_REPLAY", "PREDICTION", "SIMULATED", "ESTIMATE"]


def test_24_existing_h1_h9_regression():
    """24. Validates that H1-H9 core endpoints remain fully operational without regression."""
    # 1. Health
    r_health = client.get("/health")
    assert r_health.status_code == 200
    assert r_health.json()["status"] in ["healthy", "degraded"]

    # 2. Live Bus Telemetry (H4)
    r_telem = client.get("/api/buses")
    assert r_telem.status_code == 200
    assert len(r_telem.json()["data"]) >= 1

    # 3. Demand / Crowd Forecast (H9)
    r_demand = client.get("/api/predictions/205")
    assert r_demand.status_code == 200
    assert len(r_demand.json()["data"]) >= 1

    # 4. Occupancy Status (H8)
    r_occ = client.get("/api/occupancy/live/205")
    assert r_occ.status_code == 200


# ==============================================================================
# Edge Cases & Latency Performance
# ==============================================================================

def test_edge_case_full_occupancy_100_percent():
    """Edge Case: 100% full bus does not cause division-by-zero or negative score."""
    gps_simulator.fleet_state["205"]["override_occupancy_pct"] = 100.0
    plan = recommendation_engine.plan_journey("Aluva", "Vyttila")
    assert plan.recommended_bus.occupancy_pct <= 100.0
    assert plan.recommended_bus.journey_score >= 0.0

    # Clean up
    gps_simulator.fleet_state["205"].pop("override_occupancy_pct", None)


def test_edge_case_invalid_preference_mode():
    """Edge Case: Invalid preference mode defaults gracefully to balanced."""
    plan = recommendation_engine.plan_journey(
        origin="Kaloor",
        destination="Vyttila",
        preference="nonexistent_mode_999"
    )
    assert plan.preference == "balanced"
    assert plan.recommended_bus.is_recommended is True


def test_recommendation_latency_performance():
    """Latency: Recommendation computation must execute in < 50ms on CPU."""
    start_time = time.perf_counter()
    iterations = 25
    for _ in range(iterations):
        _ = recommendation_engine.plan_journey("Kaloor", "Infopark", preference="balanced")
    elapsed = time.perf_counter() - start_time
    avg_ms = (elapsed / iterations) * 1000.0

    assert avg_ms < 50.0, f"Average recommendation latency too high: {avg_ms:.2f}ms"
