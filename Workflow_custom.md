# 🚀 KubeFlow Ops — DevSecOps Phase-by-Phase Roadmap

> **Perspective**: You are the DevOps/Platform Engineer. Developers hand you their code (`apps/`).
> Your job is to containerize it, secure it, automate it, and ship it to production on AWS EKS.

---

## 📦 What Developers Hand You

```
apps/
├── order-service/
│   ├── main.py            ← FastAPI app (Python)
│   ├── requirements.txt   ← Python dependencies
│   └── tests/             ← Unit tests
├── user-service/
│   ├── main.py
│   ├── requirements.txt
│   └── tests/
└── notification-service/
    ├── main.py
    ├── requirements.txt
    └── tests/
```

They give you: **Python code + a requirements file + tests.**
They do NOT give you: Dockerfiles, pipelines, K8s manifests, infra, monitoring.
**That's YOUR job.**

---

## 🗺️ Full Pipeline Flow (Big Picture)

```
Developer Push
     │
     ▼
[Phase 1] Understand & Run Locally
     │
     ▼
[Phase 2] Write Dockerfiles (Containerize)
     │
     ▼
[Phase 3] docker-compose (Local Orchestration)
     │
     ▼
[Phase 4] CI Pipeline — GitHub Actions (Build, Test, Scan, Push to ECR)
     │
     ▼
[Phase 5] Infrastructure as Code — Terraform (Provision AWS: VPC, EKS, RDS, Redis, SQS, ECR)
     │
     ▼
[Phase 6] GitOps Manifests — Kubernetes YAMLs (Deployment, Service, HPA, Ingress)
     │
     ▼
[Phase 7] ArgoCD — GitOps CD (Watch Git → Auto-deploy to EKS)
     │
     ▼
[Phase 8] Security Layer (Kyverno Policies + External Secrets Operator)
     │
     ▼
[Phase 9] Observability (Prometheus + Grafana + Alertmanager)
     │
     ▼
[Phase 10] SLOs, Runbooks & Documentation
```

---

## PHASE 1 — Understand the App & Run Locally (No Docker)

**Goal**: Understand what each service does before touching any tooling.

### What to do

1. Read `apps/*/main.py` — understand the API endpoints
2. Read `apps/*/requirements.txt` — understand dependencies
3. Run each service locally with Python to see it works:

   ```bash
   cd apps/order-service
   pip install -r requirements.txt
   uvicorn main:app --host 0.0.0.0 --port 8001
   # Open: http://localhost:8001/docs
   ```

4. Run the tests:

   ```bash
   pytest tests/ -v
   ```

### Services & their roles

| Service | Port | Role |
|---|---|---|
| `order-service` | 8001 | CRUD orders, publishes to SQS |
| `user-service` | 8002 | CRUD users, validates user existence |
| `notification-service` | 8003 | Consumes SQS events, caches in Redis |

### External dependencies you'll need to provide

- **PostgreSQL** (for order-service and user-service)
- **Redis** (for notification-service caching)
- **SQS** (for async messaging between order → notification)

---

## PHASE 2 — Write Dockerfiles (Containerize Each Service)

**Goal**: Package each service into a portable, production-ready container image.

### Key principles applied

- **Multi-stage builds** → small images (~120MB vs ~900MB)
- **Non-root user** → security best practice
- **Layer caching** → copy `requirements.txt` before `main.py`
- **Health checks** → Docker-level health monitoring

### Dockerfile structure (same pattern for all 3 services)

```dockerfile
# ── Stage 1: Builder ─────────────────────────────────────────────────────
FROM python:3.12-slim AS builder
WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ── Stage 2: Production ──────────────────────────────────────────────────
FROM python:3.12-slim
RUN groupadd -r appuser && useradd -r -g appuser appuser
WORKDIR /app
COPY --from=builder /install /usr/local
COPY main.py .
USER appuser
EXPOSE 8001
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8001/healthz')" || exit 1
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8001"]
```

### Files created per service

```
apps/order-service/
├── Dockerfile        ← YOU write this
├── .dockerignore     ← YOU write this (exclude __pycache__, .env, tests/)
```

### Build & test locally

```bash
# Build
docker build -t order-service:local apps/order-service/

# Run
docker run -p 8001:8001 order-service:local

# Test
curl http://localhost:8001/healthz
```

