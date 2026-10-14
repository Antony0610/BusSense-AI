"""
BusSense AI - Historical Occupancy Dataset & Feature Engineering (Phase H9)
Generates and manages deterministic historical occupancy observations for Kerala transit corridors.
Provides chronological time-series feature extraction without future-data leakage.
"""
from datetime import datetime, timedelta, timezone
from typing import List, Dict, Any, Tuple
import math
import numpy as np

# Kerala Corridor Baselines (Corridor Profiles)
CORRIDOR_PROFILES = {
    "205": {
        "route_number": "12",
        "corridor_name": "Aluva Metro ➔ Vyttila Mobility Hub via Kaloor",
        "capacity": 55,
        "base_density": 0.42,
        "peak_morning_hour": 8.75, # 08:45 AM
        "peak_evening_hour": 17.50, # 05:30 PM
    },
    "14A": {
        "route_number": "14A",
        "corridor_name": "Fort Kochi ➔ Infopark Phase 1 via Kaloor",
        "capacity": 45,
        "base_density": 0.65,
        "peak_morning_hour": 9.25, # 09:15 AM
        "peak_evening_hour": 18.25, # 06:15 PM
    },
    "12": {
        "route_number": "12",
        "corridor_name": "Kaloor ➔ Infopark Express",
        "capacity": 55,
        "base_density": 0.50,
        "peak_morning_hour": 9.0, # 09:00 AM
        "peak_evening_hour": 17.75, # 05:45 PM
    },
}

def generate_corridor_historical_observations(
    days: int = 2,
    interval_minutes: int = 15,
    base_time: datetime = None
) -> List[Dict[str, Any]]:
    """
    Generates a deterministic, reproducible series of chronological historical observations.
    Reflects diurnal transit commute curves along Greater Kochi corridors (Aluva, Kaloor, Infopark).
    Classified as: DEVELOPMENT / LOW-DATA DATASET.
    """
    if base_time is None:
        base_time = datetime(2026, 9, 25, 0, 0, 0, tzinfo=timezone.utc)

    total_steps = int((days * 24 * 60) / interval_minutes)
    records: List[Dict[str, Any]] = []

    for bus_key, profile in CORRIDOR_PROFILES.items():
        cap = profile["capacity"]
        base_dens = profile["base_density"]
        m_peak = profile["peak_morning_hour"]
        e_peak = profile["peak_evening_hour"]

        for step in range(total_steps):
            obs_time = base_time + timedelta(minutes=step * interval_minutes)
            hour_val = obs_time.hour + (obs_time.minute / 60.0)
            is_weekend = 1 if obs_time.weekday() >= 5 else 0

            # Commuter demand curves (Gaussian bells around morning and evening peaks)
            morning_bell = math.exp(-0.5 * ((hour_val - m_peak) / 1.5) ** 2)
            evening_bell = math.exp(-0.5 * ((hour_val - e_peak) / 1.7) ** 2)
            midday_dip = 0.15 * math.sin((hour_val / 24.0) * math.pi)

            # Combined occupancy ratio
            weekend_discount = 0.65 if is_weekend else 1.0
            density = (base_dens * 0.4 + morning_bell * 0.45 + evening_bell * 0.40 + midday_dip) * weekend_discount
            # Small deterministic variation based on step index (avoids identical values)
            noise = 0.03 * math.sin(step * 0.35 + int(bus_key.replace("A", "1")))
            clamped_ratio = max(0.10, min(0.96, density + noise))

            passenger_count = int(round(clamped_ratio * cap))
            occ_pct = round((passenger_count / cap) * 100.0, 1)

            if occ_pct < 50.0:
                crowd_tier = "LOW"
            elif occ_pct <= 80.0:
                crowd_tier = "MODERATE"
            else:
                crowd_tier = "CROWDED"

            records.append({
                "bus_number": bus_key,
                "route_number": profile["route_number"],
                "capacity": cap,
                "passenger_count": passenger_count,
                "occupancy_pct": occ_pct,
                "crowd_level": crowd_tier,
                "recorded_at": obs_time.isoformat(),
                "hour_of_day": round(hour_val, 2),
                "day_of_week": obs_time.weekday(),
                "is_weekend": is_weekend,
            })

    # Sort strictly chronologically to guarantee no time leakage
    records.sort(key=lambda r: r["recorded_at"])
    return records


