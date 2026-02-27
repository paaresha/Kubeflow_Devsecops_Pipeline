# KubeFlow Ops — Implementation Plan

A **production-grade GitOps platform** with full observability, built to demonstrate senior-level DevOps/SRE/Platform Engineering skills.

**Directory**: `c:\PROJECTS\kubeflow-ops`

## User Review Required

> [!IMPORTANT]
> **Language Decision**: All 3 microservices will be in **Python (FastAPI)**. In interviews, you can say: *"I chose Python for rapid prototyping, but the platform is language-agnostic — ArgoCD deploys any container image regardless of what language built it."* This is a strong, honest answer.

> [!IMPORTANT]
> **ArgoCD is new to you.** I'll add detailed comments in every ArgoCD manifest and include an ArgoCD explainer section in the README. You'll understand every line.

> [!WARNING]
> **AWS Cost**: The full stack (EKS + RDS + ElastiCache + NAT Gateway) costs ~₹500-700/day. I'll design everything to be **teardown-able in one command** (`terraform destroy`). I'll also include a `make teardown` shortcut.

---

## Proposed Changes

### Phase 1 — Project Scaffold & Microservices

Three simple FastAPI services that talk to each other, simulating a real production system:

| Service | Purpose | Talks To |
|---|---|---|
| `order-service` | CRUD for orders | RDS (Postgres), publishes to SQS |
| `user-service` | CRUD for users | RDS (Postgres), called by order-service via REST |
| `notification-service` | Consumes SQS messages | SQS (consumer), Redis (caching) |

Each service is ~100-150 lines of Python. Simple enough to understand, real enough to demonstrate infra.

#### [NEW] [main.py](file:///c:/PROJECTS/kubeflow-ops/apps/order-service/main.py)
- FastAPI app with `/orders` CRUD endpoints, `/health` probe
- Publishes order events to SQS on creation
- Calls `user-service` to validate user exists before creating order

#### [NEW] [main.py](file:///c:/PROJECTS/kubeflow-ops/apps/user-service/main.py)
- FastAPI app with `/users` CRUD endpoints, `/health` probe
- Stores users in PostgreSQL

#### [NEW] [main.py](file:///c:/PROJECTS/kubeflow-ops/apps/notification-service/main.py)
- FastAPI app with `/health` probe
- Background worker polling SQS for new order events
- Caches processed notification IDs in Redis to prevent duplicates

#### [NEW] [Dockerfile](file:///c:/PROJECTS/kubeflow-ops/apps/order-service/Dockerfile)
- Multi-stage build: `python:3.12-slim` → install deps → copy app → run with `uvicorn`
- Same pattern for all 3 services

#### [NEW] [docker-compose.yml](file:///c:/PROJECTS/kubeflow-ops/docker-compose.yml)
- All 3 services + Postgres + Redis + LocalStack (for SQS) for local development
- One `docker-compose up` to run everything locally

---

### Phase 2 — Terraform (Modular AWS Infrastructure)

All infrastructure in reusable Terraform modules with environment separation.

#### [NEW] Modules (`terraform/modules/`)

| Module | Resources Created |
|---|---|
| `vpc` | VPC, 2 public + 2 private subnets, NAT Gateway, route tables |
| `eks` | EKS cluster, managed node group (`t3.medium`), OIDC provider for IRSA |
| `ecr` | 3 ECR repos with lifecycle policy (keep last 10 images) |
| `rds` | PostgreSQL `db.t3.micro` in private subnet, security group |
| `elasticache` | Redis `cache.t3.micro` in private subnet |
| `sqs` | Order queue + dead-letter queue with redrive policy |

#### [NEW] Environment configs (`terraform/environments/dev/`)
- `main.tf` — calls all modules with dev-sized parameters
- `backend.tf` — S3 + DynamoDB remote state
- `variables.tf` / `outputs.tf`

> [!TIP]
> **Budget optimization**: `t3.micro` and `t3.medium` instances. Single NAT Gateway (not one per AZ). RDS `db.t3.micro`. ElastiCache `cache.t3.micro`. All easily destroyable.

---

### Phase 3 — Kubernetes Manifests

Using **Kustomize** (built into `kubectl`, no extra tool needed) with a base + overlays pattern.

#### [NEW] `gitops/apps/order-service/`
- `base/deployment.yaml` — Deployment with health probes (liveness, readiness, startup), resource limits, env vars from External Secrets
- `base/service.yaml` — ClusterIP service
- `base/hpa.yaml` — Scale 2-10 pods based on CPU
- `base/kustomization.yaml` — Base kustomization
- `overlays/dev/` — Dev-specific patches (1 replica, lower resources)
- Same structure for `user-service` and `notification-service`

#### [NEW] `gitops/apps/common/`
- `namespace.yaml` — `kubeflow-ops` namespace
- `service-account.yaml` — ServiceAccount with IRSA annotation

---

### Phase 4 — GitHub Actions CI

#### [NEW] [ci.yml](file:///c:/PROJECTS/kubeflow-ops/.github/workflows/ci.yml)
- **Trigger**: On push to `apps/<service-name>/**`
- **Steps**:
  1. Checkout code
  2. Run `pytest` (unit tests)
  3. Run `trivy fs` scan (source code)
  4. Build Docker image (multi-stage)
  5. Run `trivy image` scan (container)
  6. Login to ECR (`aws-actions/amazon-ecr-login`)
  7. Push image to ECR with `${{ github.sha }}` tag
  8. Update image tag in `gitops/` directory (triggers ArgoCD sync)

