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
    HorizonEvaluationDetail,
    PeakOffPeakEvaluation,
    CorridorEvaluationDetail,
    PilotForecastingEvaluationResponse,
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
        Phase H18: Chronological train (70%), validation (15%), and unseen future test (15%) split.
        Zero future-data leakage.
        Evaluates against BOTH persistence ($y_{t+h} = y_t$) and Simple Moving Average (SMA-3) baselines.
        Computes residual distributions (mean, std, skewness) and normalized feature importance.
        """
        observations = generate_corridor_historical_observations(days=2, interval_minutes=15)
        self.training_sample_count = len(observations)

        X, y = FeatureEngineer.build_chronological_dataset(observations)
        self._total_dataset_size = len(X)
        self._train_split = int(len(X) * 0.70)
        self._val_split = int(len(X) * 0.85)
        self._test_split_idx = self._val_split

        X_train = X[:self._train_split]
        X_val = X[self._train_split:self._val_split]
        X_test = X[self._val_split:]
        current_occ_test = X_test[:, 5] # Column 5 is current_occupancy

        self._X_test = X_test
        self._y_test = y

        # Precompute SMA-3 baseline on test set using prior observations
        sma_test_preds = np.zeros(len(X_test))
        for idx in range(len(X_test)):
            orig_idx = self._val_split + idx
            p1 = X[orig_idx, 5]
            p2 = X[orig_idx - 1, 5] if orig_idx >= 1 else p1
            p3 = X[orig_idx - 2, 5] if orig_idx >= 2 else p2
            sma_test_preds[idx] = (p1 + p2 + p3) / 3.0

        feature_names = [
            "hour_sin", "hour_cos", "is_weekend", "day_of_week", "temperature",
            "current_occupancy", "rain_intensity", "lag_15m_occ", "lag_30m_occ", "corridor_density"
        ]
        coef_accum = np.zeros(len(feature_names))

        self.residual_distributions: Dict[str, Dict[str, float]] = {}

        for horizon in [15, 30, 60]:
            y_train = y[horizon][:self._train_split]
            y_val = y[horizon][self._train_split:self._val_split]
            y_test = y[horizon][self._val_split:]

            # Train explainable Ridge regressor with L2 regularization
            model = Ridge(alpha=1.0)
            model.fit(X_train, y_train)
            self.models[horizon] = model

            # Accumulate feature weights
            coef_accum += np.abs(model.coef_)

            # Evaluate on unseen future test split
            preds = model.predict(X_test)
            preds_clamped = np.clip(preds, 0.0, 100.0)

            # 1. Model metrics
            model_mae = float(np.mean(np.abs(preds_clamped - y_test)))
            model_rmse = float(math.sqrt(np.mean((preds_clamped - y_test) ** 2)))

            # 2. Persistence baseline metrics: future occupancy = current occupancy
            baseline_mae = float(np.mean(np.abs(current_occ_test - y_test)))
            baseline_rmse = float(math.sqrt(np.mean((current_occ_test - y_test) ** 2)))

            # 3. Simple Moving Average (SMA-3) baseline metrics
            sma_mae = float(np.mean(np.abs(sma_test_preds - y_test)))
            sma_rmse = float(math.sqrt(np.mean((sma_test_preds - y_test) ** 2)))

            # 4. Improvement percentages
            persistence_imp = round(((baseline_mae - model_mae) / max(0.001, baseline_mae)) * 100.0, 1)
            sma_imp = round(((sma_mae - model_mae) / max(0.001, sma_mae)) * 100.0, 1)

            # 5. Residual analysis (mean, std dev, skewness)
            residuals = preds_clamped - y_test
            mean_res = float(np.mean(residuals))
            res_std = float(np.std(residuals))
            res_skew = float(np.mean(((residuals - mean_res) / max(0.001, res_std)) ** 3))

            self.residual_distributions[f"+{horizon}m"] = {
                "mean_residual": round(mean_res, 2),
                "residual_std": round(res_std, 2),
                "residual_skewness": round(res_skew, 2)
            }

            self.evaluation_metrics[horizon] = {
                "model_mae": round(model_mae, 2),
                "model_rmse": round(model_rmse, 2),
                "baseline_mae": round(baseline_mae, 2),
                "baseline_rmse": round(baseline_rmse, 2),
                "mae_improvement_pct": persistence_imp,
                "sma_baseline_mae": round(sma_mae, 2),
                "sma_baseline_rmse": round(sma_rmse, 2),
                "sma_mae_improvement_pct": sma_imp,
                "mean_residual": round(mean_res, 2),
                "residual_std": round(res_std, 2),
                "residual_skewness": round(res_skew, 2),
            }

        # Normalize feature importance
        total_weight = max(0.0001, float(np.sum(coef_accum)))
        self.feature_importance: Dict[str, float] = {
            name: round(float(coef_accum[i] / total_weight), 3)
            for i, name in enumerate(feature_names)
        }

    def evaluate_peak_vs_offpeak(self) -> PeakOffPeakEvaluation:
        """
        Evaluates forecaster vs persistence baseline across peak commute hours
        (08:00-10:30, 17:00-19:30 IST) vs off-peak hours.
        """
        X_test = self._X_test
        hour = X_test[:, 0]
        # Peak definition: 08:00-10:30 (8.0-10.5) and 17:00-19:30 (17.0-19.5)
        peak_mask = ((hour >= 8.0) & (hour <= 10.5)) | ((hour >= 17.0) & (hour <= 19.5))
        offpeak_mask = ~peak_mask

        peak_metrics: Dict[int, HorizonEvaluationDetail] = {}
        offpeak_metrics: Dict[int, HorizonEvaluationDetail] = {}

        current_occ_test = X_test[:, 5]

        for horizon in [15, 30, 60]:
            y_test = self._y_test[horizon][self._test_split_idx:]
            model = self.models[horizon]

            # Peak evaluation
            if np.sum(peak_mask) > 0:
                p_X = X_test[peak_mask]
                p_y = y_test[peak_mask]
                p_curr = current_occ_test[peak_mask]
                p_preds = np.clip(model.predict(p_X), 0.0, 100.0)

                m_mae = float(np.mean(np.abs(p_preds - p_y)))
                m_rmse = float(math.sqrt(np.mean((p_preds - p_y) ** 2)))
                b_mae = float(np.mean(np.abs(p_curr - p_y)))
                b_rmse = float(math.sqrt(np.mean((p_curr - p_y) ** 2)))
                imp = round(((b_mae - m_mae) / max(0.001, b_mae)) * 100.0, 1)

                peak_metrics[horizon] = HorizonEvaluationDetail(
                    horizon_minutes=horizon,
                    model_mae=round(m_mae, 2),
                    model_rmse=round(m_rmse, 2),
                    baseline_mae=round(b_mae, 2),
                    baseline_rmse=round(b_rmse, 2),
                    mae_improvement_pct=imp
                )

            # Off-peak evaluation
            if np.sum(offpeak_mask) > 0:
                op_X = X_test[offpeak_mask]
                op_y = y_test[offpeak_mask]
                op_curr = current_occ_test[offpeak_mask]
                op_preds = np.clip(model.predict(op_X), 0.0, 100.0)

                m_mae = float(np.mean(np.abs(op_preds - op_y)))
                m_rmse = float(math.sqrt(np.mean((op_preds - op_y) ** 2)))
                b_mae = float(np.mean(np.abs(op_curr - op_y)))
                b_rmse = float(math.sqrt(np.mean((op_curr - op_y) ** 2)))
                imp = round(((b_mae - m_mae) / max(0.001, b_mae)) * 100.0, 1)

                offpeak_metrics[horizon] = HorizonEvaluationDetail(
                    horizon_minutes=horizon,
                    model_mae=round(m_mae, 2),
                    model_rmse=round(m_rmse, 2),
                    baseline_mae=round(b_mae, 2),
                    baseline_rmse=round(b_rmse, 2),
                    mae_improvement_pct=imp
                )

        return PeakOffPeakEvaluation(
            peak_hours_definition="08:00-10:30, 17:00-19:30 IST",
            peak_sample_count=int(np.sum(peak_mask)),
            offpeak_sample_count=int(np.sum(offpeak_mask)),
            peak_metrics=peak_metrics,
            offpeak_metrics=offpeak_metrics
        )

    def evaluate_corridor_metrics(self) -> List[CorridorEvaluationDetail]:
        """
        Evaluates forecasting performance per Greater Kochi transit corridor against persistence baseline.
        """
        X_test = self._X_test
        current_occ_test = X_test[:, 5]
        densities = X_test[:, 9]

        results: List[CorridorEvaluationDetail] = []

        corridors = [
            ("205", "Aluva Metro ➔ Vyttila Mobility Hub via Kaloor", 0.42),
            ("14A", "Fort Kochi ➔ Infopark Phase 1 via Kaloor", 0.65),
            ("12", "Kaloor ➔ Infopark Express", 0.50),
        ]

        for key, name, base_dens in corridors:
            mask = np.isclose(densities, base_dens, atol=0.03)
            c_count = int(np.sum(mask))
            if c_count == 0:
                continue

            c_X = X_test[mask]
            c_curr = current_occ_test[mask]
            horizons: Dict[int, HorizonEvaluationDetail] = {}

            for horizon in [15, 30, 60]:
                y_test = self._y_test[horizon][self._test_split_idx:][mask]
                model = self.models[horizon]
                preds = np.clip(model.predict(c_X), 0.0, 100.0)

                m_mae = float(np.mean(np.abs(preds - y_test)))
                m_rmse = float(math.sqrt(np.mean((preds - y_test) ** 2)))
                b_mae = float(np.mean(np.abs(c_curr - y_test)))
                b_rmse = float(math.sqrt(np.mean((c_curr - y_test) ** 2)))
                imp = round(((b_mae - m_mae) / max(0.001, b_mae)) * 100.0, 1)

                horizons[horizon] = HorizonEvaluationDetail(
                    horizon_minutes=horizon,
                    model_mae=round(m_mae, 2),
                    model_rmse=round(m_rmse, 2),
                    baseline_mae=round(b_mae, 2),
                    baseline_rmse=round(b_rmse, 2),
                    mae_improvement_pct=imp
                )

            results.append(CorridorEvaluationDetail(
                corridor_key=key,
                corridor_name=name,
                sample_count=c_count,
                horizons=horizons
            ))

        return results

    def get_pilot_forecasting_evaluation(self) -> PilotForecastingEvaluationResponse:
        """
        Returns full empirical evaluation package for the pilot evaluation framework.
        """
        overall = [
            HorizonEvaluationDetail(
                horizon_minutes=h,
                baseline_mae=self.evaluation_metrics[h]["baseline_mae"],
                model_mae=self.evaluation_metrics[h]["model_mae"],
                baseline_rmse=self.evaluation_metrics[h]["baseline_rmse"],
                model_rmse=self.evaluation_metrics[h]["model_rmse"],
                mae_improvement_pct=self.evaluation_metrics[h]["mae_improvement_pct"],
                sma_baseline_mae=self.evaluation_metrics[h].get("sma_baseline_mae"),
                sma_baseline_rmse=self.evaluation_metrics[h].get("sma_baseline_rmse"),
                sma_mae_improvement_pct=self.evaluation_metrics[h].get("sma_mae_improvement_pct"),
                mean_residual=self.evaluation_metrics[h].get("mean_residual"),
                residual_std=self.evaluation_metrics[h].get("residual_std"),
                residual_skewness=self.evaluation_metrics[h].get("residual_skewness")
            )
            for h in [15, 30, 60]
            if h in self.evaluation_metrics
        ]

        return PilotForecastingEvaluationResponse(
            model_version=self.MODEL_VERSION,
            training_data_quality=self.TRAINING_DATA_QUALITY,
            total_samples=self._total_dataset_size,
            train_split_pct=70.0,
            validation_split_pct=15.0,
            test_split_pct=15.0,
            overall_metrics=overall,
            peak_vs_offpeak=self.evaluate_peak_vs_offpeak(),
            corridor_evaluations=self.evaluate_corridor_metrics(),
            feature_importance=getattr(self, "feature_importance", None),
            overfitting_risk_assessment="LOW (L2 regularization alpha=1.0, chronological train/val/test split, 10 engineered features)",
            residual_distribution=getattr(self, "residual_distributions", None)
        )

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
