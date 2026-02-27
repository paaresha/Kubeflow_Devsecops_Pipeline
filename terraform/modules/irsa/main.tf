# =============================================================================
# IRSA Module — IAM Roles for Service Accounts
# =============================================================================
# Creates per-service IAM roles that Kubernetes ServiceAccounts can assume.
# This is the "least privilege" approach — each service gets ONLY the AWS
# permissions it needs, via its own IAM role.
#
# How it works:
#   1. Terraform creates an IAM role with a trust policy pointing to the
#      EKS OIDC provider + specific ServiceAccount name
#   2. You annotate the K8s ServiceAccount with the role ARN
#   3. When a pod uses that ServiceAccount, the AWS SDK automatically
#      gets temporary credentials for that role — no access keys!
#
# Architecture:
#   order-service-sa        → IAM role with SQS:SendMessage + RDS access
#   notification-service-sa → IAM role with SQS:ReceiveMessage + Redis
#   user-service-sa         → IAM role with RDS access only
# =============================================================================

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider (from EKS module output)"
  type        = string
}

variable "oidc_provider_url" {
  description = "URL of the OIDC provider without https:// (from EKS module output)"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace where ServiceAccounts live"
  type        = string
  default     = "kubeflow-ops"
}

variable "sqs_queue_arn" {
  description = "ARN of the SQS order events queue"
  type        = string
  default     = ""
}

variable "sqs_dlq_arn" {
  description = "ARN of the SQS dead-letter queue"
  type        = string
  default     = ""
}

variable "rds_secret_arn" {
  description = "ARN of the RDS credentials in Secrets Manager"
  type        = string
  default     = ""
}

# ── Order Service IAM Role ──────────────────────────────────────────────────
# Needs: SQS (send messages), Secrets Manager (DB credentials)
resource "aws_iam_role" "order_service" {
  name = "${var.project_name}-${var.environment}-order-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.oidc_provider_url}:sub" = "system:serviceaccount:${var.namespace}:order-service-sa"
          "${var.oidc_provider_url}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-order-service-role"
    Environment = var.environment
    Service     = "order-service"
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy" "order_service" {
  name = "${var.project_name}-${var.environment}-order-service-policy"
  role = aws_iam_role.order_service.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SQSSendMessage"
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:GetQueueUrl",
          "sqs:GetQueueAttributes",
        ]
        Resource = compact([var.sqs_queue_arn])
      },
      {
        Sid    = "SecretsManagerRead"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
        ]
        Resource = compact([var.rds_secret_arn])
      },
    ]
  })
}

# ── User Service IAM Role ───────────────────────────────────────────────────
# Needs: Secrets Manager (DB credentials) only
resource "aws_iam_role" "user_service" {
  name = "${var.project_name}-${var.environment}-user-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.oidc_provider_url}:sub" = "system:serviceaccount:${var.namespace}:user-service-sa"
          "${var.oidc_provider_url}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-user-service-role"
    Environment = var.environment
    Service     = "user-service"
  }
}

resource "aws_iam_role_policy" "user_service" {
  name = "${var.project_name}-${var.environment}-user-service-policy"
  role = aws_iam_role.user_service.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SecretsManagerRead"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
        ]
        Resource = compact([var.rds_secret_arn])
      },
    ]
  })
}

# ── Notification Service IAM Role ───────────────────────────────────────────
# Needs: SQS (receive messages, delete after processing), Secrets Manager
resource "aws_iam_role" "notification_service" {
  name = "${var.project_name}-${var.environment}-notification-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.oidc_provider_url}:sub" = "system:serviceaccount:${var.namespace}:notification-service-sa"
          "${var.oidc_provider_url}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-notification-service-role"
    Environment = var.environment
    Service     = "notification-service"
  }
}

resource "aws_iam_role_policy" "notification_service" {
  name = "${var.project_name}-${var.environment}-notification-service-policy"
  role = aws_iam_role.notification_service.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SQSReceiveMessage"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ChangeMessageVisibility",
        ]
        Resource = compact([var.sqs_queue_arn, var.sqs_dlq_arn])
      },
    ]
  })
}

# ── External Secrets Operator IAM Role ──────────────────────────────────────
# ESO needs to read all secrets in Secrets Manager for the project
resource "aws_iam_role" "external_secrets" {
  name = "${var.project_name}-${var.environment}-external-secrets-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.oidc_provider_url}:sub" = "system:serviceaccount:external-secrets:external-secrets"
          "${var.oidc_provider_url}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-external-secrets-role"
    Environment = var.environment
    Service     = "external-secrets"
  }
}

resource "aws_iam_role_policy" "external_secrets" {
  name = "${var.project_name}-${var.environment}-external-secrets-policy"
  role = aws_iam_role.external_secrets.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SecretsManagerReadAll"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets",
        ]
        Resource = "arn:aws:secretsmanager:*:*:secret:${var.project_name}/*"
      },
    ]
  })
}

# ── Outputs ──────────────────────────────────────────────────────────────────
output "order_service_role_arn" {
  description = "IAM role ARN for order-service ServiceAccount"
  value       = aws_iam_role.order_service.arn
}

output "user_service_role_arn" {
  description = "IAM role ARN for user-service ServiceAccount"
  value       = aws_iam_role.user_service.arn
}

output "notification_service_role_arn" {
  description = "IAM role ARN for notification-service ServiceAccount"
  value       = aws_iam_role.notification_service.arn
}

output "external_secrets_role_arn" {
  description = "IAM role ARN for External Secrets Operator"
  value       = aws_iam_role.external_secrets.arn
}
