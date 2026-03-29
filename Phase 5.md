# Chat Conversation

Note: _This is purely the output of the chat conversation and does not contain any raw data, codebase snippets, etc. used to generate the output._

### User Input

In this project,
This is phase 5

Phase 5a — Terraform Backend (One-time, manual)
Create S3 bucket for remote state + DynamoDB table for state locking
Phase 5b — Terraform Modules (Infrastructure as Code)
Goal: Provision ALL AWS infra — no clicking in the AWS console
Deploy order: VPC → ECR → RDS + ElastiCache + SQS → EKS → IRSA
Modules: vpc/, ecr/, rds/, elasticache/, sqs/, eks/, irsa/, sns/, cloudwatch/
Files Created: terraform/modules/* + terraform/environments/dev/*
Phase 5c — Terraform CI Workflow
PR → terraform plan posted as PR comment; merge to main → terraform apply
Files Created: .github/workflows/terraform.yml

Can you explain each file line by line and block by block...order wise.

### Planner Response

Let me first explore the project structure to understand all the Phase 5 files.

*Listed directory [Kubeflow_Devsecops_Pipeline](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline) *

*Listed directory [terraform](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform) *

*Listed directory [.github](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/.github) *

*Listed directory [modules](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/modules) *

*Listed directory [environments](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/environments) *

*Listed directory [workflows](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/.github/workflows) *

*Listed directory [vpc](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/modules/vpc) *

*Listed directory [ecr](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/modules/ecr) *

*Listed directory [eks](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/modules/eks) *

*Listed directory [rds](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/modules/rds) *

*Listed directory [irsa](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/modules/irsa) *

*Listed directory [dev](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/environments/dev) *

*Listed directory [elasticache](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/modules/elasticache) *

*Listed directory [sqs](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/modules/sqs) *

*Listed directory [sns](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/modules/sns) *

*Listed directory [cloudwatch](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/modules/cloudwatch) *

### Planner Response

Now let me read all files in parallel:

*Viewed [backend.tf](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/environments/dev/backend.tf) *

*Viewed [main.tf](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/environments/dev/main.tf) *

*Viewed [outputs.tf](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/environments/dev/outputs.tf) *

*Viewed [main.tf](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/modules/vpc/main.tf) *

*Viewed [main.tf](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/modules/ecr/main.tf) *

*Viewed [main.tf](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/modules/rds/main.tf) *

*Viewed [main.tf](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/modules/elasticache/main.tf) *

*Viewed [main.tf](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/modules/sqs/main.tf) *

*Viewed [main.tf](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/modules/sns/main.tf) *

*Viewed [main.tf](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/modules/eks/main.tf) *

*Viewed [main.tf](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/modules/irsa/main.tf) *

*Viewed [main.tf](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/modules/cloudwatch/main.tf) *

*Viewed [terraform.yml](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/.github/workflows/terraform.yml) *

### Planner Response

Now let me also read the VPC variables and outputs, and EKS outputs:

*Viewed [variables.tf](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/modules/vpc/variables.tf) *

*Viewed [outputs.tf](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/modules/vpc/outputs.tf) *

*Viewed [variables.tf](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/modules/eks/variables.tf) *

*Viewed [outputs.tf](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/modules/eks/outputs.tf) *

### Planner Response

I now have all the files. Let me write the comprehensive explanation document:

*User accepted the command `echo "test"`*

*User accepted the command `ls C:\Users\saraf\.gemini\antigravity\brain\590b2989-a497-4b75-bf46-3ee9040a8a27 2>&1; ls C:\Users\saraf\.gemini\antigravity\artifacts 2>&1`*

*User accepted the command `ls C:\Users\saraf\.gemini\antigravity\`*

*User accepted the command `ls C:\Users\saraf\.gemini\antigravity\conversations\`*

### Planner Response

The artifacts directory doesn't exist yet — it needs to be created by the system during the first artifact write. Let me write the artifact to the project's Explain directory instead:

### Planner Response

The explanation document is too large for a single response. I'll write it directly to the project's `Explain` folder in multiple parts.

*User rejected the command `New-Item -ItemType Directory -Force "c:\PROJECTS\Kubeflow_Devsecops_Pipeline\Explain" | Out-Null; echo "done"`*

### User Input

In this project,
This is phase 5

Phase 5a — Terraform Backend (One-time, manual)
Create S3 bucket for remote state + DynamoDB table for state locking
Phase 5b — Terraform Modules (Infrastructure as Code)
Goal: Provision ALL AWS infra — no clicking in the AWS console
Deploy order: VPC → ECR → RDS + ElastiCache + SQS → EKS → IRSA
Modules: vpc/, ecr/, rds/, elasticache/, sqs/, eks/, irsa/, sns/, cloudwatch/
Files Created: terraform/modules/* + terraform/environments/dev/*
Phase 5c — Terraform CI Workflow
PR → terraform plan posted as PR comment; merge to main → terraform apply
Files Created: .github/workflows/terraform.yml

Can you explain each file line by line and block by block...order wise.

No artifact - return output in this window

### Planner Response

I'll explain Phase 5 in order. Due to token limits, I'll go **module by module** — starting now with Phase 5a and the first set of modules.

---

# Phase 5a — Terraform Backend (`environments/dev/backend.tf`)

**Purpose:** Tell Terraform WHERE to store its state file (not locally).

```hcl
terraform {
  backend "s3" {
    bucket         = "kubeflow-ops-terraform-state"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "kubeflow-ops-terraform-lock"
    encrypt        = true
  }
}
```

| Line | What it does |
|---|---|
| `bucket` | S3 bucket name that stores the `.tfstate` file |
| `key` | Path inside the bucket — `dev/terraform.tfstate` → each env gets its own state file |
| `dynamodb_table` | Terraform writes a lock record here during `apply` — prevents two engineers running apply simultaneously (state corruption) |
| `encrypt = true` | AES-256 encryption on the state file — CRITICAL because state contains DB passwords |

**Why manual bootstrap?** You can't use Terraform to create the backend that Terraform itself needs. Chicken-and-egg. So you run these AWS CLI commands ONCE before first `terraform init`:

```bash
aws s3 mb s3://kubeflow-ops-terraform-state --region us-east-1
aws dynamodb create-table \
  --table-name kubeflow-ops-terraform-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

- `PAY_PER_REQUEST` = no capacity planning, charges per lock operation (pennies/month)

---

# Phase 5b — Terraform Modules

## Overall Project Structure

```
terraform/
├── modules/          ← Reusable building blocks
│   ├── vpc/
│   ├── ecr/
│   ├── rds/
│   ├── elasticache/
│   ├── sqs/
│   ├── eks/
│   ├── irsa/
│   ├── sns/
│   └── cloudwatch/
└── environments/
    └── dev/
        ├── backend.tf   ← WHERE state lives
        ├── main.tf      ← Calls all modules, wires outputs → inputs
        └── outputs.tf   ← Prints values after apply
```

**Why split modules from environments?** The same `vpc/` module can create a dev VPC and a prod VPC — you just pass different CIDRs. Environments are the "glue" layer that sets real values.

---

## Module 1: `modules/vpc/` — Network Foundation

**Deploy order: FIRST** (everything else lives inside it)

### `variables.tf`

```hcl
variable "vpc_cidr"             { default = "10.0.0.0/16" }
variable "availability_zones"   { default = ["us-east-1a", "us-east-1b"] }
variable "public_subnet_cidrs"  { default = ["10.0.1.0/24", "10.0.2.0/24"] }
variable "private_subnet_cidrs" { default = ["10.0.10.0/24", "10.0.20.0/24"] }
```

- `10.0.0.0/16` = 65,536 IPs for the whole VPC
- Two AZs minimum — **EKS requires multi-AZ** for high availability
- Public subnets (`10.0.1.x`, `10.0.2.x`) → for NAT Gateway + Load Balancers
- Private subnets (`10.0.10.x`, `10.0.20.x`) → for EKS nodes, RDS, Redis

### `main.tf` — Block by Block

**Block 1 — VPC**
```hcl
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true   # Required for EKS — nodes get DNS names like ip-10-0-10-5.ec2.internal
  enable_dns_support   = true   # Enables AWS DNS resolver at 10.0.0.2
}
```

**Block 2 — Internet Gateway**
```hcl
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}
```
The door between your VPC and the public internet. Without it, NOTHING in the VPC can reach the internet.

**Block 3 — Public Subnets**
```hcl
resource "aws_subnet" "public" {
  for_each = toset(var.public_subnet_cidrs)          # Creates ONE subnet per CIDR in one block
  cidr_block              = each.key
  availability_zone       = var.availability_zones[index(var.public_subnet_cidrs, each.key)]
  map_public_ip_on_launch = true                     # Resources here get public IPs automatically
  tags = {
    "kubernetes.io/role/elb" = "1"                  # AWS LB Controller uses this to place internet ALBs
    "kubernetes.io/cluster/${var.project_name}-${var.environment}" = "shared"
  }
}
```
- `for_each = toset(...)` → one Terraform block creates both subnets
- `index()` trick → maps CIDR `10.0.1.0/24` → position 0 → AZ `us-east-1a`
- `kubernetes.io/role/elb` tag → required for AWS Load Balancer Controller

**Block 4 — Private Subnets**
```hcl
resource "aws_subnet" "private" {
  for_each = toset(var.private_subnet_cidrs)
  # NO map_public_ip_on_launch — resources here NEVER get public IPs
  tags = {
    "kubernetes.io/role/internal-elb" = "1"   # For internal (pod-to-pod) load balancers
  }
}
```

**Block 5 — Elastic IP + NAT Gateway**
```hcl
resource "aws_eip" "nat" {
  domain = "vpc"    # Static public IP — doesn't change if NAT GW is recreated
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public["${var.public_subnet_cidrs[0]}"].id  # NAT GW must be in PUBLIC subnet!
  depends_on    = [aws_internet_gateway.main]   # IGW must exist first
}
```
- Private subnet resources → NAT GW → IGW → Internet (outbound only, NAT hides private IPs)
- Single NAT GW = budget dev. Production = one NAT GW per AZ for HA

**Block 6 — Route Tables**
```hcl
resource "aws_route_table" "public" {
  route {
    cidr_block = "0.0.0.0/0"       # "Any internet destination..."
    gateway_id = aws_internet_gateway.main.id   # "...go through IGW" (2-way)
  }
}

resource "aws_route_table" "private" {
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id    # "...go through NAT GW" (outbound only)
  }
}
```

**Block 7 — Route Table Associations**
```hcl
resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public     # For each public subnet...
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id   # ...wire to the public route table
}
# Same pattern for private subnets → private route table
```
Route tables do nothing until associated with subnets.

### `outputs.tf`
```hcl
output "vpc_id"             { value = aws_vpc.main.id }
output "private_subnet_ids" { value = [for s in aws_subnet.private : s.id] }
output "public_subnet_ids"  { value = [for s in aws_subnet.public : s.id] }
```
These are consumed by EKS, RDS, ElastiCache — they need to know which VPC/subnets to deploy into.

---

## Module 2: `modules/ecr/main.tf` — Container Registries

**Deploy order: 2nd** (no VPC dependency — ECR is a global AWS service)

**Block 1 — Variables**
```hcl
variable "service_names" {
  default = ["order-service", "user-service", "notification-service"]
}
```
Drive the `for_each` — add a service name → get a new repo automatically.

**Block 2 — Repositories**
```hcl
resource "aws_ecr_repository" "services" {
  for_each = toset(var.service_names)
  name     = "${var.project_name}-${each.value}"   # e.g. kubeflow-ops-order-service

  image_tag_mutability = "IMMUTABLE"   # v1.2.3 can NEVER be overwritten once pushed
  image_scanning_configuration {
    scan_on_push = true    # Auto vulnerability scan every push (CVE detection)
  }
  encryption_configuration {
    encryption_type = "AES256"
  }
}
```

**Block 3 — Lifecycle Policy**
```hcl
resource "aws_ecr_lifecycle_policy" "services" {
  for_each   = aws_ecr_repository.services   # One policy per repo
  repository = each.value.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      selection    = { tagStatus = "any", countType = "imageCountMoreThan", countNumber = 10 }
      action       = { type = "expire" }   # Auto-delete images beyond the last 10
    }]
  })
}
```
Without this: 100 deploys × 50MB = 5GB of stale images per repo. This auto-deletes old ones.

**Output:**
```hcl
output "repository_urls" {
  value = { for k, v in aws_ecr_repository.services : k => v.repository_url }
  # Returns: { "order-service" => "123456.dkr.ecr.us-east-1.amazonaws.com/kubeflow-ops-order-service" }
}
```

---

## Module 3: `modules/rds/main.tf` — PostgreSQL Database

**Block 1 — Security Group**
```hcl
resource "aws_security_group" "rds" {
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.eks_security_group_id]   # ONLY EKS nodes can hit port 5432
  }
  egress { protocol = "-1"; cidr_blocks = ["0.0.0.0/0"] }   # All outbound OK
  lifecycle { create_before_destroy = true }
}
```
Principle of least privilege: even if someone gets into the VPC, they can't reach the DB unless their traffic comes from an EKS node's security group.

**Block 2 — Auto-generated Password**
```hcl
resource "random_password" "db_password" {
  length  = 24
  special = false   # Some JDBC drivers choke on special chars in connection strings
}
```
You NEVER type the DB password. Terraform generates it, stores it in state (encrypted), and puts it in Secrets Manager.

**Block 3 — Secrets Manager**
```hcl
resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
    host     = aws_db_instance.main.address   # Dynamic — known only after RDS is created
    port     = 5432
    url      = "postgresql://admin:<pass>@<host>:5432/kubeflow"
  })
}
```
Everything an app needs to connect — one JSON blob. The External Secrets Operator reads this and creates a Kubernetes Secret automatically.

**Block 4 — RDS Instance**
```hcl
resource "aws_db_instance" "main" {
  engine         = "postgres"
  engine_version = "16.3"
  instance_class = var.instance_class       # db.t3.micro (~$13/month for dev)

  allocated_storage     = 20    # Starts at 20 GB
  max_allocated_storage = 50    # Auto-grows to 50 GB without manual intervention

  multi_az            = false   # Dev: single AZ. Prod: true (2x cost, but survives AZ failure)
  publicly_accessible = false   # NEVER expose DB to internet
  skip_final_snapshot = true    # Dev: no snapshot on destroy. Prod: false (data protection!)

  backup_retention_period = 7              # 7 days of daily automated backups
  backup_window           = "03:00-04:00"  # 3 AM UTC (low traffic window)
  maintenance_window      = "mon:04:00-mon:05:00"  # Follows backup window
}
```

---

## Module 4: `modules/elasticache/main.tf` — Redis

Same structural pattern as RDS: Subnet Group → Security Group → Cluster → Outputs.

**Key block — Cluster:**
```hcl
resource "aws_elasticache_cluster" "main" {
  engine               = "redis"
  engine_version       = "7.1"
  node_type            = var.node_type        # cache.t3.micro (~$13/month)
  num_cache_nodes      = 1                    # Single node for dev
  parameter_group_name = "default.redis7"     # Redis 7 config preset
  port                 = 6379
}
```
- `aws_elasticache_cluster` = single node (dev, no HA)
- Production would use `aws_elasticache_replication_group` (primary + replicas)

**Output:**
```hcl
output "redis_url" {
  value = "redis://${aws_elasticache_cluster.main.cache_nodes[0].address}:6379/0"
  # /0 = Redis database number (Redis has 16 DBs, 0 is default)
}
```

---

## Module 5: `modules/sqs/main.tf` — Message Queue

**Block 1 — Dead Letter Queue (created FIRST)**
```hcl
resource "aws_sqs_queue" "order_events_dlq" {
  name                      = "...-order-events-dlq"
  message_retention_seconds = 1209600   # 14 days max (gives you time to investigate failures)
}
```
DLQ must exist before main queue because main queue references its ARN.

**Block 2 — Main Queue**
```hcl
resource "aws_sqs_queue" "order_events" {
  visibility_timeout_seconds = 30     # Message hidden 30s while consumer processes it
  message_retention_seconds  = 345600 # 4 days
  receive_wait_time_seconds  = 10     # Long polling: waits up to 10s for messages (10x fewer API calls)

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.order_events_dlq.arn
    maxReceiveCount     = 3   # After 3 failed processing attempts → move to DLQ
  })
}
```

| Setting | Why |
|---|---|
| `visibility_timeout = 30` | Consumer picks up message → it's invisible to others for 30s. If not deleted in 30s → reappears for retry |
| `receive_wait_time = 10` | Long polling: waits up to 10s for a message instead of constantly polling (reduces cost/noise) |
| `maxReceiveCount = 3` | Prevents infinite retry loops on bad messages |

**Block 3 — IAM Policy (for IRSA to attach)**
```hcl
resource "aws_iam_policy" "sqs_access" {
  policy = jsonencode({
    Statement = [{
      Action   = ["sqs:SendMessage", "sqs:ReceiveMessage", "sqs:DeleteMessage",
                  "sqs:GetQueueAttributes", "sqs:GetQueueUrl"]
      Resource = [queue.arn, dlq.arn]
    }]
  })
}
```
Created here (SQS module knows the ARNs), attached by the IRSA module to specific service roles.

---

## Module 6: `modules/eks/main.tf` — Kubernetes Cluster

Most complex module. Creates IAM Roles → Cluster → OIDC Provider → Node Group → Add-ons.

**Block 1 — Control Plane IAM Role**
```hcl
resource "aws_iam_role" "eks_cluster" {
  assume_role_policy = jsonencode({
    Statement = [{ Action = "sts:AssumeRole", Principal = { Service = "eks.amazonaws.com" } }]
  })
}
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"         # Manage EC2/ELB/ASG
  role       = aws_iam_role.eks_cluster.name
}
resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController" # Manage ENIs for pod networking
}
```
The EKS **control plane** (managed by AWS behind the scenes) assumes this role to provision resources on your behalf.

**Block 2 — EKS Cluster**
```hcl
resource "aws_eks_cluster" "main" {
  name     = "...-eks-cluster"
  version  = var.kubernetes_version   # "1.29"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids              = var.private_subnet_ids  # Worker nodes in private subnets
    endpoint_private_access = true   # Nodes reach API server via private IP
    endpoint_public_access  = true   # You can run kubectl from your laptop
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator"]  # → CloudWatch Logs
  # api = all kubectl calls  |  audit = who did what  |  authenticator = IAM auth attempts

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller,
  ]
  # Explicit: IAM policies must be attached BEFORE cluster creation or it fails
}
```

**Block 3 — OIDC Provider ⭐ (Enables IRSA)**
```hcl
data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer   # Cluster's OIDC issuer URL
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
}
```
**What this enables:**
1. EKS cluster has a built-in OIDC provider at `https://oidc.eks.us-east-1.amazonaws.com/id/XXXXX`
2. We register it with AWS IAM → IAM now **trusts tokens** issued by this cluster
3. Kubernetes pods get ServiceAccount tokens automatically
4. AWS SDK in the pod exchanges those tokens for real AWS credentials via STS
5. Result: pods get AWS access **without any access keys stored anywhere**

**Block 4 — Worker Node IAM Role**
```hcl
resource "aws_iam_role" "eks_nodes" {
  assume_role_policy = jsonencode({
    Principal = { Service = "ec2.amazonaws.com" }   # EC2 instances (worker nodes) assume this
  })
}
# Three required policy attachments:
aws_iam_role_policy_attachment "eks_worker_node_policy"    # Basic node operations
aws_iam_role_policy_attachment "eks_cni_policy"            # aws-node DaemonSet manages ENIs for pod networking
aws_iam_role_policy_attachment "eks_container_registry"    # Pull images from ECR
```

**Block 5 — Managed Node Group**
```hcl
resource "aws_eks_node_group" "main" {
  instance_types = var.node_instance_types   # ["t3.medium"] — 2 vCPU, 4GB RAM
  capacity_type  = "ON_DEMAND"               # Reliable. Use SPOT for cheaper (can be interrupted)

  scaling_config {
    desired_size = 2    # Start with 2 nodes
    min_size     = 1    # Scale down to 1 minimum
    max_size     = 4    # Scale up to 4 maximum
  }
  update_config {
    max_unavailable = 1   # Rolling update: replace 1 node at a time
  }
}
```
**Managed node group** = AWS handles the EC2 lifecycle, rolling updates, draining pods before terminating nodes. Self-managed = you do all that yourself.

**Block 6 — Add-ons**
```hcl
resource "aws_eks_addon" "coredns"    { depends_on = [aws_eks_node_group.main] }
resource "aws_eks_addon" "kube_proxy" { depends_on = [aws_eks_node_group.main] }
resource "aws_eks_addon" "vpc_cni"    { depends_on = [aws_eks_node_group.main] }
```

| Add-on | Role |
|---|---|
| `coredns` | DNS inside cluster — pods resolve `service.namespace.svc.cluster.local` |
| `kube-proxy` | Maintains iptables rules for Service traffic routing on each node |
| `vpc-cni` | Gives each pod its own VPC IP address (direct routing, no overlay network) |

All `depends_on = [node_group]` — they need nodes to schedule onto.

### `outputs.tf` (EKS)
```hcl
output "cluster_security_group_id" { value = aws_security_group.eks_cluster.id }
# ↑ Used by RDS + ElastiCache to whitelist EKS in their security groups

output "oidc_provider_arn" { value = aws_iam_openid_connect_provider.eks.arn }
output "oidc_provider_url" {
  value = replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")
  # Strips "https://" — IAM trust policies need the URL WITHOUT protocol
}
```

---

## Module 7: `modules/irsa/main.tf` — IAM Roles for Service Accounts

**Core pattern (repeated 4 times):**

```hcl
resource "aws_iam_role" "order_service" {
  assume_role_policy = jsonencode({
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = var.oidc_provider_arn }   # Trust the EKS OIDC provider
      Action    = "sts:AssumeRoleWithWebIdentity"          # IRSA-specific STS action
      Condition = {
        StringEquals = {
          "${var.oidc_provider_url}:sub" = "system:serviceaccount:kubeflow-ops:order-service-sa"
          # ↑ ONLY this specific ServiceAccount in this specific namespace can assume this role
          "${var.oidc_provider_url}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}
```
**Why the `Condition` block is critical:** Without it, ANY pod in ANY namespace could assume this role. The condition locks it to one exact ServiceAccount.

**Order Service Policy:**
```hcl
resource "aws_iam_role_policy" "order_service" {
  policy = jsonencode({
    Statement = [
      { Sid = "SQSSendMessage";    Action = ["sqs:SendMessage", "sqs:GetQueueUrl", ...];    Resource = [sqs_queue_arn] },
      { Sid = "SecretsManagerRead"; Action = ["secretsmanager:GetSecretValue"];              Resource = [rds_secret_arn] },
    ]
  })
}
```
Order service: **sends** to SQS + reads DB credentials from Secrets Manager. Nothing else.

**Notification Service Policy:**
```hcl
Action = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:ChangeMessageVisibility", ...]
Resource = [sqs_queue_arn, sqs_dlq_arn]
```
Notification service: **consumes** messages. `DeleteMessage` = removes after processing. `ChangeMessageVisibility` = extends timeout if processing takes longer than 30s.

**External Secrets Operator Policy:**
```hcl
resource "aws_iam_role" "external_secrets" {
  # ServiceAccount: "external-secrets" in namespace "external-secrets"
  Condition = { "...:sub" = "system:serviceaccount:external-secrets:external-secrets" }
}
resource "aws_iam_role_policy" "external_secrets" {
  Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret", "secretsmanager:ListSecrets"]
  Resource = "arn:aws:secretsmanager:*:*:secret:${var.project_name}/*"  # All project secrets
}
```
ESO syncs AWS Secrets Manager → Kubernetes Secrets automatically. Needs broad read on all project secrets.

---

## Module 8: `modules/sns/main.tf` — Alert Topics

**Two topics (two severity levels):**
```hcl
resource "aws_sns_topic" "critical_alerts" { name = "...-critical-alerts" }  # PagerDuty + email
resource "aws_sns_topic" "warning_alerts"  { name = "...-warning-alerts" }   # Email only
```

**Conditional email subscriptions:**
```hcl
resource "aws_sns_topic_subscription" "critical_email" {
  count    = var.alert_email != "" ? 1 : 0   # Only creates if email is set
  protocol = "email"
  endpoint = var.alert_email
}
```
`count = condition ? 1 : 0` — Terraform's pattern for optional resources. In dev `alert_email = ""` so no subscription is created.

**Topic Policy (allow CloudWatch to publish):**
```hcl
resource "aws_sns_topic_policy" "critical_alerts" {
  policy = jsonencode({
    Statement = [{
      Principal = { Service = "cloudwatch.amazonaws.com" }
      Action    = "SNS:Publish"   # CloudWatch Alarms can publish to this topic
    }]
  })
}
```
By default only the topic owner can publish. This allows CloudWatch to trigger notifications.

---

## Module 9: `modules/cloudwatch/main.tf` — Dashboard + Alarms

**Monitoring split:** Prometheus watches Kubernetes-level metrics. CloudWatch watches AWS managed services (RDS, ElastiCache, SQS).

**Dashboard (4 widgets in a 24-column grid):**
```hcl
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_body = jsonencode({
    widgets = [
      { x=0,  y=0, width=12, height=6, title="RDS — CPU & Connections" },
      { x=12, y=0, width=12, height=6, title="RDS — Free Storage & Memory" },
      { x=0,  y=6, width=12, height=6, title="SQS — Message Counts" },
      { x=12, y=6, width=12, height=6, title="Redis — CPU & Memory" },
    ]
  })
}
```

**5 Alarms — each with conditional creation:**

```hcl
# 1. RDS CPU > 80% for 15 minutes
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  count               = var.rds_instance_id != "" ? 1 : 0   # Skip if no RDS
  evaluation_periods  = 3       # 3 consecutive 5-min periods = 15 minutes
  period              = 300     # 5-minute window
  threshold           = 80
  alarm_actions = [var.sns_critical_topic_arn]   # Page someone
  ok_actions    = [var.sns_warning_topic_arn]    # Notify when recovered
}

# 2. RDS Free Storage < 5 GB
threshold = 5368709120   # 5 * 1024 * 1024 * 1024 — CloudWatch storage is in BYTES

# 3. SQS DLQ > 0 (any failure)
threshold = 0   # Even 1 message in DLQ = processing bug → critical alert

# 4. SQS Backlog > 1000 messages
threshold = 1000   # Consumer may be overwhelmed → warning alert

# 5. Redis CPU > 70%
threshold = 70   # Redis is single-threaded; 70%+ = near saturation → warning
```

---

## Dev Environment `main.tf` — The Orchestrator

**Provider block:**
```hcl
provider "aws" {
  region = var.aws_region
  default_tags {
    tags = { Project = "kubeflow-ops", Environment = "dev", ManagedBy = "terraform" }
    # These 3 tags appear on EVERY resource automatically — no need to repeat them per resource
  }
}
```

**Module wiring (showing the dependency chain):**
```hcl
module "vpc" {
  source = "../../modules/vpc"
  # No dependencies — first to be created
}

module "eks" {
  vpc_id             = module.vpc.vpc_id              # ← VPC output
  private_subnet_ids = module.vpc.private_subnet_ids   # ← VPC output
  node_instance_types = ["t3.medium"]
  node_desired_size   = 2; node_min_size = 1; node_max_size = 4
}

module "rds" {
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  eks_security_group_id = module.eks.cluster_security_group_id  # ← EKS output
}

module "elasticache" {
  # Same pattern as RDS — needs VPC + EKS SG
}

module "sqs" {
  # No VPC needed — SQS is a public AWS service
}

module "sns" {
  alert_email = ""    # Set to "you@example.com" to activate email alerts
}

module "cloudwatch" {
  sns_critical_topic_arn = module.sns.critical_topic_arn   # ← SNS output
  sns_warning_topic_arn  = module.sns.warning_topic_arn    # ← SNS output
  rds_instance_id        = "${var.project_name}-${var.environment}-postgres"
}

module "irsa" {
  oidc_provider_arn = module.eks.oidc_provider_arn   # ← EKS output
  oidc_provider_url = module.eks.oidc_provider_url   # ← EKS output
  sqs_queue_arn     = module.sqs.queue_arn            # ← SQS output
  rds_secret_arn    = module.rds.secret_arn           # ← RDS output
  # IRSA is last — depends on EKS + SQS + RDS
}
```

**`outputs.tf` — What gets printed after apply:**
```hcl
output "configure_kubectl" {
  value = "aws eks update-kubeconfig --region us-east-1 --name kubeflow-ops-dev-eks-cluster"
  # Copy-paste this to set up kubectl immediately after apply
}
output "ecr_repository_urls"             { value = module.ecr.repository_urls }
output "rds_secret_arn"                  { value = module.rds.secret_arn }
output "irsa_order_service_role_arn"     { value = module.irsa.order_service_role_arn }
# Annotate K8s SA: kubectl annotate sa order-service-sa eks.amazonaws.com/role-arn=<this>
```

---

# Phase 5c — `.github/workflows/terraform.yml`

**The rule: No one runs `terraform apply` locally. Everything goes through PR.**

**Trigger block:**
```yaml
on:
  push:
    branches: [main]
    paths: ['terraform/**']   # Only runs if terraform/ files changed — README edits don't trigger apply!
  pull_request:
    branches: [main]
    paths: ['terraform/**']
  workflow_dispatch:           # Manual trigger for emergency reapply
```

**Permissions:**
```yaml
permissions:
  contents: read
  id-token: write        # Required for keyless AWS auth via OIDC — NO stored access keys
  pull-requests: write   # To post plan as PR comment
```

**Environment variables:**
```yaml
env:
  TF_WORKING_DIR: terraform/environments/dev
# All steps run in this directory automatically via defaults.run.working-directory
```

**Step 1 — Checkout:** `actions/checkout@v4` — fetches repo at the triggering commit.

**Step 2 — AWS Auth (keyless OIDC):**
```yaml
uses: aws-actions/configure-aws-credentials@v4
with:
  role-to-assume: ${{ secrets.AWS_ROLE_ARN }}  # GitHub gets temp creds by assuming this role
  aws-region: us-east-1
```
Flow: GitHub generates JWT → AWS STS validates → returns 1-hour temp credentials. No `AWS_ACCESS_KEY_ID` stored anywhere.

**Step 3 — Setup Terraform:**
```yaml
uses: hashicorp/setup-terraform@v3
with:
  terraform_version: 1.7.0   # Pin exact version — "latest" causes unexpected surprises
```

**Step 4 — Format Check:**
```yaml
run: terraform fmt -check -recursive ../../terraform/
continue-on-error: true   # Warn but don't block pipeline — formatting is style not function
```

**Step 5 — Init:**
```yaml
run: terraform init -input=false
# Downloads AWS/random/tls providers, configures S3 backend, no interactive prompts
```

**Step 6 — Validate:**
```yaml
run: terraform validate
# Checks HCL syntax + variable references + provider schema. Faster feedback than plan.
```

**Step 7 — Trivy Security Scan:**
```yaml
uses: aquasecurity/trivy-action@master
with:
  scan-type: 'config'           # IaC misconfiguration scan (not container scan)
  scan-ref: 'terraform/'
  severity: 'HIGH,CRITICAL'     # Only block on serious issues
```
Catches: S3 without encryption, RDS with `publicly_accessible=true`, SG open to `0.0.0.0/0` on sensitive ports.

**Step 8 — Plan:**
```yaml
- name: Terraform Plan
  id: plan                                             # id → lets next step read its output
  run: terraform plan -input=false -no-color -out=tfplan
  continue-on-error: true   # Even a failing plan gets posted as PR comment
```
- `-no-color` → GitHub comments can't render ANSI escape codes
- `-out=tfplan` → saves binary plan (apply uses this exact plan — no drift)

**Step 9 — Post Plan as PR Comment:**
```yaml
- if: github.event_name == 'pull_request'   # Only on PRs
  uses: actions/github-script@v7
  with:
    script: |
      github.rest.issues.createComment({
        body: `### Terraform Plan\n\`\`\`\n${{ steps.plan.outputs.stdout }}\n\`\`\``
      })
```
Every reviewer sees **exactly what will change in AWS** before clicking Approve. `steps.plan.outputs.stdout` = the plan text from Step 8.

**Step 10 — Apply:**
```yaml
- if: github.ref == 'refs/heads/main' && github.event_name == 'push'
  run: terraform apply -auto-approve -input=false tfplan
```
**Double condition = the safety gate:**
- `github.ref == main` → only on the main branch
- `github.event_name == 'push'` → only after a merge (not on PR preview)

`tfplan` = the binary from Step 8. Apply executes **exactly** what was shown in the PR comment. No surprises.

---

## Complete Dependency + Data Flow

```
Phase 5a (manual once)
  `aws s3 mb` + `aws dynamodb create-table`

Phase 5b (terraform apply order)
  VPC → outputs: vpc_id, private_subnet_ids
    ↓
  EKS ← vpc_id, private_subnet_ids
      → outputs: cluster_sg_id, oidc_provider_arn, oidc_provider_url
    ↓
  RDS ← vpc_id, private_subnet_ids, cluster_sg_id
      → outputs: secret_arn, endpoint
  ElastiCache ← vpc_id, private_subnet_ids, cluster_sg_id
  SQS (no VPC dep)
      → outputs: queue_arn, dlq_url
  SNS (no VPC dep)
      → outputs: critical_topic_arn, warning_topic_arn
  CloudWatch ← sns topic ARNs
  IRSA ← oidc_arn, oidc_url, sqs_queue_arn, rds_secret_arn  [LAST]

Phase 5c (GitHub Actions on every PR/merge)
  PR opened → plan → posted as PR comment (reviewers see changes)
  PR merged → apply → infra updated in AWS
```

## Key Principles Applied

| Principle | Implementation |
|---|---|
| **Remote State** | S3 + DynamoDB lock in `backend.tf` |
| **Least Privilege** | IRSA: each pod gets only its own IAM role |
| **Network Isolation** | Private subnets + SG whitelisting EKS→RDS/Redis |
| **No Secrets in Code** | Passwords auto-generated + stored in Secrets Manager |
| **Immutable Images** | ECR `IMMUTABLE` tags |
| **GitOps for Infra** | Plan on PR, apply on merge — no local apply |
| **Cost Controls** | Dev-sized instances, lifecycle policies, single NAT GW |
| **DRY** | Reusable modules + `for_each` loops |
| **Defense in Depth** | Trivy scan + CW alarms + audit logs + SG rules |