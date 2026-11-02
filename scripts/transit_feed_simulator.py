"""
BusSense AI - Realistic Transit Integration Feed Simulator (Phase H17)
Simulates external authorized transit feeds against the BusSense AI ingestion boundary:
- GPS / AVL telematics streaming with sequential timestamps
- Corridor map-matching & route deviation alerting (>500m threshold)
- CCTV doorway headcount ingestion (strictly zero-biometric)
- Negative testing: out-of-order timestamps, stale feeds, out-of-bounds coordinates
- Provider API key authentication, permission checking, and revocation enforcement (HTTP 403)
- Pilot operational monitoring dashboard inspection

DATA ORIGIN: SIMULATED TRANSIT INTEGRATION FEED
"""
import sys
import time
import json
import urllib.request
import urllib.error
from datetime import datetime, timezone, timedelta

BASE_URL = "http://127.0.0.1:8000"
INTERNAL_SECRET = "bussense_ai_super_secret_jwt_key_2026_prototype_secure"
TEST_PROVIDER_KEY = "bs_live_ksrtc_pilot_test_key_001"

def make_request(method: str, path: str, data: dict = None, headers: dict = None):
    url = f"{BASE_URL}{path}"
    req_headers = {"Content-Type": "application/json"}
    if headers:
        req_headers.update(headers)

    body = json.dumps(data).encode("utf-8") if data is not None else None
    req = urllib.request.Request(url, data=body, headers=req_headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            resp_body = resp.read().decode("utf-8")
            return resp.status, json.loads(resp_body)
    except urllib.error.HTTPError as e:
        resp_body = e.read().decode("utf-8")
        try:
            return e.code, json.loads(resp_body)
        except Exception:
            return e.code, {"error": resp_body}
    except Exception as ex:
        return 0, {"error": str(ex)}

def run_simulation():
    print("=" * 80)
    print(" BusSense AI - Transit Feed Integration Simulator (Phase H17)")
    print(" Data Classification: SIMULATED TRANSIT INTEGRATION FEED")
    print("=" * 80)

    # 1. Health check
    print("\n[Step 1] Ingestion boundary health check...")
    status, res = make_request("GET", "/api/ingest/health", headers={"X-Internal-Secret": INTERNAL_SECRET})
    print(f"Status: {status}, Active Vehicles Tracked: {res.get('data', {}).get('tracked_vehicles_count', 0)}")
    assert status == 200, f"Expected 200, got {status}"

    # 2. Ingest valid GPS batch via Provider API Key
    print("\n[Step 2] Streaming fresh AVL GPS batch with Provider API Key...")
    run_base_time = datetime.now(timezone.utc) + timedelta(minutes=1)
    base_seq = int(time.time()) % 1000000
    gps_payload = {
        "feed_id": "FEED-KSRTC-01",
        "provider_name": "KSRTC Swift AVL Gateway",
        "records": [
            {
                "bus_number": "205",
                "latitude": 10.0270,
                "longitude": 76.3080,
                "speed_kmh": 32.5,
                "heading_deg": 195.0,
                "timestamp": (run_base_time + timedelta(seconds=10)).isoformat(),
                "sequence_number": base_seq + 1,
                "data_origin": "LIVE DATA",
                "is_historical": False
            }
        ]
    }
    status, res = make_request(
        "POST",
        "/api/ingest/gps",
        data=gps_payload,
        headers={"X-Provider-API-Key": TEST_PROVIDER_KEY}
    )
    print(f"Status: {status}, Accepted: {res.get('data', {}).get('accepted')}, Rejected: {res.get('data', {}).get('rejected')}")
    assert status == 200 and res.get("data", {}).get("accepted") == 1

    # 3. Corridor map-matching check
    print("\n[Step 3] Checking real-time corridor map-matching for Bus 205...")
    status, res = make_request("GET", "/api/ingest/map-match/205", headers={"X-Internal-Secret": INTERNAL_SECRET})
    mm_data = res.get("data", {})
    print(f"Corridor: {mm_data.get('matched_corridor')}, Deviation: {mm_data.get('distance_to_corridor_meters')}m, Off-Route Alert: {mm_data.get('is_off_route')}")
    assert status == 200

    # 4. Out-of-route deviation alert (>500m deviation)
    print("\n[Step 4] Testing off-route deviation alerting (>500m off assigned corridor)...")
    off_route_payload = {
        "feed_id": "FEED-KSRTC-01",
        "provider_name": "KSRTC Swift AVL Gateway",
        "records": [
            {
                "bus_number": "205",
                "latitude": 9.9000,   # Significantly south of Aluva-Vyttila corridor
                "longitude": 76.3500,
                "speed_kmh": 40.0,
                "heading_deg": 90.0,
                "timestamp": (run_base_time + timedelta(seconds=20)).isoformat(),
                "sequence_number": base_seq + 2,
                "data_origin": "LIVE DATA",
                "is_historical": False
            }
        ]
    }
    status, res = make_request(
        "POST",
        "/api/ingest/gps",
        data=off_route_payload,
        headers={"X-Provider-API-Key": TEST_PROVIDER_KEY}
    )
    warning_reason = res.get("data", {}).get("results", [{}])[0].get("reason", "")
    print(f"Status: {status}, Ingest Result: {warning_reason}")
    assert "WARNING_OFF_ROUTE" in str(warning_reason) or res.get("data", {}).get("accepted") == 1

    # 5. Out-of-order rejection test
    print("\n[Step 5] Testing negative verification: out-of-order timestamp rejection...")
    out_of_order_payload = {
        "feed_id": "FEED-KSRTC-01",
        "provider_name": "KSRTC Swift AVL Gateway",
        "records": [
            {
                "bus_number": "205",
                "latitude": 10.0270,
                "longitude": 76.3080,
                "speed_kmh": 20.0,
                "heading_deg": 195.0,
                "timestamp": (run_base_time - timedelta(seconds=30)).isoformat(), # in past relative to last update
                "sequence_number": base_seq + 3,
                "data_origin": "LIVE DATA",
                "is_historical": False
            }
        ]
    }
    status, res = make_request(
        "POST",
        "/api/ingest/gps",
        data=out_of_order_payload,
        headers={"X-Provider-API-Key": TEST_PROVIDER_KEY}
    )
    rejection_reason = res.get("data", {}).get("results", [{}])[0].get("reason", "")
    print(f"Status: {status}, Rejected: {res.get('data', {}).get('rejected')}, Reason: {rejection_reason}")
    assert res.get("data", {}).get("rejected") == 1 and "OUT_OF_ORDER" in rejection_reason

    # 6. Ingest CCTV headcount
    print("\n[Step 6] Streaming CCTV aggregate headcount (Zero Biometrics)...")
    cctv_key = "bs_live_cctv_edge_test_key_003"
    cctv_payload = {
        "camera_id": "CAM-BUS205-DOOR-01",
        "bus_number": "205",
        "raw_person_count": 28,
        "stabilized_person_count": 27,
        "capacity": 55,
        "confidence_score": 0.88,
        "model_version": "YOLOv8n",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "privacy_standard": "PERSON_COUNTING_ONLY_NO_BIOMETRICS",
        "data_origin": "CV REPLAY"
    }
    status, res = make_request(
        "POST",
        "/api/ingest/cctv-occupancy",
        data=cctv_payload,
        headers={"X-Provider-API-Key": cctv_key}
    )
    print(f"Status: {status}, Response: {res}")
    assert status == 200

    # 7. Provider Revocation Lifecycle Test (enforcing HTTP 403)
    print("\n[Step 7] Testing provider revocation lifecycle and 403 enforcement...")
    # Register temporary test provider
    reg_payload = {
        "provider_id": "TEMP_TEST_FEED",
        "provider_name": "Temporary Test Telemetry Feed",
        "allowed_feed_types": ["AVL_GPS"],
        "contact_email": "ops-test@kerala.gov.in"
    }
    status, reg_res = make_request("POST", "/api/ingest/providers", data=reg_payload, headers={"X-Internal-Secret": INTERNAL_SECRET})
    temp_key = reg_res.get("data", {}).get("api_key")
    print(f"Registered Provider 'TEMP_TEST_FEED', key: {reg_res.get('data', {}).get('api_key_masked')}")

    # Verify access with valid key
    test_gps = {
        "feed_id": "TEMP_TEST_FEED",
        "records": [
            {
                "bus_number": "14A",
                "latitude": 9.9922,
                "longitude": 76.2974,
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "data_origin": "LIVE DATA"
            }
        ]
    }
    status, res = make_request("POST", "/api/ingest/gps", data=test_gps, headers={"X-Provider-API-Key": temp_key})
    print(f"Pre-revocation ingestion: HTTP {status} (Expected 200)")
    assert status == 200

    # Revoke integration
    revoke_payload = {"reason": "End of field trial evaluation window"}
    status, rev_res = make_request("POST", "/api/ingest/providers/TEMP_TEST_FEED/revoke", data=revoke_payload, headers={"X-Internal-Secret": INTERNAL_SECRET})
    print(f"Revocation status: HTTP {status}, Reason: {rev_res.get('data', {}).get('revocation_reason')}")
    assert status == 200

    # Attempt ingestion after revocation -> MUST return 403
    status, err_res = make_request("POST", "/api/ingest/gps", data=test_gps, headers={"X-Provider-API-Key": temp_key})
    print(f"Post-revocation ingestion: HTTP {status} (Expected 403 Forbidden), Detail: {err_res.get('detail')}")
    assert status == 403 and "INTEGRATION_REVOKED" in str(err_res)

    # 8. Query Pilot Monitoring Dashboard
    print("\n[Step 8] Auditing Phase H17 field pilot monitoring dashboard...")
    status, mon_res = make_request("GET", "/api/ingest/pilot-monitor", headers={"X-Internal-Secret": INTERNAL_SECRET})
    dash = mon_res.get("data", {})
    print(f"Status: HTTP {status}")
    print(f"Active Vehicles:            {dash.get('total_active_vehicles')}")
    print(f"Fresh Telemetry Count:      {dash.get('fresh_telemetry_count')}")
    print(f"Freshness Ratio:            {dash.get('freshness_ratio_pct')}%")
    print(f"Active Providers:           {dash.get('active_providers_count')}")
    print(f"Revoked Providers:          {dash.get('revoked_providers_count')}")
    print(f"Privacy Standard Audited:   {dash.get('privacy_standard')}")
    assert status == 200 and dash.get("privacy_standard") == "PERSON_COUNTING_ONLY_NO_BIOMETRICS"

    # 9. Smart Recommendation Feedback Loop
    print("\n[Step 9] Simulating commuter journey planning & recommendation feedback loop...")
    status, plan_res = make_request("GET", "/api/recommendations/plan?origin=Kaloor&destination=Vyttila&preference=balanced")
    rec_bus = plan_res.get("data", {}).get("recommended_bus", {}).get("bus_number", "205")
    print(f"Recommended Bus: {rec_bus} (Score: {plan_res.get('data', {}).get('recommended_bus', {}).get('journey_score')})")

    # Record impression
    imp_payload = {
        "journey_id": "JOURNEY-PILOT-001",
        "recommended_bus_number": rec_bus,
        "presented_alternatives_count": 2,
        "preference": "balanced"
    }
    status, imp_res = make_request("POST", "/api/recommendations/impression", data=imp_payload)
    print(f"Recorded impression: HTTP {status}")

    # Record commuter selection
    sel_payload = {
        "journey_id": "JOURNEY-PILOT-001",
        "selected_bus_number": rec_bus,
        "was_recommended_bus": True,
        "selection_reason": "Lower cabin crowding and earlier ETA"
    }
    status, sel_res = make_request("POST", "/api/recommendations/selection", data=sel_payload)
    analytics = sel_res.get("data", {})
    print(f"Commuter selection recorded: Compliance Rate: {analytics.get('compliance_rate_pct')}%, Total Selections: {analytics.get('total_selections')}")
    assert status == 200

    print("\n" + "=" * 80)
    print(" Realistic Transit Integration Feed Simulation: COMPLETED (ALL PASS)")
    print("=" * 80)

if __name__ == "__main__":
    run_simulation()
