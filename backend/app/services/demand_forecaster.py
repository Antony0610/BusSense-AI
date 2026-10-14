"""
BusSense AI - Demand Prediction & Crowd Forecasting Engine (Phase H9)
Uses chronological time-series observations along Kerala transit corridors
with explainable scikit-learn Ridge regression across standard horizons:
NOW, +15 MIN, +30 MIN, +60 MIN.

Features:
- Chronological train/test split respecting time-ordering (zero future-data leakage)
- Persistence baseline model comparison (MAE & RMSE evaluation)
- Dynamic inference based on real-time fleet state / CV replay data
- Low-data safety & quality classification
- Zero hardcoded vehicle trajectories
- Strict privacy: only operates on aggregate headcounts and occupancy ratios
"""
from datetime import datetime, timezone, timedelta
import math
from typing import List, Dict, Any, Optional
import numpy as np
from sklearn.linear_model import Ridge

from app.schemas.prediction import (
    CrowdForecastPoint,
    DetailedForecastItem,
    CurrentObservationDetail,
    EvaluationMetricSummary,
    DetailedBusForecastResponse,
)
from app.schemas.common import CrowdLevel, DataOrigin
from app.services.cv_occupancy import cv_occupancy_service
from app.services.prediction_dataset import (
    generate_corridor_historical_observations,
    FeatureEngineer,
    CORRIDOR_PROFILES,
)

