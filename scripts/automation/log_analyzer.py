#!/usr/bin/env python3
"""
=============================================================================
Log Analyzer — Kubernetes Pod Log Analysis
=============================================================================
Fetches and analyzes pod logs for error patterns, extracting:
  - Error frequency and distribution
  - Most common error messages
  - Error timeline (when do errors spike?)
  - Actionable recommendations

Works with kubectl (accesses cluster directly) or with log files.

Usage:
  python scripts/automation/log_analyzer.py --service order-service
  python scripts/automation/log_analyzer.py --service order-service --since 1h
  python scripts/automation/log_analyzer.py --file /path/to/logfile.log
  python scripts/automation/log_analyzer.py --service order-service --json
=============================================================================
"""

import argparse
import json
import re
import subprocess
import sys
from collections import Counter, defaultdict
from datetime import datetime
from typing import Optional


NAMESPACE = "kubeflow-ops"

# ── Error Patterns to Search For ────────────────────────────────────────────
ERROR_PATTERNS = {
    "database_error": re.compile(r"(OperationalError|psycopg2|sqlalchemy\.exc|database.*error|connection.*refused.*5432)", re.IGNORECASE),
    "http_5xx": re.compile(r"(HTTP\s*5\d{2}|status.*5\d{2}|Internal Server Error|502 Bad Gateway|503 Service Unavailable)", re.IGNORECASE),
    "timeout": re.compile(r"(timeout|timed?\s*out|deadline\s*exceeded|context\s*canceled)", re.IGNORECASE),
    "oom": re.compile(r"(OOMKilled|out\s*of\s*memory|memory\s*limit|MemoryError)", re.IGNORECASE),
    "auth_error": re.compile(r"(unauthorized|forbidden|403|401|authentication.*fail|access.*denied)", re.IGNORECASE),
    "sqs_error": re.compile(r"(SQS.*error|queue.*error|send_message.*fail|receive_message.*fail)", re.IGNORECASE),
    "redis_error": re.compile(r"(redis.*error|connection.*refused.*6379|redis\.exceptions)", re.IGNORECASE),
    "import_error": re.compile(r"(ImportError|ModuleNotFoundError|No module named)", re.IGNORECASE),
    "crash": re.compile(r"(Traceback|Exception|Error|CRITICAL|FATAL)", re.IGNORECASE),
    "image_pull": re.compile(r"(ImagePullBackOff|ErrImagePull|image.*not.*found)", re.IGNORECASE),
}

# ── Timestamp Patterns ──────────────────────────────────────────────────────
TIMESTAMP_PATTERNS = [
    re.compile(r"(\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2})"),
    re.compile(r"(\d{2}/\w{3}/\d{4}:\d{2}:\d{2}:\d{2})"),
]


def fetch_logs_kubectl(service: str, since: str, tail: int) -> list[str]:
    """Fetch logs from Kubernetes pods using kubectl."""
    try:
        cmd = [
            "kubectl", "logs",
            "-n", NAMESPACE,
            "-l", f"app={service}",
            "--all-containers=true",
            f"--since={since}",
            f"--tail={tail}",
        ]
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)

        if result.returncode != 0:
            print(f"  ⚠️  kubectl error: {result.stderr.strip()}")
            return []

        return result.stdout.strip().split("\n")
    except FileNotFoundError:
        print("  ❌ kubectl not found — install kubectl or use --file flag")
        return []
    except subprocess.TimeoutExpired:
        print("  ❌ kubectl timed out — cluster might be unreachable")
        return []


def read_log_file(filepath: str) -> list[str]:
    """Read logs from a file."""
    try:
        with open(filepath, "r") as f:
            return f.readlines()
    except FileNotFoundError:
        print(f"  ❌ File not found: {filepath}")
        return []


def extract_timestamp(line: str) -> Optional[str]:
    """Extract timestamp from a log line."""
    for pattern in TIMESTAMP_PATTERNS:
        match = pattern.search(line)
        if match:
            return match.group(1)
    return None


def analyze_logs(lines: list[str]) -> dict:
    """Analyze log lines and return structured analysis."""
    total_lines = len(lines)
    error_counts = Counter()
    error_examples = defaultdict(list)
    hourly_errors = defaultdict(int)

    for line in lines:
        line = line.strip()
        if not line:
            continue

        for category, pattern in ERROR_PATTERNS.items():
            if pattern.search(line):
                error_counts[category] += 1

                # Keep first 3 examples per category
                if len(error_examples[category]) < 3:
                    # Truncate long lines
                    example = line[:200] + "..." if len(line) > 200 else line
                    error_examples[category].append(example)

                # Extract hour for timeline
                ts = extract_timestamp(line)
                if ts:
                    try:
                        hour = ts[:13]  # "2025-02-28T01"
                        hourly_errors[hour] += 1
                    except (IndexError, ValueError):
                        pass

    total_errors = sum(error_counts.values())
    error_rate = (total_errors / total_lines * 100) if total_lines > 0 else 0

    return {
        "total_lines": total_lines,
        "total_errors": total_errors,
        "error_rate_percent": round(error_rate, 2),
        "error_counts": dict(error_counts.most_common()),
        "error_examples": dict(error_examples),
        "hourly_timeline": dict(sorted(hourly_errors.items())),
    }


