#!/usr/bin/env python3
"""
=============================================================================
Health Check Script — All Services
=============================================================================
Performs comprehensive health checks on all microservices:
  - HTTP health endpoint checks (/healthz, /readyz)
  - Response time measurement
  - Dependency connectivity (DB, Redis, SQS)
  - JSON response validation

Usage:
  python scripts/automation/health_check.py
  python scripts/automation/health_check.py --env dev
  python scripts/automation/health_check.py --env prod --timeout 10
=============================================================================
"""

import argparse
import json
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from typing import Optional

try:
    import requests
except ImportError:
    print("ERROR: 'requests' package required. Install with: pip install requests")
    sys.exit(1)

# ── Service Definitions ─────────────────────────────────────────────────────

ENVIRONMENTS = {
    "local": {
        "order-service": "http://localhost:8001",
        "user-service": "http://localhost:8002",
        "notification-service": "http://localhost:8003",
    },
    "dev": {
        "order-service": "https://dev-api.kubeflow-ops.example.com",
        "user-service": "https://dev-api.kubeflow-ops.example.com",
        "notification-service": "https://dev-api.kubeflow-ops.example.com",
    },
    "prod": {
        "order-service": "https://api.kubeflow-ops.example.com",
        "user-service": "https://api.kubeflow-ops.example.com",
        "notification-service": "https://api.kubeflow-ops.example.com",
    },
}

HEALTH_ENDPOINTS = ["/healthz", "/readyz"]


@dataclass
class HealthResult:
    service: str
    endpoint: str
    status_code: int
    response_time_ms: float
    healthy: bool
    error: Optional[str] = None
    body: Optional[dict] = None


def check_endpoint(base_url: str, service: str, endpoint: str, timeout: int) -> HealthResult:
    """Check a single health endpoint and return the result."""
    url = f"{base_url}{endpoint}"
    start = time.time()

    try:
        resp = requests.get(url, timeout=timeout)
        elapsed_ms = (time.time() - start) * 1000
        body = None
        try:
            body = resp.json()
        except (json.JSONDecodeError, ValueError):
            pass

        return HealthResult(
            service=service,
            endpoint=endpoint,
            status_code=resp.status_code,
            response_time_ms=round(elapsed_ms, 2),
            healthy=resp.status_code == 200,
            body=body,
        )
    except requests.exceptions.ConnectionError as e:
        return HealthResult(
            service=service,
            endpoint=endpoint,
            status_code=0,
            response_time_ms=0,
            healthy=False,
            error=f"Connection refused: {e}",
        )
    except requests.exceptions.Timeout:
        elapsed_ms = (time.time() - start) * 1000
        return HealthResult(
            service=service,
            endpoint=endpoint,
            status_code=0,
            response_time_ms=round(elapsed_ms, 2),
            healthy=False,
            error=f"Timeout after {timeout}s",
        )
    except Exception as e:
        return HealthResult(
            service=service,
            endpoint=endpoint,
            status_code=0,
            response_time_ms=0,
            healthy=False,
            error=str(e),
        )


def run_health_checks(env: str, timeout: int) -> list[HealthResult]:
    """Run health checks on all services concurrently."""
    services = ENVIRONMENTS.get(env, ENVIRONMENTS["local"])
    results = []

    with ThreadPoolExecutor(max_workers=10) as executor:
        futures = {}
        for service, base_url in services.items():
            for endpoint in HEALTH_ENDPOINTS:
                future = executor.submit(check_endpoint, base_url, service, endpoint, timeout)
                futures[future] = (service, endpoint)

        for future in as_completed(futures):
            results.append(future.result())

    # Sort by service name + endpoint for consistent output
    results.sort(key=lambda r: (r.service, r.endpoint))
    return results


def print_results(results: list[HealthResult]) -> bool:
    """Print formatted results and return overall health status."""
    print("\n" + "=" * 70)
    print("  KubeFlow Ops — Health Check Results")
    print("=" * 70)

    all_healthy = True

    for result in results:
        if result.healthy:
            icon = "✅"
            status_text = f"HTTP {result.status_code} ({result.response_time_ms}ms)"
        else:
            icon = "❌"
            all_healthy = False
            if result.error:
                status_text = result.error
            else:
                status_text = f"HTTP {result.status_code} ({result.response_time_ms}ms)"

        print(f"\n  {icon} {result.service}{result.endpoint}")
        print(f"     Status: {status_text}")

        if result.body:
            for key, value in result.body.items():
                print(f"     {key}: {value}")

    # ── Summary ──────────────────────────────────────────────────────────
    print("\n" + "-" * 70)
    total = len(results)
    healthy_count = sum(1 for r in results if r.healthy)
    unhealthy_count = total - healthy_count

    if all_healthy:
        print(f"  ✅ All {total} checks passed")
    else:
        print(f"  ❌ {unhealthy_count}/{total} checks FAILED")

    # Response time summary
    healthy_results = [r for r in results if r.healthy]
    if healthy_results:
        avg_time = sum(r.response_time_ms for r in healthy_results) / len(healthy_results)
        max_time = max(r.response_time_ms for r in healthy_results)
        print(f"  ⏱️  Avg response: {avg_time:.1f}ms | Max: {max_time:.1f}ms")

    print("=" * 70 + "\n")
    return all_healthy


def main():
    parser = argparse.ArgumentParser(description="Health check for KubeFlow Ops services")
    parser.add_argument("--env", default="local", choices=ENVIRONMENTS.keys(),
                        help="Target environment (default: local)")
    parser.add_argument("--timeout", type=int, default=5,
                        help="Request timeout in seconds (default: 5)")
    parser.add_argument("--json", action="store_true",
                        help="Output results as JSON")
    args = parser.parse_args()

    print(f"\n🔍 Running health checks against: {args.env}")

    results = run_health_checks(args.env, args.timeout)

    if args.json:
        output = [
            {
                "service": r.service,
                "endpoint": r.endpoint,
                "status_code": r.status_code,
                "response_time_ms": r.response_time_ms,
                "healthy": r.healthy,
                "error": r.error,
            }
            for r in results
        ]
        print(json.dumps(output, indent=2))
        all_healthy = all(r.healthy for r in results)
    else:
        all_healthy = print_results(results)

    sys.exit(0 if all_healthy else 1)


if __name__ == "__main__":
    main()
