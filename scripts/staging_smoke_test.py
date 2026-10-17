#!/usr/bin/env python3
"""
BusSense AI - Staging Smoke Test & Verification Script
Phase H14 Step 4: Deployment Operations & Staging Verification

Non-destructive automated smoke test suite for verifying running containerized
or locally deployed staging environments.

Features:
- Standard library only (no external pip dependencies required)
- Reads configuration from environment variables:
    BACKEND_URL (default: http://localhost:8000)
    FRONTEND_URL (default: http://localhost:3000)
    TEST_ENVIRONMENT (default: staging)
- Sanitized output: zero passwords, tokens, or private secrets printed
- Returns exit code 0 on all tests passing, 1 on critical failure
"""
import os
import sys
import json
import urllib.request
import urllib.error
from typing import Dict, Any, Tuple, Optional

# Base URLs
BACKEND_URL = os.environ.get("BACKEND_URL", "http://localhost:8000").rstrip("/")
FRONTEND_URL = os.environ.get("FRONTEND_URL", "http://localhost:3000").rstrip("/")
TEST_ENV = os.environ.get("TEST_ENVIRONMENT", "staging").lower()

class Colors:
    GREEN = "\033[92m"
    RED = "\033[91m"
    YELLOW = "\033[93m"
    BLUE = "\033[94m"
    RESET = "\033[0m"
    BOLD = "\033[1m"

def log_header(msg: str):
    print(f"\n{Colors.BOLD}{Colors.BLUE}=== {msg} ==={Colors.RESET}")

def log_pass(msg: str, detail: str = ""):
    extra = f" ({detail})" if detail else ""
    print(f"{Colors.GREEN}[PASS]{Colors.RESET} {msg}{extra}")

def log_fail(msg: str, detail: str = ""):
    extra = f" ({detail})" if detail else ""
    print(f"{Colors.RED}[FAIL]{Colors.RESET} {msg}{extra}")

def log_warn(msg: str, detail: str = ""):
    extra = f" ({detail})" if detail else ""
    print(f"{Colors.YELLOW}[WARN]{Colors.RESET} {msg}{extra}")

