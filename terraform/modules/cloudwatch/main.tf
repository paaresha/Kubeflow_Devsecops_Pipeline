# =============================================================================
# CloudWatch Module — Dashboard & Alarms
# =============================================================================
# Creates a CloudWatch dashboard showing key metrics from all AWS services
# and alarms that trigger SNS notifications when thresholds are breached.
#
# This is the AWS-native monitoring layer. Prometheus handles K8s-level
# metrics; CloudWatch handles AWS-managed service metrics (RDS, ElastiCache,
# SQS, EKS node group).
# =============================================================================

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "sns_critical_topic_arn" {
  description = "SNS topic ARN for critical alerts"
  type        = string
}

variable "sns_warning_topic_arn" {
  description = "SNS topic ARN for warning alerts"
  type        = string
}

variable "rds_instance_id" {
  description = "RDS instance identifier for monitoring"
  type        = string
  default     = ""
}

variable "elasticache_cluster_id" {
  description = "ElastiCache cluster ID for monitoring"
  type        = string
  default     = ""
}

variable "sqs_queue_name" {
  description = "SQS queue name for monitoring"
  type        = string
  default     = ""
}

variable "sqs_dlq_name" {
  description = "SQS DLQ name for monitoring"
  type        = string
  default     = ""
}

# ── CloudWatch Dashboard ────────────────────────────────────────────────────
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}-overview"

  dashboard_body = jsonencode({
    widgets = [
      # ── RDS Metrics ─────────────────────────────────────────────────
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "RDS — CPU & Connections"
          region = var.aws_region
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.rds_instance_id],
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", var.rds_instance_id],
          ]
          period = 300
          stat   = "Average"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "RDS — Free Storage & Memory"
          region = var.aws_region
          metrics = [
            ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", var.rds_instance_id],
            ["AWS/RDS", "FreeableMemory", "DBInstanceIdentifier", var.rds_instance_id],
          ]
          period = 300
          stat   = "Average"
        }
      },
      # ── SQS Metrics ────────────────────────────────────────────────
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "SQS — Message Counts"
          region = var.aws_region
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", var.sqs_queue_name],
            ["AWS/SQS", "ApproximateNumberOfMessagesNotVisible", "QueueName", var.sqs_queue_name],
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", var.sqs_dlq_name],
          ]
          period = 60
          stat   = "Sum"
        }
      },
      # ── ElastiCache Metrics ────────────────────────────────────────
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Redis — CPU & Memory"
          region = var.aws_region
          metrics = [
            ["AWS/ElastiCache", "CPUUtilization", "CacheClusterId", var.elasticache_cluster_id],
            ["AWS/ElastiCache", "DatabaseMemoryUsagePercentage", "CacheClusterId", var.elasticache_cluster_id],
            ["AWS/ElastiCache", "CurrConnections", "CacheClusterId", var.elasticache_cluster_id],
          ]
          period = 300
          stat   = "Average"
        }
      },
    ]
  })
}

# ── Alarm: RDS CPU > 80% ────────────────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  count = var.rds_instance_id != "" ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "RDS CPU utilization > 80% for 15 minutes"

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  alarm_actions = [var.sns_critical_topic_arn]
  ok_actions    = [var.sns_warning_topic_arn]

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ── Alarm: RDS Free Storage < 5GB ───────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "rds_storage_low" {
  count = var.rds_instance_id != "" ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-rds-storage-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 5368709120  # 5 GB in bytes
  alarm_description   = "RDS free storage < 5GB"

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  alarm_actions = [var.sns_critical_topic_arn]

  tags = {
    Environment = var.environment
  }
}

# ── Alarm: SQS DLQ Messages > 0 ────────────────────────────────────────────
# Any message in the DLQ means something failed processing 3 times
resource "aws_cloudwatch_metric_alarm" "sqs_dlq_messages" {
  count = var.sqs_dlq_name != "" ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-sqs-dlq-not-empty"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "DLQ has messages — processing failures detected"

  dimensions = {
    QueueName = var.sqs_dlq_name
  }

  alarm_actions = [var.sns_critical_topic_arn]
  ok_actions    = [var.sns_warning_topic_arn]

  tags = {
    Environment = var.environment
  }
}

# ── Alarm: SQS Queue Backlog > 1000 ────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "sqs_queue_backlog" {
  count = var.sqs_queue_name != "" ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-sqs-backlog-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Sum"
  threshold           = 1000
  alarm_description   = "SQS queue has > 1000 messages waiting — consumer may be down"

  dimensions = {
    QueueName = var.sqs_queue_name
  }

  alarm_actions = [var.sns_warning_topic_arn]

  tags = {
    Environment = var.environment
  }
}

# ── Alarm: Redis CPU > 70% ─────────────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "redis_cpu_high" {
  count = var.elasticache_cluster_id != "" ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-redis-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Redis CPU > 70% for 15 minutes"

  dimensions = {
    CacheClusterId = var.elasticache_cluster_id
  }

  alarm_actions = [var.sns_warning_topic_arn]

  tags = {
    Environment = var.environment
  }
}

# ── Outputs ──────────────────────────────────────────────────────────────────
output "dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "dashboard_url" {
  description = "Direct URL to the CloudWatch dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}