#### [NEW] [terraform.yml](file:///c:/PROJECTS/kubeflow-ops/.github/workflows/terraform.yml)
- **Trigger**: On push to `terraform/**` or manual dispatch
- **Steps**: `terraform fmt -check` → `validate` → `plan` → manual approval → `apply`

---

### Phase 5 — ArgoCD (GitOps CD)

> [!NOTE]
> **What is ArgoCD?** It's a Kubernetes controller that watches a Git repo. When you change a YAML file in Git, ArgoCD automatically applies that change to the cluster. No `kubectl apply` in CI/CD — Git becomes the single source of truth. If someone manually edits the cluster, ArgoCD detects the "drift" and reverts it.

#### [NEW] `gitops/platform/argocd/`
- `install.yaml` — ArgoCD installation (namespace + Helm values)
- `app-of-apps.yaml` — A single ArgoCD Application that manages all other Applications (App-of-Apps pattern)
- Every manifest will have detailed comments explaining what each field does

#### [NEW] `gitops/platform/argocd/applications/`
- One `Application` CRD per microservice + per platform tool
- Each configured with `automated sync`, `selfHeal: true`, `prune: true`

---

### Phase 6 — Observability Stack

#### [NEW] `gitops/platform/prometheus-stack/`
- **kube-prometheus-stack** Helm values — deploys Prometheus, Grafana, Alertmanager, node-exporter in one shot
- Custom alert rules: high error rate, pod restarts, high latency, node pressure

#### [NEW] `dashboards/`
- `sre-overview.json` — Cluster health, request rates, error rates, latency (RED method)
- `order-service.json` — Per-service metrics

#### [NEW] Alertmanager rules
- Pod CrashLoopBackOff → Slack
- Error rate > 5% → Slack
- Disk pressure → Slack

---

### Phase 7 — Platform Tools

#### [NEW] `gitops/platform/karpenter/`
- Karpenter Helm values + NodePool CRD
- Replaces Cluster Autoscaler — provisions right-sized nodes in seconds

#### [NEW] `gitops/platform/kyverno/`
- Policies:
  - Block `latest` image tag
  - Require resource limits on all pods
  - Require specific labels (`app`, `team`, `env`)
  - Block privileged containers

#### [NEW] `gitops/platform/external-secrets/`
- External Secrets Operator + `ClusterSecretStore` pointing to AWS Secrets Manager
- `ExternalSecret` resources for DB credentials, API keys

#### [NEW] `gitops/platform/cert-manager/`
- Cert-Manager + ClusterIssuer (Let's Encrypt)

#### [NEW] `gitops/platform/external-dns/`
- External DNS pointing to Route53 hosted zone

---

### Phase 8 — Documentation

#### [NEW] [README.md](file:///c:/PROJECTS/kubeflow-ops/README.md)
- Architecture diagram, getting started, teardown commands
- ArgoCD explainer section with screenshots workflow

#### [NEW] [docs/slo-definitions.md](file:///c:/PROJECTS/kubeflow-ops/docs/slo-definitions.md)
- SLI/SLO definitions for each service (availability, latency, error rate)

#### [NEW] [docs/runbook.md](file:///c:/PROJECTS/kubeflow-ops/docs/runbook.md)
- Incident response procedures per alert type

#### [NEW] [Makefile](file:///c:/PROJECTS/kubeflow-ops/Makefile)
- `make local-up` — docker-compose up
- `make deploy` — terraform apply
- `make teardown` — full teardown (terraform destroy + ECR cleanup)

#### [NEW] [QUESTIONS.md](file:///c:/PROJECTS/kubeflow-ops/QUESTIONS.md)
- Interview prep questions and answers covering every tool/concept in the project

---

## Verification Plan

### Automated Tests
1. **Python unit tests** — `pytest` for each microservice
   ```bash
   cd apps/order-service && pytest tests/ -v
   cd apps/user-service && pytest tests/ -v
   cd apps/notification-service && pytest tests/ -v
   ```

2. **Terraform validation** — syntax and configuration checks
   ```bash
   cd terraform/environments/dev
   terraform init -backend=false
   terraform validate
   terraform fmt -check -recursive
   ```

3. **Docker build test** — ensure all 3 images build successfully
   ```bash
   docker build -t order-service:test apps/order-service/
   docker build -t user-service:test apps/user-service/
   docker build -t notification-service:test apps/notification-service/
   ```

4. **Kustomize build test** — ensure manifests render correctly
   ```bash
   kubectl kustomize gitops/apps/order-service/overlays/dev/
   ```

5. **GitHub Actions syntax** — validate workflow files
   ```bash
   # actionlint can be used if installed
   actionlint .github/workflows/*.yml
   ```

### Manual Verification (by you after deploying to AWS)
1. Run `docker-compose up` locally and hit `http://localhost:8001/docs` (FastAPI Swagger UI) to verify services work
2. After `terraform apply` — verify EKS cluster is accessible with `kubectl get nodes`
3. After ArgoCD install — open ArgoCD UI and verify all apps show "Synced" and "Healthy"
4. After full deploy — hit the app endpoint and verify Grafana dashboards show live metrics
5. Run `make teardown` and verify all AWS resources are destroyed (check AWS console)
