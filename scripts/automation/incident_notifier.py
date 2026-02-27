#!/usr/bin/env python3
"""
=============================================================================
Incident Notifier — Multi-Channel Alert Dispatcher
=============================================================================
Sends incident notifications to multiple channels:
  - Slack (via webhook)
  - AWS SNS (for PagerDuty/email integration)
  - Console (for local testing)

Designed to be called from alerting pipelines, cron jobs, or the
rollback script when automatic rollback occurs.

Usage:
  python scripts/automation/incident_notifier.py \
      --severity critical \
      --service order-service \
      --title "High Error Rate" \
      --description "Order service returning 500s" \
      --channel slack sns

  python scripts/automation/incident_notifier.py \
      --severity warning \
      --service notification-service \
      --title "High Latency" \
      --description "P95 latency > 2s" \
      --channel console
=============================================================================
"""

import argparse
import json
import os
import sys
from datetime import datetime, timezone
from typing import Optional

try:
    import boto3
except ImportError:
    boto3 = None

try:
    import requests
except ImportError:
    requests = None

# ── Configuration ────────────────────────────────────────────────────────────
SLACK_WEBHOOK_URL = os.getenv("SLACK_WEBHOOK_URL", "")
SNS_TOPIC_ARN = os.getenv("SNS_TOPIC_ARN", "")
AWS_REGION = os.getenv("AWS_REGION", "us-east-1")

SEVERITY_COLORS = {
    "critical": "#FF0000",   # Red
    "warning": "#FFA500",    # Orange
    "info": "#36A64F",       # Green
}

SEVERITY_EMOJIS = {
    "critical": "🔴",
    "warning": "🟡",
    "info": "🟢",
}


def build_message(severity: str, service: str, title: str,
                   description: str, environment: str) -> dict:
    """Build a structured message from incident details."""
    return {
        "severity": severity,
        "service": service,
        "title": title,
        "description": description,
        "environment": environment,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "emoji": SEVERITY_EMOJIS.get(severity, "⚪"),
        "color": SEVERITY_COLORS.get(severity, "#808080"),
    }


def send_to_console(message: dict):
    """Print incident to console (always available, useful for testing)."""
    print("\n" + "=" * 60)
    print(f"  {message['emoji']} INCIDENT — {message['severity'].upper()}")
    print("=" * 60)
    print(f"  Service:     {message['service']}")
    print(f"  Title:       {message['title']}")
    print(f"  Description: {message['description']}")
    print(f"  Environment: {message['environment']}")
    print(f"  Time:        {message['timestamp']}")
    print("=" * 60 + "\n")


def send_to_slack(message: dict) -> bool:
    """Send incident notification to Slack via webhook."""
    if not SLACK_WEBHOOK_URL:
        print("  ⚠️  SLACK_WEBHOOK_URL not set — skipping Slack notification")
        return False

    if requests is None:
        print("  ⚠️  'requests' package not installed — skipping Slack")
        return False

    payload = {
        "attachments": [{
            "color": message["color"],
            "title": f"{message['emoji']} {message['title']}",
            "fields": [
                {"title": "Service", "value": message["service"], "short": True},
                {"title": "Severity", "value": message["severity"].upper(), "short": True},
                {"title": "Environment", "value": message["environment"], "short": True},
                {"title": "Time", "value": message["timestamp"], "short": True},
                {"title": "Description", "value": message["description"], "short": False},
            ],
            "footer": "KubeFlow Ops Incident Notifier",
        }]
    }

    try:
        resp = requests.post(SLACK_WEBHOOK_URL, json=payload, timeout=10)
        if resp.status_code == 200:
            print("  ✅ Slack notification sent")
            return True
        else:
            print(f"  ❌ Slack failed: HTTP {resp.status_code} — {resp.text}")
            return False
    except Exception as e:
        print(f"  ❌ Slack error: {e}")
        return False


def send_to_sns(message: dict) -> bool:
    """Publish incident to AWS SNS topic (for PagerDuty/email/SMS routing)."""
    if not SNS_TOPIC_ARN:
        print("  ⚠️  SNS_TOPIC_ARN not set — skipping SNS notification")
        return False

    if boto3 is None:
        print("  ⚠️  'boto3' package not installed — skipping SNS")
        return False

    sns_client = boto3.client("sns", region_name=AWS_REGION)

    subject = f"[{message['severity'].upper()}] {message['service']}: {message['title']}"
    # SNS subject max 100 chars
    if len(subject) > 100:
        subject = subject[:97] + "..."

    body = json.dumps(message, indent=2)

    try:
        sns_client.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=subject,
            Message=body,
            MessageAttributes={
                "severity": {
                    "DataType": "String",
                    "StringValue": message["severity"],
                },
                "service": {
                    "DataType": "String",
                    "StringValue": message["service"],
                },
            },
        )
        print("  ✅ SNS notification published")
        return True
    except Exception as e:
        print(f"  ❌ SNS error: {e}")
        return False


CHANNELS = {
    "console": send_to_console,
    "slack": send_to_slack,
    "sns": send_to_sns,
}


def main():
    parser = argparse.ArgumentParser(description="Send incident notifications")
    parser.add_argument("--severity", required=True,
                        choices=["critical", "warning", "info"],
                        help="Incident severity level")
    parser.add_argument("--service", required=True,
                        help="Affected service name")
    parser.add_argument("--title", required=True,
                        help="Short incident title")
    parser.add_argument("--description", required=True,
                        help="Detailed description")
    parser.add_argument("--environment", default="dev",
                        help="Environment (default: dev)")
    parser.add_argument("--channel", nargs="+", default=["console"],
                        choices=CHANNELS.keys(),
                        help="Notification channels (default: console)")
    args = parser.parse_args()

    message = build_message(
        severity=args.severity,
        service=args.service,
        title=args.title,
        description=args.description,
        environment=args.environment,
    )

    print(f"\n📢 Sending {args.severity} incident to: {', '.join(args.channel)}")

    success_count = 0
    for channel in args.channel:
        handler = CHANNELS[channel]
        result = handler(message)
        if result is not False:
            success_count += 1

    if success_count == 0:
        print("\n❌ All notification channels failed!")
        sys.exit(1)
    else:
        print(f"\n✅ {success_count}/{len(args.channel)} channels notified")


if __name__ == "__main__":
    main()