def generate_recommendations(analysis: dict) -> list[str]:
    """Generate actionable recommendations based on error patterns."""
    recommendations = []
    counts = analysis["error_counts"]

    if counts.get("database_error", 0) > 0:
        recommendations.append(
            "🔧 DATABASE: Check RDS connectivity, security groups, and credentials. "
            "Verify DB is not at max connections: aws rds describe-db-instances"
        )

    if counts.get("oom", 0) > 0:
        recommendations.append(
            "🔧 MEMORY: Pods are being OOM-killed. Increase memory limits in deployment.yaml "
            "or investigate memory leaks with: kubectl top pods -n kubeflow-ops"
        )

    if counts.get("timeout", 0) > 0:
        recommendations.append(
            "🔧 TIMEOUT: Requests are timing out. Check downstream service health, "
            "database query performance, and network connectivity."
        )

    if counts.get("sqs_error", 0) > 0:
        recommendations.append(
            "🔧 SQS: Queue operations failing. Check IAM permissions (IRSA), "
            "SQS queue URL, and AWS region configuration."
        )

    if counts.get("redis_error", 0) > 0:
        recommendations.append(
            "🔧 REDIS: Redis connection issues. Check ElastiCache security groups "
            "and endpoint configuration in ConfigMap."
        )

    if counts.get("auth_error", 0) > 0:
        recommendations.append(
            "🔧 AUTH: Authentication/authorization failures. Check IRSA role, "
            "ServiceAccount annotations, and IAM policy permissions."
        )

    if counts.get("image_pull", 0) > 0:
        recommendations.append(
            "🔧 IMAGE: Image pull failures. Verify ECR repository exists, "
            "image tag is correct, and node IAM role has ECR read access."
        )

    if analysis["error_rate_percent"] > 5:
        recommendations.append(
            "🚨 ERROR RATE > 5%: Consider rolling back: "
            "./scripts/ops/rollback_deployment.sh <service-name>"
        )

    return recommendations


def print_analysis(service: str, analysis: dict):
    """Print formatted analysis report."""
    print("\n" + "=" * 70)
    print(f"  Log Analysis — {service}")
    print("=" * 70)

    print(f"\n  📊 Summary")
    print(f"     Total lines analyzed: {analysis['total_lines']:,}")
    print(f"     Total errors found:   {analysis['total_errors']:,}")
    print(f"     Error rate:           {analysis['error_rate_percent']}%")

    if analysis["error_counts"]:
        print(f"\n  🔍 Error Distribution")
        for category, count in analysis["error_counts"].items():
            bar = "█" * min(count, 50)
            print(f"     {category:<20} {count:>5}  {bar}")

        print(f"\n  📝 Error Examples")
        for category, examples in analysis["error_examples"].items():
            print(f"\n     [{category}]")
            for ex in examples:
                print(f"       → {ex}")

    if analysis["hourly_timeline"]:
        print(f"\n  ⏰ Error Timeline (per hour)")
        for hour, count in analysis["hourly_timeline"].items():
            bar = "▓" * min(count, 40)
            print(f"     {hour}  {count:>4}  {bar}")

    recommendations = generate_recommendations(analysis)
    if recommendations:
        print(f"\n  💡 Recommendations")
        for rec in recommendations:
            print(f"     {rec}")

    print("\n" + "=" * 70 + "\n")


def main():
    parser = argparse.ArgumentParser(description="Analyze Kubernetes pod logs")
    parser.add_argument("--service", type=str, default=None,
                        help="Service to analyze (fetches via kubectl)")
    parser.add_argument("--file", type=str, default=None,
                        help="Log file path (alternative to kubectl)")
    parser.add_argument("--since", type=str, default="1h",
                        help="How far back to fetch logs (default: 1h)")
    parser.add_argument("--tail", type=int, default=5000,
                        help="Max number of log lines (default: 5000)")
    parser.add_argument("--json", action="store_true",
                        help="Output as JSON")
    args = parser.parse_args()

    if not args.service and not args.file:
        parser.error("Either --service or --file is required")

    if args.file:
        source = args.file
        lines = read_log_file(args.file)
    else:
        source = args.service
        print(f"\n🔍 Fetching logs for: {args.service} (last {args.since})")
        lines = fetch_logs_kubectl(args.service, args.since, args.tail)

    if not lines or (len(lines) == 1 and not lines[0].strip()):
        print("  ⚠️  No logs found")
        sys.exit(0)

    analysis = analyze_logs(lines)

    if args.json:
        print(json.dumps(analysis, indent=2))
    else:
        print_analysis(source, analysis)

    # Exit with error if error rate is critical
    if analysis["error_rate_percent"] > 10:
        sys.exit(2)
    elif analysis["error_rate_percent"] > 5:
        sys.exit(1)
    else:
        sys.exit(0)


if __name__ == "__main__":
    main()