---

## PHASE 3 — docker-compose (Local Full-Stack Orchestration)

**Goal**: Spin up ALL services + their dependencies (Postgres, Redis, LocalStack/SQS) with one command.

### What `docker-compose.yml` wires together

```yaml
services:
  order-service:        # your built image
  user-service:         # your built image
  notification-service: # your built image
  postgres:             # official image
  redis:                # official image
  localstack:           # AWS services locally (SQS emulation)
```

### Key concepts in the compose file

- **`depends_on`** → ensures Postgres starts before app services
- **`healthcheck`** → readiness probes at compose level
- **`networks`** → service-to-service discovery by name
- **`volumes`** → persist Postgres data across restarts
- **`environment`** → inject connection strings (DB_URL, REDIS_URL, etc.)

### Usage

```bash
docker-compose up --build        # Start everything
docker-compose up --build -d     # Start in background
docker-compose logs -f order-service  # Tail logs
docker-compose down -v           # Stop + clean volumes
```

### ✅ Acceptance Criteria for Phase 3

- `http://localhost:8001/docs` loads (order-service)
- `http://localhost:8002/docs` loads (user-service)
- `http://localhost:8003/docs` loads (notification-service)
- Creating an order triggers a notification (end-to-end test)

---

## PHASE 4 — CI Pipeline (GitHub Actions)

**Goal**: Automate Build → Test → Security Scan → Push to ECR on every code push.

### File: `.github/workflows/ci.yml`

### Pipeline jobs

```
┌─────────────────────┐
│  detect-changes     │  ← Which service changed? (path filter)
└─────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────┐
│  build-and-push (matrix: runs once per changed service) │
│                                                         │
│  1. Checkout code                                       │
│  2. AWS Auth via OIDC (no static keys!)                 │
│  3. Login to Amazon ECR                                 │
│  4. Setup Python → Run pytest                           │
│  5. docker build -t <ECR_URL>/<service>:<git-sha>       │
│  6. Trivy scan (HIGH/CRITICAL CVEs)                     │
│  7. docker push (only on main branch)                   │
│  8. Update image tag in gitops/ → git commit + push     │
└─────────────────────────────────────────────────────────┘
```

### AWS Authentication (OIDC — NO Access Keys)

```yaml
- name: Configure AWS Credentials (OIDC)
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
    aws-region: us-east-1
```

> GitHub assumes an IAM Role via OIDC. Zero static credentials stored anywhere. This is the modern, secure approach.

### Security Scan with Trivy

```yaml
- name: Scan image with Trivy
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: <ecr-url>/kubeflow-ops-order-service:<sha>
    severity: 'HIGH,CRITICAL'
    exit-code: '0'   # Set to '1' to fail the pipeline on critical CVEs
```

### GitOps Tag Update (triggers ArgoCD via Helm values)

```bash
# CI uses yq to update the Helm values file (not raw YAML!)
yq -i '.image.repository = "$ECR_REGISTRY/kubeflow-ops-order-service"' \
    gitops/apps/order-service/values.yaml
yq -i '.image.tag = "$GIT_SHA"' \
    gitops/apps/order-service/values.yaml
git commit -m "ci: update order-service image to $GIT_SHA"
git push
```

### GitHub Secrets to configure

| Secret | Value |
|---|---|
| `AWS_ROLE_ARN` | IAM role ARN that GitHub can assume |

---

## PHASE 5 — Infrastructure as Code (Terraform on AWS)

**Goal**: Provision the entire AWS infrastructure using reusable Terraform modules.

### File layout

```
terraform/
├── modules/
│   ├── vpc/          ← VPC, subnets (public/private), NAT Gateway, IGW
│   ├── eks/          ← EKS cluster, IRSA (IAM for service accounts), node group
│   ├── ecr/          ← Container registries (one per service)
│   ├── rds/          ← PostgreSQL (Multi-AZ in prod)
│   ├── elasticache/  ← Redis cluster
│   └── sqs/          ← Message queues + Dead Letter Queues (DLQ)
└── environments/
    └── dev/          ← Calls all modules with dev-specific values
```

### Deploy order (dependencies matter!)

