# =============================================================================
# Dev Environment — Main Configuration
# =============================================================================
# This file calls all the modules and wires them together.
# Each module is self-contained — you just pass in the required variables.
# =============================================================================

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.30"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# ── Variables ────────────────────────────────────────────────────────────────
variable "project_name" {
  type    = string
  default = "kubeflow-ops"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

# ── Module: VPC ──────────────────────────────────────────────────────────────
module "vpc" {
  source = "../../modules/vpc"

  project_name = var.project_name
  environment  = var.environment
}

# ── Module: EKS ──────────────────────────────────────────────────────────────
module "eks" {
  source = "../../modules/eks"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  # Budget-friendly settings for dev
  node_instance_types = ["t3.medium"]
  node_desired_size   = 2
  node_min_size       = 1
  node_max_size       = 4
}

# ── Module: ECR ──────────────────────────────────────────────────────────────
module "ecr" {
  source = "../../modules/ecr"

  project_name  = var.project_name
  environment   = var.environment
  service_names = ["order-service", "user-service", "notification-service"]
}

# ── Module: RDS (PostgreSQL) ─────────────────────────────────────────────────
module "rds" {
  source = "../../modules/rds"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  eks_security_group_id = module.eks.cluster_security_group_id
  instance_class        = "db.t3.micro"
}

# ── Module: ElastiCache (Redis) ──────────────────────────────────────────────
module "elasticache" {
  source = "../../modules/elasticache"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  eks_security_group_id = module.eks.cluster_security_group_id
  node_type             = "cache.t3.micro"
}

# ── Module: SQS ──────────────────────────────────────────────────────────────
module "sqs" {
  source = "../../modules/sqs"

  project_name = var.project_name
  environment  = var.environment
}

# ── Module: SNS (Alert Notifications) ────────────────────────────────────────
module "sns" {
  source = "../../modules/sns"

  project_name = var.project_name
  environment  = var.environment
  alert_email  = ""  # Set to your email: "you@example.com"
}

# ── Module: CloudWatch (Dashboard + Alarms) ──────────────────────────────────
module "cloudwatch" {
  source = "../../modules/cloudwatch"

  project_name           = var.project_name
  environment            = var.environment
  sns_critical_topic_arn = module.sns.critical_topic_arn
  sns_warning_topic_arn  = module.sns.warning_topic_arn
  rds_instance_id        = "${var.project_name}-${var.environment}-postgres"
  elasticache_cluster_id = "${var.project_name}-${var.environment}-redis"
  sqs_queue_name         = "${var.project_name}-${var.environment}-order-events"
  sqs_dlq_name           = "${var.project_name}-${var.environment}-order-events-dlq"
}

# ── Module: IRSA (Per-Service IAM Roles) ─────────────────────────────────────
module "irsa" {
  source = "../../modules/irsa"

  project_name      = var.project_name
  environment       = var.environment
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  sqs_queue_arn     = module.sqs.queue_arn
  sqs_dlq_arn       = ""
  rds_secret_arn    = module.rds.secret_arn
}
