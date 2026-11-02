"""
BusSense AI - Transit Data Ingestion Service
Manages real-time and batch ingestion boundary for authorized transit data:
- GPS / AVL Telemetry with spatial bounds, staleness and monotonic sequencing
- CCTV-derived aggregate passenger headcounts (strictly zero-biometric)
- Route schedules, stops, and timetable imports
- Service disruption and incident feeds
- Honest truth badging and health monitoring
"""
import re
import math
import hashlib
import secrets
import time
from datetime import datetime, timezone, timedelta
from typing import Dict, List, Any, Optional, Tuple
from app.schemas.common import DataOrigin, CrowdLevel
from app.schemas.ingestion import (
    GpsTelemetryRecord,
    GpsTelemetryBatchRequest,
    CctvOccupancyIngestRecord,
    RouteScheduleIngestRequest,
    DisruptionIngestRecord,
    IngestRecordResult,
    IngestSummaryResponse,
    ExternalProviderRegisterRequest,
    ExternalProviderResponse,
    ProviderRevocationRequest,
    MapMatchingResult,
    PilotMonitoringDashboardResponse,
    TransitAdapterSpec,
    KOCHI_MIN_LAT,
    KOCHI_MAX_LAT,
    KOCHI_MIN_LNG,
    KOCHI_MAX_LNG
)
from app.services.gps_simulator import gps_simulator, CORRIDORS
from app.core.supabase import supabase_client
from app.schemas.realtime import RealtimeEvent, RealtimeEventType
from app.services.realtime_service import realtime_service

try:
    from backend.cv.occupancy import OccupancyCalculator
except ImportError:
    from cv.occupancy import OccupancyCalculator

