"""
BusSense AI - Phase H21 API Performance & Latency Benchmark Script
Executes 50 requests per critical endpoint, measuring Mean, P95, and P99 latency.
"""
import sys
import os
import time
import statistics
from pathlib import Path

backend_dir = Path(__file__).resolve().parent.parent / "backend"
sys.path.insert(0, str(backend_dir))

from fastapi.testclient import TestClient
from app.main import app
from app.core.security import create_access_token

client = TestClient(app)

def get_auth_token(role: str = "AUTHORITY") -> str:
    return create_access_token({
        "sub": "00000000-0000-0000-0000-000000000001",
        "email": "benchmark@bussense.ai",
        "role": role,
        "full_name": "Benchmark Runner"
    })

def benchmark_endpoint(name: str, method: str, path: str, payload: dict = None, n_iterations: int = 50) -> dict:
    token = get_auth_token()
    headers = {"Authorization": f"Bearer {token}"}
    latencies_ms = []

    # Warmup
    for _ in range(3):
        if method == "GET":
            client.get(path, headers=headers)
        else:
            client.post(path, json=payload, headers=headers)

    for _ in range(n_iterations):
        t0 = time.perf_counter()
        if method == "GET":
            resp = client.get(path, headers=headers)
        else:
            resp = client.post(path, json=payload, headers=headers)
        t1 = time.perf_counter()
        assert resp.status_code == 200, f"Benchmark request failed: {resp.status_code} - {resp.text}"
        latencies_ms.append((t1 - t0) * 1000.0)

    latencies_ms.sort()
    mean_lat = statistics.mean(latencies_ms)
    median_lat = statistics.median(latencies_ms)
    p95_idx = int(0.95 * len(latencies_ms))
    p95_lat = latencies_ms[p95_idx]
    p99_idx = int(0.99 * len(latencies_ms))
    p99_lat = latencies_ms[p99_idx]
    min_lat = min(latencies_ms)
    max_lat = max(latencies_ms)

    return {
        "endpoint": name,
        "method": method,
        "path": path,
        "samples": n_iterations,
        "mean_ms": round(mean_lat, 2),
        "median_ms": round(median_lat, 2),
        "p95_ms": round(p95_lat, 2),
        "p99_ms": round(p99_lat, 2),
        "min_ms": round(min_lat, 2),
        "max_ms": round(max_lat, 2)
    }

def main():
    print("=" * 80)
    print(" BusSense AI - Phase H21 API Performance & Latency Benchmark")
    print("=" * 80)

    endpoints = [
        ("Health Probe", "GET", "/health", None),
        ("Fleet Routes", "GET", "/api/routes", None),
        ("Corridor Stops", "GET", "/api/stops", None),
        ("Active Fleet", "GET", "/api/buses", None),
        ("Fleet Crowd", "GET", "/api/crowd", None),
        ("GPS Locations", "GET", "/api/locations", None),
        ("Journey Recommendations", "POST", "/api/recommendations/plan", {
            "origin": "Kaloor Metro Station, Kochi",
            "destination": "Vyttila Mobility Hub",
            "preference": "balanced"
        }),
        ("Demand Predictions", "GET", "/api/predictions", None),
        ("Pilot Monitor HUD", "GET", "/api/ingest/pilot-monitor", None)
    ]

    results = []
    for name, method, path, payload in endpoints:
        res = benchmark_endpoint(name, method, path, payload, n_iterations=40)
        results.append(res)
        print(f"  [PASS] {res['endpoint']:<25} | Mean: {res['mean_ms']:>6.2f} ms | P95: {res['p95_ms']:>6.2f} ms | Min: {res['min_ms']:>6.2f} ms")

    print("\n" + "=" * 80)
    print(" Performance Benchmark Summary Table")
    print("=" * 80)
    print(f"{'Endpoint':<25} | {'Method':<6} | {'Mean (ms)':<10} | {'P95 (ms)':<10} | {'P99 (ms)':<10} | {'Min (ms)':<10}")
    print("-" * 80)
    for r in results:
        print(f"{r['endpoint']:<25} | {r['method']:<6} | {r['mean_ms']:<10} | {r['p95_ms']:<10} | {r['p99_ms']:<10} | {r['min_ms']:<10}")

    print("=" * 80)

if __name__ == "__main__":
    main()