```
Step 1: Create Terraform backend (S3 + DynamoDB for state locking)
        aws s3 mb s3://kubeflow-ops-terraform-state
        aws dynamodb create-table --table-name kubeflow-ops-terraform-lock ...

Step 2: VPC  →  Step 3: ECR  →  Step 4: RDS + ElastiCache + SQS  →  Step 5: EKS
        (EKS needs VPC subnets, ECR needed before pushing images)

Step 6: terraform init → terraform plan → terraform apply
```

### Key Terraform commands

```bash
cd terraform/environments/dev
terraform init          # Download providers, connect to S3 backend
terraform plan          # Preview changes (ALWAYS do this before apply)
terraform apply         # Create/update resources
terraform destroy       # Tear everything down
```

### What gets created on AWS

| Resource | Purpose |
|---|---|
| **VPC** | Isolated network with public/private subnets |
| **EKS Cluster** | Managed Kubernetes control plane |
| **Node Group** | EC2 worker nodes (Karpenter manages scaling) |
| **ECR** | 3 private container registries (one per service) |
| **RDS PostgreSQL** | Managed database |
| **ElastiCache Redis** | Managed Redis cluster |
| **SQS + DLQ** | Async message queue for order → notification |
| **IAM Roles** | IRSA — pods authenticate to AWS without static keys |

---

## PHASE 6 — GitOps Manifests (Helm Charts)

**Goal**: Define the desired state of your apps using a reusable Helm chart. ArgoCD renders + deploys.

### Why Helm instead of Kustomize?

| | Kustomize | Helm |
|---|---|---|
| Templating | Patch-based (JSON patches) | Go templates with `values.yaml` |
| Reusability | Copy base per service | Single chart, many values files |
| Environment tuning | Separate overlay dirs | `values-dev.yaml` / `values-prod.yaml` |
| CI integration | `sed` to replace image tags | `yq` to update `image.tag` in values |
| ArgoCD support | Built-in | Built-in (multi-source) |

### File layout

```
gitops/
├── charts/
│   └── microservice/               ← Shared Helm chart (reusable for all services)
│       ├── Chart.yaml
│       ├── values.yaml             ← Default values
│       └── templates/
│           ├── _helpers.tpl        ← Label helpers
│           ├── deployment.yaml     ← Templated Deployment
│           ├── service.yaml        ← Templated Service
│           └── hpa.yaml            ← Templated HPA
├── apps/
│   ├── common/                     ← Shared K8s resources (namespace, configmap, ingress)
│   ├── order-service/
│   │   ├── values.yaml             ← Service-specific config (port, env vars, image)
│   │   ├── values-dev.yaml         ← Dev overrides (1 replica, low resources)
│   │   └── values-prod.yaml        ← Prod overrides (3 replicas, high resources)
│   ├── user-service/
│   │   ├── values.yaml
│   │   ├── values-dev.yaml
│   │   └── values-prod.yaml
│   └── notification-service/
│       ├── values.yaml
│       ├── values-dev.yaml
│       └── values-prod.yaml
└── platform/
    ├── argocd/                     ← App-of-Apps (Helm multi-source)
    ├── prometheus/                 ← Alert rules (PrometheusRule CRDs)
    ├── kyverno/                    ← Security policies
    └── external-secrets/           ← Secrets sync from AWS Secrets Manager
```

### Helm values.yaml (per service)

```yaml
# gitops/apps/order-service/values.yaml
name: order-service
containerPort: 8001

image:
  repository: IMAGE_PLACEHOLDER   # ← CI updates this with yq
  tag: latest                     # ← CI updates this with git SHA

service:
  port: 8001

env:
  - name: DATABASE_URL
    valueFrom:
      secretKeyRef: { name: db-credentials, key: url }
  - name: SQS_QUEUE_URL
    valueFrom:
      configMapKeyRef: { name: app-config, key: sqs-queue-url }
```

### Environment overrides

```yaml
# gitops/apps/order-service/values-dev.yaml
replicaCount: 1
resources:
  requests: { cpu: 50m, memory: 64Mi }
  limits:   { cpu: 250m, memory: 128Mi }
autoscaling:
  minReplicas: 1
  maxReplicas: 3

# gitops/apps/order-service/values-prod.yaml
replicaCount: 3
resources:
  requests: { cpu: 200m, memory: 256Mi }
  limits:   { cpu: 1000m, memory: 512Mi }
autoscaling:
  minReplicas: 3
  maxReplicas: 20
```