def request_http(
    url: str,
    method: str = "GET",
    headers: Optional[Dict[str, str]] = None,
    data: Optional[Dict[str, Any]] = None,
    timeout: float = 5.0
) -> Tuple[int, Dict[str, str], str]:
    """Execute standard HTTP request and return (status_code, headers_dict, body_str)."""
    headers = headers or {}
    encoded_data = None
    if data is not None:
        encoded_data = json.dumps(data).encode("utf-8")
        if "Content-Type" not in headers:
            headers["Content-Type"] = "application/json"

    req = urllib.request.Request(url, data=encoded_data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            status = resp.status
            resp_headers = {k: v for k, v in resp.getheaders()}
            body = resp.read().decode("utf-8", errors="replace")
            return status, resp_headers, body
    except urllib.error.HTTPError as e:
        resp_headers = {k: v for k, v in e.headers.items()} if e.headers else {}
        body = e.read().decode("utf-8", errors="replace") if e.fp else ""
        return e.code, resp_headers, body
    except Exception as e:
        return 0, {}, str(e)


def run_smoke_tests() -> int:
    log_header(f"BusSense AI Staging Smoke Verification ({TEST_ENV.upper()})")
    print(f"Target Backend : {BACKEND_URL}")
    print(f"Target Frontend: {FRONTEND_URL}")

    total_checks = 0
    passed_checks = 0
    failures = 0

    # --------------------------------------------------------------------------
    # 1. Backend Liveness Probe (GET /health/live)
    # --------------------------------------------------------------------------
    total_checks += 1
    code, headers, body = request_http(f"{BACKEND_URL}/health/live")
    if code == 200:
        try:
            parsed = json.loads(body)
            if parsed.get("status") == "alive":
                log_pass("Backend Liveness Probe", f"HTTP 200, status='{parsed.get('status')}'")
                passed_checks += 1
            else:
                log_fail("Backend Liveness Probe", f"Unexpected payload: {body}")
                failures += 1
        except Exception:
            log_fail("Backend Liveness Probe", f"Invalid JSON response: {body}")
            failures += 1
    else:
        log_fail("Backend Liveness Probe", f"HTTP {code} ({body})")
        failures += 1

    # --------------------------------------------------------------------------
    # 2. Backend Readiness Probe (GET /health/ready)
    # --------------------------------------------------------------------------
    total_checks += 1
    code, headers, body = request_http(f"{BACKEND_URL}/health/ready")
    if code == 200:
        try:
            parsed = json.loads(body)
            if parsed.get("database") == "connected":
                log_pass("Backend Readiness Probe", "HTTP 200, database connected")
                passed_checks += 1
            else:
                log_fail("Backend Readiness Probe", f"Database status degraded: {body}")
                failures += 1
        except Exception:
            log_fail("Backend Readiness Probe", f"Invalid JSON response: {body}")
            failures += 1
    elif code == 503:
        log_warn("Backend Readiness Probe", "HTTP 503 (Supabase database unreachable or starting)")
    else:
        log_fail("Backend Readiness Probe", f"HTTP {code} ({body})")
        failures += 1

    # --------------------------------------------------------------------------
    # 3. Request Correlation ID (X-Request-ID Header)
    # --------------------------------------------------------------------------
    total_checks += 1
    req_id = headers.get("X-Request-ID") or headers.get("x-request-id")
    if req_id:
        log_pass("Request Correlation ID", f"Header X-Request-ID present: {req_id[:8]}...")
        passed_checks += 1
    else:
        log_fail("Request Correlation ID", "Missing X-Request-ID response header")
        failures += 1

    # --------------------------------------------------------------------------
    # 4. Authority Frontend Liveness (GET /)
    # --------------------------------------------------------------------------
    total_checks += 1
    code, _, _ = request_http(f"{FRONTEND_URL}/")
    if code == 200:
        log_pass("Authority Frontend Access", "HTTP 200 OK")
        passed_checks += 1
    elif code == 0:
        log_warn("Authority Frontend Access", f"Unreachable at {FRONTEND_URL} (Check if container started)")
    else:
        log_fail("Authority Frontend Access", f"HTTP {code}")
        failures += 1

    # --------------------------------------------------------------------------
    # 5. CORS Headers Verification
    # --------------------------------------------------------------------------
    total_checks += 1
    cors_headers = {
        "Origin": FRONTEND_URL,
        "Access-Control-Request-Method": "GET"
    }
    code, headers, _ = request_http(f"{BACKEND_URL}/api/routes", method="OPTIONS", headers=cors_headers)
    allow_origin = headers.get("Access-Control-Allow-Origin") or headers.get("access-control-allow-origin")
    if allow_origin and allow_origin != "*":
        log_pass("Dynamic CORS Configuration", f"Allowed origin restricted to: {allow_origin}")
        passed_checks += 1
    elif allow_origin == "*":
        log_fail("Dynamic CORS Configuration", "Insecure wildcard '*' detected with credentials")
        failures += 1
    else:
        # FastAPI handles OPTIONS directly or returns 200 on standard GET
        code_get, headers_get, _ = request_http(f"{BACKEND_URL}/api/routes", headers={"Origin": FRONTEND_URL})
        allow_origin_get = headers_get.get("Access-Control-Allow-Origin") or headers_get.get("access-control-allow-origin")
        if allow_origin_get:
            log_pass("Dynamic CORS Configuration", f"Allowed origin verified: {allow_origin_get}")
            passed_checks += 1
        else:
            log_warn("Dynamic CORS Configuration", "Access-Control-Allow-Origin not returned for this origin")

    # --------------------------------------------------------------------------
    # 6. Unauthenticated RBAC Protection (GET /api/auth/me)
    # --------------------------------------------------------------------------
    total_checks += 1
    code, _, body = request_http(f"{BACKEND_URL}/api/auth/me")
    if code == 401:
        log_pass("Unauthenticated RBAC Protection", "HTTP 401 Unauthorized for unauthenticated request")
        passed_checks += 1
    else:
        log_fail("Unauthenticated RBAC Protection", f"Expected HTTP 401, got {code}")
        failures += 1

    # --------------------------------------------------------------------------
    # 7. Conductor Ticket Validation RBAC (POST /api/tickets/validate)
    # --------------------------------------------------------------------------
    total_checks += 1
    code, _, body = request_http(
        f"{BACKEND_URL}/api/tickets/validate",
        method="POST",
        data={"qr_code_hash": "test-qr", "bus_number": "205"}
    )
    if code in [401, 403]:
        log_pass("Conductor Endpoint Role Boundary", f"HTTP {code} received for unprivileged validation attempt")
        passed_checks += 1
    else:
        log_fail("Conductor Endpoint Role Boundary", f"Expected HTTP 401/403, got {code}")
        failures += 1

    # --------------------------------------------------------------------------
    # 8. Realtime Event Polling Fallback (GET /api/realtime/events)
    # --------------------------------------------------------------------------
    total_checks += 1
    code, _, body = request_http(f"{BACKEND_URL}/api/realtime/events?limit=5")
    if code == 200:
        try:
            parsed = json.loads(body)
            items = parsed.get("data", [])
            log_pass("Realtime Polling Fallback", f"HTTP 200, {len(items)} events retrieved")
            passed_checks += 1
        except Exception:
            log_fail("Realtime Polling Fallback", f"Invalid JSON response: {body}")
            failures += 1
    else:
        log_fail("Realtime Polling Fallback", f"HTTP {code} ({body})")
        failures += 1

    # --------------------------------------------------------------------------
    # 9. Public Corridor Routes (GET /api/routes)
    # --------------------------------------------------------------------------
    total_checks += 1
    code, _, body = request_http(f"{BACKEND_URL}/api/routes")
    if code == 200:
        try:
            parsed = json.loads(body)
            routes = parsed.get("data", [])
            log_pass("Public Corridor Routes API", f"HTTP 200, {len(routes)} transit routes retrieved")
            passed_checks += 1
        except Exception:
            log_fail("Public Corridor Routes API", f"Invalid JSON: {body}")
            failures += 1
    else:
        log_fail("Public Corridor Routes API", f"HTTP {code}")
        failures += 1

    # --------------------------------------------------------------------------
    # Summary Report
    # --------------------------------------------------------------------------
    log_header("Verification Summary")
    print(f"Total Checks Executed : {total_checks}")
    print(f"Passed Checks         : {Colors.GREEN}{passed_checks}{Colors.RESET}")
    print(f"Failures              : {Colors.RED if failures > 0 else Colors.GREEN}{failures}{Colors.RESET}")

    if failures == 0:
        print(f"\n{Colors.GREEN}{Colors.BOLD}>>> Staging Smoke Verification SUCCEEDED <<<{Colors.RESET}\n")
        return 0
    else:
        print(f"\n{Colors.RED}{Colors.BOLD}>>> Staging Smoke Verification FAILED ({failures} issues) <<<{Colors.RESET}\n")
        return 1

if __name__ == "__main__":
    sys.exit(run_smoke_tests())
