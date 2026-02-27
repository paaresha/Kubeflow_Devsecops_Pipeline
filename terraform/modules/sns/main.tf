# =============================================================================
# SNS Module — Notification Topics
# =============================================================================
# Creates SNS topics for alert routing. Prometheus Alertmanager and CloudWatch
# alarms publish to these topics, which then fan out to:
#   - Email subscriptions
#   - PagerDuty integration (via HTTPS endpoint)
#   - Slack (via Lambda or Chatbot)
#
# Two topics:
#   - critical-alerts: High-priority, pages on-call engineer
#   - warning-alerts:  Low-priority, informational (email only)
# =============================================================================

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "alert_email" {
  description = "Email address for alert notifications"
  type        = string
  default     = ""
}

# ── Critical Alerts Topic ───────────────────────────────────────────────────
# Used for: HighErrorRate, PodCrashLoop, NodeDiskPressure, DB down
resource "aws_sns_topic" "critical_alerts" {
  name = "${var.project_name}-${var.environment}-critical-alerts"

  tags = {
    Name        = "${var.project_name}-${var.environment}-critical-alerts"
    Environment = var.environment
    ManagedBy   = "terraform"
    Severity    = "critical"
  }
}

# ── Warning Alerts Topic ────────────────────────────────────────────────────
# Used for: HighLatency, PodNotReady, HighCPU, scaling events
resource "aws_sns_topic" "warning_alerts" {
  name = "${var.project_name}-${var.environment}-warning-alerts"

  tags = {
    Name        = "${var.project_name}-${var.environment}-warning-alerts"
    Environment = var.environment
    ManagedBy   = "terraform"
    Severity    = "warning"
  }
}

# ── Email Subscription (Critical) ──────────────────────────────────────────
resource "aws_sns_topic_subscription" "critical_email" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.critical_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ── Email Subscription (Warning) ───────────────────────────────────────────
resource "aws_sns_topic_subscription" "warning_email" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.warning_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ── SNS Topic Policy ───────────────────────────────────────────────────────
# Allows CloudWatch Alarms and EKS (Alertmanager via IRSA) to publish
resource "aws_sns_topic_policy" "critical_alerts" {
  arn = aws_sns_topic.critical_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudWatchAlarms"
        Effect    = "Allow"
        Principal = { Service = "cloudwatch.amazonaws.com" }
        Action    = "SNS:Publish"
        Resource  = aws_sns_topic.critical_alerts.arn
      },
    ]
  })
}

resource "aws_sns_topic_policy" "warning_alerts" {
  arn = aws_sns_topic.warning_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudWatchAlarms"
        Effect    = "Allow"
        Principal = { Service = "cloudwatch.amazonaws.com" }
        Action    = "SNS:Publish"
        Resource  = aws_sns_topic.warning_alerts.arn
      },
    ]
  })
}

# ── Outputs ──────────────────────────────────────────────────────────────────
output "critical_topic_arn" {
  description = "ARN of the critical alerts SNS topic"
  value       = aws_sns_topic.critical_alerts.arn
}

output "warning_topic_arn" {
  description = "ARN of the warning alerts SNS topic"
  value       = aws_sns_topic.warning_alerts.arn
}