### Deploy locally with Helm

```bash
# Render templates (dry run) to see what would be created
helm template order-service gitops/charts/microservice/ \
  -f gitops/apps/order-service/values.yaml \
  -f gitops/apps/order-service/values-dev.yaml

# Install/upgrade a release
helm upgrade --install order-service gitops/charts/microservice/ \
  -f gitops/apps/order-service/values.yaml \
  -f gitops/apps/order-service/values-dev.yaml \
  --namespace kubeflow-ops --create-namespace
```

---

## PHASE 7 — ArgoCD (GitOps Continuous Deployment)

**Goal**: ArgoCD watches `gitops/` in Git. Any change → auto-syncs to the EKS cluster.

### Install ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Access UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Open: https://localhost:8080
```

### App-of-Apps Pattern (Helm Multi-Source)

```
gitops/platform/argocd/app-of-apps.yaml
       │
       └── Creates 3 child ArgoCD apps (each uses Helm multi-source):
               ├── order-service     → chart: charts/microservice + values: apps/order-service/
               ├── user-service      → chart: charts/microservice + values: apps/user-service/
               └── notification-service → chart: charts/microservice + values: apps/notification-service/
```

Each child Application uses the ArgoCD **multi-source** pattern:

```yaml
spec:
  sources:
    - repoURL: https://github.com/YOUR_USERNAME/kubeflow-ops.git
      targetRevision: main
      ref: repo                    # ← Name this source "repo"
    - repoURL: https://github.com/YOUR_USERNAME/kubeflow-ops.git
      targetRevision: main
      path: gitops/charts/microservice
      helm:
        valueFiles:
          - $repo/gitops/apps/order-service/values.yaml
          - $repo/gitops/apps/order-service/values-dev.yaml
```

### Full deployment flow (automated, zero manual steps)

```
1. Developer pushes code to apps/order-service/
2. GitHub Actions detects change (path filter)
3. CI: pytest → SonarQube → docker build → trivy scan → docker push to ECR
4. CI: yq updates image.tag in gitops/apps/order-service/values.yaml
5. CI: git commit + git push
6. ArgoCD: detects values.yaml changed
7. ArgoCD: renders Helm chart with updated values → applies to cluster
8. Kubernetes: Rolling update → New pods come up → Old pods go down
9. Done. New code is live.
```

**Apply the root app:**

```bash
kubectl apply -f gitops/platform/argocd/app-of-apps.yaml
```

---

## PHASE 8 — Security Layer

### 8a. Kyverno (Policy-as-Code)

**Goal**: Enforce security rules at the cluster level. Blocks non-compliant deployments.

**File**: `gitops/platform/kyverno/`

```yaml
# Example Kyverno policy: Block root containers
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: disallow-root-containers
spec:
  rules:
  - name: check-runAsNonRoot
    match:
      resources: { kinds: [Pod] }
    validate:
      message: "Containers must not run as root"
      pattern:
        spec:
          containers:
          - securityContext:
              runAsNonRoot: true
```

**Policies enforced in this project:**

| Policy | Effect |
|---|---|
| Disallow root containers | `runAsNonRoot: true` required |
| Disallow privileged mode | No `privileged: true` |
| Require resource limits | CPU/memory limits mandatory |
| Disallow `:latest` tag | Forces pinned image tags |

### 8b. External Secrets Operator (ESO)

**Goal**: Pull secrets from AWS Secrets Manager into Kubernetes Secrets automatically.

**File**: `gitops/platform/external-secrets/`

```yaml
# ExternalSecret → fetches from AWS Secrets Manager → creates K8s Secret
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: app-secrets
spec:
  secretStoreRef: { name: aws-secrets-manager, kind: ClusterSecretStore }
  target: { name: app-secrets }  # K8s Secret name
  data:
  - secretKey: DB_PASSWORD        # K8s Secret key
    remoteRef:
      key: kubeflow-ops/dev       # AWS Secrets Manager path
      property: db_password
