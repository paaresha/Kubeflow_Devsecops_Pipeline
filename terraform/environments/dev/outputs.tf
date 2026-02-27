# =============================================================================
# Dev Environment — Outputs
# =============================================================================
# These values are printed after terraform apply and can be used to
# configure kubectl, GitHub Actions secrets, etc.
# =============================================================================

output "eks_cluster_name" {
  description = "EKS cluster name (used in: aws eks update-kubeconfig --name <this>)"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS API endpoint"
  value       = module.eks.cluster_endpoint
}

output "ecr_repository_urls" {
  description = "ECR repo URLs for each microservice"
  value       = module.ecr.repository_urls
}

output "rds_endpoint" {
  description = "PostgreSQL endpoint"
  value       = module.rds.endpoint
}

output "rds_secret_arn" {
  description = "ARN of DB credentials in Secrets Manager"
  value       = module.rds.secret_arn
}

output "redis_endpoint" {
  description = "Redis endpoint"
  value       = module.elasticache.endpoint
}

output "redis_url" {
  description = "Redis connection URL"
  value       = module.elasticache.redis_url
}

output "sqs_queue_url" {
  description = "SQS order events queue URL"
  value       = module.sqs.queue_url
}

output "sqs_dlq_url" {
  description = "SQS dead-letter queue URL"
  value       = module.sqs.dlq_url
}

# ── New module outputs ───────────────────────────────────────────────────────

output "sns_critical_topic_arn" {
  description = "SNS topic ARN for critical alerts"
  value       = module.sns.critical_topic_arn
}

output "sns_warning_topic_arn" {
  description = "SNS topic ARN for warning alerts"
  value       = module.sns.warning_topic_arn
}

output "cloudwatch_dashboard_url" {
  description = "URL to the CloudWatch overview dashboard"
  value       = module.cloudwatch.dashboard_url
}

output "irsa_order_service_role_arn" {
  description = "IAM role ARN for order-service (annotate K8s ServiceAccount with this)"
  value       = module.irsa.order_service_role_arn
}

output "irsa_user_service_role_arn" {
  description = "IAM role ARN for user-service"
  value       = module.irsa.user_service_role_arn
}

output "irsa_notification_service_role_arn" {
  description = "IAM role ARN for notification-service"
  value       = module.irsa.notification_service_role_arn
}

output "irsa_external_secrets_role_arn" {
  description = "IAM role ARN for External Secrets Operator"
  value       = module.irsa.external_secrets_role_arn
}

# ── Convenience: kubeconfig command ──────────────────────────────────────────
output "configure_kubectl" {
  description = "Run this to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}