class DemandForecasterService:
    """
    Central demand prediction and crowd forecasting service for BusSense AI.
    """
    MODEL_VERSION = "ridge-demand-v2-corridor"
    TRAINING_DATA_QUALITY = "DEVELOPMENT / LOW-DATA (558 chronological observations)"

    def __init__(self):
        self.models: Dict[int, Ridge] = {}
        self.evaluation_metrics: Dict[int, Dict[str, float]] = {}
        self.training_sample_count: int = 0
        self._train_models()

    def _train_models(self):
        """
        Trains multi-horizon Ridge models on chronological historical corridor observations.
        Strictly applies chronological train/test split (80% train, 20% test) to prevent
        future data leakage.
        Evaluates models against a persistence baseline: future_occupancy = current_occupancy.
        """
        observations = generate_corridor_historical_observations(days=2, interval_minutes=15)
        self.training_sample_count = len(observations)

        X, y = FeatureEngineer.build_chronological_dataset(observations)
        split = int(len(X) * 0.8)

        X_train, X_test = X[:split], X[split:]
        current_occ_test = X_test[:, 5] # Column 5 is current_occupancy

        for horizon in [15, 30, 60]:
            y_train = y[horizon][:split]
            y_test = y[horizon][split:]

            # Train explainable Ridge regressor with L2 regularization
            model = Ridge(alpha=1.0)
            model.fit(X_train, y_train)
            self.models[horizon] = model

            # Evaluate on unseen future test split
            preds = model.predict(X_test)
            preds_clamped = np.clip(preds, 0.0, 100.0)

            # 1. Model metrics
            model_mae = float(np.mean(np.abs(preds_clamped - y_test)))
            model_rmse = float(math.sqrt(np.mean((preds_clamped - y_test) ** 2)))

            # 2. Persistence baseline metrics: future occupancy = current occupancy
            baseline_mae = float(np.mean(np.abs(current_occ_test - y_test)))
            baseline_rmse = float(math.sqrt(np.mean((current_occ_test - y_test) ** 2)))

            # 3. Improvement percentage
            improvement = round(((baseline_mae - model_mae) / max(0.001, baseline_mae)) * 100.0, 1)

            self.evaluation_metrics[horizon] = {
                "model_mae": round(model_mae, 2),
                "model_rmse": round(model_rmse, 2),
                "baseline_mae": round(baseline_mae, 2),
                "baseline_rmse": round(baseline_rmse, 2),
                "mae_improvement_pct": improvement,
            }

    def _get_bus_state(self, bus_number: str) -> Dict[str, Any]:
        """
        Retrieves real-time telemetry from gps_simulator fleet state.
        Supports bus number (e.g. '205', '14A', '12') or bus UUID.
        """
        from app.services.gps_simulator import gps_simulator
        bus = gps_simulator.fleet_state.get(bus_number)
        if not bus:
            # Check by bus_id
            for b_num, state in gps_simulator.fleet_state.items():
                if state.get("bus_id") == bus_number:
                    bus = state
                    break
        return bus or {}

    def forecast_corridor_crowd(
        self,
        route_number: str = "205",
        is_rain: bool = False
    ) -> List[CrowdForecastPoint]:
        """
        Generates standard 4-horizon predictive crowd estimates:
        NOW, +15 MIN, +30 MIN, +60 MIN.
        Dynamically drives predictions from real fleet observations / CV replay data.
        Zero hardcoded bus trajectories.
        """
        bus_state = self._get_bus_state(route_number)
        now_dt = datetime.now(timezone.utc)
        hour_val = now_dt.hour + (now_dt.minute / 60.0)
        day_of_week = now_dt.weekday()
        is_weekend = 1 if day_of_week >= 5 else 0

        # Current observed occupancy
        if bus_state:
            curr_occ = float(bus_state.get("occupancy_pct", 41.8))
            cap = int(bus_state.get("capacity", 55))
            origin = bus_state.get("data_origin", DataOrigin.SIMULATED)
            is_low_data = False
        else:
            # Fallback for unmonitored bus identifier (Low-Data mode)
            profile = CORRIDOR_PROFILES.get(route_number)
            curr_occ = (profile["base_density"] * 100.0) if profile else 40.0
            cap = profile["capacity"] if profile else 50
            origin = DataOrigin.SIMULATED
            is_low_data = True

        profile = CORRIDOR_PROFILES.get(route_number, {})
        base_dens = profile.get("base_density", 0.50)

        # Build feature vector for current vehicle context
        features = FeatureEngineer.extract_features_for_observation(
            hour_of_day=hour_val,
            day_of_week=day_of_week,
            is_weekend=is_weekend,
            current_occupancy=curr_occ,
            lag_1_occupancy=max(0.0, curr_occ - 2.5),
            lag_2_occupancy=max(0.0, curr_occ - 5.0),
            corridor_base_density=base_dens
        )

        horizons = [
            ("NOW", 0),
            ("+15 MIN", 15),
            ("+30 MIN", 30),
            ("+60 MIN", 60)
        ]

        # Rain impact modifiers (modest realistic load increase due to modal shift from 2-wheelers)
        rain_bump = {0: 0.0, 15: 3.5, 30: 5.5, 60: 7.0} if is_rain else {0: 0.0, 15: 0.0, 30: 0.0, 60: 0.0}

        points: List[CrowdForecastPoint] = []

        for label, mins in horizons:
            if mins == 0:
                pred_val = curr_occ
                # High confidence for current observation
                conf = 0.95 if origin == DataOrigin.CV_REPLAY else 0.88
            else:
                raw_pred = float(self.models[mins].predict([features])[0])
                pred_val = raw_pred + rain_bump[mins]
                # Confidence naturally decays over forecast horizon
                decay = {15: 0.84, 30: 0.76, 60: 0.65}.get(mins, 0.70)
                conf = round(decay * (0.65 if is_low_data else 1.0), 2)

            clamped_pct = round(max(0.0, min(100.0, pred_val)), 1)
            crowd_tier = cv_occupancy_service.calculate_crowd_tier(clamped_pct)

            points.append(
                CrowdForecastPoint(
                    time_offset=label,
                    minutes_from_now=mins,
                    predicted_occupancy_pct=clamped_pct,
                    crowd_level=crowd_tier,
                    confidence=conf,
                    data_origin=DataOrigin.PREDICTION
                )
            )

        return points

    def get_detailed_forecast(
        self,
        bus_number: str = "205",
        is_rain: bool = False
    ) -> DetailedBusForecastResponse:
        """
        Returns rich structured forecast conforming to Step 4 & Step 9 specification:
        current observation, multi-horizon forecasts, evaluation metrics, and low-data status.
        """
        bus_state = self._get_bus_state(bus_number)
        is_low_data = not bool(bus_state)
        now_dt = datetime.now(timezone.utc)

        raw_points = self.forecast_corridor_crowd(route_number=bus_number, is_rain=is_rain)
        lookup = {p.time_offset: p for p in raw_points}

        p_now = lookup.get("NOW", raw_points[0])
        p_15 = lookup.get("+15 MIN", raw_points[1] if len(raw_points) > 1 else raw_points[0])
        p_30 = lookup.get("+30 MIN", raw_points[2] if len(raw_points) > 2 else raw_points[0])
        p_60 = lookup.get("+60 MIN", raw_points[3] if len(raw_points) > 3 else raw_points[0])

        current_detail = CurrentObservationDetail(
            occupancy_pct=p_now.predicted_occupancy_pct,
            crowd_level=p_now.crowd_level,
            passenger_count=int(bus_state.get("passenger_count", round(p_now.predicted_occupancy_pct * 0.55))),
            capacity=int(bus_state.get("capacity", 55)),
            data_origin=bus_state.get("data_origin", DataOrigin.SIMULATED)
        )

        def _trend_message(curr: float, fut: float) -> str:
            diff = fut - curr
            if diff >= 10.0:
                return "Expected to get significantly busier"
            elif diff >= 4.0:
                return "Expected to get busier"
            elif diff <= -10.0:
                return "Expected to clear up considerably"
            elif diff <= -4.0:
                return "Expected to ease slightly"
            return "Expected to remain steady"

        forecast_items = [
            DetailedForecastItem(
                horizon_minutes=15,
                occupancy_pct=p_15.predicted_occupancy_pct,
                crowd_level=p_15.crowd_level,
                confidence=p_15.confidence,
                message=_trend_message(p_now.predicted_occupancy_pct, p_15.predicted_occupancy_pct)
            ),
            DetailedForecastItem(
                horizon_minutes=30,
                occupancy_pct=p_30.predicted_occupancy_pct,
                crowd_level=p_30.crowd_level,
                confidence=p_30.confidence,
                message=_trend_message(p_15.predicted_occupancy_pct, p_30.predicted_occupancy_pct)
            ),
            DetailedForecastItem(
                horizon_minutes=60,
                occupancy_pct=p_60.predicted_occupancy_pct,
                crowd_level=p_60.crowd_level,
                confidence=p_60.confidence,
                message=_trend_message(p_30.predicted_occupancy_pct, p_60.predicted_occupancy_pct)
            ),
        ]

        metric_summaries = [
            EvaluationMetricSummary(
                horizon_minutes=h,
                baseline_mae=self.evaluation_metrics[h]["baseline_mae"],
                model_mae=self.evaluation_metrics[h]["model_mae"],
                baseline_rmse=self.evaluation_metrics[h]["baseline_rmse"],
                model_rmse=self.evaluation_metrics[h]["model_rmse"],
                mae_improvement_pct=self.evaluation_metrics[h]["mae_improvement_pct"],
            )
            for h in [15, 30, 60]
            if h in self.evaluation_metrics
        ]

        status = "LOW_DATA" if is_low_data else "OPTIMAL"

        return DetailedBusForecastResponse(
            bus_number=bus_number,
            route_number=bus_state.get("route_number", f"Route {bus_number}"),
            generated_at=now_dt.isoformat(),
            current=current_detail,
            forecast=forecast_items,
            model_version=self.MODEL_VERSION,
            training_data_quality=self.TRAINING_DATA_QUALITY,
            status=status,
            evaluation_metrics=metric_summaries,
            data_origin=DataOrigin.PREDICTION
        )

demand_forecaster = DemandForecasterService()