```

> **Why this matters**: Database passwords never live in Git or environment variables directly. They're fetched securely from AWS Secrets Manager at runtime.

---

## PHASE 9 — Observability Stack

**Goal**: Full visibility into your system — metrics, dashboards, and alerts.

### Stack deployed via ArgoCD (Helm charts in gitops/platform/)

```
Prometheus    → Scrapes metrics from all pods (CPU, memory, request rate, error rate)
Grafana       → Dashboards for your SLIs/SLOs
Alertmanager  → Routes alerts to Slack / PagerDuty / SNS when SLOs breach
```

> All three are deployed together via the `kube-prometheus-stack` Helm chart.
> This also installs **node-exporter** (host metrics) and **kube-state-metrics** (K8s object metrics).

### Alert rules (`gitops/platform/prometheus/`)

```yaml
# Example: Alert if error rate > 5% for 5 minutes
- alert: HighErrorRate
  expr: rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) > 0.05
  for: 5m
  labels:
    severity: critical
  annotations:
    summary: "High error rate on {{ $labels.service }}"
```

### SLI/SLO Definitions (from `docs/slo-definitions.md`)

| Service | SLI | SLO Target |
|---|---|---|
| order-service | Availability | 99.9% uptime |
| order-service | Latency | p99 < 500ms |
| user-service | Availability | 99.9% uptime |
| notification-service | Processing | < 30s notification delay |

---

## PHASE 10 — Runbooks & Documentation

**Goal**: Operational knowledge base so anyone can handle incidents.

### Files in `docs/`

```
docs/
├── slo-definitions.md   ← What we measure and why
└── runbook.md           ← Step-by-step incident response procedures
```

### Runbook topics

- How to rollback a bad deployment (ArgoCD)
- How to access pod logs (via `kubectl logs` or Grafana dashboards)
- How to scale manually in an emergency
- How to restore from database backup
- How to debug a crashing pod

---

## 📋 Summary Checklist

| Phase | Task | Files Involved |
|---|---|---|
| 1 | Understand the app, run locally | `apps/*/main.py`, `requirements.txt` |
| 2 | Write Dockerfiles | `apps/*/Dockerfile`, `.dockerignore` |
| 3 | docker-compose for local dev | `docker-compose.yml` |
| 4a | GitHub Actions CI + SonarQube | `.github/workflows/ci.yml`, `sonarqube/` |
| 4b | Deployment pipeline (CD) | `.github/workflows/deploy.yml` |
| 5a | Terraform AWS infra | `terraform/modules/`, `terraform/environments/` |
| 5b | SNS + CloudWatch + IRSA | `terraform/modules/{sns,cloudwatch,irsa}/` |
| 6a | Shared Helm chart | `gitops/charts/microservice/` |
| 6b | Per-service Helm values (dev/prod) | `gitops/apps/*/values{,-dev,-prod}.yaml` |
| 7 | ArgoCD GitOps CD | `gitops/platform/argocd/` |
| 8a | Kyverno security policies | `gitops/platform/kyverno/` |
| 8b | External Secrets (AWS SM) | `gitops/platform/external-secrets/` |
| 9 | Prometheus alerts (infra + business) | `gitops/platform/prometheus/` |
| 10 | SLOs, Runbooks | `docs/` |
| 11 | Operational scripts | `scripts/ops/`, `scripts/automation/` |

---

## 🔑 Key DevSecOps Principles Applied

| Principle | Implementation |
|---|---|
| **Shift-Left Security** | Trivy scans + SonarQube quality gate in CI before push |
| **No Static Credentials** | OIDC for GitHub→AWS auth, IRSA for Pod→AWS auth, ESO for secrets |
| **GitOps** | Git is the single source of truth. No `kubectl apply` by hand |
| **Least Privilege** | Kyverno blocks root, per-service IRSA roles scoped minimally |
| **Immutable Infrastructure** | Never patch running containers. Rebuild → redeploy |
| **Observability-First** | Health checks, metrics, dashboards, business + capacity alerts |
| **Infrastructure as Code** | Everything in Git. Reproducible. Reviewable |
| **Multi-Environment** | Helm values-dev.yaml / values-prod.yaml for resource tuning |
| **Safe Deployments** | Approval gates, smoke tests, automatic rollback on failure |
| **Operational Readiness** | Runbooks, SLOs, health check scripts, log analyzers |
