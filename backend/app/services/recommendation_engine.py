"""
BusSense AI - Smart Bus Recommendation & Journey Score Engine (Phase H10)
Evaluates candidate transit options across Greater Kochi corridors using:
1. Live vehicle telemetry (ETA, real-time occupancy, operator type)
2. H9 demand forecasting (+15m, +30m, +60m predicted occupancy & confidence)
3. Multi-factor scoring (ETA, crowd, predicted crowd, travel duration, fare, reliability)
4. Dynamic passenger preference modes (balanced, fastest, least_crowded, lowest_fare)
5. Explainable, data-grounded reasoning without hardcoded winners
"""
import math
from typing import Dict, Any, List, Optional, Tuple
from app.schemas.prediction import (
    BusRecommendationItem,
    JourneyPlanResponse,
    JourneyPlanRequest,
)
from app.schemas.common import CrowdLevel, DataOrigin
from app.services.gps_simulator import gps_simulator, CORRIDORS
from app.services.demand_forecaster import demand_forecaster
from app.services.cv_occupancy import cv_occupancy_service

# Greater Kochi Corridor Route Metadata & Distance Matrix
CORRIDOR_METADATA = {
    "205": {
        "route_number": "205",
        "route_name": "Aluva Metro ➔ Vyttila Mobility Hub via Kaloor",
        "operator_type": "KSRTC",
        "total_distance_km": 22.4,
        "base_duration_mins": 45,
        "has_priority_lane": True,
        "base_fare_inr": 25.0,
        "stops": [
            "aluva metro station",
            "en route kalamassery",
            "kalamassery premier junction",
            "edappally toll & lulu terminal",
            "palarivattom bypass junction",
            "kaloor metro station & bus stand",
            "en route kadavanthra",
            "vyttila mobility hub"
        ]
    },
    "14A": {
        "route_number": "14A",
        "route_name": "Fort Kochi ➔ Infopark Phase 1 via Kaloor",
        "operator_type": "PRIVATE",
        "total_distance_km": 26.5,
        "base_duration_mins": 55,
        "has_priority_lane": False,
        "base_fare_inr": 22.0,
        "stops": [
            "fort kochi boat jetty",
            "mg road north",
            "kaloor metro station & bus stand",
            "palarivattom bypass junction",
            "kakkanad civil station",
            "infopark phase 1 express bay"
        ]
    },
    "12": {
        "route_number": "12",
        "route_name": "Kaloor Metro ➔ Infopark Phase 1 Corridor",
        "operator_type": "KSRTC",
        "total_distance_km": 14.8,
        "base_duration_mins": 32,
        "has_priority_lane": True,
        "base_fare_inr": 20.0,
        "stops": [
            "kaloor metro station & bus stand",
            "palarivattom bypass junction",
            "kakkanad civil station",
            "infopark phase 1 express bay"
        ]
    }
}

PREFERENCE_WEIGHTS = {
    "balanced": {
        "eta": 0.25,
        "crowd": 0.25,
        "pred_crowd": 0.25,
        "duration": 0.15,
        "fare": 0.10
    },
    "fastest": {
        "eta": 0.45,
        "crowd": 0.10,
        "pred_crowd": 0.05,
        "duration": 0.35,
        "fare": 0.05
    },
    "least_crowded": {
        "eta": 0.15,
        "crowd": 0.35,
        "pred_crowd": 0.35,
        "duration": 0.10,
        "fare": 0.05
    },
    "lowest_fare": {
        "eta": 0.15,
        "crowd": 0.10,
        "pred_crowd": 0.10,
        "duration": 0.15,
        "fare": 0.50
    }
}