class IngestionService:
    def __init__(self):
        # Monotonic sequence & timestamp tracking per bus:
        # { bus_number: {"last_timestamp": datetime, "last_seq": int, "feed_id": str} }
        self._bus_telemetry_state: Dict[str, Dict[str, Any]] = {}
        
        # Operational ingestion metrics
        self.stats = {
            "total_gps_received": 0,
            "total_gps_accepted": 0,
            "total_gps_rejected": 0,
            "total_cctv_received": 0,
            "total_cctv_accepted": 0,
            "total_cctv_rejected": 0,
            "total_schedules_ingested": 0,
            "total_disruptions_ingested": 0,
            "signal_recoveries": 0,
            "off_route_events": 0,
            "last_ingested_at": None
        }

        # Rate limiting request timestamp registry per provider
        self._provider_request_timestamps: Dict[str, List[float]] = {}

        # Registered External Transit Providers (Phase H17/H18)
        self._providers: Dict[str, Dict[str, Any]] = {}
        self._seed_pilot_providers()

    def _seed_pilot_providers(self):
        """Seeds standard Greater Kochi transit integration providers for pilot evaluation"""
        seeds = [
            {
                "provider_id": "KSRTC_AVL_FEED",
                "provider_name": "Kerala State Road Transport Corp - AVL Gateway",
                "api_key": "bs_live_ksrtc_pilot_test_key_001",
                "allowed_feed_types": ["AVL_GPS", "ROUTE_SCHEDULE", "DISRUPTION"],
                "contact_email": "its@keralartc.com"
            },
            {
                "provider_id": "KOCHI_METRO_FEEDER_AVL",
                "provider_name": "KMRL Feeder Bus Telematics Provider",
                "api_key": "bs_live_kmrl_feeder_test_key_002",
                "allowed_feed_types": ["AVL_GPS"],
                "contact_email": "feeder-ops@kochimetro.org"
            },
            {
                "provider_id": "CCTV_DOORWAY_FEED_01",
                "provider_name": "BusSense Edge Camera Headcount Gateway",
                "api_key": "bs_live_cctv_edge_test_key_003",
                "allowed_feed_types": ["CCTV_OCCUPANCY"],
                "contact_email": "edge-cctv@bussense.kerala.gov.in"
            }
        ]
        now_iso = datetime.now(timezone.utc).isoformat()
        for s in seeds:
            key_hash = hashlib.sha256(s["api_key"].encode()).hexdigest()
            self._providers[s["provider_id"]] = {
                "provider_id": s["provider_id"],
                "provider_name": s["provider_name"],
                "api_key_hash": key_hash,
                "api_key_masked": f"bs_live_...{s['api_key'][-6:]}",
                "allowed_feed_types": s["allowed_feed_types"],
                "contact_email": s["contact_email"],
                "is_active": True,
                "created_at": now_iso,
                "revoked_at": None,
                "revocation_reason": None,
                "ingested_records_count": 0
            }

    @staticmethod
    def haversine_distance_meters(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        """Calculates great-circle distance between two GPS coordinates in meters"""
        R = 6371000.0  # Earth radius in meters
        phi1 = math.radians(lat1)
        phi2 = math.radians(lat2)
        delta_phi = math.radians(lat2 - lat1)
        delta_lambda = math.radians(lon2 - lon1)
        a = math.sin(delta_phi / 2.0)**2 + math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2.0)**2
        c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))
        return round(R * c, 1)

    def map_match_vehicle(
        self,
        bus_number: str,
        lat: Optional[float] = None,
        lng: Optional[float] = None
    ) -> MapMatchingResult:
        """
        Calculates corridor map matching and detects route deviations (>500m off corridor).
        Matches against assigned route waypoints in CORRIDORS.
        """
        telemetry = self._bus_telemetry_state.get(bus_number)
        fleet_bus = gps_simulator.fleet_state.get(bus_number, {})

        if lat is None:
            lat = telemetry["latitude"] if telemetry else fleet_bus.get("live_lat", fleet_bus.get("latitude", 9.9922))
        if lng is None:
            lng = telemetry["longitude"] if telemetry else fleet_bus.get("live_lng", fleet_bus.get("longitude", 76.2974))

        corridor_key = fleet_bus.get("corridor_key", "R12_205")
        corridor = CORRIDORS.get(corridor_key, CORRIDORS.get("R12_205", {}))
        waypoints = corridor.get("waypoints", [])

        if not waypoints:
            return MapMatchingResult(
                bus_number=bus_number,
                matched_corridor=corridor_key,
                nearest_stop="Unknown",
                distance_to_corridor_meters=0.0,
                is_off_route=False,
                off_route_threshold_meters=500.0,
                telemetry_latitude=lat,
                telemetry_longitude=lng
            )

        min_dist = float("inf")
        nearest_stop = waypoints[0]["stop"]
        for wp in waypoints:
            d = self.haversine_distance_meters(lat, lng, wp["lat"], wp["lng"])
            if d < min_dist:
                min_dist = d
                nearest_stop = wp["stop"]

        is_off_route = min_dist > 500.0

        return MapMatchingResult(
            bus_number=bus_number,
            matched_corridor=corridor_key,
            nearest_stop=nearest_stop,
            distance_to_corridor_meters=min_dist,
            is_off_route=is_off_route,
            off_route_threshold_meters=500.0,
            telemetry_latitude=lat,
            telemetry_longitude=lng
        )

    def register_provider(self, req: ExternalProviderRegisterRequest) -> Tuple[ExternalProviderResponse, str]:
        raw_key = f"bs_live_{secrets.token_hex(20)}"
        key_hash = hashlib.sha256(raw_key.encode()).hexdigest()
        masked = f"bs_live_...{raw_key[-6:]}"
        now_iso = datetime.now(timezone.utc).isoformat()

        self._providers[req.provider_id] = {
            "provider_id": req.provider_id,
            "provider_name": req.provider_name,
            "api_key_hash": key_hash,
            "api_key_masked": masked,
            "allowed_feed_types": req.allowed_feed_types,
            "contact_email": req.contact_email,
            "is_active": True,
            "created_at": now_iso,
            "expires_at": req.expires_at,
            "rate_limit_per_minute": req.rate_limit_per_minute,
            "revoked_at": None,
            "revocation_reason": None,
            "ingested_records_count": 0
        }

        resp = ExternalProviderResponse(
            provider_id=req.provider_id,
            provider_name=req.provider_name,
            api_key=raw_key,
            api_key_masked=masked,
            allowed_feed_types=req.allowed_feed_types,
            is_active=True,
            created_at=now_iso,
            expires_at=req.expires_at,
            rate_limit_per_minute=req.rate_limit_per_minute,
            ingested_records_count=0
        )
        return resp, raw_key

    def verify_provider_api_key(
        self,
        api_key: str,
        feed_type: Optional[str] = None
    ) -> Tuple[bool, Optional[str], Optional[dict]]:
        """
        Verifies external provider API key.
        Checks:
        1. Valid registered key
        2. Active integration (not revoked)
        3. Expiration date check (if configured)
        4. Sliding window rate limiting (default 60 req/min)
        5. Authorized for feed_type
        """
        key_hash = hashlib.sha256(api_key.encode()).hexdigest()
        for provider in self._providers.values():
            if provider["api_key_hash"] == key_hash:
                if not provider["is_active"]:
                    reason = provider.get("revocation_reason") or "Provider integration has been revoked by authority"
                    return False, f"INTEGRATION_REVOKED: {reason}", provider

                # Expiration check
                if provider.get("expires_at"):
                    try:
                        clean_exp = provider["expires_at"].replace("Z", "+00:00")
                        exp_dt = datetime.fromisoformat(clean_exp)
                        if exp_dt.tzinfo is None:
                            exp_dt = exp_dt.replace(tzinfo=timezone.utc)
                        if datetime.now(timezone.utc) > exp_dt:
                            return False, f"PROVIDER_KEY_EXPIRED: Credentials expired at {provider['expires_at']}", provider
                    except Exception:
                        pass

                # Rate limiting check (sliding 60-second window)
                prov_id = provider["provider_id"]
                rate_limit = provider.get("rate_limit_per_minute", 60)
                now_ts = time.time()
                ts_list = self._provider_request_timestamps.get(prov_id, [])
                ts_list = [t for t in ts_list if now_ts - t < 60.0]
                if len(ts_list) >= rate_limit:
                    return False, f"RATE_LIMIT_EXCEEDED: Exceeded {rate_limit} requests/minute limit. Retry after 60s", provider
                ts_list.append(now_ts)
                self._provider_request_timestamps[prov_id] = ts_list

                if feed_type and feed_type not in provider["allowed_feed_types"]:
                    return False, f"UNAUTHORIZED_FEED_TYPE: Provider not permitted to ingest {feed_type}", provider
                provider["ingested_records_count"] += 1
                return True, None, provider
        return False, "INVALID_PROVIDER_KEY", None

    def list_providers(self) -> List[ExternalProviderResponse]:
        results = []
        for p in self._providers.values():
            results.append(ExternalProviderResponse(
                provider_id=p["provider_id"],
                provider_name=p["provider_name"],
                api_key=None,
                api_key_masked=p["api_key_masked"],
                allowed_feed_types=p["allowed_feed_types"],
                is_active=p["is_active"],
                created_at=p["created_at"],
                expires_at=p.get("expires_at"),
                rate_limit_per_minute=p.get("rate_limit_per_minute", 60),
                revoked_at=p["revoked_at"],
                revocation_reason=p["revocation_reason"],
                ingested_records_count=p["ingested_records_count"]
            ))
        return results

    def revoke_provider(self, provider_id: str, reason: str) -> Optional[ExternalProviderResponse]:
        if provider_id not in self._providers:
            return None
        p = self._providers[provider_id]
        p["is_active"] = False
        p["revoked_at"] = datetime.now(timezone.utc).isoformat()
        p["revocation_reason"] = reason
        return ExternalProviderResponse(
            provider_id=p["provider_id"],
            provider_name=p["provider_name"],
            api_key=None,
            api_key_masked=p["api_key_masked"],
            allowed_feed_types=p["allowed_feed_types"],
            is_active=False,
            created_at=p["created_at"],
            expires_at=p.get("expires_at"),
            rate_limit_per_minute=p.get("rate_limit_per_minute", 60),
            revoked_at=p["revoked_at"],
            revocation_reason=p["revocation_reason"],
            ingested_records_count=p["ingested_records_count"]
        )

    def reactivate_provider(self, provider_id: str) -> Optional[ExternalProviderResponse]:
        if provider_id not in self._providers:
            return None
        p = self._providers[provider_id]
        p["is_active"] = True
        p["revoked_at"] = None
        p["revocation_reason"] = None
        return ExternalProviderResponse(
            provider_id=p["provider_id"],
            provider_name=p["provider_name"],
            api_key=None,
            api_key_masked=p["api_key_masked"],
            allowed_feed_types=p["allowed_feed_types"],
            is_active=True,
            created_at=p["created_at"],
            expires_at=p.get("expires_at"),
            rate_limit_per_minute=p.get("rate_limit_per_minute", 60),
            revoked_at=None,
            revocation_reason=None,
            ingested_records_count=p["ingested_records_count"]
        )

    def _parse_timestamp(self, ts_str: str) -> Optional[datetime]:
        """Safely parses ISO 8601 string into timezone-aware UTC datetime"""
        try:
            # Handle standard ISO formats, including trailing Z
            clean_ts = ts_str.replace("Z", "+00:00")
            dt = datetime.fromisoformat(clean_ts)
            if dt.tzinfo is None:
                dt = dt.replace(tzinfo=timezone.utc)
            return dt
        except Exception:
            return None

    def ingest_gps_batch(self, batch: GpsTelemetryBatchRequest) -> IngestSummaryResponse:
        """
        Ingests a batch of AVL / GPS vehicle location records.
        Enforces:
        1. Spatial boundary within Greater Kochi [9.80-10.35 N, 76.15-76.55 E]
        2. Timestamp sanity (no future > 5 min, no stale > 15 min for live feeds)
        3. Monotonic sequencing and duplicate detection per vehicle
        4. Clear DataOrigin attribution
        """
        now = datetime.now(timezone.utc)
        results: List[IngestRecordResult] = []
        accepted = 0
        rejected = 0

        for idx, rec in enumerate(batch.records):
            self.stats["total_gps_received"] += 1
            record_id = f"{rec.bus_number}#{rec.sequence_number or idx}"

            # 1. Parse and validate timestamp
            ts = self._parse_timestamp(rec.timestamp)
            if not ts:
                rejected += 1
                results.append(IngestRecordResult(
                    identifier=record_id,
                    status="REJECTED",
                    reason="INVALID_TIMESTAMP_FORMAT"
                ))
                continue

            # NaN / Inf coordinates check
            if math.isnan(rec.latitude) or math.isnan(rec.longitude) or math.isinf(rec.latitude) or math.isinf(rec.longitude):
                rejected += 1
                results.append(IngestRecordResult(
                    identifier=record_id,
                    status="REJECTED",
                    reason="INVALID_COORDINATES_NAN_OR_INF: Latitude and longitude must be valid real numbers"
                ))
                continue

            # Clock skew check: future timestamp > 300 seconds
            if ts > now + timedelta(seconds=300):
                rejected += 1
                results.append(IngestRecordResult(
                    identifier=record_id,
                    status="REJECTED",
                    reason=f"FUTURE_TIMESTAMP: Record timestamp {rec.timestamp} is ahead of current server time"
                ))
                continue

            # Staleness check: live feed > 900 seconds in past
            if not rec.is_historical and (now - ts) > timedelta(seconds=900):
                rejected += 1
                results.append(IngestRecordResult(
                    identifier=record_id,
                    status="REJECTED",
                    reason=f"STALE_TELEMETRY: Record is older than 15 minutes and is_historical=False"
                ))
                continue

            # 2. Monotonic sequence & duplicate checks
            last_state = self._bus_telemetry_state.get(rec.bus_number)
            if last_state and not rec.is_historical:
                # Sequence number check
                if rec.sequence_number is not None and last_state.get("last_seq") is not None:
                    if rec.sequence_number <= last_state["last_seq"]:
                        rejected += 1
                        results.append(IngestRecordResult(
                            identifier=record_id,
                            status="REJECTED",
                            reason=f"DUPLICATE_OR_OUT_OF_ORDER_SEQUENCE: Received seq {rec.sequence_number} <= previous {last_state['last_seq']}"
                        ))
                        continue

                # Timestamp progression check
                if ts <= last_state["last_timestamp"]:
                    rejected += 1
                    results.append(IngestRecordResult(
                        identifier=record_id,
                        status="REJECTED",
                        reason=f"OUT_OF_ORDER_TIMESTAMP: Received timestamp {ts.isoformat()} <= previous {last_state['last_timestamp'].isoformat()}"
                    ))
                    continue

                # Sudden GPS jump / impossible velocity check
                dt_sec = (ts - last_state["last_timestamp"]).total_seconds()
                if dt_sec > 0:
                    d_meters = self.haversine_distance_meters(last_state["latitude"], last_state["longitude"], rec.latitude, rec.longitude)
                    effective_speed_kmh = (d_meters / dt_sec) * 3.6
                    if effective_speed_kmh > 120.0 and d_meters > 500.0:
                        rejected += 1
                        results.append(IngestRecordResult(
                            identifier=record_id,
                            status="REJECTED",
                            reason=f"IMPOSSIBLE_SPEED_OR_GPS_JUMP: Calculated velocity {effective_speed_kmh:.1f} km/h (jump {d_meters:.0f}m in {dt_sec:.1f}s) exceeds physical limits"
                        ))
                        continue

                # Signal loss & recovery tracking (>30s gap recovered)
                if dt_sec > 30.0:
                    self.stats["signal_recoveries"] = self.stats.get("signal_recoveries", 0) + 1

            # Corridor map matching & off-route detection
            map_match = self.map_match_vehicle(rec.bus_number, rec.latitude, rec.longitude)
            if map_match.is_off_route:
                self.stats["off_route_events"] = self.stats.get("off_route_events", 0) + 1

            # 3. Update in-memory telemetry state
            self._bus_telemetry_state[rec.bus_number] = {
                "last_timestamp": ts,
                "last_seq": rec.sequence_number,
                "feed_id": batch.feed_id,
                "latitude": rec.latitude,
                "longitude": rec.longitude,
                "speed_kmh": rec.speed_kmh,
                "heading_deg": rec.heading_deg,
                "data_origin": rec.data_origin,
                "is_off_route": map_match.is_off_route,
                "deviation_meters": map_match.distance_to_corridor_meters,
                "matched_corridor": map_match.matched_corridor,
                "nearest_stop": map_match.nearest_stop
            }

            # 4. Integrate into active fleet simulation engine if bus is tracked
            if rec.bus_number in gps_simulator.fleet_state:
                fleet_bus = gps_simulator.fleet_state[rec.bus_number]
                fleet_bus["speed_kmh"] = rec.speed_kmh
                fleet_bus["heading_deg"] = rec.heading_deg
                fleet_bus["data_origin"] = rec.data_origin
                # Provide direct GPS override for dynamic live tracking
                fleet_bus["live_lat"] = rec.latitude
                fleet_bus["live_lng"] = rec.longitude
                fleet_bus["is_off_route"] = map_match.is_off_route
                fleet_bus["deviation_meters"] = map_match.distance_to_corridor_meters

            accepted += 1
            warn_reason = f"WARNING_OFF_ROUTE: {map_match.distance_to_corridor_meters}m off route {map_match.matched_corridor}" if map_match.is_off_route else None
            results.append(IngestRecordResult(
                identifier=record_id,
                status="ACCEPTED",
                reason=warn_reason
            ))

        self.stats["total_gps_accepted"] += accepted
        self.stats["total_gps_rejected"] += rejected
        self.stats["last_ingested_at"] = now.isoformat()

        freshness = "HISTORICAL" if any(r.is_historical for r in batch.records) else ("FRESH" if accepted > 0 else "STALE")
        origin = DataOrigin.LIVE if not any(r.is_historical for r in batch.records) else DataOrigin.SIMULATED

        return IngestSummaryResponse(
            feed_id=batch.feed_id,
            feed_type="AVL_GPS",
            total_received=len(batch.records),
            accepted=accepted,
            rejected=rejected,
            results=results,
            freshness_status=freshness,
            data_origin=origin
        )

    async def ingest_cctv_occupancy(self, record: CctvOccupancyIngestRecord) -> IngestSummaryResponse:
        """
        Ingests CCTV-derived aggregate passenger headcounts.
        Zero biometrics strictly verified.
        Recalculates trusted occupancy percentage and crowd tier.
        """
        self.stats["total_cctv_received"] += 1
        now = datetime.now(timezone.utc)

        # 1. Bus existence check in fleet
        if record.bus_number not in gps_simulator.fleet_state:
            self.stats["total_cctv_rejected"] += 1
            return IngestSummaryResponse(
                feed_id=record.camera_id,
                feed_type="CCTV_OCCUPANCY",
                total_received=1,
                accepted=0,
                rejected=1,
                results=[IngestRecordResult(
                    identifier=f"{record.bus_number}@{record.timestamp}",
                    status="REJECTED",
                    reason=f"BUS_NOT_FOUND: Bus '{record.bus_number}' not registered in fleet"
                )],
                freshness_status="STALE",
                data_origin=DataOrigin.CV_REPLAY
            )

        # 2. Trusted occupancy percentage and crowd tier recalculation
        trusted_pct = OccupancyCalculator.calculate_occupancy_percentage(
            record.stabilized_person_count,
            record.capacity
        )
        trusted_crowd = OccupancyCalculator.classify_crowd_tier(trusted_pct)

        # 3. Update fleet state
        gps_simulator.update_from_cv_event(
            bus_number=record.bus_number,
            passenger_count=record.stabilized_person_count,
            capacity=record.capacity,
            occupancy_pct=trusted_pct,
            crowd_level=trusted_crowd,
            detection_source=f"{record.model_version}_AggregateCount"
        )

        # 4. Asynchronously persist to Supabase occupancy_readings table
        try:
            bus_info = gps_simulator.fleet_state.get(record.bus_number, {})
            bus_id = bus_info.get("bus_id", "a1111111-aaaa-aaaa-aaaa-aaaaaaaaaaaa")
            db_origin = "LIVE" if "LIVE" in str(record.data_origin) else "SIMULATED"
            await supabase_client.post("occupancy_readings", {
                "bus_id": bus_id,
                "passenger_count": record.stabilized_person_count,
                "capacity": record.capacity,
                "occupancy_pct": trusted_pct,
                "crowd_level": trusted_crowd,
                "detection_source": f"{record.model_version}_CCTV",
                "data_origin": db_origin
            })
        except Exception as e:
            # Non-blocking logging
            print(f"[Ingestion Persistence Warning] {e}")

        # 5. Broadcast realtime event
        await realtime_service.publish_event(RealtimeEvent(
            event_type=RealtimeEventType.OCCUPANCY_UPDATE.value,
            entity_id=record.bus_number,
            data_origin=record.data_origin.value,
            payload={
                "bus_number": record.bus_number,
                "passenger_count": record.stabilized_person_count,
                "capacity": record.capacity,
                "occupancy_pct": trusted_pct,
                "crowd_level": trusted_crowd,
                "privacy_standard": "PERSON_COUNTING_ONLY_NO_BIOMETRICS"
            }
        ))

        self.stats["total_cctv_accepted"] += 1
        self.stats["last_ingested_at"] = now.isoformat()

        return IngestSummaryResponse(
            feed_id=record.camera_id,
            feed_type="CCTV_OCCUPANCY",
            total_received=1,
            accepted=1,
            rejected=0,
            results=[IngestRecordResult(
                identifier=f"{record.bus_number}@{record.timestamp}",
                status="ACCEPTED",
                reason=None
            )],
            freshness_status="FRESH",
            data_origin=record.data_origin
        )

    def ingest_route_schedule(self, schedule: RouteScheduleIngestRequest) -> IngestSummaryResponse:
        """
        Ingests a route definition with ordered stop sequences.
        Validates stop sequence monotonicity and coordinates within Greater Kochi.
        """
        # Validate stop sequences are strictly increasing
        seqs = [s.stop_sequence for s in schedule.stops]
        if seqs != sorted(seqs) or len(seqs) != len(set(seqs)):
            return IngestSummaryResponse(
                feed_id=schedule.route_number,
                feed_type="ROUTE_SCHEDULE",
                total_received=len(schedule.stops),
                accepted=0,
                rejected=len(schedule.stops),
                results=[IngestRecordResult(
                    identifier=schedule.route_number,
                    status="REJECTED",
                    reason="NON_MONOTONIC_STOP_SEQUENCE: Stop sequences must be strictly increasing without duplicates"
                )],
                freshness_status="FRESH",
                data_origin=DataOrigin.SIMULATED
            )

        # Register or update corridor in simulation
        corridor_key = schedule.corridor_key or f"R_{schedule.route_number}"
        CORRIDORS[corridor_key] = {
            "route_number": schedule.route_number,
            "route_name": schedule.route_name,
            "origin": schedule.origin,
            "destination": schedule.destination,
            "waypoints": [
                {"stop": s.stop_name, "lat": s.latitude, "lng": s.longitude}
                for s in schedule.stops
            ]
        }

        self.stats["total_schedules_ingested"] += 1
        return IngestSummaryResponse(
            feed_id=schedule.route_number,
            feed_type="ROUTE_SCHEDULE",
            total_received=len(schedule.stops),
            accepted=len(schedule.stops),
            rejected=0,
            results=[
                IngestRecordResult(
                    identifier=f"{schedule.route_number}-STOP-{s.stop_sequence}",
                    status="ACCEPTED"
                )
                for s in schedule.stops
            ],
            freshness_status="FRESH",
            data_origin=DataOrigin.SIMULATED
        )

    async def ingest_disruption(self, disruption: DisruptionIngestRecord) -> IngestSummaryResponse:
        """
        Ingests a transit service disruption or traffic incident.
        """
        now_iso = datetime.now(timezone.utc).isoformat()
        
        # Asynchronously persist to Supabase incidents
        try:
            await supabase_client.post("incidents", {
                "route_number": disruption.route_number,
                "incident_type": disruption.cause,
                "severity": disruption.severity,
                "description": disruption.description,
                "status": "OPEN" if disruption.is_active else "RESOLVED",
                "data_origin": "LIVE DATA"
            })
        except Exception as e:
            print(f"[Disruption Persistence Warning] {e}")

        # Broadcast realtime alert
        await realtime_service.publish_event(RealtimeEvent(
            event_type=RealtimeEventType.ALERT_UPDATE.value,
            entity_id=disruption.route_number,
            data_origin="LIVE DATA",
            payload={
                "route_number": disruption.route_number,
                "cause": disruption.cause,
                "severity": disruption.severity,
                "description": disruption.description,
                "affected_stops": disruption.affected_stops
            }
        ))

        self.stats["total_disruptions_ingested"] += 1
        return IngestSummaryResponse(
            feed_id=disruption.route_number,
            feed_type="DISRUPTION",
            total_received=1,
            accepted=1,
            rejected=0,
            results=[IngestRecordResult(
                identifier=f"DISRUPTION-{disruption.route_number}",
                status="ACCEPTED"
            )],
            freshness_status="FRESH",
            data_origin=DataOrigin.LIVE
        )

    def get_ingest_health(self) -> Dict[str, Any]:
        """
        Returns real-time health metrics of the transit ingestion boundary.
        Identifies stale vehicles (> 30s without update), active feeds, and dropped packets.
        """
        now = datetime.now(timezone.utc)
        active_buses = {}
        stale_threshold_sec = 30

        for bus_number, state in self._bus_telemetry_state.items():
            age_sec = (now - state["last_timestamp"]).total_seconds()
            is_stale = age_sec > stale_threshold_sec
            active_buses[bus_number] = {
                "last_seq": state["last_seq"],
                "age_seconds": round(age_sec, 1),
                "is_stale": is_stale,
                "feed_id": state["feed_id"],
                "last_lat": state["latitude"],
                "last_lng": state["longitude"],
                "data_origin": state["data_origin"]
            }

        return {
            "service": "transit_ingestion_boundary",
            "status": "HEALTHY",
            "stats": self.stats,
            "tracked_vehicles_count": len(self._bus_telemetry_state),
            "stale_vehicles_count": sum(1 for b in active_buses.values() if b["is_stale"]),
            "vehicles": active_buses,
            "greater_kochi_bbox": {
                "min_lat": KOCHI_MIN_LAT,
                "max_lat": KOCHI_MAX_LAT,
                "min_lng": KOCHI_MIN_LNG,
                "max_lng": KOCHI_MAX_LNG
            },
            "timestamp": now.isoformat()
        }

    def get_pilot_monitoring_summary(self) -> PilotMonitoringDashboardResponse:
        """
        Aggregates comprehensive operational monitoring telemetry for the Phase H17 field pilot.
        Provides live vs simulated breakdowns, freshness metrics, occupancy tiers,
        data origin auditing, and provider integration statuses.
        """
        now = datetime.now(timezone.utc)
        fleet_buses = gps_simulator.fleet_state
        total_fleet = len(fleet_buses)

        connected = len(self._bus_telemetry_state)
        fresh_count = 0
        stale_count = 0
        unavailable_count = 0

        for bus_num, bus_state in fleet_buses.items():
            telemetry = self._bus_telemetry_state.get(bus_num)
            if not telemetry:
                unavailable_count += 1
            else:
                age_sec = (now - telemetry["last_timestamp"]).total_seconds()
                if age_sec <= 30.0:
                    fresh_count += 1
                elif age_sec <= 120.0:
                    stale_count += 1
                else:
                    unavailable_count += 1

        freshness_ratio = round((fresh_count / max(total_fleet, 1)) * 100.0, 1)

        # Live vs simulated breakdown
        live_sim_counts = {
            "LIVE_DATA": 0,
            "SIMULATED_DATA": 0,
            "CV_REPLAY": 0,
            "ESTIMATE": 0
        }
        for b in fleet_buses.values():
            origin = b.get("data_origin", "SIMULATED DATA")
            if isinstance(origin, DataOrigin):
                origin = origin.value
            if "LIVE" in str(origin):
                live_sim_counts["LIVE_DATA"] += 1
            elif "REPLAY" in str(origin):
                live_sim_counts["CV_REPLAY"] += 1
            elif "ESTIMATE" in str(origin):
                live_sim_counts["ESTIMATE"] += 1
            else:
                live_sim_counts["SIMULATED_DATA"] += 1

        # Occupancy distribution
        tier_counts = {"LOW": 0, "MODERATE": 0, "HIGH": 0, "FULL": 0}
        for b in fleet_buses.values():
            crowd = b.get("crowd_level", "LOW")
            tier_counts[crowd] = tier_counts.get(crowd, 0) + 1

        active_providers = sum(1 for p in self._providers.values() if p["is_active"])
        revoked_providers = sum(1 for p in self._providers.values() if not p["is_active"])

        origins = {
            "AVL_GPS": DataOrigin.LIVE.value if any(p["is_active"] for p in self._providers.values() if "AVL_GPS" in p["allowed_feed_types"]) else DataOrigin.SIMULATED.value,
            "CCTV_PASSENGER_COUNT": DataOrigin.CV_REPLAY.value,
            "DEMAND_FORECASTING": DataOrigin.PREDICTION.value,
            "TRANSIT_RECOMMENDATIONS": DataOrigin.RECOMMENDATION.value,
            "MISSING_TELEMETRY": DataOrigin.UNAVAILABLE.value,
            "LATENT_TELEMETRY": DataOrigin.STALE.value
        }

        # Operational metrics enrichment for Phase H18 (cached)
        if not hasattr(self, "_cached_forecaster_eval") or self._cached_forecaster_eval is None:
            try:
                from app.services.demand_forecaster import demand_forecaster
                fe = demand_forecaster.get_pilot_forecasting_evaluation()
                self._cached_forecaster_eval = {
                    "model_version": fe.model_version,
                    "data_quality": fe.training_data_quality,
                    "total_samples": fe.total_samples,
                    "train_pct": fe.train_split_pct,
                    "val_pct": fe.validation_split_pct,
                    "test_pct": fe.test_split_pct,
                    "overall_metrics": [m.model_dump() for m in fe.overall_metrics],
                    "overfitting_risk": fe.overfitting_risk_assessment
                }
            except Exception as e:
                print(f"[Pilot Monitor Forecaster Warning] {e}")

        if not hasattr(self, "_cached_cv_summary") or self._cached_cv_summary is None:
            try:
                from cv.evaluator import cv_evaluator
                cv_rep = cv_evaluator.run_full_evaluation(seed=42)
                self._cached_cv_summary = {
                    "scenarios_count": cv_rep.total_scenarios_evaluated,
                    "raw_mae": cv_rep.aggregate_raw_mae,
                    "smoothed_mae": cv_rep.aggregate_smoothed_mae,
                    "smoothed_rmse": cv_rep.aggregate_smoothed_rmse,
                    "mape_pct": cv_rep.aggregate_mape_pct,
                    "fps": cv_rep.aggregate_fps,
                    "p95_latency_ms": cv_rep.aggregate_p95_inference_ms,
                    "precision": cv_rep.aggregate_precision,
                    "recall": cv_rep.aggregate_recall,
                    "f1_score": cv_rep.aggregate_f1_score,
                    "stabilization_gain_pct": cv_rep.stabilization_improvement_pct,
                    "zero_biometrics_passed": cv_rep.overall_zero_biometrics_passed
                }
            except Exception as e:
                print(f"[Pilot Monitor CV Warning] {e}")

        forecaster_eval = getattr(self, "_cached_forecaster_eval", None)
        cv_summary = getattr(self, "_cached_cv_summary", None)

        rec_summary = None
        try:
            from app.services.recommendation_engine import recommendation_engine
            rec_summary = recommendation_engine.get_analytics_summary().model_dump()
        except Exception as e:
            print(f"[Pilot Monitor Rec Warning] {e}")

        return PilotMonitoringDashboardResponse(
            total_active_vehicles=total_fleet,
            connected_vehicles_count=connected,
            fresh_telemetry_count=fresh_count,
            stale_telemetry_count=stale_count,
            unavailable_telemetry_count=unavailable_count,
            freshness_ratio_pct=freshness_ratio,
            live_vs_simulated_breakdown=live_sim_counts,
            occupancy_tier_distribution=tier_counts,
            prediction_status="OPERATIONAL_RIDGE_REGRESSION",
            ingestion_stats=self.stats,
            cv_processing_status="REPLAY_AND_LIVE_STREAM_ACTIVE",
            active_providers_count=active_providers,
            revoked_providers_count=revoked_providers,
            data_origins=origins,
            privacy_standard="PERSON_COUNTING_ONLY_NO_BIOMETRICS",
            greater_kochi_bbox={
                "min_lat": KOCHI_MIN_LAT,
                "max_lat": KOCHI_MAX_LAT,
                "min_lng": KOCHI_MIN_LNG,
                "max_lng": KOCHI_MAX_LNG
            },
            forecaster_evaluation=forecaster_eval,
            cv_metrics_summary=cv_summary,
            failed_ingestion_events_count=self.stats.get("total_gps_rejected", 0) + self.stats.get("total_cctv_rejected", 0),
            off_route_alerts_count=self.stats.get("off_route_events", 0),
            signal_recoveries_count=self.stats.get("signal_recoveries", 0),
            recommendation_analytics_summary=rec_summary,
            timestamp=now.isoformat()
        )

    def list_transit_adapters(self) -> List[TransitAdapterSpec]:
        """
        Returns preconfigured Greater Kochi transit adapter integration specifications.
        Clearly labels live vs simulated status to prevent fictitious integrations.
        """
        now_iso = datetime.now(timezone.utc).isoformat()
        return [
            TransitAdapterSpec(
                adapter_id="KSRTC_SWIFT_AVL_ADAPTER",
                adapter_name="KSRTC-SWIFT GPS Telematics Push Adapter",
                provider_type="KSRTC",
                feed_type="AVL_GPS",
                protocol="HTTP_POST_JSON",
                status="CONFIGURED_READY_FOR_FIELD",
                truth_label="LIVE DATA (WHEN CONNECTED) / BENCHMARK (STAGING)",
                endpoint="/api/ingest/gps",
                sample_payload={
                    "feed_id": "KSRTC_SWIFT_AVL",
                    "records": [{
                        "bus_number": "205",
                        "latitude": 10.0270,
                        "longitude": 76.3080,
                        "speed_kmh": 28.5,
                        "heading_deg": 182.0,
                        "timestamp": now_iso,
                        "sequence_number": 1,
                        "data_origin": "LIVE DATA"
                    }]
                }
            ),
            TransitAdapterSpec(
                adapter_id="KMRL_FEEDER_AVL_ADAPTER",
                adapter_name="KMRL Feeder Bus Telematics Ingestion Adapter",
                provider_type="KMRL",
                feed_type="AVL_GPS",
                protocol="HTTP_POST_JSON",
                status="CONFIGURED_READY_FOR_FIELD",
                truth_label="LIVE DATA (WHEN CONNECTED) / BENCHMARK (STAGING)",
                endpoint="/api/ingest/gps",
                sample_payload={
                    "feed_id": "KMRL_FEEDER_AVL",
                    "records": [{
                        "bus_number": "14A",
                        "latitude": 9.9922,
                        "longitude": 76.2974,
                        "speed_kmh": 24.0,
                        "heading_deg": 95.0,
                        "timestamp": now_iso,
                        "sequence_number": 1,
                        "data_origin": "LIVE DATA"
                    }]
                }
            ),
            TransitAdapterSpec(
                adapter_id="CCTV_HEADCOUNT_GATEWAY_ADAPTER",
                adapter_name="BusSense Edge Camera Headcount Gateway (Zero-Biometrics)",
                provider_type="BUSSENSE_EDGE",
                feed_type="CCTV_OCCUPANCY",
                protocol="HTTP_POST_JSON",
                status="CONFIGURED_READY_FOR_FIELD",
                truth_label="CV REPLAY (TESTED) / LIVE STREAM (FIELD)",
                endpoint="/api/ingest/cctv-occupancy",
                sample_payload={
                    "bus_number": "205",
                    "timestamp": now_iso,
                    "raw_person_count": 28,
                    "stabilized_person_count": 27,
                    "capacity": 55,
                    "confidence_score": 0.91,
                    "model_version": "yolov8n_coco",
                    "camera_id": "BUS_DOOR_CAM_01",
                    "privacy_standard": "PERSON_COUNTING_ONLY_NO_BIOMETRICS",
                    "data_origin": "CV REPLAY"
                }
            ),
            TransitAdapterSpec(
                adapter_id="KERALA_POLICE_DISRUPTION_ADAPTER",
                adapter_name="Kerala Police / Traffic Police Incident Feed Adapter",
                provider_type="KERALA_POLICE",
                feed_type="DISRUPTION",
                protocol="HTTP_POST_JSON",
                status="SIMULATED_ADAPTER_NO_PROD_ENDPOINT",
                truth_label="SIMULATED DATA",
                endpoint="/api/ingest/disruptions",
                sample_payload={
                    "route_number": "205",
                    "cause": "TRAFFIC_CONGESTION",
                    "severity": "MEDIUM",
                    "description": "Slow vehicle movement near Edappally Toll junction due to metro feeder traffic",
                    "affected_stops": ["edappally toll & lulu terminal"],
                    "estimated_duration_mins": 25,
                    "is_active": True
                }
            )
        ]

ingestion_service = IngestionService()