class FeatureEngineer:
    """
    Extracts chronological, explainable features for demand forecasting.
    Guarantees no future-data leakage.
    """
    FEATURE_NAMES = [
        "hour_of_day",
        "sin_hour",
        "cos_hour",
        "day_of_week",
        "is_weekend",
        "current_occupancy",
        "lag_1_occupancy",
        "rolling_mean_3",
        "occupancy_trend_slope",
        "corridor_base_density"
    ]

    @classmethod
    def extract_features_for_observation(
        cls,
        hour_of_day: float,
        day_of_week: int,
        is_weekend: int,
        current_occupancy: float,
        lag_1_occupancy: float,
        lag_2_occupancy: float,
        corridor_base_density: float = 0.50
    ) -> List[float]:
        """
        Builds a single 10-feature vector for inference.
        """
        # Cyclical temporal encoding
        rad = 2.0 * math.pi * (hour_of_day / 24.0)
        sin_h = math.sin(rad)
        cos_h = math.cos(rad)

        # Rolling mean of recent 3 steps (current, lag-1, lag-2)
        rolling_3 = (current_occupancy + lag_1_occupancy + lag_2_occupancy) / 3.0

        # Occupancy slope (rate of change between consecutive 15-min intervals)
        slope = current_occupancy - lag_1_occupancy

        return [
            round(hour_of_day, 2),
            round(sin_h, 4),
            round(cos_h, 4),
            day_of_week,
            is_weekend,
            round(current_occupancy, 2),
            round(lag_1_occupancy, 2),
            round(rolling_3, 2),
            round(slope, 2),
            round(corridor_base_density, 2)
        ]

    @classmethod
    def build_chronological_dataset(
        cls,
        observations: List[Dict[str, Any]]
    ) -> Tuple[np.ndarray, Dict[int, np.ndarray]]:
        """
        Processes historical observations into chronological feature matrix X
        and multi-horizon targets y:
        horizons: 15 min (+1 step), 30 min (+2 steps), 60 min (+4 steps).
        Strictly preserves time ordering without random shuffling.
        """
        # Group by bus_number to preserve route-specific temporal continuity
        by_bus: Dict[str, List[Dict[str, Any]]] = {}
        for obs in observations:
            by_bus.setdefault(obs["bus_number"], []).append(obs)

        X_rows = []
        y_15 = []
        y_30 = []
        y_60 = []

        for bus_key, bus_obs in by_bus.items():
            bus_obs.sort(key=lambda r: r["recorded_at"])
            base_dens = CORRIDOR_PROFILES.get(bus_key, {}).get("base_density", 0.50)

            # Need at least 2 lag steps and 4 future steps (+60 min)
            for i in range(2, len(bus_obs) - 4):
                curr = bus_obs[i]
                prev1 = bus_obs[i - 1]
                prev2 = bus_obs[i - 2]

                fut_15 = bus_obs[i + 1] # +15 min
                fut_30 = bus_obs[i + 2] # +30 min
                fut_60 = bus_obs[i + 4] # +60 min

                feat = cls.extract_features_for_observation(
                    hour_of_day=curr["hour_of_day"],
                    day_of_week=curr["day_of_week"],
                    is_weekend=curr["is_weekend"],
                    current_occupancy=curr["occupancy_pct"],
                    lag_1_occupancy=prev1["occupancy_pct"],
                    lag_2_occupancy=prev2["occupancy_pct"],
                    corridor_base_density=base_dens
                )

                X_rows.append(feat)
                y_15.append(fut_15["occupancy_pct"])
                y_30.append(fut_30["occupancy_pct"])
                y_60.append(fut_60["occupancy_pct"])

        X = np.array(X_rows, dtype=np.float32)
        y = {
            15: np.array(y_15, dtype=np.float32),
            30: np.array(y_30, dtype=np.float32),
            60: np.array(y_60, dtype=np.float32),
        }
        return X, y