class RecommendationEngine:
    """
    Central Smart Recommendation Engine for BusSense AI.
    Dynamically balances multi-factor transit operational conditions without hardcoded winners.
    """

    @staticmethod
    def calculate_journey_score(
        occupancy_pct: float,
        eta_mins: int,
        travel_duration_mins: int,
        has_priority_lane: bool = True
    ) -> float:
        """
        AI Journey Score (0 - 100):
        Legacy compatibility calculation combining crowd comfort, ETA, and priority duration.
        """
        crowd_score = max(0.0, 100.0 - occupancy_pct)
        eta_score = max(20.0, 100.0 - (eta_mins * 5.0))
        duration_score = 95.0 if has_priority_lane else 75.0

        total_score = (crowd_score * 0.40) + (eta_score * 0.30) + (duration_score * 0.30)
        return round(total_score, 1)

    def _match_stop_index(self, query: str, stops: List[str]) -> Optional[int]:
        """Finds stop index matching query tokens."""
        q = query.lower().strip()
        tokens = [t for t in q.replace(",", " ").replace("-", " ").split() if len(t) > 2]
        if not tokens:
            return None

        for idx, stop in enumerate(stops):
            if any(t in stop for t in tokens):
                return idx
        return None

    def find_candidate_buses(self, origin: str, destination: str) -> List[Dict[str, Any]]:
        """
        Identifies active fleet buses servicing the requested corridor with direction validity.
        """
        candidates: List[Dict[str, Any]] = []

        for bus_num, meta in CORRIDOR_METADATA.items():
            stops = meta["stops"]
            orig_idx = self._match_stop_index(origin, stops)
            dest_idx = self._match_stop_index(destination, stops)

            # Check if corridor services both stops in valid forward sequence
            if orig_idx is not None and dest_idx is not None and orig_idx < dest_idx:
                step_fraction = (dest_idx - orig_idx) / max(1, len(stops) - 1)
                dist_km = round(meta["total_distance_km"] * step_fraction, 1)
                dur_mins = max(10, int(round(meta["base_duration_mins"] * step_fraction)))
                fare = round(10.0 + (dist_km * 1.5), 1)

                candidates.append({
                    "bus_number": bus_num,
                    "metadata": meta,
                    "is_direct": True,
                    "distance_km": dist_km,
                    "duration_mins": dur_mins,
                    "fare_inr": fare,
                    "has_priority_lane": meta["has_priority_lane"]
                })

        # Ensure alternatives exist for journey comparison
        existing_bus_numbers = {c["bus_number"] for c in candidates}
        for bus_num, meta in CORRIDOR_METADATA.items():
            if bus_num not in existing_bus_numbers:
                candidates.append({
                    "bus_number": bus_num,
                    "metadata": meta,
                    "is_direct": False,
                    "distance_km": meta["total_distance_km"],
                    "duration_mins": meta["base_duration_mins"] + 10, # transfer/indirect delay
                    "fare_inr": meta["base_fare_inr"],
                    "has_priority_lane": meta["has_priority_lane"]
                })

        return candidates

    def _select_prediction_horizon(self, duration_mins: int) -> int:
        """Picks suitable H9 forecast horizon based on passenger journey duration."""
        if duration_mins <= 20:
            return 15
        elif duration_mins <= 45:
            return 30
        else:
            return 60

    def evaluate_bus_candidate(
        self,
        candidate: Dict[str, Any],
        preference: str = "balanced"
    ) -> Tuple[BusRecommendationItem, Dict[str, float], str]:
        """
        Evaluates a single bus option across all live and predictive dimensions.
        Returns the scored BusRecommendationItem, score breakdown, and data quality rating.
        """
        bus_num = candidate["bus_number"]
        meta = candidate["metadata"]
        dur_mins = candidate["duration_mins"]
        dist_km = candidate["distance_km"]
        fare = candidate["fare_inr"]
        has_priority = candidate["has_priority_lane"]

        # 1. Live Telemetry
        telemetry = gps_simulator.get_bus_telemetry(bus_num) or {}
        has_live = bool(telemetry)
        raw_eta = telemetry.get("eta_next_stop_mins", 5)
        eta_mins = max(1, int(raw_eta if raw_eta is not None else 5))
        curr_occ = max(0.0, min(100.0, float(telemetry.get("occupancy_pct", 45.0))))
        crowd_tier = telemetry.get("crowd_level", CrowdLevel.MODERATE)
        data_origin = telemetry.get("data_origin", DataOrigin.SIMULATED) if has_live else DataOrigin.ESTIMATE

        # 2. H9 Demand Prediction Integration
        horizon_mins = self._select_prediction_horizon(dur_mins)
        detailed_pred = demand_forecaster.get_detailed_forecast(bus_num)
        
        pred_item = next(
            (f for f in detailed_pred.forecast if f.horizon_minutes == horizon_mins),
            detailed_pred.forecast[0] if detailed_pred.forecast else None
        )

        raw_pred_occ = float(pred_item.occupancy_pct) if pred_item else curr_occ
        pred_occ = max(0.0, min(100.0, raw_pred_occ))
        pred_crowd = pred_item.crowd_level if pred_item else crowd_tier
        pred_conf = max(0.10, min(1.0, float(pred_item.confidence if pred_item else 0.70)))
        is_low_data = (detailed_pred.status == "LOW_DATA")

        # 3. Factor Normalization to [0.0, 1.0] scale
        # ETA component: lower is better (ideal wait <= 5 min)
        s_eta = max(0.10, min(1.0, 1.0 - (eta_mins / 30.0)))
        
        # Current crowd component: lower occupancy is better
        s_crowd = max(0.0, min(1.0, (100.0 - curr_occ) / 100.0))

        # Predicted crowd component: weighted by confidence (low confidence discounts prediction)
        s_pred_raw = max(0.0, min(1.0, (100.0 - pred_occ) / 100.0))
        s_pred = (pred_conf * s_pred_raw) + ((1.0 - pred_conf) * s_crowd)

        # Journey duration component: faster duration + priority lane bonus
        priority_saving = 8.0 if has_priority else 0.0
        eff_duration = max(5.0, dur_mins - priority_saving)
        s_duration = max(0.10, min(1.0, 1.0 - (eff_duration / 60.0)))

        # Fare component: lower fare is better
        raw_fare = candidate.get("fare_inr", 20.0)
        fare = max(10.0, float(raw_fare if raw_fare is not None else 20.0))
        s_fare = max(0.10, min(1.0, 1.0 - ((fare - 10.0) / 40.0)))

        # 4. Multi-Factor Scoring with Preference Weights
        pref_key = preference.lower().strip() if preference else "balanced"
        weights = PREFERENCE_WEIGHTS.get(pref_key, PREFERENCE_WEIGHTS["balanced"])

        composite_score = (
            weights["eta"] * s_eta +
            weights["crowd"] * s_crowd +
            weights["pred_crowd"] * s_pred +
            weights["duration"] * s_duration +
            weights["fare"] * s_fare
        )

        # Reliability adjustment
        if has_live and data_origin == DataOrigin.CV_REPLAY and pred_conf >= 0.75:
            reliability_bonus = 0.04
            data_quality = "HIGH"
        elif not has_live or is_low_data or pred_conf < 0.60:
            reliability_bonus = -0.05
            data_quality = "LOW"
        else:
            reliability_bonus = 0.0
            data_quality = "MEDIUM"

        # Direct route vs transfer adjustment
        is_direct = candidate.get("is_direct", True)
        direct_bonus = 0.08 if is_direct else -0.12

        final_composite = max(0.05, min(0.99, composite_score + reliability_bonus + direct_bonus))
        journey_score_100 = round(final_composite * 100.0, 1)

        score_breakdown = {
            "eta": round(s_eta, 3),
            "crowd": round(s_crowd, 3),
            "predicted_crowd": round(s_pred, 3),
            "journey_time": round(s_duration, 3),
            "fare": round(s_fare, 3),
            "eta_score": round(s_eta, 2),
            "crowd_score": round(s_crowd, 2),
            "predicted_crowd_score": round(s_pred, 2),
            "duration_score": round(s_duration, 2),
            "fare_score": round(s_fare, 2),
            "composite_score": round(final_composite, 3)
        }

        # Candidate item (is_recommended will be assigned during ranking)
        rec_item = BusRecommendationItem(
            bus_number=bus_num,
            route_number=meta["route_number"],
            route_name=meta["route_name"],
            operator_type=meta["operator_type"],
            eta_mins=eta_mins,
            occupancy_pct=curr_occ,
            crowd_level=crowd_tier,
            is_recommended=False,
            journey_score=journey_score_100,
            why_recommended="",
            crowd_saving_vs_alternative_pct=None,
            time_saving_mins=None,
            fare_inr=fare,
            predicted_occupancy_pct=pred_occ,
            predicted_crowd_level=pred_crowd,
            data_quality=data_quality,
            score_breakdown=score_breakdown,
            data_origin=DataOrigin.RECOMMENDATION
        )

        return rec_item, score_breakdown, data_quality

    def _generate_explanation(
        self,
        winner: BusRecommendationItem,
        runner_up: Optional[BusRecommendationItem],
        preference: str,
        data_quality: str
    ) -> Tuple[str, str]:
        """
        Generates deterministic, data-grounded explanations.
        Returns: (why_recommended_for_bus, overall_journey_explanation)
        """
        has_priority = CORRIDOR_METADATA.get(winner.bus_number, {}).get("has_priority_lane", False)
        priority_str = " via Banerji Rd priority lane" if has_priority else ""

        if not runner_up:
            why = f"Direct active service on corridor, arriving in {winner.eta_mins} min ({winner.occupancy_pct:.0f}% occupied){priority_str}."
            exp = f"We recommend Bus {winner.bus_number} as the primary active transit service for this journey."
            return why, exp

        crowd_diff = runner_up.occupancy_pct - winner.occupancy_pct
        eta_diff = runner_up.eta_mins - winner.eta_mins
        winner_dur = CORRIDOR_METADATA.get(winner.bus_number, {}).get("base_duration_mins", 35)
        runner_dur = CORRIDOR_METADATA.get(runner_up.bus_number, {}).get("base_duration_mins", 35)
        time_saving = max(0, runner_dur - winner_dur)

        # Contextual explanation phrasing based on preference mode
        if preference == "least_crowded":
            if crowd_diff > 0:
                why = f"Lowest crowd option ({winner.occupancy_pct:.0f}% vs {runner_up.occupancy_pct:.0f}%), saving {crowd_diff:.0f}% cabin density{priority_str}."
                exp = f"We recommend Bus {winner.bus_number} because it offers the calmest cabin ({winner.occupancy_pct:.0f}% occupancy vs {runner_up.occupancy_pct:.0f}% on Bus {runner_up.bus_number}), with moderate seating availability."
            else:
                why = f"Optimal cabin comfort with predicted occupancy of {winner.predicted_occupancy_pct:.0f}%{priority_str}."
                exp = f"We recommend Bus {winner.bus_number} for cabin comfort under your least crowded preference."
        elif preference == "fastest":
            if eta_diff >= 0:
                why = f"Arrives {eta_diff} min sooner and saves {time_saving} min travel time{priority_str}."
                exp = f"We recommend Bus {winner.bus_number} as the fastest option, arriving in {winner.eta_mins} minutes and saving transit travel time."
            else:
                why = f"Fastest corridor transit time saving {time_saving} min travel time{priority_str}."
                exp = f"We recommend Bus {winner.bus_number} for transit speed and dedicated corridor headway."
        elif preference == "lowest_fare":
            fare_diff = runner_up.fare_inr - winner.fare_inr
            why = f"Economical option at ₹{winner.fare_inr:.0f} (saves ₹{max(0.0, fare_diff):.0f}){priority_str}."
            exp = f"We recommend Bus {winner.bus_number} under your budget preference, offering a fare of ₹{winner.fare_inr:.0f}."
        else:
            # Balanced mode
            if eta_diff >= 0 and crowd_diff >= 0:
                why = f"Arrives {eta_diff} min earlier with {crowd_diff:.0f}% lower crowd ({winner.occupancy_pct:.0f}% vs {runner_up.occupancy_pct:.0f}%){priority_str}."
                exp = (
                    f"We recommend Bus {winner.bus_number} because it arrives in {winner.eta_mins} minutes "
                    f"with only {winner.occupancy_pct:.0f}% occupancy, providing a significantly calmer journey "
                    f"and saving {time_saving} minutes over Bus {runner_up.bus_number}."
                )
            elif crowd_diff > 15:
                why = f"Arrives {abs(eta_diff)} min later, but provides {crowd_diff:.0f}% lower crowding and calmer seating{priority_str}."
                exp = f"Bus {winner.bus_number} arrives {abs(eta_diff)} minutes later than Bus {runner_up.bus_number}, but is expected to be substantially less crowded ({winner.occupancy_pct:.0f}% vs {runner_up.occupancy_pct:.0f}%)."
            else:
                why = f"Optimal balance of {winner.eta_mins} min arrival, {winner.occupancy_pct:.0f}% occupancy, and corridor reliability{priority_str}."
                exp = f"We recommend Bus {winner.bus_number} for the best overall balance of arrival timing, cabin crowding, and journey duration."

        if data_quality == "LOW":
            exp += " (Note: Limited live crowd data available; recommendation is primarily based on ETA)."

        return why, exp

    def plan_journey(
        self,
        origin: str = "Kaloor Metro Station, Kochi",
        destination: str = "Vyttila Mobility Hub",
        preference: str = "balanced"
    ) -> JourneyPlanResponse:
        """
        Main recommendation entry point.
        Scores candidate buses dynamically with zero hardcoded winners.
        """
        # Validate preference
        pref = preference.lower().strip() if preference else "balanced"
        if pref not in PREFERENCE_WEIGHTS:
            pref = "balanced"

        candidates = self.find_candidate_buses(origin, destination)
        if not candidates:
            # Fallback for completely unknown route
            candidates = [{
                "bus_number": "205",
                "metadata": CORRIDOR_METADATA["205"],
                "is_direct": False,
                "distance_km": 15.0,
                "duration_mins": 30,
                "fare_inr": 25.0,
                "has_priority_lane": True
            }]

        evaluated: List[Tuple[BusRecommendationItem, Dict[str, float], str]] = []
        for cand in candidates:
            item, breakdown, quality = self.evaluate_bus_candidate(cand, preference=pref)
            evaluated.append((item, breakdown, quality))

        # Sort strictly descending by journey_score (NO hardcoded bus winner) with deterministic tie-breaking
        evaluated.sort(key=lambda x: (x[0].journey_score, -x[0].eta_mins, -x[0].occupancy_pct), reverse=True)

        winner_item, winner_breakdown, winner_quality = evaluated[0]
        runner_up_item = evaluated[1][0] if len(evaluated) > 1 else None

        # Build explainability deltas
        crowd_saving = round(runner_up_item.occupancy_pct - winner_item.occupancy_pct, 1) if runner_up_item else None
        time_saving = max(0, runner_up_item.eta_mins - winner_item.eta_mins) if runner_up_item else None

        why_rec, overall_exp = self._generate_explanation(
            winner=winner_item,
            runner_up=runner_up_item,
            preference=pref,
            data_quality=winner_quality
        )

        # Mark winner as recommended
        recommended_bus = BusRecommendationItem(
            bus_number=winner_item.bus_number,
            route_number=winner_item.route_number,
            route_name=winner_item.route_name,
            operator_type=winner_item.operator_type,
            eta_mins=winner_item.eta_mins,
            occupancy_pct=winner_item.occupancy_pct,
            crowd_level=winner_item.crowd_level,
            is_recommended=True,
            journey_score=winner_item.journey_score,
            why_recommended=why_rec,
            crowd_saving_vs_alternative_pct=crowd_saving if (crowd_saving and crowd_saving > 0) else None,
            time_saving_mins=time_saving if (time_saving and time_saving > 0) else None,
            fare_inr=winner_item.fare_inr,
            predicted_occupancy_pct=winner_item.predicted_occupancy_pct,
            predicted_crowd_level=winner_item.predicted_crowd_level,
            data_quality=winner_quality,
            score_breakdown=winner_breakdown,
            data_origin=DataOrigin.RECOMMENDATION
        )

        alternative_buses: List[BusRecommendationItem] = []
        for item, b_down, b_qual in evaluated[1:]:
            alt_why = (
                f"{item.occupancy_pct:.0f}% occupied ({item.crowd_level.value if hasattr(item.crowd_level, 'value') else item.crowd_level}), "
                f"arrives in {item.eta_mins} min."
            )
            alternative_buses.append(
                BusRecommendationItem(
                    bus_number=item.bus_number,
                    route_number=item.route_number,
                    route_name=item.route_name,
                    operator_type=item.operator_type,
                    eta_mins=item.eta_mins,
                    occupancy_pct=item.occupancy_pct,
                    crowd_level=item.crowd_level,
                    is_recommended=False,
                    journey_score=item.journey_score,
                    why_recommended=alt_why,
                    crowd_saving_vs_alternative_pct=None,
                    time_saving_mins=None,
                    fare_inr=item.fare_inr,
                    predicted_occupancy_pct=item.predicted_occupancy_pct,
                    predicted_crowd_level=item.predicted_crowd_level,
                    data_quality=b_qual,
                    score_breakdown=b_down,
                    data_origin=DataOrigin.SIMULATED
                )
            )

        # Distance & duration
        winner_dist = candidates[0].get("distance_km", 14.8)
        winner_dur = candidates[0].get("duration_mins", 28)

        factors = {
            "eta": True,
            "current_crowd": True,
            "predicted_crowd": True,
            "journey_time": True,
            "fare": True,
            "walking": False
        }

        return JourneyPlanResponse(
            origin_stop=origin,
            destination_stop=destination,
            recommended_bus=recommended_bus,
            alternative_buses=alternative_buses,
            route_distance_km=winner_dist,
            estimated_travel_time_mins=winner_dur,
            explanation=overall_exp,
            preference=pref,
            factors_considered=factors,
            data_quality=winner_quality,
            data_origin=DataOrigin.RECOMMENDATION
        )

recommendation_engine = RecommendationEngine()
