"""
BusSense AI - Staging Runtime Verification Harness
Starts the local backend ASGI service in-process, runs the realistic transit feed simulator (all 11 checks),
runs the staging smoke test suite, and cleanly terminates the server.
"""
import os
import sys
import time
import threading
import urllib.request
from pathlib import Path

# Add root and backend directories to sys.path
root_dir = Path(__file__).resolve().parent.parent
backend_dir = root_dir / "backend"
sys.path.insert(0, str(root_dir))
sys.path.insert(0, str(backend_dir))

def wait_for_server(url: str, timeout: float = 20.0) -> bool:
    start_t = time.time()
    while time.time() - start_t < timeout:
        try:
            with urllib.request.urlopen(url, timeout=2.0) as resp:
                if resp.status == 200:
                    return True
        except Exception:
            pass
        time.sleep(0.5)
    return False

def main():
    import uvicorn
    from app.main import app

    print("=" * 80)
    print(" BusSense AI - Staging Runtime Verification Harness")
    print("=" * 80)

    config = uvicorn.Config(app, host="127.0.0.1", port=8000, log_level="warning")
    server = uvicorn.Server(config)
    server_thread = threading.Thread(target=server.run, daemon=True)

    print("\n[Step 1] Starting backend ASGI server (Uvicorn on port 8000 in-process)...")
    server_thread.start()

    health_url = "http://127.0.0.1:8000/health/live"
    print(f"Waiting for {health_url} to become ready...")
    ready = wait_for_server(health_url, timeout=20.0)
    if not ready:
        print("ERROR: Backend server failed to start within 20 seconds.")
        server.should_exit = True
        sys.exit(1)

    print("Backend server is ALIVE and accepting requests!")

    try:
        print("\n[Step 2] Executing Transit Feed Simulator (11 Ingestion Checks)...")
        from scripts.transit_feed_simulator import run_simulation
        run_simulation()

        print("\n[Step 3] Executing Staging Smoke Test Suite...")
        from scripts.staging_smoke_test import run_smoke_tests
        run_smoke_tests()

        print("\n" + "=" * 80)
        print(" Verification Harness completed successfully!")
        print("=" * 80)

    finally:
        print("\n[Cleanup] Signaling backend server to shut down...")
        server.should_exit = True
        time.sleep(1)
        print("Backend server shut down cleanly.")

if __name__ == "__main__":
    main()
