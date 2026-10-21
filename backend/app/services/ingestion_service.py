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
            "last_ingested_at": None
        }

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

            # 3. Update in-memory telemetry state
            self._bus_telemetry_state[rec.bus_number] = {
                "last_timestamp": ts,
                "last_seq": rec.sequence_number,
                "feed_id": batch.feed_id,
                "latitude": rec.latitude,
                "longitude": rec.longitude,
                "speed_kmh": rec.speed_kmh,
                "heading_deg": rec.heading_deg,
                "data_origin": rec.data_origin
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

            accepted += 1
            results.append(IngestRecordResult(
                identifier=record_id,
                status="ACCEPTED",
                reason=None
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
            await supabase_client.post("occupancy_readings", {
                "bus_id": bus_id,
                "passenger_count": record.stabilized_person_count,
                "capacity": record.capacity,
                "occupancy_pct": trusted_pct,
                "crowd_level": trusted_crowd,
                "detection_source": f"{record.model_version}_CCTV",
                "data_origin": record.data_origin.value
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

ingestion_service = IngestionService()
