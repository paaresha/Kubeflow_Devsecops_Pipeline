# Chat Conversation

Note: _This is purely the output of the chat conversation and does not contain any raw data, codebase snippets, etc. used to generate the output._

### User Input

Read the Project opened explaination file and tell me all the phases

### Planner Response

Let me explore the project directory to find the explanation file.

*Listed directory [Kubeflow_Devsecops_Pipeline](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline) *

### Planner Response

I can see there are a few relevant files: [Explaination.md](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/Explaination.md:0:0-0:0), [Explaination_Phase_5_onwards.md](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/Explaination_Phase_5_onwards.md:0:0-0:0), and [Phases_Custom.md](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/Phases_Custom.md:0:0-0:0). Let me read all of them to get the full picture.

*Viewed [Phases_Custom.md](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/Phases_Custom.md) *

*Analyzed [Explaination.md](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/Explaination.md) *

*Analyzed [Explaination_Phase_5_onwards.md](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/Explaination_Phase_5_onwards.md) *

### Planner Response

I have everything I need from [Phases_Custom.md](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/Phases_Custom.md:0:0-0:0), which contains the complete, authoritative phase guide. Here's a full breakdown of all the phases:

---

# 🚀 KubeFlow DevSecOps Pipeline — All Phases

> **Starting point:** Developers handed you only the `apps/` folder (Python code + requirements + tests). Everything else is **your job**.

---

## 📦 Phase Overview Summary

| Phase | Name | Goal |
|---|---|---|
| **1** | Understand & Run Locally | Know the code before touching any tooling |
| **2** | Dockerfiles | Containerize each service |
| **3** | docker-compose | Local full-stack orchestration |
| **4a** | CI Pipeline (GitHub Actions) | Auto Build → Test → Scan → Push to ECR |
| **4b** | CD / Deploy Pipeline | Manual gated deployments with rollback |
| **5a** | Terraform Backend Setup | S3 + DynamoDB for remote state (one-time) |
| **5b** | Terraform Modules | Provision ALL AWS infrastructure as code |
| **5c** | Terraform CI Workflow | Auto plan/apply via GitHub Actions |
| **6** | GitOps Manifests (Helm) | Define desired state as Helm charts |
| **7** | ArgoCD | GitOps-based continuous deployment to EKS |
| **8a** | Kyverno | Policy-as-Code security enforcement |
| **8b** | External Secrets Operator | Pull secrets from AWS Secrets Manager into K8s |
| **9** | Observability Stack | Metrics, dashboards, and alerts |
| **10** | Runbooks & Documentation | Operational incident procedures |
| **11** | Operational Scripts | Helper scripts for ops tasks |

---

## 📋 Detailed Phase Breakdown

### **Phase 1 — Understand & Run the App Locally** *(No Docker)*
- **Goal:** Know the code before touching any tooling
- Read `apps/*/main.py` and `apps/*/requirements.txt`
- Run each service manually with Python (`uvicorn`)
- Run unit tests with `pytest`
- **3 services:** `order-service` (port 8001), `user-service` (8002), `notification-service` (8003)
- **Files Created:** None

---

### **Phase 2 — Write Dockerfiles** *(Containerize Each Service)*
- **Goal:** Package each service into a portable, production-ready container image
- Use **multi-stage builds** (builder → lean production image)
- Implement **non-root user** (security best practice)
- Add `HEALTHCHECK` pointing to `/healthz`
- **Files Created:** `apps/*/Dockerfile`, `apps/*/.dockerignore`

---

### **Phase 3 — docker-compose** *(Local Full-Stack Orchestration)*
- **Goal:** One command (`docker-compose up`) spins up ALL services + dependencies
- Wires together: all 3 services + Postgres + Redis + LocalStack (SQS)
- Implements `depends_on`, healthchecks, named networks, volumes, env vars
- **Files Created:** [docker-compose.yml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/docker-compose.yml:0:0-0:0) at project root

---

### **Phase 4a — CI Pipeline** *(GitHub Actions)*
- **Goal:** On every code push → auto Build → Test → Scan → Push image to ECR → Update GitOps tag
- Pipeline jobs: `detect-changes` → `build-and-push` (matrix per service)
  - Checkout → AWS OIDC auth → ECR login → pytest → SonarQube → `docker build` → Trivy scan → `docker push` → `yq` update `values.yaml`
- **Files Created:** [.github/workflows/ci.yml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/.github/workflows/ci.yml:0:0-0:0)

### **Phase 4b — Deploy / CD Workflow**
- **Goal:** Manually triggered, gated deployments with smoke-test rollback
- Flow: `preflight` → `approval (prod only)` → `deploy (helm)` → `smoke-test` → `notify (Slack)`
- **Files Created:** [.github/workflows/deploy.yml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/.github/workflows/deploy.yml:0:0-0:0)

---

### **Phase 5a — Terraform Backend** *(One-time, manual)*
- Create S3 bucket for remote state + DynamoDB table for state locking

### **Phase 5b — Terraform Modules** *(Infrastructure as Code)*
- **Goal:** Provision ALL AWS infra — no clicking in the AWS console
- **Deploy order:** `VPC → ECR → RDS + ElastiCache + SQS → EKS → IRSA`
- Modules: `vpc/`, `ecr/`, `rds/`, `elasticache/`, `sqs/`, `eks/`, `irsa/`, `sns/`, `cloudwatch/`
- **Files Created:** `terraform/modules/*` + `terraform/environments/dev/*`

### **Phase 5c — Terraform CI Workflow**
- PR → `terraform plan` posted as PR comment; merge to main → `terraform apply`
- **Files Created:** [.github/workflows/terraform.yml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/.github/workflows/terraform.yml:0:0-0:0)

---

### **Phase 6 — GitOps Manifests** *(Helm Charts)*
- **Goal:** Define desired state of all services as Helm templates for ArgoCD to render & deploy
- ONE shared Helm chart (`gitops/charts/microservice/`) reused for all 3 services
- Per-service `values.yaml`, `values-dev.yaml`, `values-prod.yaml`
- CI updates `image.tag` in `values.yaml` automatically after every push
- **Files Created:** `gitops/charts/`, `gitops/apps/*/values*.yaml`, `gitops/apps/common/*`

---

### **Phase 7 — ArgoCD** *(GitOps Continuous Deployment)*
- **Goal:** ArgoCD watches `gitops/` in Git — any commit auto-deploys to EKS. **Zero manual `kubectl apply`**
- Uses the **App-of-Apps** pattern: one root app manages all child apps
- You only `kubectl apply` the root `app-of-apps.yaml` **once**
- **Files Created:** `gitops/platform/argocd/app-of-apps.yaml` + `applications/*.yaml`

---

### **Phase 8a — Kyverno** *(Policy-as-Code)*
- **Goal:** Enforce security rules at the cluster level, block non-compliant deployments
- Policies: disallow root containers, disallow privileged containers, require resource limits, disallow `:latest` image tags
- **Files Created:** `gitops/platform/kyverno/policies.yaml`

### **Phase 8b — External Secrets Operator (ESO)**
- **Goal:** DB passwords & API keys pulled from **AWS Secrets Manager** → K8s Secrets automatically. **Nothing sensitive in Git**
- Flow: `AWS Secrets Manager → ESO (syncs every 1h) → K8s Secret → Pod env var`
- **Files Created:** `gitops/platform/external-secrets/external-secrets.yaml`

---

### **Phase 9 — Observability Stack**
- **Goal:** Full visibility — metrics, dashboards, alerts
- Stack (deployed via ArgoCD Helm): **Prometheus + Grafana + Alertmanager + node-exporter + kube-state-metrics**
- Key alerts: `HighErrorRate`, `HighLatency`, `PodCrashLooping`, `LowDiskSpace`
- **Files Created:** `gitops/platform/prometheus/alert-rules.yaml`

---

### **Phase 10 — Runbooks & Documentation**
- **Goal:** Operational knowledge so anyone can handle incidents
- Covers: rollback via ArgoCD, accessing pod logs, emergency scaling, RDS restore, debugging crashlooping pods
- **Files Created:** `docs/slo-definitions.md`, `docs/runbook.md`

---

### **Phase 11 — Operational Scripts**
- **Goal:** Automate common ops tasks
- **Files Created:**
  - `scripts/localstack-init.sh` — create SQS queues in LocalStack
  - `scripts/ops/health-check.sh` — curl all `/healthz` endpoints
  - `scripts/ops/log-analyzer.sh` — parse pod logs for errors
  - `scripts/automation/setup-github-oidc.sh` — automate IAM OIDC trust policy
  - `scripts/automation/bootstrap-argocd.sh` — install + configure ArgoCD
  - `scripts/automation/create-secrets.sh` — push secrets to AWS Secrets Manager
  - `scripts/automation/smoke-test.sh` — post-deploy smoke tests

---

## 🔑 Core DevSecOps Principles Applied

| Principle | How |
|---|---|
| **Shift-Left Security** | Trivy + SonarQube in CI *before* push |
| **No Static Credentials** | OIDC (GitHub→AWS), IRSA (Pod→AWS), ESO (secrets from AWS SM) |
| **GitOps** | Git is single source of truth. No manual `kubectl apply` ever |
| **Least Privilege** | Kyverno blocks root; IRSA roles scoped per-service |
| **Immutable Infra** | Never patch running containers. Rebuild → redeploy |
| **Observability-First** | Metrics + dashboards + alerts from day one |

### User Input

Okay lets start from Phase 6.
You need to explain each thing line by line for devops prespective, Block by block, I only know basic docker terraform and kubernets basic
So any new topic u need to explain in detail as if beginner.If something is developer work no in depth required,  

### Planner Response

Let me read the explanation file for Phase 6 content first.

*Grep searched codebase*

*Grep searched codebase*

*Grep searched codebase*

*Grep searched codebase*

*Viewed [Explaination_Phase_5_onwards.md](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/Explaination_Phase_5_onwards.md) *

### Planner Response

Let me now find where Phase 6 content specifically is in the explanation file:

*Grep searched codebase*

*Viewed [Explaination_Phase_5_onwards.md](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/Explaination_Phase_5_onwards.md) *

### Planner Response

Now I see — the [Explaination_Phase_5_onwards.md](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/Explaination_Phase_5_onwards.md:0:0-0:0) file covers up through Phase 5. Phase 6 hasn't been written in detail yet in the explanation files. Let me check the actual gitops files in the project to directly explain them:

*Listed directory [gitops](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops) *

*Listed directory [charts](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/charts) *

*Listed directory [apps](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps) *

*Listed directory [microservice](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/charts/microservice) *

*Listed directory [common](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps/common) *

*Listed directory [order-service](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps/order-service) *

*Listed directory [templates](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/charts/microservice/templates) *

### Planner Response

Now let me read all the actual files:

*Viewed [Chart.yaml](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/charts/microservice/Chart.yaml) *

*Viewed [values.yaml](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/charts/microservice/values.yaml) *

*Viewed [_helpers.tpl](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/charts/microservice/templates/_helpers.tpl) *

*Viewed [deployment.yaml](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/charts/microservice/templates/deployment.yaml) *

*Viewed [service.yaml](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/charts/microservice/templates/service.yaml) *

*Viewed [hpa.yaml](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/charts/microservice/templates/hpa.yaml) *

*Viewed [values.yaml](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps/order-service/values.yaml) *

*Viewed [values-dev.yaml](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps/order-service/values-dev.yaml) *

*Viewed [values-prod.yaml](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps/order-service/values-prod.yaml) *

*Viewed [namespace.yaml](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps/common/namespace.yaml) *

*Viewed [configmap.yaml](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps/common/configmap.yaml) *

*Viewed [ingress.yaml](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps/common/ingress.yaml) *

*Viewed [service-account.yaml](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps/common/service-account.yaml) *

### Planner Response

Now also let me quickly check notification and user service values for completeness:

*Viewed [values.yaml](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps/notification-service/values.yaml) *

*Viewed [values.yaml](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps/user-service/values.yaml) *

### Planner Response

I now have every file. Let me write the complete, beginner-friendly Phase 6 deep-dive as an artifact:

*Edited relevant file*

### Planner Response

Here is the full, block-by-block Phase 6 explanation:

---

# 🚀 Phase 6 — GitOps Manifests (Helm Charts) — Deep-Dive

## 🧠 First — What Problem Does Phase 6 Solve?

You have a live EKS cluster from Phase 5. It's **empty**. Nothing is running. Phase 6 is where you define *what should run on it*.

### Why Not Just Write Plain Kubernetes YAML?

You know Kubernetes basics — so you know you'd write a `Deployment` + `Service` YAML per service. That's 6 files for 3 services, almost identical except for the name and port. Copy-paste hell.

### The Solution: **Helm**

> **Helm = the package manager for Kubernetes.** Think of it like `apt-get` for Ubuntu, or `npm` for Node.js — but for K8s YAML.

**How it works:**
```
Template (parameterized YAML)  +  Values file  →  Real Kubernetes YAML
    image: {{ .Values.image.tag }}       tag: abc1234    →    image: abc1234
```

### Why ONE Shared Chart for ALL 3 Services?

Instead of 3 charts, this project has **ONE chart called `microservice`**, reused for all 3 services. Each service just passes its own [values.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps/user-service/values.yaml:0:0-0:0) to customize it. DRY principle.

---

## 📁 Folder Structure

```
gitops/
├── charts/microservice/         ← ONE shared Helm chart (template)
│   ├── Chart.yaml               ← Chart identity card
│   ├── values.yaml              ← Default values (fallbacks)
│   └── templates/
│       ├── _helpers.tpl         ← Reusable label/name functions
│       ├── deployment.yaml      ← Parameterized K8s Deployment
│       ├── service.yaml         ← Parameterized K8s Service
│       └── hpa.yaml             ← Parameterized Autoscaler
│
└── apps/
    ├── common/                  ← Plain YAML, applied once, shared by all
    │   ├── namespace.yaml
    │   ├── configmap.yaml
    │   ├── ingress.yaml
    │   └── service-account.yaml
    ├── order-service/
    │   ├── values.yaml          ← CI updates image.tag here after every build
    │   ├── values-dev.yaml      ← Dev: 1 replica, tiny resources
    │   └── values-prod.yaml     ← Prod: 3+ replicas, big resources
    ├── user-service/ …
    └── notification-service/ …
```

---

## 📄 FILE 1: [Chart.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/charts/microservice/Chart.yaml:0:0-0:0) — Chart Identity

```yaml
apiVersion: v2            # Helm 3 (always v2 now)
name: microservice        # Chart name — reused for all 3 services
type: application         # Deploys real workloads (vs "library" = helpers only)
version: 1.0.0            # Chart code version (bump when you change templates)
appVersion: "1.0.0"       # App version (informational, overridden by image.tag)
```

> `version` = infrastructure code version. `appVersion` = software version. They move independently.

---

## 📄 FILE 2: [values.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps/user-service/values.yaml:0:0-0:0) — The Control Panel

Every template variable is defined here. Per-service files override what they need.

### Service Identity Block
```yaml
name: my-service     # Placeholder — each service overrides this
team: platform       # Label on every K8s resource → cost tracking, filtering
version: v1          # Pod label — useful for canary deployments
```

---

### Image Block
```yaml
image:
  repository: IMAGE_PLACEHOLDER   # ECR URL — updated by Terraform output once
  tag: latest                      # ← THE KEY FIELD — CI updates this on every push
  pullPolicy: IfNotPresent         # Only pull from ECR if not already on node
```

**`image.tag` is the engine of GitOps.** After CI builds a new Docker image and pushes to ECR, the pipeline does:
```bash
yq -i '.image.tag = "abc1234"' gitops/apps/order-service/values.yaml
git commit + git push
```
ArgoCD sees the commit → re-renders Helm → deploys to EKS. **Zero manual steps.**

**`pullPolicy: IfNotPresent`** — With pinned tags like `abc1234`, `IfNotPresent` is correct. The same `abc1234` image never changes. No need to re-pull it every pod restart (`Always` would waste bandwidth).

---

### Replicas & Port
```yaml
replicaCount: 2      # Default 2 pods → HA. Dev overrides to 1. Prod to 3.
containerPort: 8000  # Port the app listens on inside the container
```

---

### 🆕 NEW CONCEPT: Kubernetes Service Types
```yaml
service:
  type: ClusterIP   # Internal-only — only reachable inside the cluster
  port: 8000
```

| Type | Reachable from | When to use |
|---|---|---|
| **`ClusterIP`** | Inside cluster only | **Service-to-service comms** (this project) |
| `NodePort` | Node IP + static port | Quick testing only |
| `LoadBalancer` | Public Internet | Too expensive per-service; use Ingress instead |

All 3 microservices use `ClusterIP`. External traffic enters through **one single Ingress** → routes to the right ClusterIP service.

---

### 🆕 NEW CONCEPT: Resource Requests vs Limits
```yaml
resources:
  requests:
    cpu: 100m      # 100 millicores = 10% of 1 CPU core
    memory: 128Mi  # ~128 MB RAM — GUARANTEED minimum
  limits:
    cpu: 500m      # 500 millicores = half a CPU core — MAXIMUM ceiling
    memory: 256Mi  # Can burst up to 256MB, then gets killed (OOMKilled)
```

| | What it means | What happens if exceeded |
|---|---|---|
| **`requests`** | Minimum guaranteed | Kubernetes won't schedule pod if node doesn't have this free |
| **`limits`** | Maximum allowed | CPU → throttled (slowed). Memory → pod killed and restarted |

> **`m` = millicores.** `1000m = 1 full CPU core`. `100m = 10%` of one core.
>
> **WHY set them?** Without limits, one runaway pod can eat all node resources and starve all other pods. Kyverno (Phase 8) will *block* pods that don't have limits set.

---

### 🆕 NEW CONCEPT: The 3 Health Probes
```yaml
probes:
  startup:
    path: /healthz
    initialDelaySeconds: 5
    periodSeconds: 5
    failureThreshold: 30    # 30 × 5s = 150s allowed to start
  liveness:
    path: /healthz
    periodSeconds: 15       # Check every 15s
    failureThreshold: 3     # 3 failures → restart pod
  readiness:
    path: /readyz           # Different endpoint!
    periodSeconds: 10
    failureThreshold: 3     # 3 failures → remove from Service (stop traffic)
```

| Probe | Question | Failure action |
|---|---|---|
| **Startup** | "Finished starting?" | Restart pod |
| **Liveness** | "Still alive / not deadlocked?" | Restart pod |
| **Readiness** | "Ready to receive traffic?" | Remove from Service (no restart) |

> **Why Readiness matters for zero-downtime deploys:** New pod starts → Readiness fails (warming up) → Kubernetes does NOT send traffic to it yet. Old pod keeps serving. New pod warms up → Readiness passes → traffic shifts over → old pod killed. **Zero downtime, automatic.**
>
> **`/healthz` vs `/readyz`:** `/healthz` = "I'm alive" (simple). `/readyz` = "I'm ready for requests" (deeper check — may verify DB connection is live).

---

### 🆕 NEW CONCEPT: HPA — Horizontal Pod Autoscaler
```yaml
autoscaling:
  enabled: true
  minReplicas: 2        # Never go below 2 (HA guarantee)
  maxReplicas: 10       # Never go above 10 (cost ceiling)
  targetCPUUtilizationPercentage: 70    # Scale up when avg CPU hits 70%
  targetMemoryUtilizationPercentage: 80 # Scale up when avg Memory hits 80%
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300  # Wait 5 min before removing pods
      maxPodsPerMinute: 1              # Remove at most 1 pod/minute (gentle)
    scaleUp:
      stabilizationWindowSeconds: 60   # Confirm scale-up need within 1 min
      maxPodsPerMinute: 4              # Add up to 4 pods/minute (fast response)
```

**HPA automatically adds/removes pod replicas based on CPU/Memory usage.**

- Normal traffic → 2 pods. Black Friday spike → HPA adds pods → up to 10. Traffic drops → waits 5 min → removes pods slowly.
- **`stabilizationWindowSeconds: 300` for scaleDown** — prevents flapping. Traffic might spike in waves. Without this, HPA could remove pods between waves and not have time to add them back.
- **70% target, not 100%** — you scale *before* you're saturated. At 100% you're already struggling.

---

### Security & Anti-Affinity
```yaml
securityContext:
  runAsNonRoot: true    # Kubernetes REFUSES to start pod if runs as root
  runAsUser: 1000       # Run as the appuser you created in Phase 2 Dockerfile
  fsGroup: 1000         # Mounted volumes owned by this group

podAntiAffinity:
  enabled: true         # Prefer to spread replicas across different nodes
```

> **Anti-Affinity:** If both replicas of `order-service` land on the same node and that node crashes → both go down. Anti-affinity says "prefer different nodes." With `preferred` (not `required`), it's best-effort — won't block scheduling on single-node dev clusters.

---

### Prometheus Auto-Discovery
```yaml
prometheus:
  enabled: true
  path: /metrics
```
When `true`, the Deployment template adds these **annotations** to every Pod:
```yaml
prometheus.io/scrape: "true"
prometheus.io/port: "8001"
prometheus.io/path: "/metrics"
```
Prometheus reads these annotations and **automatically discovers** this pod as a scrape target. Zero manual Prometheus config needed.

---

## 📄 FILE 3: [_helpers.tpl](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/charts/microservice/templates/_helpers.tpl:0:0-0:0) — Reusable Template Functions

> [.tpl](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/charts/microservice/templates/_helpers.tpl:0:0-0:0) files with `_` prefix are **never rendered as K8s resources**. They only define helper functions `include`d by other templates.

```
{{ define "microservice.fullname" }}   → renders as just the service name (e.g. "order-service")
{{ define "microservice.labels" }}     → renders a full block of K8s labels
{{ define "microservice.selectorLabels" }} → just "app: order-service" for Service selector
{{ define "microservice.podLabels" }}  → app + team + version for pod metadata
```

**`{{- ... -}}`** — the `-` trims surrounding whitespace. Without it, you'd get ugly blank lines in rendered YAML.

**`| nindent 4`** — a Helm pipe function. Takes the output, adds a newline, then indents every line by 4 spaces. Required to correctly embed multi-line blocks inside YAML.

**Why `selectorLabels` uses only `app: <name>` (not all labels):** Service selectors must be stable — if you later add a `version` label, updating it would break the selector match. Minimal selectors = safer.

---

## 📄 FILE 4: [deployment.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/charts/microservice/templates/deployment.yaml:0:0-0:0) Template — Block by Block

```yaml
# Kubernetes resource declaration
apiVersion: apps/v1
kind: Deployment

metadata:
  name: {{ include "microservice.fullname" . }}   # → "order-service"
  namespace: {{ .Values.namespace }}              # → "kubeflow-ops"
  labels:
    {{- include "microservice.labels" . | nindent 4 }}
```

**`{{ include "fn" . }}`** — calls a helper function, passing `.` (the full context: `.Values`, `.Chart`, `.Release`).

---

**Prometheus annotations (conditional):**
```yaml
annotations:
  {{- if .Values.prometheus.enabled }}
  prometheus.io/scrape: "true"
  ...
  {{- end }}
```
`{{- if ... }}...{{- end }}` — Helm conditional. This entire block only appears in the rendered YAML if `prometheus.enabled` is true. If false → the annotations section is completely absent.

---

**ServiceAccount + SecurityContext:**
```yaml
spec:
  serviceAccountName: kubeflow-ops-sa   # ← IRSA — gives pod AWS credentials automatically
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 1000
```

---

**Container image:**
```yaml
containers:
  - name: {{ .Values.name }}
    image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
```
→ Rendered: `image: "123456.dkr.ecr.us-east-1.amazonaws.com/order-service:abc1234"`

---

**Environment variables (conditional):**
```yaml
{{- if .Values.env }}
env:
  {{- toYaml .Values.env | nindent 12 }}
{{- end }}
```
**`toYaml`** — converts the `env` list from values.yaml back to YAML string format. `nindent 12` indents it to correct depth. This is the standard Helm pattern for embedding complex structures.

---

**Pod Anti-Affinity:**
```yaml
{{- if .Values.podAntiAffinity.enabled }}
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
              - key: app
                operator: In
                values:
                  - {{ .Values.name }}
          topologyKey: kubernetes.io/hostname
{{- end }}
```
- `preferredDuring...` = best-effort, not hard requirement
- `weight: 100` = maximum preference score
- `topologyKey: kubernetes.io/hostname` = spread = different nodes (different hostnames)

---

## 📄 FILE 5: [service.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/charts/microservice/templates/service.yaml:0:0-0:0) Template

```yaml
spec:
  type: ClusterIP
  selector:
    app: order-service      # ← Must match pod labels exactly (selector glue)
  ports:
    - port: 8001            # Port you call from OTHER services
      targetPort: http      # Port on the pod (named "http" = 8001)
```

**ClusterIP DNS — once this Service exists, any pod inside the cluster can reach it at:**
```
http://order-service:8001
http://order-service.kubeflow-ops.svc.cluster.local:8001
```
Built-in Kubernetes DNS, automatic, zero config.

---

## 📄 FILE 6: [hpa.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/charts/microservice/templates/hpa.yaml:0:0-0:0) Template

```yaml
{{- if .Values.autoscaling.enabled }}   ← Entire HPA only rendered if enabled
apiVersion: autoscaling/v2              ← v2 = CPU + Memory + custom metrics
kind: HorizontalPodAutoscaler
...
  scaleTargetRef:
    kind: Deployment
    name: order-service    ← Tells HPA which Deployment to control
  minReplicas: 2
  maxReplicas: 10
  metrics:                 ← What to measure
    - type: Resource
      resource: cpu → target 70%
    - type: Resource
      resource: memory → target 80%
  behavior:
    scaleDown: ← conservative (slow, stabilized)
    scaleUp:   ← aggressive (fast response)
{{- end }}
```

---

## 📄 Per-Service [values.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps/user-service/values.yaml:0:0-0:0) Files

### [order-service/values.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps/order-service/values.yaml:0:0-0:0)
```yaml
name: order-service       # Overrides default "my-service"
containerPort: 8001       # Real port

env:
  - name: DATABASE_URL
    valueFrom:
      secretKeyRef:        # ← reads from K8s Secret "db-credentials"
        name: db-credentials
        key: url           # The password NEVER appears in this file. Ever.

  - name: SQS_QUEUE_URL
    valueFrom:
      configMapKeyRef:     # ← reads from K8s ConfigMap "app-config"
        name: app-config
        key: sqs-queue-url

  - name: USER_SERVICE_URL
    value: "http://user-service.kubeflow-ops.svc.cluster.local:8002"
    # ↑ Kubernetes internal DNS — how order-service calls user-service
```

**`secretKeyRef` vs `configMapKeyRef`:**
| | Use for | Stored in |
|---|---|---|
| `secretKeyRef` | Passwords, tokens, keys | K8s Secret (from AWS Secrets Manager via ESO) |
| `configMapKeyRef` | URLs, region names, feature flags | K8s ConfigMap (safe to have in Git) |

---

### [values-dev.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps/order-service/values-dev.yaml:0:0-0:0) vs [values-prod.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps/order-service/values-prod.yaml:0:0-0:0)

```yaml
# DEV — cheap                    # PROD — resilient
replicaCount: 1                  replicaCount: 3
cpu requests: 50m                cpu requests: 200m
memory requests: 64Mi            memory requests: 256Mi
maxReplicas: 3                   maxReplicas: 20
```

**How ArgoCD merges these (Phase 7):**
```bash
helm template ... \
  -f gitops/apps/order-service/values.yaml \      ← base (CI updates image.tag here)
  -f gitops/apps/order-service/values-dev.yaml    ← env overrides (later file wins)
```

---

## 📄 `common/` Files — Shared Cluster Resources

### [namespace.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps/common/namespace.yaml:0:0-0:0)
```yaml
kind: Namespace
metadata:
  name: kubeflow-ops
```
**Why not `default`?** Isolation, RBAC granularity, resource quotas, clean deletion. Production clusters never use `default`.

### [configmap.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps/common/configmap.yaml:0:0-0:0)
```yaml
kind: ConfigMap
data:
  aws-region: "us-east-1"
  sqs-queue-url: "PLACEHOLDER_AFTER_TERRAFORM_APPLY"
  redis-url:     "PLACEHOLDER_AFTER_TERRAFORM_APPLY"
```
After `terraform apply`, you fill in the real SQS URL and Redis URL from Terraform outputs, commit to Git — ArgoCD updates the ConfigMap, pods restart with new values.

### [service-account.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps/common/service-account.yaml:0:0-0:0)
```yaml
kind: ServiceAccount
metadata:
  name: kubeflow-ops-sa
  annotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::ACCOUNT_ID:role/kubeflow-ops-dev-app-role"
```

### 🆕 NEW CONCEPT: IRSA — IAM Roles for Service Accounts

This annotation is **the magic line** that connects pods to AWS without any access keys.

**How it works:**
1. Terraform (Phase 5) creates IAM Role with SQS permissions
2. You put that role ARN in this annotation
3. When a pod uses `kubeflow-ops-sa`, EKS automatically injects **temporary rotating AWS credentials** into the pod
4. boto3 (the AWS SDK in the app) picks them up automatically
5. **No static keys. No secrets in Git. Credentials rotate every hour.**

### [ingress.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps/common/ingress.yaml:0:0-0:0) — The Traffic Router

### 🆕 NEW CONCEPT: Kubernetes Ingress

**Problem:** 3 ClusterIP services are internal-only. Users can't reach them. `LoadBalancer` type would create 3 AWS Load Balancers = ~$150/month.

**Solution: One Ingress** = One Load Balancer + URL path-based routing.

```yaml
kind: Ingress
annotations:
  nginx.ingress.kubernetes.io/rewrite-target: /$2      # Strip /api/orders prefix
  nginx.ingress.kubernetes.io/use-regex: "true"        # Enable regex paths
  nginx.ingress.kubernetes.io/limit-rps: "50"          # Rate limit: 50 req/sec/IP
  nginx.ingress.kubernetes.io/limit-burst-multiplier: "5"  # Allow burst to 250/sec
spec:
  ingressClassName: nginx      # Use NGINX Ingress Controller (deployed in Phase 7)
  rules:
    - http:
        paths:
          - path: /api/orders(/|$)(.*)    # Regex: /api/orders → order-service:8001
          - path: /api/users(/|$)(.*)     # → user-service:8002
          - path: /api/notifications(/|$)(.*) # → notification-service:8003
```

**`rewrite-target: /$2`** — URL rewriting. `/api/orders/123` → `/$2` = `/123`. Because inside the cluster, `order-service` is listening at `/orders/123`, not `/api/orders/123`. The Ingress strips the `/api/orders` prefix.

**Rate limiting** — blocks abuse at the Load Balancer level before it even hits your pods.

---

## 🔄 The Complete CI → GitOps Flow

```
1. Developer pushes code
2. GitHub Actions CI:
   → pytest → Trivy → docker push to ECR (sha: abc1234)
   → yq -i '.image.tag = "abc1234"' gitops/apps/order-service/values.yaml
   → git commit + push
3. ArgoCD detects values.yaml changed in Git
4. ArgoCD renders: helm template ... -f values.yaml -f values-dev.yaml
5. ArgoCD applies rendered YAML to EKS
6. Kubernetes rolling update:
   → New pod starts → startup probe → readiness probe passes
   → New pod added to Service
   → Old pod removed from Service → killed
   → Zero downtime ✅
```

---

## 🔑 Key Takeaways

| Pattern | Why It Matters |
|---|---|
| **One chart, 3 services** | Maintain 1 template not 3 |
| **`image.tag` = deploy trigger** | CI updates 1 field → full deployment |
| **ClusterIP + Single Ingress** | Cost-efficient, one load balancer |
| **3-layer probes** | Handles slow starts, deadlocks, zero-downtime updates |
| **HPA with stabilization** | Autoscaling without flapping |
| **Pod Anti-Affinity** | HA across nodes |
| **IRSA** | Zero static AWS keys |
| **ConfigMap vs Secret** | Non-sensitive in Git, sensitive in AWS Secrets Manager |
| **Prometheus annotations** | Auto-discovery, zero Prometheus config |

---

**Next up → Phase 7: ArgoCD** — You apply ONE manifest, and from that point on, every Git commit to `gitops/` automatically deploys to EKS. **Forever. Automatically.** 🚀

### User Input

NO seperate Artifact, combine window output and artifact and share it here in this window

### Planner Response

# 🚀 Phase 6 — GitOps Manifests (Helm Charts) — Complete Deep-Dive

---

## 🧠 Big Picture First — What Problem Does Phase 6 Solve?

You have a **live EKS cluster from Phase 5**. It's completely empty — nothing is running on it. Phase 6 is where you define *what should run on it*.

### The Problem Without Helm

You know basic Kubernetes — to deploy an app you write a `Deployment` YAML + a `Service` YAML. Now you have 3 services → 6 YAML files, all nearly identical (same structure, just different name/port/image). Copy-paste hell. And for dev vs prod you want different replica counts and resource limits. Without a tool, you'd edit the same YAML over and over — error-prone.

### The Solution: Helm

> **Helm = the package manager for Kubernetes.** Think of it like `apt-get` for Ubuntu, or `npm` for Node.js — but for Kubernetes YAML files.

**How it works — think of it like a template engine:**
```
Template (parameterized YAML)  +  Values file  →  Real Kubernetes YAML

Template says:   image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
Values say:      image.tag: abc1234
Helm produces:   image: "123456.dkr.ecr.us-east-1.amazonaws.com/order-service:abc1234"
```

### Why ONE Shared Chart for ALL 3 Services?

Instead of 3 separate charts, this project uses **ONE chart called `microservice`**, reused for all 3 services. Each service passes its own [values.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps/user-service/values.yaml:0:0-0:0) to customize it. This is the **DRY principle** (Don't Repeat Yourself).

```
gitops/charts/microservice/           ← ONE template, reused 3 times
gitops/apps/order-service/values.yaml        ← customizes for order-service
gitops/apps/user-service/values.yaml         ← customizes for user-service
gitops/apps/notification-service/values.yaml ← customizes for notification-service
```

---

## 📁 Full Folder Structure

```
gitops/
├── charts/
│   └── microservice/              ← THE shared Helm chart (the mold)
│       ├── Chart.yaml             ← Chart identity card
│       ├── values.yaml            ← Default values (fallback)
│       └── templates/             ← The actual parameterized YAML
│           ├── _helpers.tpl       ← Reusable helper functions (labels etc.)
│           ├── deployment.yaml    ← Kubernetes Deployment template
│           ├── service.yaml       ← Kubernetes Service template
│           └── hpa.yaml           ← Kubernetes Autoscaler template
│
└── apps/
    ├── common/                    ← Plain YAML (not templates), applied once
    │   ├── namespace.yaml         ← Creates the kubeflow-ops namespace
    │   ├── configmap.yaml         ← Non-secret config (SQS URL, Redis URL)
    │   ├── ingress.yaml           ← Routes external traffic to all services
    │   └── service-account.yaml   ← K8s SA with AWS IAM role attached (IRSA)
    │
    ├── order-service/
    │   ├── values.yaml            ← Service-specific config; CI updates image.tag here!
    │   ├── values-dev.yaml        ← Dev overrides (fewer replicas, less resources)
    │   └── values-prod.yaml       ← Prod overrides (more replicas, more resources)
    ├── user-service/     (same 3 files)
    └── notification-service/ (same 3 files)
```

**Order to understand the files:**
1. [Chart.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/charts/microservice/Chart.yaml:0:0-0:0) → what is this chart?
2. [values.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps/user-service/values.yaml:0:0-0:0) → what are the defaults?
3. [_helpers.tpl](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/charts/microservice/templates/_helpers.tpl:0:0-0:0) → utility functions
4. [deployment.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/charts/microservice/templates/deployment.yaml:0:0-0:0) → the main workload template
5. [service.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/charts/microservice/templates/service.yaml:0:0-0:0) → how to reach the pods
6. [hpa.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/charts/microservice/templates/hpa.yaml:0:0-0:0) → how it scales automatically
7. Per-service [values.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps/user-service/values.yaml:0:0-0:0) → what each service customizes
8. `common/` → shared cluster-level resources

---

## 📄 FILE 1: [gitops/charts/microservice/Chart.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/charts/microservice/Chart.yaml:0:0-0:0)

This is the **identity card** of your Helm chart.

```yaml
apiVersion: v2
name: microservice
description: Shared Helm chart for KubeFlow Ops microservices
type: application
version: 1.0.0
appVersion: "1.0.0"
```

**`apiVersion: v2`**
→ Helm chart API version. `v2` = you're using **Helm 3** (the current version). You'll always write `v2`. Just like `apiVersion: apps/v1` in Kubernetes YAML — it tells the tool which schema to use.

**`name: microservice`**
→ The chart's internal name. When you run `helm install`, you reference this chart by this name.

**`type: application`**
→ Two types of Helm charts:
- `application` → Deploys actual workloads (Deployments, Services, etc.) — **this is what you want**
- `library` → Contains only reusable Helm helpers, never deployed directly

**`version: 1.0.0`**
→ **The chart version** — this is the version of *your infrastructure code*, not the app code. If you change a template (add a new probe, fix a port), you bump this number.

**`appVersion: "1.0.0"`**
→ **The application version** — informational only. In practice, `image.tag` in values files is what actually controls which version of the app gets deployed. They move independently.

> **Key distinction:** `version` = your Helm template changed. `appVersion` = the app software changed.

---

## 📄 FILE 2: [gitops/charts/microservice/values.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/charts/microservice/values.yaml:0:0-0:0) — The Control Panel

This file defines **every variable** used in the templates with its default value. Think of it as the ingredient list with default measurements. Per-service [values.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps/user-service/values.yaml:0:0-0:0) files are substitutions ("use port 8001 instead of 8000").

### Block 1 — Service Identity
```yaml
name: my-service    # Placeholder — each service overrides this with e.g. "order-service"
team: platform      # Label on every K8s resource → for cost tracking & filtering
version: v1         # Pod label → useful for canary deployments (v1 and v2 side by side)
```

**`team: platform`** — Gets attached as a label to every Kubernetes resource this chart creates. Used for:
- Filtering: `kubectl get pods -l team=platform`
- Cost dashboards (which team is spending what on the cluster)
- Compliance tagging

---

### Block 2 — Container Image
```yaml
image:
  repository: IMAGE_PLACEHOLDER   # Full ECR URL — updated once after Terraform
  tag: latest                      # ← THE MOST IMPORTANT FIELD IN GITOPS
  pullPolicy: IfNotPresent
```

**`image.tag`** — This is the **engine of the entire GitOps flow**. After CI builds a Docker image and pushes it to ECR, the pipeline does:
```bash
yq -i '.image.tag = "abc1234"' gitops/apps/order-service/values.yaml
git commit -m "ci: update order-service to abc1234"
git push
```
ArgoCD (Phase 7) sees this commit → re-renders Helm → deploys to EKS. **No human involved. Git is the source of truth.**

**`pullPolicy: IfNotPresent`** — Three options:
- `IfNotPresent` → Only pull image if not already on the node (**correct for pinned tags like `abc1234`**)
- `Always` → Pull every pod start (slow, wastes bandwidth — only use with `latest`)
- `Never` → Never pull (local testing only)

> With a pinned tag like `abc1234`, the image never changes on the registry, so `IfNotPresent` is perfect. `Always` would re-download identical bytes on every pod restart.

---

### Block 3 — Replicas & Port
```yaml
replicaCount: 2      # Default 2 pods → basic HA. Dev overrides to 1. Prod to 3+.
containerPort: 8000  # Port the app listens on inside the container
```

---

### Block 4 — 🆕 NEW CONCEPT: Kubernetes Service Types
```yaml
service:
  type: ClusterIP   # Internal-only service
  port: 8000
```

A **Kubernetes Service** gives your pods a **stable DNS name + internal load balancer**. Without it, pod IPs change every restart and nothing can reliably reach them.

| Service Type | Reachable from | When to use |
|---|---|---|
| **`ClusterIP`** | Inside cluster only | **Service-to-service communication** (this project) |
| `NodePort` | Node IP + static port | Quick testing only, not production |
| `LoadBalancer` | Public Internet | Creates a cloud LB per service — expensive; use Ingress instead |

**All 3 microservices use `ClusterIP`** because they're internal. External traffic enters through **one single Ingress** (explained later as [ingress.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps/common/ingress.yaml:0:0-0:0)), which routes to the right ClusterIP.

---

### Block 5 — ServiceAccount
```yaml
serviceAccount:
  name: kubeflow-ops-sa
```

This references the `ServiceAccount` defined in [common/service-account.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps/common/service-account.yaml:0:0-0:0). Every pod uses this SA. **This is the IRSA setup** — it's how pods get AWS credentials automatically without any hardcoded keys. Full explanation when we cover [service-account.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps/common/service-account.yaml:0:0-0:0).

---

### Block 6 — 🆕 NEW CONCEPT: Resource Requests vs Limits
```yaml
resources:
  requests:
    cpu: 100m        # 100 millicores = 10% of 1 CPU core — GUARANTEED minimum
    memory: 128Mi    # ~128 MB RAM — GUARANTEED minimum
  limits:
    cpu: 500m        # 500 millicores = half a CPU — MAXIMUM ceiling
    memory: 256Mi    # If pod uses more than 256MB → killed (OOMKilled) and restarted
```

**CPU units:** `1000m = 1 full CPU core`. `100m = 10%` of one core. `500m = half a core`.

**Memory units:** `Mi = Mebibytes` (≈ megabytes).

| | Meaning | Scheduler uses it for | Exceeded = |
|---|---|---|---|
| **`requests`** | Minimum guaranteed | Finding a node with enough free capacity | Nothing — it's a reservation |
| **`limits`** | Maximum allowed | Hard ceiling | CPU → throttled (slowed). Memory → pod killed+restarted |

**Why MUST you set these?**
- Without limits → one runaway pod can eat ALL node CPU/memory → starves every other pod on the cluster → cascading failures
- **Kyverno (Phase 8) will block any pod deployment that doesn't have resource limits set.** This is enforced.

**Why are `requests` < `limits`?**
- Requests lower = Kubernetes can pack more pods per node (efficient)
- Limits higher = pods can burst under load without being killed
- This pattern is called **Burstable QoS** — the standard for microservices

---

### Block 7 — 🆕 NEW CONCEPT: The 3 Kubernetes Health Probes
```yaml
probes:
  startup:
    path: /healthz
    initialDelaySeconds: 5
    periodSeconds: 5
    failureThreshold: 30      # 30 × 5s = 150 seconds allowed to start up
  liveness:
    path: /healthz
    periodSeconds: 15         # Check every 15 seconds
    timeoutSeconds: 5         # If no response in 5s → count as failure
    failureThreshold: 3       # 3 consecutive failures → restart pod
  readiness:
    path: /readyz             # ← Different endpoint from liveness!
    periodSeconds: 10
    timeoutSeconds: 5
    failureThreshold: 3       # 3 failures → remove pod from Service (no traffic)
```

You know Docker's single `HEALTHCHECK`. Kubernetes has **three separate probes** for three different situations:

| Probe | Question It Asks | What Happens on Failure |
|---|---|---|
| **Startup** | "Has the app finished starting up?" | Restarts the pod |
| **Liveness** | "Is the app still alive, not deadlocked?" | Restarts the pod |
| **Readiness** | "Is the app ready to receive traffic right now?" | Removes from Service (no restart) |

**Startup Probe — why `failureThreshold: 30`?**
It gives the app up to `30 × 5s = 150 seconds` to start. During this window, the liveness and readiness probes are **paused**. This prevents Kubernetes from killing a slow-starting app that's just taking time to initialize database connections and warm up.

**Liveness Probe — why `failureThreshold: 3` (not 1)?**
One slow response doesn't mean the app is dead. Maybe it's handling a heavy request. 3 consecutive failures over 45 seconds gives you confidence the app is genuinely hung before restarting it.

**Readiness Probe — the key to zero-downtime deployments:**
```
Rolling Update scenario:
1. New pod starts → Startup probe: waiting...
2. Startup passes → Readiness probe: FAILS (DB connections still warming)
3. Kubernetes: "New pod not ready, keep old pod serving traffic"
4. Readiness probe: PASSES (warm-up complete)
5. Kubernetes: adds new pod to Service, old pod removed and killed
→ Users never experienced downtime ✅
```

**`/healthz` vs `/readyz`:**
- `/healthz` = simple "I'm alive" check — just returns `{"status": "alive"}`
- `/readyz` = deeper check — verifies DB connection is live, queues are reachable, the app can actually handle requests

---

### Block 8 — 🆕 NEW CONCEPT: HPA — Horizontal Pod Autoscaler
```yaml
autoscaling:
  enabled: true
  minReplicas: 2          # Never drop below 2 (HA guarantee — even at zero load)
  maxReplicas: 10         # Never exceed 10 (your cost ceiling)
  targetCPUUtilizationPercentage: 70     # Scale UP when avg CPU > 70%
  targetMemoryUtilizationPercentage: 80  # Scale UP when avg Memory > 80%
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300    # Wait 5 minutes before removing pods
      maxPodsPerMinute: 1                # Remove at most 1 pod per minute (gentle)
    scaleUp:
      stabilizationWindowSeconds: 60     # Confirm need for scaling within 1 minute
      maxPodsPerMinute: 4                # Add up to 4 pods per minute (fast response)
```

**HPA automatically adjusts the number of running pods based on CPU/Memory usage.**

Real-world scenario:
- Normal time → 2 pods. Black Friday traffic spike → CPU climbs above 70% → HPA adds pods → 8 pods. Sale ends → load drops → HPA waits 5 minutes (stabilization) → slowly removes pods (1/min) → back to 2.

**Why `targetCPUUtilizationPercentage: 70` and not 100%?**
At 100% you're already overwhelmed. You need to scale *before* saturation. 70% means "add pods when we're at 70% capacity so new pods are ready before we hit 100%."

**`stabilizationWindowSeconds: 300` for scaleDown — the flapping prevention:**
Traffic comes in waves. Without this, HPA might remove pods during a 30-second lull between waves, then scramble to add them back. 5-minute stabilization = confidence the load is genuinely lower, not just a brief dip.

**Why scaleDown is `maxPodsPerMinute: 1` but scaleUp is `4`?**
Scaling down has consequences (if you remove too fast and traffic spikes, users get slow responses). Scaling up is urgent (users are waiting right now). Asymmetric behavior is intentional.

---

### Block 9 — Security Context & Pod Anti-Affinity
```yaml
securityContext:
  runAsNonRoot: true   # Kubernetes REFUSES to start pod if it tries to run as root (UID 0)
  runAsUser: 1000      # Process runs as UID 1000 (the appuser from Phase 2 Dockerfile)
  fsGroup: 1000        # Mounted volumes owned by group 1000 (app can read its own files)

podAntiAffinity:
  enabled: true        # Prefer to place replicas on DIFFERENT nodes
```

**`runAsNonRoot: true`** — This works alongside your Phase 2 Dockerfile where you created `appuser`. The Dockerfile sets the user; this enforces it at the Kubernetes level — double protection. Kyverno (Phase 8) adds a third layer.

**Pod Anti-Affinity — why?**
If both replicas of `order-service` land on the **same Node** and that node crashes or gets rebooted → both pods die simultaneously → your service is completely down.

Anti-Affinity says: "**Prefer** different nodes for each replica." It's `preferred` (not `required`), so on a single-node dev cluster it won't block scheduling — but in prod (multi-node) it spreads your pods for real HA.

---

### Block 10 — Prometheus & Env Vars
```yaml
prometheus:
  enabled: true
  path: /metrics

env: []    # Empty by default — each service's values.yaml fills this in
```

**`prometheus.enabled: true`** — When true, the Deployment template adds these **annotations** to every Pod:
```yaml
prometheus.io/scrape: "true"
prometheus.io/port: "8001"
prometheus.io/path: "/metrics"
```
Prometheus reads pod annotations and **automatically discovers** this pod as a scrape target every 15 seconds. **Zero manual Prometheus config.** This is how your metrics flow into Grafana dashboards in Phase 9.

---

## 📄 FILE 3: [templates/_helpers.tpl](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/charts/microservice/templates/_helpers.tpl:0:0-0:0) — Reusable Helper Functions

### 🆕 NEW CONCEPT: Helm Template Helpers

[.tpl](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/charts/microservice/templates/_helpers.tpl:0:0-0:0) files with a `_` prefix are **never rendered as Kubernetes resources**. They only define named template functions that other templates can call to avoid repetition.

```
{{- define "microservice.fullname" -}}
{{- .Values.name -}}
{{- end -}}
```

**`{{- define "name" -}}`** → Defines a named template block.  
**The `-` inside `{{-` and `-}}`** → Trims surrounding whitespace. Without it, you'd get extra blank lines in the rendered YAML which would make it invalid or ugly.

**`.Values.name`** → `.Values` is the global object containing everything from all merged [values.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps/user-service/values.yaml:0:0-0:0) files. So `.Values.name` → `"order-service"`.

---

```
{{- define "microservice.labels" -}}
app: {{ .Values.name }}
team: {{ .Values.team }}
version: {{ .Values.version }}
app.kubernetes.io/name: {{ .Values.name }}
app.kubernetes.io/part-of: kubeflow-ops
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end -}}
```

This defines the **full label block** applied to every Kubernetes resource.

**`app: {{ .Values.name }}`** → Primary label. Used by Services to match Pods via selector.

**`app.kubernetes.io/*` labels** → These are **Kubernetes recommended labels** — a standard convention so all tools (dashboards, ArgoCD UI, monitoring) can identify what this resource belongs to.

**`app.kubernetes.io/managed-by: {{ .Release.Service }}`** → `.Release.Service` = "Helm". Marks this resource as Helm-managed — ArgoCD and `helm` CLI know to track it.

**`helm.sh/chart: microservice-1.0.0`** → Records which chart version created this resource. Useful for auditing.

---

```
{{- define "microservice.selectorLabels" -}}
app: {{ .Values.name }}
{{- end -}}
```

**Why only `app: <name>` for selectors?** A Service's `selector` must exactly match pod labels — if labels change later (e.g., you add a `version` label to the selector), the Service breaks. Minimal selectors = more stable.

---

## 📄 FILE 4: [templates/deployment.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/charts/microservice/templates/deployment.yaml:0:0-0:0) — The Heart of the Chart (Block by Block)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "microservice.fullname" . }}    # → "order-service"
  namespace: {{ .Values.namespace }}               # → "kubeflow-ops"
  labels:
    {{- include "microservice.labels" . | nindent 4 }}
```

**`{{ include "microservice.fullname" . }}`** → Calls the helper from [_helpers.tpl](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/charts/microservice/templates/_helpers.tpl:0:0-0:0).  
The `.` passes the **current full context** (`.Values`, `.Chart`, `.Release`) into the function.

**`| nindent 4`** → A Helm pipe. Takes the output of `include`, adds a leading newline, then indents every line by 4 spaces. Required so the labels block is correctly indented inside `metadata.labels:`.

---

```yaml
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "microservice.selectorLabels" . | nindent 6 }}
```

**`replicas: 2`** → Desired pod count. HPA will override this dynamically at runtime.

**`selector.matchLabels`** → The Deployment uses this to track which Pods it manages. Must exactly match pod labels. Uses the minimal `selectorLabels` helper → `app: order-service`.

---

```yaml
  template:
    metadata:
      labels:
        {{- include "microservice.podLabels" . | nindent 8 }}
      annotations:
        {{- if .Values.prometheus.enabled }}
        prometheus.io/scrape: "true"
        prometheus.io/port: "{{ .Values.containerPort }}"
        prometheus.io/path: "{{ .Values.prometheus.path }}"
        {{- end }}
```

**`{{- if .Values.prometheus.enabled }}`** → Helm conditional. The entire annotations block is **only included in the rendered YAML** if this value is `true`. If `false`, zero annotation lines are generated. This is called a **conditional block** — one of Helm's most powerful features.

---

```yaml
    spec:
      serviceAccountName: {{ .Values.serviceAccount.name }}
      securityContext:
        runAsNonRoot: {{ .Values.securityContext.runAsNonRoot }}
        runAsUser: {{ .Values.securityContext.runAsUser }}
        fsGroup: {{ .Values.securityContext.fsGroup }}
```

**`serviceAccountName: kubeflow-ops-sa`** → Every pod gets the IRSA-annotated ServiceAccount — automatic AWS credentials injected, no hardcoded keys.

---

```yaml
      containers:
        - name: {{ .Values.name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - containerPort: {{ .Values.containerPort }}
              name: http       # Naming the port allows other places to reference it by name
              protocol: TCP
```

**`image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"`**
→ Rendered: `image: "123456.dkr.ecr.us-east-1.amazonaws.com/order-service:abc1234"`
This is the line that changes on every CI build.

**`name: http`** on the port → Named ports. Later code references this port as `port: http` instead of `port: 8001`. If the port number ever changes, you update it in ONE place.

---

```yaml
          {{- if .Values.env }}
          env:
            {{- toYaml .Values.env | nindent 12 }}
          {{- end }}
```

**`{{- if .Values.env }}`** → Only add the `env:` block if the env list is not empty. Default [values.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps/user-service/values.yaml:0:0-0:0) has `env: []` which is falsy.

**`{{- toYaml .Values.env | nindent 12 }}`** → `toYaml` converts the env list (a Go/YAML object) back to YAML string format. `nindent 12` indents it 12 spaces (matching depth inside `containers:`). **This is the standard Helm pattern for embedding complex structures from values into templates.**

---

```yaml
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
```
→ Same pattern — converts the full resources block (requests + limits) to YAML.

---

**The three probes — all follow the same pattern:**
```yaml
          startupProbe:
            httpGet:
              path: {{ .Values.probes.startup.path }}
              port: http          # References the named port
            initialDelaySeconds: {{ .Values.probes.startup.initialDelaySeconds }}
            periodSeconds: {{ .Values.probes.startup.periodSeconds }}
            failureThreshold: {{ .Values.probes.startup.failureThreshold }}

          livenessProbe:
            httpGet:
              path: {{ .Values.probes.liveness.path }}
              port: http
            periodSeconds: {{ .Values.probes.liveness.periodSeconds }}
            timeoutSeconds: {{ .Values.probes.liveness.timeoutSeconds }}
            failureThreshold: {{ .Values.probes.liveness.failureThreshold }}

          readinessProbe:
            httpGet:
              path: {{ .Values.probes.readiness.path }}
              port: http
            periodSeconds: {{ .Values.probes.readiness.periodSeconds }}
            timeoutSeconds: {{ .Values.probes.readiness.timeoutSeconds }}
            failureThreshold: {{ .Values.probes.readiness.failureThreshold }}
```
`port: http` → Helm resolves the named port `http` to the actual port number (e.g., 8001) when rendering.

---

```yaml
      {{- if .Values.podAntiAffinity.enabled }}
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 100
              podAffinityTerm:
                labelSelector:
                  matchExpressions:
                    - key: app
                      operator: In
                      values:
                        - {{ .Values.name }}
                topologyKey: kubernetes.io/hostname
      {{- end }}
```

**`preferredDuringSchedulingIgnoredDuringExecution`** → The long name breaks down as:
- **`preferred`** = best-effort, not a hard requirement (won't block scheduling if impossible)
- **`DuringScheduling`** = applied when placing new pods on nodes
- **`IgnoredDuringExecution`** = existing running pods are NOT evicted if rule can't be satisfied later

**`weight: 100`** → Maximum preference score (1–100). Kubernetes scheduler heavily favors this rule.

**`matchExpressions: app In [order-service]`** → Identifies "pods to avoid co-locating with" = other pods with label `app: order-service`. So it says "don't put me on the same node as another pod of the same service."

**`topologyKey: kubernetes.io/hostname`** → "Different topology domain" = different physical/virtual nodes (different hostnames).

---

## 📄 FILE 5: [templates/service.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/charts/microservice/templates/service.yaml:0:0-0:0) — Kubernetes Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ include "microservice.fullname" . }}    # → "order-service"
  namespace: {{ .Values.namespace }}
  labels:
    {{- include "microservice.labels" . | nindent 4 }}
spec:
  type: {{ .Values.service.type }}                 # → "ClusterIP"
  selector:
    {{- include "microservice.selectorLabels" . | nindent 4 }}  # → "app: order-service"
  ports:
    - name: http
      port: {{ .Values.service.port }}             # → 8001 (port you call FROM other services)
      targetPort: http                             # → resolves to 8001 on the pod
      protocol: TCP
```

**`selector: app: order-service`** → The **glue** between Service and Pods. The Service routes traffic to any pod with `app: order-service`. When HPA adds new pods with that label, they're automatically included. When pods with that label die, they're automatically removed.

**`port` vs `targetPort`:**
- `port` → The port external callers use (e.g., `http://order-service:8001`)
- `targetPort` → The port on the actual pod (8001 inside the container)

They're the same here, but they don't have to be. Named `http` resolves to 8001.

**ClusterIP DNS — once this Service exists, any pod inside the cluster can reach `order-service` at:**
```
http://order-service:8001                                       # short (same namespace)
http://order-service.kubeflow-ops:8001                         # with namespace
http://order-service.kubeflow-ops.svc.cluster.local:8001       # fully qualified
```
All three work. Built-in Kubernetes DNS. Zero configuration.

---

## 📄 FILE 6: [templates/hpa.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/charts/microservice/templates/hpa.yaml:0:0-0:0) — Horizontal Pod Autoscaler

```yaml
{{- if .Values.autoscaling.enabled }}    # ← Entire file only rendered if enabled = true
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ include "microservice.fullname" . }}-hpa   # → "order-service-hpa"
  namespace: {{ .Values.namespace }}
  labels:
    {{- include "microservice.labels" . | nindent 4 }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ include "microservice.fullname" . }}   # → tells HPA which Deployment to control
  minReplicas: {{ .Values.autoscaling.minReplicas }}
  maxReplicas: {{ .Values.autoscaling.maxReplicas }}
```

**`scaleTargetRef`** → Points to the Deployment named `order-service`. HPA reads this Deployment's pod metrics and writes back to its `replicas` field. The Deployment doesn't configure HPA — HPA controls the Deployment.

---

```yaml
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: {{ .Values.autoscaling.targetCPUUtilizationPercentage }}
    {{- if .Values.autoscaling.targetMemoryUtilizationPercentage }}
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: {{ .Values.autoscaling.targetMemoryUtilizationPercentage }}
    {{- end }}
```

**`type: Utilization`** → Tracks usage as a percentage of **requests** (not limits). If a pod has `requests.cpu: 100m` and currently uses `70m`, that's 70% utilization.

The memory block uses another conditional — if `targetMemoryUtilizationPercentage` is 0 or not set, only CPU scaling is active.

---

```yaml
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Pods
          value: 1
          periodSeconds: 60       # Remove max 1 pod per 60 seconds
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
        - type: Pods
          value: 4
          periodSeconds: 60       # Add max 4 pods per 60 seconds
{{- end }}
```

`type: Pods` + `value: 1` + `periodSeconds: 60` = "at most 1 pod change per 60 seconds."

The final `{{- end }}` closes the `if autoscaling.enabled` block that opened at line 1. If `enabled: false`, **the entire HPA YAML is completely absent** — no HPA object is created in Kubernetes.

---

## 📄 FILE 7: Per-Service [values.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps/user-service/values.yaml:0:0-0:0) Files

### [gitops/apps/order-service/values.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps/order-service/values.yaml:0:0-0:0) — Service-Specific Config

```yaml
name: order-service       # Overrides "my-service" from chart default
containerPort: 8001       # Real port for this service

image:
  repository: IMAGE_PLACEHOLDER   # Replaced with real ECR URL once after Terraform
  tag: latest                      # ← CI pipeline updates this field on every build

service:
  port: 8001
```

---

```yaml
env:
  - name: DATABASE_URL
    valueFrom:
      secretKeyRef:          # NOT a literal value — reads from a K8s Secret
        name: db-credentials
        key: url             # The DB password NEVER appears in this file or in Git
```

**`secretKeyRef`** — This is how you inject secrets into pods **without putting them in Git**. The DB password lives in AWS Secrets Manager → External Secrets Operator (Phase 8b) automatically creates a K8s Secret called `db-credentials` → this `secretKeyRef` reads the `url` key from that Secret → the pod gets the password as an environment variable.

```yaml
  - name: SQS_QUEUE_URL
    valueFrom:
      configMapKeyRef:       # Reads from a K8s ConfigMap — safe, non-sensitive
        name: app-config
        key: sqs-queue-url
```

**`configMapKeyRef`** — Reads non-sensitive config from a ConfigMap. The SQS URL isn't a secret — it's just a URL.

| Type | Use for | Stored in |
|---|---|---|
| `secretKeyRef` | Passwords, tokens, API keys | K8s Secret (populated by ESO from AWS Secrets Manager) |
| `configMapKeyRef` | URLs, regions, feature flags | K8s ConfigMap (defined in [common/configmap.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps/common/configmap.yaml:0:0-0:0)) |

```yaml
  - name: USER_SERVICE_URL
    value: "http://user-service.kubeflow-ops.svc.cluster.local:8002"
```
→ A **literal value** — the Kubernetes internal DNS address of `user-service`. This is how `order-service` calls `user-service` inside the cluster.

---

### [values-dev.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps/order-service/values-dev.yaml:0:0-0:0) vs [values-prod.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps/order-service/values-prod.yaml:0:0-0:0)

```yaml
# values-dev.yaml — Budget-friendly for development
replicaCount: 1             # One replica is enough for testing (not HA)
resources:
  requests:
    cpu: 50m                # Very small — save money on dev cluster
    memory: 64Mi
  limits:
    cpu: 250m
    memory: 128Mi
autoscaling:
  minReplicas: 1
  maxReplicas: 3            # Dev cluster doesn't need to scale high
```

```yaml
# values-prod.yaml — Production-grade
replicaCount: 3             # 3 replicas = true HA across 3 nodes
resources:
  requests:
    cpu: 200m               # Larger reservation for real traffic
    memory: 256Mi
  limits:
    cpu: 1000m              # Up to 1 full CPU core under load
    memory: 512Mi
autoscaling:
  minReplicas: 3
  maxReplicas: 20           # Can absorb large traffic spikes
```

**How values layers merge** (later files override earlier):
```bash
# ArgoCD runs this internally for dev:
helm template microservice gitops/charts/microservice \
  -f gitops/apps/order-service/values.yaml \      ← Layer 2: service-specific
  -f gitops/apps/order-service/values-dev.yaml    ← Layer 3: env-specific (wins)
# Chart's values.yaml is always Layer 1 (lowest priority)
```

**[user-service/values.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps/user-service/values.yaml:0:0-0:0)** — Simpler, fewer env vars (no SQS, no Redis):
```yaml
name: user-service
containerPort: 8002
env:
  - name: DATABASE_URL     # Only needs database — no SQS, no Redis
    valueFrom:
      secretKeyRef:
        name: db-credentials
        key: url
```

**[notification-service/values.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps/notification-service/values.yaml:0:0-0:0)** — SQS + Redis, no database:
```yaml
name: notification-service
containerPort: 8003
env:
  - name: SQS_QUEUE_URL    # Polls for messages from SQS
    valueFrom:
      configMapKeyRef: ...
  - name: REDIS_URL        # Caches notifications in Redis
    valueFrom:
      configMapKeyRef: ...
  # No DATABASE_URL — notification-service has no PostgreSQL!
```

---

## 📄 FILE 8: [gitops/apps/common/namespace.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps/common/namespace.yaml:0:0-0:0)

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: kubeflow-ops
  labels:
    app.kubernetes.io/part-of: kubeflow-ops
    prometheus.io/scrape: "true"
```

**Why not the `default` namespace?**

In Kubernetes, `default` is the catch-all namespace every tutorial uses. In production, **you never use `default`**. Reasons:

| Reason | Explanation |
|---|---|
| **Isolation** | Everything in `kubeflow-ops` is clearly separated from other apps |
| **RBAC** | Grant permissions per-namespace — teams can't touch each other's apps |
| **Resource Quotas** | Set CPU/memory limits at namespace level |
| **Clean deletion** | Delete the namespace → all resources inside are deleted cleanly |

**`prometheus.io/scrape: "true"` on the namespace** → Prometheus uses this to know which namespaces to watch for pods to scrape.

---

## 📄 FILE 9: [gitops/apps/common/configmap.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps/common/configmap.yaml:0:0-0:0) — Non-Sensitive Configuration

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: kubeflow-ops
data:
  aws-region: "us-east-1"
  sqs-queue-url: "PLACEHOLDER_AFTER_TERRAFORM_APPLY"
  redis-url: "PLACEHOLDER_AFTER_TERRAFORM_APPLY"
```

### 🆕 NEW CONCEPT: ConfigMap

A **ConfigMap** stores **non-sensitive key-value configuration** in Kubernetes. It's like a `.env` file, but stored in the cluster and injected into pods as environment variables.

**Rule of thumb:**
- ✅ **ConfigMap** = non-sensitive (URLs, region names, feature flags, debug levels)
- ❌ **Secret** = sensitive (passwords, API keys, tokens) — handled by ESO in Phase 8b

**`sqs-queue-url: "PLACEHOLDER_AFTER_TERRAFORM_APPLY"`**
→ The SQS URL is only known after `terraform apply` in Phase 5. After apply, you run:
```bash
SQS_URL=$(terraform output -raw sqs_queue_url)
# Update the placeholder in configmap.yaml, commit to Git
# ArgoCD detects the change → updates the ConfigMap → pods restart with new URL
```
The `PLACEHOLDER` text serves as an explicit reminder: "this value is not filled in yet."

---

## 📄 FILE 10: [gitops/apps/common/service-account.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps/common/service-account.yaml:0:0-0:0)

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: kubeflow-ops-sa
  namespace: kubeflow-ops
  annotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::ACCOUNT_ID:role/kubeflow-ops-dev-app-role"
  labels:
    app.kubernetes.io/part-of: kubeflow-ops
```

### 🆕 NEW CONCEPT: IRSA — IAM Roles for Service Accounts

This is one of the most important security concepts in this entire project.

**The problem:** Your pods need to talk to AWS services (SQS, etc.). They need AWS credentials. The old (bad) way: put `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` in environment variables. This is terrible — static keys that never expire, stored in Git, leaked if the pod is compromised.

**IRSA — the correct way:** Pods get **temporary, automatically rotating** AWS credentials through Kubernetes → IAM trust.

**How IRSA works end-to-end:**
```
Phase 5 Terraform:
  → Creates IAM Role with SQS permissions
  → Creates OIDC Provider on the EKS cluster

Phase 6 (this file):
  → Creates K8s ServiceAccount annotated with the IAM Role ARN

At pod startup:
  → EKS sees pod is using "kubeflow-ops-sa"
  → Checks annotation: this SA maps to IAM role X
  → Mints temporary AWS credentials (valid for 1 hour)
  → Injects them into the pod automatically

boto3 in the app:
  → Automatically picks up these credentials
  → Makes SQS API calls without any explicit auth code
  → No keys in code. No keys in Git. Credentials auto-rotate. ✅
```

**`eks.amazonaws.com/role-arn: "arn:aws:iam::ACCOUNT_ID:role/..."`** — This is the magic annotation. After Phase 5 `terraform apply`, you replace `ACCOUNT_ID` with the real value from: `terraform output irsa_order_service_role_arn`.

---

## 📄 FILE 11: [gitops/apps/common/ingress.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps/common/ingress.yaml:0:0-0:0) — The Traffic Router

### 🆕 NEW CONCEPT: Kubernetes Ingress

**The problem:** All 3 services use `ClusterIP` (internal only). External users can't reach them. If you changed each to `LoadBalancer` type, you'd create 3 separate AWS Load Balancers = ~$50/month *each* = expensive.

**The solution: One Ingress** = One Load Balancer + URL path-based routing to all 3 services.

```
Internet
   │
   ▼
[One AWS Application Load Balancer]  ← ~$20/month total
   │
   ▼
[NGINX Ingress Controller]           ← runs as pods inside EKS
   │
   ├── /api/orders/*         → order-service ClusterIP:8001
   ├── /api/users/*          → user-service ClusterIP:8002
   └── /api/notifications/*  → notification-service ClusterIP:8003
```

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: kubeflow-ops-ingress
  namespace: kubeflow-ops
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
    nginx.ingress.kubernetes.io/use-regex: "true"
    nginx.ingress.kubernetes.io/limit-rps: "50"
    nginx.ingress.kubernetes.io/limit-burst-multiplier: "5"
```

**`nginx.ingress.kubernetes.io/rewrite-target: /$2`** — URL rewriting.

When a user calls `/api/orders/123`, the app inside the cluster only knows `/orders/123` (it doesn't have the `/api/orders` prefix — that's the routing prefix, not the app's URL). The `/$2` captures only the second regex group (the `(.*)` part after the prefix) and rewrites the URL before forwarding.

```
External:  /api/orders/123
           ↓ rewrite-target: /$2 (captures "123")
Internal:  /123  → order-service receives this
```

**`use-regex: "true"`** → Enables regex pattern matching in path rules. Required because the paths use capture groups `(/|$)(.*)`.

**`limit-rps: "50"`** → **Rate limiting** at the Ingress level — max 50 requests per second from any single IP Address. Blocks simple DDoS and API abuse *before* it reaches your pods.

**`limit-burst-multiplier: "5"`** → Traffic can burst momentarily to `50 × 5 = 250 req/sec`. Brief spikes (like a user double-clicking) aren't blocked. Sustained traffic above 50 rps from one IP gets dropped with HTTP 429.

---

```yaml
spec:
  ingressClassName: nginx
  rules:
    - http:
        paths:
          - path: /api/orders(/|$)(.*)
            pathType: ImplementationSpecific
            backend:
              service:
                name: order-service
                port:
                  number: 8001
          - path: /api/users(/|$)(.*)
            ...
          - path: /api/notifications(/|$)(.*)
            ...
```

**`ingressClassName: nginx`** → Specifies which Ingress Controller handles this rule. NGINX Ingress Controller is deployed in Phase 7 (via ArgoCD). Without specifying the class, if multiple controllers are installed, they'd all try to handle this Ingress.

**`path: /api/orders(/|$)(.*)`** → Regex breakdown:
- `/api/orders` → literal prefix to match
- `(/|$)` → Group 1: either a `/` or end of string (handles both `/api/orders` and `/api/orders/something`)
- `(.*)` → Group 2: everything after (captured as `$2` for the rewrite)

**`pathType: ImplementationSpecific`** → Means "use the Ingress Controller's own regex interpretation." The other path types (`Exact`, `Prefix`) don't support regex, so you must use this when using regex patterns.

---

## 🔄 The Complete CI → GitOps Flow (Everything Together)

```
Step 1: Developer pushes code to GitHub
                │
                ▼
Step 2: GitHub Actions CI (Phase 4) triggers:
  → pytest tests run and pass
  → docker build → image tagged abc1234
  → Trivy security scan (no CRITICAL CVEs allowed)
  → docker push to ECR (123456.dkr.ecr.us-east-1.amazonaws.com/order-service:abc1234)
  → yq -i '.image.tag = "abc1234"' gitops/apps/order-service/values.yaml
  → git commit -m "ci: update order-service to abc1234"
  → git push
                │
                ▼
Step 3: Git now has a new commit:
  values.yaml changed:  tag: old9999  →  tag: abc1234
                │
                ▼
Step 4: ArgoCD (Phase 7) polls Git every 3 minutes, detects the change
                │
                ▼
Step 5: ArgoCD renders the Helm chart:
  helm template microservice gitops/charts/microservice \
    -f gitops/apps/order-service/values.yaml \
    -f gitops/apps/order-service/values-dev.yaml
  → Produces real Deployment YAML with:
    image: "123456.dkr.ecr.us-east-1.amazonaws.com/order-service:abc1234"
                │
                ▼
Step 6: ArgoCD applies rendered YAML to EKS (like kubectl apply)
                │
                ▼
Step 7: Kubernetes Rolling Update (zero downtime):
  → Starts new pod with abc1234 image
  → Startup probe: passes (app started)
  → Readiness probe: passes (app ready for traffic)
  → Adds new pod to Service (starts receiving traffic)
  → Old pod (old9999) removed from Service
  → Old pod terminated
  → New pod fully live ✅
```

**This entire flow — from git push to live deployment — is 100% automatic. Zero human clicks.**

---

## 🔑 Key DevOps Takeaways from Phase 6

| Pattern | What You Applied |
|---|---|
| **One chart, 3 services** | DRY — maintain 1 template, not 3. Add a 4th service? Copy a values folder. |
| **`image.tag` = deploy trigger** | CI updates 1 field in Git → GitOps deploys automatically |
| **Values layering** | chart → service → environment. Later files override earlier. Compose cleanly |
| **ClusterIP + one Ingress** | One AWS Load Balancer for all services. Cost-efficient |
| **Regex rewrite** | Clean external URLs (`/api/orders/`) → clean internal URLs (`/orders/`) |
| **Rate limiting at Ingress** | DDoS protection before traffic hits your pods |
| **3-probe health model** | Startup (slow starts), Liveness (deadlocks), Readiness (rolling deploys) |
| **HPA with stabilization** | Autoscaling that doesn't flap. Aggressive up, conservative down |
| **Pod Anti-Affinity** | HA guarantee — replicas spread across nodes |
| **SecurityContext** | Non-root pods, enforced at K8s level (Kyverno adds Phase 8 enforcement) |
| **ServiceAccount + IRSA** | Zero static AWS keys anywhere — not in code, not in Git, not in env vars |
| **`secretKeyRef` vs `configMapKeyRef`** | Sensitive → Secret (from AWS SM). Non-sensitive → ConfigMap |
| **Prometheus annotations** | Zero-config auto-discovery by Prometheus |
| **`PLACEHOLDER` values** | Explicit markers — "fill this in after terraform apply" |

---

## ✅ Phase 6 Complete — What's Next

You now have:
- ✅ A shared Helm chart that describes HOW to deploy any microservice
- ✅ Per-service values files with service-specific config (ports, env vars)
- ✅ Per-environment values files (dev = cheap, prod = resilient)
- ✅ Common cluster resources (namespace, configmap, ingress, service account)
- ✅ A CI-friendly design where `image.tag` in Git = a deployment

All of this currently exists as **YAML files in Git**. Nothing has been deployed yet. The cluster is still empty.

**Phase 7: ArgoCD** — This is where it all comes alive. You apply ONE manifest to the cluster manually (`app-of-apps.yaml`), and from that moment forward, every Git commit to `gitops/` automatically renders these Helm charts and deploys them to EKS. **Forever. Automatically. Zero manual `kubectl apply` ever again.** 🚀

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

### User Input

Okay lets start from Phase 7.
You need to explain each thing line by line for devops prespective, Block by block, I only know basic docker terraform and kubernets basic
So any new topic u need to explain in detail as if beginner.If something is developer work no in depth required, NO seperate Artifact, , share it here in this window

### Planner Response

Let me read all the Phase 7 ArgoCD files first.

*Listed directory [platform](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/platform) *

*Listed directory [argocd](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/platform/argocd) *

*Listed directory [applications](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/platform/argocd/applications) *

*Viewed [app-of-apps.yaml](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/platform/argocd/app-of-apps.yaml) *

*Viewed [order-service.yaml](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/platform/argocd/applications/order-service.yaml) *

*Viewed [user-service.yaml](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/platform/argocd/applications/user-service.yaml) *

*Viewed [notification-service.yaml](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/platform/argocd/applications/notification-service.yaml) *

*Viewed [common.yaml](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/platform/argocd/applications/common.yaml) *

*Viewed [kyverno.yaml](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/platform/argocd/applications/kyverno.yaml) *

*Viewed [external-secrets.yaml](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/platform/argocd/applications/external-secrets.yaml) *

*Viewed [prometheus-stack.yaml](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/platform/argocd/applications/prometheus-stack.yaml) *

### Planner Response

I have all the files. Here is the full Phase 7 explanation:

---

# 🚀 Phase 7 — ArgoCD (GitOps Continuous Deployment) — Complete Deep-Dive

---

## 🧠 Big Picture First — What Problem Does Phase 7 Solve?

At the end of Phase 6, you have a folder full of beautiful YAML files (Helm charts, values files). But the EKS cluster is **still empty**. Nothing is deployed. Those files are just text on disk.

The old (manual) way would be:
```bash
helm install order-service gitops/charts/microservice -f values.yaml
helm install user-service ...
kubectl apply -f common/namespace.yaml
# ... and repeat every time anything changes
```

**This is terrible for several reasons:**
- Someone has to do it manually every time
- No one knows what's actually running vs. what's in Git
- Someone runs `kubectl edit` and changes something → now Git and the cluster are out of sync → mystery bugs

### ArgoCD solves all of this permanently

> **ArgoCD is a tool that runs INSIDE your Kubernetes cluster and constantly watches your Git repository. When anything in `gitops/` changes → ArgoCD automatically applies it to the cluster. This is GitOps — Git is the single source of truth.**

```
Git (source of truth)
        │
        │  ArgoCD polls every 3 minutes
        │  (or detects webhooks instantly)
        ▼
ArgoCD (running inside EKS)
        │
        │  Renders Helm → applies YAML
        ▼
EKS Cluster (always matches Git)
```

**If someone manually runs `kubectl edit` and changes something → ArgoCD detects the "drift" → reverts it back to match Git within minutes.** The cluster is always in the state Git says it should be.

---

## 🆕 NEW CONCEPT: The App-of-Apps Pattern

One of the first questions with ArgoCD is: "OK ArgoCD is managing my apps — but who manages ArgoCD's own config? Who tells ArgoCD what to watch?"

**The App-of-Apps pattern solves this:**

```
You apply ONE YAML manually (just once):
gitops/platform/argocd/app-of-apps.yaml
        │
        ▼
This creates the PARENT ArgoCD Application
        │
        │ Parent watches: gitops/platform/argocd/applications/
        ▼
ArgoCD automatically finds and applies all CHILD Application YAMLs:
├── order-service.yaml       → deploys order-service
├── user-service.yaml        → deploys user-service
├── notification-service.yaml → deploys notification-service
├── common.yaml              → deploys namespace, configmap, ingress
├── prometheus-stack.yaml    → deploys Prometheus + Grafana
├── kyverno.yaml             → deploys Kyverno security policies
└── external-secrets.yaml    → deploys External Secrets Operator
```

**The brilliant part:** When you later add a new application (say `payment-service.yaml`) to the `applications/` folder and push to Git → the parent App automatically detects the new child YAML and deploys it. **Zero manual steps. Self-expanding.**

---

## 📁 Folder Structure for Phase 7

```
gitops/platform/argocd/
├── app-of-apps.yaml              ← YOU apply this ONCE manually (bootstrap)
└── applications/                 ← Parent watches this folder forever after
    ├── common.yaml               ← Deploys namespace, configmap, ingress, SA
    ├── order-service.yaml        ← Deploys order-service via Helm
    ├── user-service.yaml         ← Deploys user-service via Helm
    ├── notification-service.yaml ← Deploys notification-service via Helm
    ├── prometheus-stack.yaml     ← Deploys monitoring stack via Helm
    ├── kyverno.yaml              ← Deploys security policy engine via Helm
    └── external-secrets.yaml    ← Deploys secrets sync operator via Helm
```

---

## 🆕 NEW CONCEPT: ArgoCD Installation (One-Time Bootstrap)

Before any of the files above apply, ArgoCD itself needs to be installed into the cluster. This is done **manually once**:

```bash
# Step 1: Create the namespace ArgoCD lives in
kubectl create namespace argocd

# Step 2: Install ArgoCD using its official manifest
kubectl apply -n argocd -f \
  https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

**`kubectl create namespace argocd`**
→ ArgoCD always runs in a dedicated namespace called `argocd`. It's an isolation convention — ArgoCD's own pods don't mix with your application pods.

**`kubectl apply -n argocd -f <url>`**
→ Downloads ArgoCD's official YAML (has ~4000 lines: Deployments, Services, CRDs, RBAC rules, etc.) and applies it to the cluster. ArgoCD's pods start up inside the `argocd` namespace.

What gets installed:
- `argocd-server` → the API + Web UI pod
- `argocd-repo-server` → pod that clones Git repos and renders Helm charts
- `argocd-application-controller` → pod that compares cluster state vs. Git state and syncs
- `argocd-redis` → internal caching for ArgoCD itself

```bash
# Step 3: Apply the root App-of-Apps (ONE TIME ONLY)
kubectl apply -f gitops/platform/argocd/app-of-apps.yaml
```

**After this one command, everything is automatic forever.** ArgoCD manages itself and all your apps.

---

## 📄 FILE 1: [gitops/platform/argocd/app-of-apps.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/platform/argocd/app-of-apps.yaml:0:0-0:0) — The Root Application

This is the **single most important file in Phase 7**. It's the trigger that bootstraps the entire GitOps system.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
```

### 🆕 NEW CONCEPT: ArgoCD CRDs — Custom Resource Definitions

You know `kind: Deployment` and `kind: Service` from Kubernetes. But `kind: Application` is **not** a standard Kubernetes resource — it's a **Custom Resource Definition (CRD)** that ArgoCD adds to Kubernetes when it's installed.

**What is a CRD?**
A CRD lets you **extend Kubernetes with your own resource types**. After ArgoCD is installed, Kubernetes understands `kind: Application` just like it understands `kind: Deployment`. You can `kubectl get applications -n argocd` just like `kubectl get pods`.

This is a very powerful Kubernetes concept — many tools (ArgoCD, Kyverno, External Secrets, Prometheus) work by adding their own custom resource types.

---

```yaml
metadata:
  name: kubeflow-ops-root      # Name of the parent Application
  namespace: argocd            # ArgoCD resources always go in the 'argocd' namespace
  finalizers:
    - resources-finalizer.argocd.argoproj.io
```

**`name: kubeflow-ops-root`**
→ The name of this ArgoCD Application. You'll see this in the ArgoCD UI as a named app. "root" signals that this is the parent managing all others.

**`namespace: argocd`**
→ All ArgoCD `Application` resources must live in the `argocd` namespace. This is how ArgoCD's controller finds and tracks them.

**`finalizers: - resources-finalizer.argocd.argoproj.io`**
→ A **finalizer** is a Kubernetes mechanism that runs cleanup before a resource is deleted.

Without this finalizer: If you delete this Application object → ArgoCD stops tracking it, but all the child Deployments, Services, ConfigMaps, etc. it created in the cluster **stay running** (orphaned resources).

With this finalizer: If you delete this Application → ArgoCD first **cascades the deletion** — deletes all child ArgoCD Applications it managed, which in turn delete all Kubernetes resources they deployed. Clean teardown.

> **Think of it as: checking out of a hotel.** Without a finalizer, you leave but all your stuff stays in the room. With it, everything is cleaned up before you leave.

---

```yaml
spec:
  project: default
```

**`project: default`**
→ ArgoCD has a concept of **Projects** for multi-team clusters — you can create projects with restrictions (e.g., "team-A can only deploy to namespace `payments`"). `default` is the built-in project with no restrictions. For a single-team setup, `default` is perfectly fine.

---

```yaml
  source:
    repoURL: https://github.com/YOUR_USERNAME/kubeflow-ops.git
    targetRevision: main
    path: gitops/platform/argocd/applications
```

**`source:`** → This block tells ArgoCD where to find the YAML files to apply.

**`repoURL: https://github.com/YOUR_USERNAME/kubeflow-ops.git`**  
→ The Git repository to watch. ArgoCD clones this repo (the `argocd-repo-server` pod does the cloning). You must replace `YOUR_USERNAME` with your actual GitHub username. ArgoCD also needs read access to this repo — for public repos it works as-is; for private repos you register an SSH key or token in ArgoCD.

**`targetRevision: main`**  
→ Which branch to track. When CI pushes new commits to `main`, ArgoCD detects it. Tip: in production you might point this to a `release` branch so you control exactly when changes take effect.

**`path: gitops/platform/argocd/applications`**  
→ The folder inside the repo that contains the YAML files to apply. ArgoCD will apply **every YAML file** it finds in this folder. So every [.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps/common/ingress.yaml:0:0-0:0) file in `applications/` becomes a child ArgoCD Application.

---

```yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
```

**`destination:`** → Where to deploy what ArgoCD finds in the `source`.

**`server: https://kubernetes.default.svc`**  
→ This is the Kubernetes API server address — the special internal DNS name that points to the cluster's own API server. It means "deploy to the **same cluster** ArgoCD is running in." ArgoCD can also manage **remote clusters** (by registering their API server URLs), but for this project everything is in one cluster.

**`namespace: argocd`**  
→ Where to create the child `Application` resources. Since child Application YAMLs are themselves `kind: Application`, they go in `argocd` namespace.

> **Important distinction:** `destination.namespace` here = where the Application *objects* go (argocd). Each child Application separately defines where its *workloads* go (e.g., `kubeflow-ops` namespace for the services).

---

```yaml
  syncPolicy:
    automated:
      selfHeal: true
      prune: true
    syncOptions:
      - CreateNamespace=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```

**`syncPolicy:`** → How ArgoCD reacts to changes and drift. This is one of the most important sections.

**`automated:`** → Enables **automatic sync**. Without `automated`, ArgoCD only detects changes and tells you ("OutOfSync"), but you'd have to click "Sync" manually in the UI. With `automated`, it syncs **automatically** when it detects changes.

---

**`selfHeal: true`** → 🔑 **This is the GitOps enforcement mechanism.**

Scenario:
1. Git says `replicas: 2`
2. An engineer panics during an incident, runs `kubectl scale deployment order-service --replicas=10`
3. Without selfHeal: cluster has 10 replicas, Git says 2 → permanent drift, nobody notices
4. **With selfHeal:** ArgoCD detects within minutes "cluster differs from Git" → reverts to `replicas: 2` → Git wins, always

This is what enforces the "Git is the single source of truth" principle. If you want to change replicas, you **must** change [values.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps/user-service/values.yaml:0:0-0:0) in Git. Then ArgoCD picks it up. No more direct `kubectl` edits in production ever.

---

**`prune: true`** → Handles deletions.

Scenario:
1. You delete [order-service.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/platform/argocd/applications/order-service.yaml:0:0-0:0) from `gitops/platform/argocd/applications/`
2. Without prune: ArgoCD ignores the deletion. The order-service Application object + all its Pods/Services stay in the cluster forever (orphaned).
3. **With prune:** ArgoCD detects the YAML is gone from Git → deletes the ArgoCD Application → which (via its own finalizer) deletes all Pods, Services, ConfigMaps the service owned → clean removal.

---

**`CreateNamespace=true`** (under `syncOptions`)  
→ If the target namespace doesn't exist when ArgoCD tries to sync, it auto-creates it. Without this, syncs would fail with "namespace not found" if you haven't pre-created namespaces.

---

**`retry:` block:**
```yaml
retry:
  limit: 5          # Try syncing up to 5 times if it fails
  backoff:
    duration: 5s    # Wait 5s before first retry
    factor: 2       # Double the wait time each retry (exponential backoff)
    maxDuration: 3m # Never wait more than 3 minutes between retries
```

→ **Exponential backoff** means the retry waits grow: 5s → 10s → 20s → 40s → 80s (capped at 3m). This prevents ArgoCD from hammering a temporarily unavailable API server with rapid retries.

**`limit: 5`** → After 5 failed sync attempts, ArgoCD marks the app as `SyncFailed` and stops retrying — letting the team investigate. Infinite retries would hide real problems.

---

## 📄 FILE 2: `applications/common.yaml` — Common Resources Application

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: common-resources
  namespace: argocd
  labels:
    type: infrastructure         # Label for grouping in ArgoCD UI
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/YOUR_USERNAME/kubeflow-ops.git
    targetRevision: main
    path: gitops/apps/common     # ← Plain YAML folder (not Helm)
  destination:
    server: https://kubernetes.default.svc
    namespace: kubeflow-ops
  syncPolicy:
    automated:
      selfHeal: true
      prune: true
    syncOptions:
      - CreateNamespace=true
```

**`type: infrastructure`** label → ArgoCD UI lets you filter apps by label. This groups `common-resources` separately from application deployments in the dashboard.

**`source.path: gitops/apps/common`**  
→ Points to the `common/` folder with plain YAML files (namespace, configmap, ingress, service-account). This is **NOT using Helm** — just plain Kubernetes YAML. ArgoCD handles both: plain YAML folders and Helm charts.

**`destination.namespace: kubeflow-ops`**  
→ All common resources (namespace, configmap, ingress, service account) get created in `kubeflow-ops`. Note: the namespace resource itself (`namespace.yaml`) creates `kubeflow-ops` — ArgoCD applies it before applying the other files.

**`selfHeal: true` + `prune: true`** → Same behavior as the parent. If someone manually edits the ConfigMap in the cluster (e.g., changes the SQS URL directly), ArgoCD reverts it. The only way to change config is to edit `configmap.yaml` in Git.

---

## 📄 FILE 3: `applications/order-service.yaml` — The Helm Multi-Source App

This is the most complex ArgoCD Application type in this project, and the most important one to understand:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: order-service
  namespace: argocd
  labels:
    type: application
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  sources:              # ← NOTE: "sources" (plural), not "source" (singular)
    - repoURL: https://github.com/YOUR_USERNAME/kubeflow-ops.git
      targetRevision: main
      ref: repo         # ← This source is just a reference alias, not deployed
    - repoURL: https://github.com/YOUR_USERNAME/kubeflow-ops.git
      targetRevision: main
      path: gitops/charts/microservice
      helm:
        valueFiles:
          - $repo/gitops/apps/order-service/values.yaml
          - $repo/gitops/apps/order-service/values-dev.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: kubeflow-ops
  syncPolicy:
    automated:
      selfHeal: true
      prune: true
    syncOptions:
      - CreateNamespace=true
```

### 🆕 NEW CONCEPT: Multi-Source in ArgoCD

This is a **newer ArgoCD feature** (v2.6+) that solves a specific problem.

**The problem with single-source Helm:**
When ArgoCD deploys a Helm chart, it needs both:
1. The **chart files** (the templates in `gitops/charts/microservice/`)
2. The **values files** (in `gitops/apps/order-service/`)

In ArgoCD's old single-source mode, the chart and values had to be in the same folder. That's why multi-source exists — to reference files from different paths in the same repo.

**How Multi-Source works here:**

```yaml
sources:
  # SOURCE 1 — Reference only (no deployment)
  - repoURL: https://github.com/YOUR_USERNAME/kubeflow-ops.git
    targetRevision: main
    ref: repo            # ← This names this source as "$repo"
```

**`ref: repo`** — This source is **not deployed**. It's just registering the repo under the alias `$repo`. This alias is then used in Source 2 to reference files from it.

```yaml
  # SOURCE 2 — The actual Helm deployment
  - repoURL: https://github.com/YOUR_USERNAME/kubeflow-ops.git
    targetRevision: main
    path: gitops/charts/microservice    # ← The Helm chart (templates)
    helm:
      valueFiles:
        - $repo/gitops/apps/order-service/values.yaml      # ← Layer 1 values
        - $repo/gitops/apps/order-service/values-dev.yaml  # ← Layer 2 values (overrides)
```

**`path: gitops/charts/microservice`** — ArgoCD clones the repo and uses this folder as the Helm chart root (it reads `Chart.yaml` here).

**`valueFiles: [$repo/...]`** — ArgoCD passes these values files to Helm when rendering. The `$repo` alias resolves to the repo registered in Source 1. Values are merged: `values.yaml` first, then `values-dev.yaml` overrides on top.

**What ArgoCD does internally (simplified):**
```bash
# This is what ArgoCD's repo-server effectively runs:
helm template order-service gitops/charts/microservice \
  -f gitops/apps/order-service/values.yaml \
  -f gitops/apps/order-service/values-dev.yaml
# → Produces real Kubernetes YAML
# → Applies it to EKS (like kubectl apply)
```

**`destination.namespace: kubeflow-ops`** → The Deployment, Service, HPA — all go into `kubeflow-ops` namespace.

---

**`user-service.yaml` and `notification-service.yaml`** are identical in structure — just different names, ports, and value file paths. No need to repeat — you've seen the pattern.

---

## 📄 FILE 4: `applications/kyverno.yaml` — Deploying from an External Helm Repo

```yaml
spec:
  project: default
  source:
    repoURL: https://kyverno.github.io/kyverno/   # ← External Helm repository
    chart: kyverno                                  # ← Chart name in that repo
    targetRevision: 3.2.7                          # ← Exact chart version to use
    helm:
      releaseName: kyverno
  destination:
    server: https://kubernetes.default.svc
    namespace: kyverno                              # ← Own namespace, not kubeflow-ops
  syncPolicy:
    automated:
      selfHeal: true
      prune: true
    syncOptions:
      - CreateNamespace=true
      - ServerSideApply=true                       # ← Required for CRDs
```

### 🆕 NEW CONCEPT: External Helm Repository Source

So far you've seen ArgoCD deploying from **your own Git repo** (Path-based source). This is different — deploying from a **Helm chart repository** (like ArtifactHub).

A Helm chart repository is a URL that hosts packaged `.tgz` Helm charts, like a registry for Kubernetes apps. `https://kyverno.github.io/kyverno/` is Kyverno's official chart repo.

| Field | Purpose |
|---|---|
| `repoURL` | URL of the Helm repository |
| `chart` | Name of the chart inside that repository |
| `targetRevision` | **Exact pinned version** — critical! Never use `latest` |

**`targetRevision: 3.2.7`** — Always pin the exact version. If you use `latest` or a range, a Kyverno update could break your cluster silently. With `3.2.7`, you only upgrade when you consciously change this number and push to Git — and ArgoCD will do the upgrade automatically.

**`releaseName: kyverno`** — The Helm release name. Used for tracking resources belonging to this Helm install.

**`destination.namespace: kyverno`** — Kyverno gets its own isolated namespace, separate from your app workloads.

---

**`ServerSideApply=true`** → 🆕 NEW CONCEPT

Kubernetes has two ways to apply YAML:
- **Client-Side Apply** (default, the old `kubectl apply`): The client computes diffs and sends the full object
- **Server-Side Apply** (SSA): The Kubernetes API server computes the diff. Smarter for CRDs

**Why is SSA required for Kyverno?**
Kyverno installs **CRDs (Custom Resource Definitions)** — very large YAML objects that define new Kubernetes resource types. Client-side apply has a size limit on annotations (~250KB) — CRD objects can exceed this, causing apply errors. Server-Side Apply bypasses this limitation.

**Rule of thumb:** Any ArgoCD app that installs CRDs (Kyverno, External Secrets, Prometheus stack, cert-manager) should use `ServerSideApply=true`.

---

## 📄 FILE 5: `applications/external-secrets.yaml` — External Secrets Operator

```yaml
spec:
  source:
    repoURL: https://charts.external-secrets.io/  # External Secrets' own Helm repo
    chart: external-secrets
    targetRevision: 0.10.7                         # Pinned version
    helm:
      releaseName: external-secrets
  destination:
    namespace: external-secrets                    # Own namespace
  syncPolicy:
    automated:
      selfHeal: true
      prune: true
    syncOptions:
      - CreateNamespace=true
      - ServerSideApply=true                       # Required — installs CRDs
```

Same pattern as Kyverno — external Helm repo, exact version pinned, own namespace, ServerSideApply for CRDs.

**Why is External Secrets Operator deployed via ArgoCD and not manually?**
By deploying ESO via ArgoCD, if the ESO pod crashes or is accidentally deleted, ArgoCD automatically reinstalls it. The entire platform is self-healing through ArgoCD.

---

## 📄 FILE 6: `applications/prometheus-stack.yaml` — Monitoring Stack with Inline Values

This is the most complex Application file. Let's go through it block by block:

```yaml
spec:
  source:
    repoURL: https://prometheus-community.github.io/helm-charts
    chart: kube-prometheus-stack
    targetRevision: 65.1.0
    helm:
      releaseName: prometheus-stack
      values: |                  # ← Inline Helm values (not a separate file)
        ...
```

**`chart: kube-prometheus-stack`** — This is a large community Helm chart that bundles **5 tools in one**:
- **Prometheus** → collects metrics from all pods (scrapes `/metrics` every 15s)
- **Grafana** → visualization dashboards
- **Alertmanager** → routes alerts to Slack/email/PagerDuty
- **node-exporter** → collects CPU/memory/disk metrics from the underlying EC2 nodes  
- **kube-state-metrics** → exposes metrics about Kubernetes objects (pod counts, deployment status, etc.)

**`values: |`** → The `|` character in YAML means a **literal block scalar** — everything indented below it is treated as a raw string (the Helm values). Instead of pointing to a separate `values.yaml` file, this embeds the values **inline** inside the ArgoCD Application YAML.

When to use inline values vs. a file? Inline is fine when the values are short. For large customizations, use a `valueFiles:` reference to a separate file.

---

### Block-by-Block: The Inline Helm Values

```yaml
        grafana:
          enabled: true
          adminPassword: "admin"   # ← CHANGE THIS in production!
          sidecar:
            dashboards:
              enabled: true
              searchNamespace: ALL
```

**`grafana.enabled: true`** — Enables Grafana deployment. (You could set `false` to deploy Prometheus-only).

**`adminPassword: "admin"`** — Default admin password for Grafana UI. In production, use External Secrets to inject a real password from AWS Secrets Manager. The comment explicitly says "Change this!"

**`sidecar.dashboards.enabled: true`** + **`searchNamespace: ALL`**  
→ Grafana has a **sidecar pattern** — a small helper container that watches all namespaces for `ConfigMap` objects with the label `grafana_dashboard: "1"`. If it finds one, it automatically loads the JSON dashboard inside into Grafana. This allows teams to add Grafana dashboards by creating a ConfigMap in Git → ArgoCD applies it → Grafana auto-loads the dashboard. No manual Grafana UI clicking.

---

```yaml
        prometheus:
          prometheusSpec:
            retention: 7d
            storageSpec:
              volumeClaimTemplate:
                spec:
                  accessModes: ["ReadWriteOnce"]
                  resources:
                    requests:
                      storage: 10Gi
```

**`retention: 7d`** — How long Prometheus keeps metric data. After 7 days, old data is deleted to free disk space. Adjust based on your compliance and debugging needs. Long retention = more storage cost.

**`storageSpec.volumeClaimTemplate`** → 🆕 NEW CONCEPT: **PersistentVolumeClaim (PVC)**

By default, Prometheus stores metrics data **in-memory or in node-local disk**. If the Prometheus pod restarts, all metric history is lost. A PVC (Persistent Volume Claim) requests **permanent storage** from the cluster.

On AWS EKS, a PVC automatically provisions an **EBS (Elastic Block Store) volume** — a persistent disk that survives pod restarts. When the Prometheus pod restarts, it remounts the same EBS volume and retains all historical metrics.

```
storageSpec.volumeClaimTemplate:
  accessModes: ["ReadWriteOnce"]   ← Only one pod can write at a time (EBS limitation)
  storage: 10Gi                    ← Request a 10 GB EBS volume
```

**`ReadWriteOnce`** — EBS volumes can only be mounted by ONE pod on ONE node at a time. This is the standard for stateful apps with persistent storage.

---

```yaml
            serviceMonitorSelectorNilUsesHelmValues: false
            podMonitorSelectorNilUsesHelmValues: false
```

These two fields control **how Prometheus discovers what to scrape**.

### 🆕 NEW CONCEPT: ServiceMonitor vs. Annotation-Based Scraping

Prometheus has two ways to discover scrape targets:

**Method 1 (what this project uses): Annotation-based**  
You add annotations to pods:
```yaml
prometheus.io/scrape: "true"
prometheus.io/port: "8001"
prometheus.io/path: "/metrics"
```
Prometheus finds these pods automatically. Simple, no extra resources needed.

**Method 2 (enterprise approach): ServiceMonitor CRDs**  
Instead of annotations, you create `ServiceMonitor` Kubernetes objects (another CRD). More powerful but more complex.

**`serviceMonitorSelectorNilUsesHelmValues: false`** + **`podMonitorSelectorNilUsesHelmValues: false`**  
→ When set to `false`, Prometheus watches for `ServiceMonitor` and `PodMonitor` objects **across ALL namespaces**, not just the ones labelled with specific Helm values. This means: any namespace can add a `ServiceMonitor` and Prometheus will automatically pick it up. **Maximum flexibility.**

---

```yaml
        alertmanager:
          enabled: true
          alertmanagerSpec:
            storage:
              volumeClaimTemplate:
                spec:
                  accessModes: ["ReadWriteOnce"]
                  resources:
                    requests:
                      storage: 2Gi
```

**`alertmanager.enabled: true`** — Deploys Alertmanager, the routing engine for alerts.

**`storage: 2Gi`** — Alertmanager also gets a PVC (2GB) to persist its silence rules and alert state across restarts. Without it, if Alertmanager restarts during an incident, all silence rules are lost.

---

```yaml
  destination:
    namespace: observability     # Not kubeflow-ops — its own namespace
  syncPolicy:
    automated:
      selfHeal: true
      prune: true
    syncOptions:
      - CreateNamespace=true
      - ServerSideApply=true    # Required — kube-prometheus-stack installs many CRDs
```

**`namespace: observability`** — The monitoring stack gets its own namespace. Separation of concerns: `kubeflow-ops` = your apps. `observability` = monitoring tools. `argocd` = GitOps tool. `kyverno` = security tool. Each concern in its own namespace.

**`ServerSideApply=true`** — `kube-prometheus-stack` installs many CRDs (PrometheusRule, ServiceMonitor, Alertmanager, etc.) and is notorious for hitting client-side apply size limits. SSA is mandatory.

---

## 🔄 The Complete ArgoCD Lifecycle (End-to-End Picture)

```
BOOTSTRAP (one time only):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
kubectl create namespace argocd
kubectl apply -n argocd -f https://...argocd/install.yaml
kubectl apply -f gitops/platform/argocd/app-of-apps.yaml
                    │
                    ▼
ArgoCD reads app-of-apps.yaml
  → Watches: gitops/platform/argocd/applications/
  → Finds: order-service.yaml, user-service.yaml, etc.
  → Creates ArgoCD Application objects for each
  → Each Application syncs its own resources to EKS

STEADY STATE (automatic forever):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Every 3 minutes (or on webhook):
  ArgoCD polls GitHub
  → No changes? Sleep.
  → Change detected (e.g., image.tag updated by CI)?
      → Render Helm chart with new values
      → Apply diff to EKS
      → Kubernetes rolling update
      → Zero downtime

DRIFT PROTECTION (continuous):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Someone runs: kubectl scale deployment order-service --replicas=10
ArgoCD detects: "Cluster has 10 replicas, Git says 2 — DRIFT!"
ArgoCD reverts: Sets replicas back to 2
Log shows: "SelfHeal triggered for order-service"

ADDING A NEW SERVICE (no manual steps):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Create gitops/apps/payment-service/values.yaml
2. Create gitops/platform/argocd/applications/payment-service.yaml
3. git commit + git push
4. ArgoCD (parent) detects new file in applications/
5. Creates ArgoCD Application for payment-service
6. payment-service is deployed to EKS
→ ZERO manual kubectl commands
```

---

## 🆕 NEW CONCEPT: ArgoCD Application States

When you look at the ArgoCD UI, each Application shows a **Sync Status** and **Health Status**. Understanding these is essential for operations:

### Sync Status (Does cluster match Git?)

| Status | Meaning | Action |
|---|---|---|
| **Synced** | Cluster matches Git exactly ✅ | Nothing to do |
| **OutOfSync** | Cluster differs from Git | ArgoCD is about to sync (or needs manual sync if `automated` is off) |
| **Unknown** | ArgoCD can't determine state | Check ArgoCD's own logs |

### Health Status (Is what's deployed actually working?)

| Status | Meaning | What to check |
|---|---|---|
| **Healthy** | All resources running fine ✅ | Nothing |
| **Progressing** | Deployment is rolling out | Normal during deployments |
| **Degraded** | Something is wrong | Pod crashlooping? Check logs |
| **Missing** | Resources don't exist | Sync hasn't run yet |
| **Suspended** | Auto-sync is paused | Intentional pause |

---

## 🔑 Key DevOps Takeaways from Phase 7

| Concept | What You Applied | Why It Matters |
|---|---|---|
| **GitOps** | Git = single source of truth | No manual `kubectl apply` ever again |
| **App-of-Apps** | One parent manages all child apps | Adding new apps is one Git commit |
| **`selfHeal: true`** | Cluster always reverts to Git state | Prevents config drift from manual changes |
| **`prune: true`** | Deleted from Git = deleted from cluster | Clean teardown, no orphaned resources |
| **Finalizers** | Cascade deletion when app is removed | No orphaned pods/services after teardown |
| **External Helm repos** | Deploy Kyverno/ESO/Prometheus from official charts | No copy-pasting 10,000 line YAMLs |
| **Pinned versions** | `targetRevision: 3.2.7` (not latest) | Upgrades only when YOU decide, never automatic surprises |
| **`ServerSideApply`** | Required for CRDs | Avoids annotation size limits |
| **Retry + Backoff** | Exponential retry on sync failure | Self-recovering from transient errors |
| **Multi-source** | Chart templates + values from same repo | Clean separation of shared chart from per-service config |
| **Own namespaces per tool** | `argocd`, `kyverno`, `observability` | Isolation, RBAC, clean organization |
| **PVC for stateful apps** | Prometheus + Alertmanager get EBS volumes | Metric history survives pod restarts |

---

## ✅ Phase 7 Complete — What's Next

After Phase 7, your cluster looks like this:
- ✅ ArgoCD is managing everything — Git is in full control
- ✅ All 3 microservices are deployed and running (order, user, notification)
- ✅ Common resources live (namespace, configmap, ingress, service account)
- ✅ Prometheus + Grafana + Alertmanager are running in `observability` namespace
- ✅ Kyverno is installed in `kyverno` namespace (but no *policies* yet — those come in Phase 8)
- ✅ External Secrets Operator is installed (but not configured yet — that's also Phase 8)

**Phase 8: Security Layer** — Kyverno is installed but has no rules yet. You'll now write the Kyverno `ClusterPolicy` resources that block root containers, block pods without resource limits, block `:latest` tags, etc. And you'll configure External Secrets Operator to sync DB passwords from AWS Secrets Manager into Kubernetes Secrets. 🛡️

*Edited relevant file*

*Edited relevant file*

### User Input

Okay lets start from Phase 8.
You need to explain each thing line by line for devops prespective, Block by block, I only know basic docker terraform and kubernets basic
So any new topic u need to explain in detail as if beginner.If something is developer work no in depth required, NO seperate Artifact, , share it here in this window

### Planner Response

Let me read all the Phase 8 files first.

*Listed directory [kyverno](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/platform/kyverno) *

*Listed directory [external-secrets](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/platform/external-secrets) *

*Viewed [policies.yaml](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/platform/kyverno/policies.yaml) *

*Viewed [secrets.yaml](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/platform/external-secrets/secrets.yaml) *

### Planner Response

I have all the files. Here's the complete Phase 8 explanation:

---

# 🛡️ Phase 8 — Security Layer — Complete Deep-Dive

**Phase 8 has two parts:**
- **8a — Kyverno:** Policy engine that enforces security rules BEFORE anything runs
- **8b — External Secrets Operator (ESO):** Syncs secrets FROM AWS Secrets Manager INTO Kubernetes automatically

---

## 🧠 Big Picture First — Why Does Phase 8 Exist?

At the end of Phase 7, ArgoCD is happily deploying whatever YAML it finds in Git. **But what if someone pushes bad YAML?**

For example:
- A developer forgets to set resource limits → pod eats the whole node
- Someone accidentally uses `image: myapp:latest` → you don't know what's running
- CI deploys an image running as `root` inside the container
- A developer commits a DB password directly to [values.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps/user-service/values.yaml:0:0-0:0)

**Phase 8 builds automated enforcement at two layers:**

```
LAYER 1: Kyverno (Phase 8a)
  → Intercepts EVERY kubectl apply / ArgoCD sync
  → Checks: "Does this YAML comply with our security rules?"
  → If NO → REJECT the deployment with a clear error message
  → If YES → Allow through

LAYER 2: External Secrets Operator (Phase 8b)
  → Bridges AWS Secrets Manager ↔ Kubernetes Secrets
  → DB passwords NEVER enter Git or any YAML file
  → Kubernetes pods get fresh, auto-rotating credentials automatically
```

---

# 🔐 PHASE 8a — Kyverno: Policy-as-Code

## 🆕 NEW CONCEPT: What is Kyverno?

You know how in code reviews, a human reviews PRs and catches issues like "you forgot error handling" or "this function is too complex"? Kyverno is **automated code review for Kubernetes YAML** — but instead of suggestions, it blocks bad deployments.

**How Kyverno Works (the admission webhook mechanism):**

```
Developer/ArgoCD runs: kubectl apply / kubectl create
                              │
                              ▼
              Kubernetes API Server
                              │
                              │ "Wait, before I apply this..."
                              │ "Let me check with Kyverno first"
                              ▼
              ┌─────────────────────────────┐
              │    Kyverno Admission        │
              │    Webhook                  │
              │                             │
              │  Check Policy 1: latest?    │
              │  Check Policy 2: limits?    │
              │  Check Policy 3: labels?    │
              │  Check Policy 4: privileged?│
              └─────────────────────────────┘
                              │
               ┌──────────────┴──────────────┐
               │                             │
           COMPLIANT                    VIOLATES POLICY
               │                             │
               ▼                             ▼
      Kubernetes applies it         Error returned:
      (pod gets created)            "Image tag 'latest' is not allowed"
                                    Deployment BLOCKED
```

**`Admission Webhook`** — This is the technical name for the interception point. Kubernetes has a feature where external tools can register themselves to be called before any resource is created/updated. Kyverno registers as an "admission webhook" — giving it the power to approve or deny any incoming resource.

> **Real-world analogy:** Think of Kyverno as airport security. The Kubernetes API Server is the gate to your flight. Before ANY pod can "board" the cluster, it must pass through the Kyverno scanner. If it violates policy, it doesn't get through — no exceptions.

---

## 📄 FILE: [gitops/platform/kyverno/policies.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/platform/kyverno/policies.yaml:0:0-0:0)

This one file contains **4 separate Kubernetes resources** separated by `---` (the YAML document separator).

---

### 🆕 NEW CONCEPT: `kind: ClusterPolicy`

Just like `kind: Application` was ArgoCD's custom resource, **`kind: ClusterPolicy`** is Kyverno's custom resource — added to Kubernetes when Kyverno is installed (in Phase 7 via ArgoCD).

**`Cluster` in the name = cluster-wide.** It applies to ALL namespaces, not just one. Compare this to a namespaced `Policy` that only applies within one namespace.

---

## 📄 POLICY 1 — `disallow-latest-tag` — Block `:latest` Image Tags

```yaml
apiVersion: kyverno.io/v1           # Kyverno's API version (like argoproj.io/v1alpha1)
kind: ClusterPolicy                  # Cluster-wide policy (all namespaces)
metadata:
  name: disallow-latest-tag
  annotations:
    policies.kyverno.io/title: Disallow Latest Tag
    policies.kyverno.io/severity: medium
    policies.kyverno.io/description: >-
      Using the 'latest' tag is dangerous because it's mutable.
      Always use a specific version or commit SHA.
```

**`apiVersion: kyverno.io/v1`** → Kyverno's own API group. Just like `apps/v1` means "managed by Kubernetes apps controller", `kyverno.io/v1` means "managed by Kyverno controller."

**`annotations` block** → These are **metadata for humans and Kyverno's own policy library UI**. `severity: medium` doesn't change enforcement — it's just labelling. Kyverno has a Policy Reporter tool that uses these annotations to generate compliance dashboards.

**`>-`** in YAML = **block scalar folded style** — multi-line string converted to a single line (newlines → spaces). Just a YAML way to write long strings nicely.

---

```yaml
spec:
  validationFailureAction: Enforce   # ← THE KEY DECISION
  background: true
```

### 🆕 NEW CONCEPT: `validationFailureAction` — Enforce vs Audit

This is **the most important field in any Kyverno policy.** Two options:

| Mode | What happens on violation | When to use |
|---|---|---|
| **`Enforce`** | Deployment is **BLOCKED**. Hard rejection. | When you're confident the policy is correct and want zero exceptions |
| **`Audit`** | Deployment goes through but **violation is LOGGED** in a report | When you're introducing a new policy and don't want to break things first |

**Best practice for introducing new policies:**
1. Start with `Audit` → run for 1 week → see what would have been blocked
2. Fix any legitimate violations
3. Switch to `Enforce`

**`background: true`** → Kyverno checks existing resources in the cluster, not just new ones being admitted. Without this, a policy only applies to future deployments, not what's already running. With `true`, Kyverno scans existing pods and reports violations.

---

```yaml
  rules:
    - name: validate-image-tag
      match:
        any:
          - resources:
              kinds:
                - Pod                # ← This policy applies to Pods
      validate:
        message: "Image tag 'latest' is not allowed. Use a specific tag like a git SHA."
        pattern:
          spec:
            containers:
              - image: "!*:latest"   # ← The pattern that must match
```

**`rules:`** → A policy can have **multiple rules** in a list. Each rule has a name, a `match` (what resources to check), and either `validate`, `mutate`, or `generate` (what to do).

**`match.any` → `resources.kinds: - Pod`** → This rule applies to any **Pod** being created. Note it's `Pod`, not `Deployment`. Why?

> **Why `Pod` and not `Deployment`?** When Kubernetes creates a Deployment, it creates ReplicaSets, which then create Pods. Kyverno intercepts at the **Pod** level to catch ALL pod creation paths — whether from a Deployment, a DaemonSet, a CronJob, or someone running `kubectl run` directly. `Deployment` check alone would miss `kubectl run myapp –image=nginx:latest`.

**`validate.pattern:`** → The YAML pattern the resource MUST match. If the field doesn't match the pattern → violation.

**`image: "!*:latest"`** → **Kyverno pattern syntax**, not regex.
- `*` = wildcard (any characters)
- `!` = negation (must NOT match)
- So `!*:latest` = "must NOT be anything ending in `:latest`"

**Examples:**
```
nginx:latest          → BLOCKED ✅
myapp:latest          → BLOCKED ✅
myapp:1.2.3           → ALLOWED ✅
myapp:abc1234         → ALLOWED ✅
myapp                 → ALLOWED (no tag at all = not latest) ✅
```

---

## 📄 POLICY 2 — `require-resource-limits` — No Limits = No Entry

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-resource-limits
  annotations:
    policies.kyverno.io/severity: medium
spec:
  validationFailureAction: Enforce   # Hard block
  background: true
  rules:
    - name: validate-resources
      match:
        any:
          - resources:
              kinds:
                - Pod
      exclude:
        any:
          - resources:
              namespaces:
                - kube-system    # ← Kubernetes system pods — we DON'T control these
                - argocd         # ← ArgoCD's own pods — they may not have limits
                - kyverno        # ← Kyverno's own pods — they may not have limits
                - observability  # ← Prometheus/Grafana — vendor charts, hard to control
      validate:
        message: "CPU and memory limits are required for all containers."
        pattern:
          spec:
            containers:
              - resources:
                  limits:
                    memory: "?*"   # ← Must have SOME memory limit
                    cpu: "?*"      # ← Must have SOME CPU limit
```

**`exclude:` block** → 🔑 Critical concept. This policy applies to ALL pods across the cluster — **except** those in the listed namespaces.

**Why exclude `kube-system`?**
`kube-system` contains Kubernetes' own infrastructure components (`coredns`, `kube-proxy`, AWS EBS CSI driver, etc.). These are deployed by AWS/Kubernetes and don't always have resource limits defined. If you enforced limits on them, your cluster would break itself during node bootstrapping.

**Why exclude `argocd`, `kyverno`, `observability`?**
These are third-party tools installed via community Helm charts. The chart authors may not have set resource limits. If you enforced limits on them, ArgoCD would fail to deploy itself → chicken-and-egg problem. You exclude them and manage them separately.

**`"?*"` pattern:**
- `?` = at least one character must be present
- `*` = any characters after
- So `"?*"` = "must have ANY non-empty value"
- `memory: "?*"` means: the memory limit field must exist and have some value (`256Mi`, `1Gi`, anything)

**What happens when someone forgets limits?**
```
ArgoCD tries to sync order-service (missing limits in values.yaml)
kubectl apply → Kubernetes API → Kyverno webhook
Kyverno: "This Pod has no cpu limit"
Kyverno: REJECTED
Error: "CPU and memory limits are required for all containers."
ArgoCD marks the app as SyncFailed
You get an alert
You fix values.yaml, push to Git
ArgoCD retries → Kyverno accepts → pod starts ✅
```

---

## 📄 POLICY 3 — `require-labels` — Enforce Labeling Standards

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-labels
  annotations:
    policies.kyverno.io/severity: low
spec:
  validationFailureAction: Audit   # ← AUDIT, not Enforce. Just warn.
  background: true
  rules:
    - name: check-labels
      match:
        any:
          - resources:
              kinds:
                - Deployment      # ← Checks Deployments, not Pods
                - StatefulSet
      exclude:
        any:
          - resources:
              namespaces:
                - kube-system
                - argocd
                - kyverno
      validate:
        message: "Labels 'app' and 'team' are required."
        pattern:
          metadata:
            labels:
              app: "?*"           # Must have non-empty 'app' label
              team: "?*"          # Must have non-empty 'team' label
```

**`validationFailureAction: Audit`** — This policy does NOT block. It only reports. Why?

Labels are important for cost tracking and monitoring, but they're not a security issue. Using `Audit` means: violations show up in Kyverno's Policy Report, you can see which Deployments are missing labels, and fix them over time — without emergency blocking anyone.

**`kinds: - Deployment` (not Pod)** — Labels are a governance concern, checked at the Deployment level. You want to see "this Deployment in namespace X doesn't follow our labeling standard." At the Pod level it gets noisy.

**`metadata.labels.app: "?*"` + `team: "?*"`** → The Deployment's `metadata.labels` block must contain an `app` key and a `team` key, both with non-empty values.

---

## 📄 POLICY 4 — `disallow-privileged` — NO Privileged Containers

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: disallow-privileged
  annotations:
    policies.kyverno.io/severity: high   # ← Highest severity
spec:
  validationFailureAction: Enforce        # ← Hard block — no exceptions
  background: true
  rules:
    - name: deny-privileged
      match:
        any:
          - resources:
              kinds:
                - Pod
      validate:
        message: "Privileged containers are not allowed."
        pattern:
          spec:
            containers:
              - =(securityContext):        # ← Conditional operator
                  =(privileged): "false"  # ← If present, must be false
```

### 🆕 NEW CONCEPT: Privileged Containers — Why This is Catastrophic

A **privileged container** runs with almost all Linux capabilities enabled — including the ability to:
- Access the **host's filesystem** directly (including `/etc`, all secrets, all other pods' data)
- Load **kernel modules** (install rootkits)
- **Break out of the container** entirely and access the underlying EC2 node
- Pivot to **attack other nodes** in the cluster

**`severity: high`** — This is the most dangerous misconfiguration in Kubernetes. A single privileged container can compromise the entire cluster and all data.

**`=(securityContext):` and `=(privileged):`** — The `=()` operator in Kyverno is a **conditional/optional check operator**:

- Without `=()`: `securityContext.privileged` MUST be present and MUST be `"false"`
- With `=()`: "IF `securityContext` exists, AND IF `privileged` is set, THEN it MUST be `"false"`"

**Why use the conditional operator?** Because `securityContext` is optional in Kubernetes. If a pod doesn't set `securityContext` at all → it gets default (non-privileged) → that's fine. The `=()` operator handles this: "if you set it, it must say false; if you don't set it, that's also fine."

**What `privileged: true` looks like in a bad Deployment:**
```yaml
containers:
  - name: bad-app
    securityContext:
      privileged: true   # ← Kyverno would BLOCK this immediately
```

**No exclusions on this policy** → Unlike resource limits (where we exclude `kube-system`), privileged containers are blocked **everywhere** — even system namespaces shouldn't be running privileged pods without explicit special handling outside this policy.

---

## 🔄 How ArgoCD Deploys These Policies

In Phase 7, ArgoCD was set up to watch `gitops/platform/argocd/applications/`. You saw `kyverno.yaml` which installs the Kyverno engine. But the **policies themselves** also need to be deployed.

The `policies.yaml` is in `gitops/platform/kyverno/`. You'd add a new ArgoCD Application (similar to `common.yaml`) pointing to this folder:

```yaml
# Would go in: gitops/platform/argocd/applications/kyverno-policies.yaml
source:
  path: gitops/platform/kyverno     # ← This folder
  # ArgoCD applies policies.yaml → Kyverno ClusterPolicy objects created
```

Once applied: **Every future deployment attempt, by anyone, through any method — is subject to these 4 policies.**

---

# 🔑 PHASE 8b — External Secrets Operator (ESO)

## 🧠 The Problem ESO Solves

In Phase 6, `order-service/values.yaml` has:
```yaml
env:
  - name: DATABASE_URL
    valueFrom:
      secretKeyRef:
        name: db-credentials   # ← References a K8s Secret called "db-credentials"
        key: url
```

This K8s Secret `db-credentials` needs to **exist in the cluster** before the pod can start. But where does it come from?

**BAD approaches:**
```bash
# Option A — Hardcode in Git (TERRIBLE):
# values.yaml → DATABASE_URL: "postgres://admin:password123@rds.aws.com:5432/db"
# ↑ DB password is in Git forever. Anyone who ever cloned the repo has it.

# Option B — Apply manually (not GitOps-friendly):
# kubectl create secret generic db-credentials --from-literal=url=postgres://...
# ↑ Manual step. Not in Git. The next engineer who deploys from scratch doesn't know to do this.
```

**The ESO approach:**
```
AWS Secrets Manager
  (secret: "kubeflow-ops/dev/db-credentials")
  (contains: url, username, password, host)
               │
               │  ESO polls every 1 hour
               │  (uses IRSA — no static AWS keys)
               ▼
  External Secrets Operator (running in cluster)
               │
               │  Creates & updates
               ▼
  K8s Secret "db-credentials" in kubeflow-ops namespace
  (base64-encoded, stored in etcd, never in Git)
               │
               │  Pod env var injection
               ▼
  order-service pod
  (env DATABASE_URL = "postgres://...")
```

**Key properties:**
- DB password **NEVER** appears in Git. Not now, not ever.
- Secret is **automatically refreshed** every 1 hour (if you rotate the password in AWS SM, the pod gets the new one within 1 hour)
- Everything is still GitOps-friendly — you define WHICH secret to sync in Git, not the secret VALUE itself

---

## 📄 FILE: `gitops/platform/external-secrets/secrets.yaml`

This file contains **2 resources** separated by `---`.

---

### RESOURCE 1 — `ClusterSecretStore` — "Where Are The Secrets?"

```yaml
apiVersion: external-secrets.io/v1beta1  # ESO's own API version
kind: ClusterSecretStore                  # Another CRD — installed by ESO in Phase 7
metadata:
  name: aws-secrets-manager               # Name other resources reference this by
spec:
  provider:
    aws:
      service: SecretsManager            # Use AWS Secrets Manager (not Parameter Store)
      region: us-east-1
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets       # The ESO ServiceAccount
            namespace: external-secrets  # In the external-secrets namespace
```

### 🆕 NEW CONCEPT: `ClusterSecretStore` — The Connection Config

A `ClusterSecretStore` is a cluster-wide configuration that says: **"When you need a secret, go look in THIS place using THIS authentication method."**

Think of it as an address book entry: "If you need secrets, the address is: `AWS Secrets Manager, region us-east-1, authenticated via IRSA.`"

**`service: SecretsManager`** → AWS has two secrets services:
- **Secrets Manager** → Full-featured, supports automatic rotation, fine-grained IAM, versioning. **Used here. Costs ~$0.40/secret/month.**
- **Parameter Store** → Simpler, cheaper. Good for configuration flags, not mission-critical secrets.

**`auth.jwt.serviceAccountRef`** → This is how ESO authenticates with AWS — through **IRSA** (same concept as Phase 6 service-account).

ESO has its OWN ServiceAccount (`external-secrets` in `external-secrets` namespace) that has an IAM Role attached (created by Terraform in Phase 5). That role has permission to read from AWS Secrets Manager. ESO uses this SA's temporary JWT token to get AWS credentials. **Zero static AWS keys.**

---

### RESOURCE 2 — `ExternalSecret` — "Which Secret to Sync?"

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret                      # Another ESO CRD
metadata:
  name: db-credentials
  namespace: kubeflow-ops               # ← Created in the APP namespace
spec:
  refreshInterval: 1h                   # Check AWS SM for updates every 1 hour
  secretStoreRef:
    name: aws-secrets-manager           # ← Reference to the ClusterSecretStore above
    kind: ClusterSecretStore
  target:
    name: db-credentials                # ← Name of the K8s Secret to create
    creationPolicy: Owner               # ← ESO owns this Secret (manages its lifecycle)
  data:
    - secretKey: url                    # ← Key in the K8s Secret
      remoteRef:
        key: kubeflow-ops/dev/db-credentials  # ← Secret NAME in AWS SM
        property: url                          # ← JSON key within that secret
    - secretKey: username
      remoteRef:
        key: kubeflow-ops/dev/db-credentials
        property: username
    - secretKey: password
      remoteRef:
        key: kubeflow-ops/dev/db-credentials
        property: password
    - secretKey: host
      remoteRef:
        key: kubeflow-ops/dev/db-credentials
        property: host
```

**`namespace: kubeflow-ops`** — ExternalSecrets are **namespaced** (unlike ClusterSecretStore which is cluster-wide). The K8s Secret gets created in the SAME namespace as the ExternalSecret. So `db-credentials` Secret appears in `kubeflow-ops` namespace — exactly where `order-service` pods look for it.

**`refreshInterval: 1h`** — ESO polls AWS Secrets Manager every 1 hour. If you rotate the DB password in AWS SM, within 1 hour:
1. ESO fetches the new value
2. Updates the K8s Secret
3. Kubernetes detects the Secret changed
4. Pods that use `envFrom` automatically pick up the new value on next restart
5. (Or you can configure ESO to trigger a rolling restart automatically — Phase 8 advanced)

**`secretStoreRef`** → Links this ExternalSecret to the `aws-secrets-manager` ClusterSecretStore. This is the "use the address from the address book" step.

**`target.name: db-credentials`** → The Kubernetes Secret that gets **created and managed** by ESO. After ESO runs, you can see it with: `kubectl get secret db-credentials -n kubeflow-ops`. But if you look at its YAML, the values are base64-encoded (standard K8s Secret behavior). You cannot decrypt them without cluster access.

**`target.creationPolicy: Owner`** → ESO is the **owner** of this Secret. If the ExternalSecret is deleted from Kubernetes, ESO cleans up the K8s Secret too. ESO also recreates the Secret if someone accidentally deletes it. ESO owns the lifecycle.

---

**The `data` block — mapping AWS SM fields to K8s Secret keys:**

```yaml
data:
  - secretKey: url          # ←── This becomes a key INSIDE the K8s Secret
    remoteRef:
      key: kubeflow-ops/dev/db-credentials   # ←── Secret NAME in AWS Secrets Manager
      property: url                           # ←── JSON key WITHIN that AWS secret
```

**AWS Secrets Manager stores secrets as JSON objects.** The secret named `kubeflow-ops/dev/db-credentials` in AWS SM looks like:
```json
{
  "url": "postgresql://admin:pass123@rds.endpoint:5432/mydb",
  "username": "admin",
  "password": "pass123",
  "host": "rds.endpoint.us-east-1.rds.amazonaws.com"
}
```

ESO reads this JSON, extracts each field (`property: url`, `property: username`, etc.), and puts them as **separate keys** in the K8s Secret:

```
K8s Secret "db-credentials" in kubeflow-ops:
  url      = "postgresql://admin:pass123@rds.endpoint:5432/mydb"   (base64)
  username = "admin"                                                  (base64)
  password = "pass123"                                                (base64)
  host     = "rds.endpoint.us-east-1.rds.amazonaws.com"              (base64)
```

And the pod's `secretKeyRef: key: url` maps exactly to this `url` key → pod gets the full connection string as `DATABASE_URL` environment variable.

**`key: kubeflow-ops/dev/db-credentials`** — Secret naming convention in AWS SM: `<project>/<environment>/<secret-name>`. The `/dev/` part means the dev environment's credentials. Prod would use `kubeflow-ops/prod/db-credentials` — a completely separate secret with different (higher-privileged, production) credentials.

---

## 🔄 The Complete Phase 8 Security Picture (End-to-End)

```
HOW A SECURE DEPLOYMENT FLOWS (everything working together):

Developer pushes code → CI builds image → pushes to ECR (Phase 4)
                                │
CI updates: image.tag: abc1234 in values.yaml → git push
                                │
ArgoCD detects change → runs helm template → produces K8s YAML
                                │
                                ▼
         Kubernetes API Server receives the Pod spec
                                │
                                ▼
              ┌─────────────────────────────┐
              │      Kyverno admission      │
              │      webhook checks:        │
              │                             │
              │ ✅ image tag ≠ latest       │
              │ ✅ cpu limit set: 500m      │
              │ ✅ memory limit set: 256Mi  │
              │ ✅ app + team labels exist  │
              │ ✅ privileged = false       │
              └─────────────────────────────┘
                                │
                           All pass!
                                │
                                ▼
              Pod scheduled on a node
                                │
                                ▼
         Pod starts → needs DATABASE_URL env var
         K8s reads from Secret "db-credentials"
                                │
                          Secret EXISTS?
                                │
                                ▼
         YES — ESO synced it from AWS Secrets Manager
         pod gets: DATABASE_URL = "postgres://admin:pass123@..."
                                │
                                ▼
              ✅ App running, secure, no secrets in Git
```

---

## 🆕 NEW CONCEPT: Kubernetes Secret Security Caveats

It's important to understand: **Kubernetes Secrets are NOT encrypted by default.** They're base64-encoded — which is just encoding, not encryption. Anyone with access to the cluster can decode them.

But this is STILL far better than secrets in Git because:
1. Cluster access is protected by IAM + RBAC (who can `kubectl get secret`)
2. AWS Secrets Manager has full audit logs (who accessed what, when)
3. Secrets can be rotated without redeploying
4. Secrets never appear in `git log` history (permanent Git exposure is the real danger)

For additional security, you can enable **EKS envelope encryption** (Phase 5 Terraform supports it) — which uses AWS KMS to encrypt the data stored in Kubernetes' etcd database.

---

## 🆕 NEW CONCEPT: How to Create Secrets in AWS Secrets Manager (One-Time)

Before ESO can sync them, you first need to CREATE the secrets in AWS SM. This is done using the `create-secrets.sh` script (Phase 11):

```bash
# What create-secrets.sh essentially does:
aws secretsmanager create-secret \
  --name "kubeflow-ops/dev/db-credentials" \
  --secret-string '{
    "url": "postgresql://admin:password@rds-endpoint:5432/mydb",
    "username": "admin",
    "password": "YourActualPassword",
    "host": "rds-endpoint.us-east-1.rds.amazonaws.com"
  }'
```

You run this **ONCE** after `terraform apply` gives you your RDS endpoint. After that:
- ESO syncs it to Kubernetes every hour automatically
- You rotate it in AWS SM when needed — ESO picks up the change
- The old password is never accessible to ESO again (AWS SM keeps version history, but ESO only reads the current version)

---

## 🔑 Key DevOps Takeaways from Phase 8

| Concept | What You Applied | Why It Matters |
|---|---|---|
| **Kyverno ClusterPolicy** | YAML-based security rules enforced at API admission | No runtime surprises; bad configs never enter the cluster |
| **`Enforce` mode** | Hard block on `:latest` tags, missing limits, privileged containers | Zero tolerance — DevSec enforced, not suggested |
| **`Audit` mode** | Soft reporting for labels policy | Gradual adoption without breaking everything |
| **`exclude` namespaces** | System/tool namespaces excluded from app-level policies | Prevents policies from breaking the cluster's own infrastructure |
| **`=()` conditional operator** | Optional field checks | Handles optional K8s fields gracefully without false positives |
| **`ClusterPolicy` vs `Policy`** | Cluster-wide vs namespace-scoped | Security rules must be cluster-wide to prevent bypass |
| **`ClusterSecretStore`** | One connection config for all secrets | Single place to update if AWS region or auth changes |
| **`ExternalSecret`** | Per-service, per-namespace secret sync config | Each service gets only its own secrets (least privilege) |
| **`refreshInterval: 1h`** | Auto-rotation without redeploy | Credential rotation is operational necessity at scale |
| **`creationPolicy: Owner`** | ESO manages Secret lifecycle | Secrets don't get orphaned when ExternalSecrets are deleted |
| **JSON property mapping** | `property: url` extracts individual fields | One AWS secret can serve multiple K8s secret keys |
| **Naming convention** | `project/env/secret-name` in AWS SM | Clear separation of dev/prod secrets, auditable |
| **IRSA for ESO** | ESO itself uses IRSA (no AWS keys in-cluster) | Zero static credentials anywhere in the entire system |

---

## ✅ Phase 8 Complete — What's Next

After Phase 8, your cluster now has:
- ✅ Every pod deployment is checked against 4 security policies automatically
- ✅ DB passwords and other secrets are pulled from AWS Secrets Manager every hour
- ✅ Zero secrets in Git — not now, not historically
- ✅ Privileged containers are impossible to run — cluster-wide enforcement
- ✅ You can't deploy without resource limits — every pod is bounded

**Phase 9: Observability** — Now you need to SEE what's happening. Phase 9 covers the `alert-rules.yaml` file that defines Prometheus alerting rules — when CPU is too high, when a pod is crash-looping, when disk space is low — and how Alertmanager routes those alerts to Slack. 📊

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

*Edited relevant file*

### User Input

Okay lets start from Phase 9.
You need to explain each thing line by line for devops prespective, Block by block, I only know basic docker terraform and kubernets basic
So any new topic u need to explain in detail as if beginner.If something is developer work no in depth required, NO seperate Artifact, , share it here in this window

### Planner Response

Let me read all the Phase 9 files first.

*Listed directory [prometheus](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/platform/prometheus) *

*Listed directory [docs](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/docs) *

*Viewed [alert-rules.yaml](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/platform/prometheus/alert-rules.yaml) *

### Planner Response

I have the file. Here is the complete Phase 9 explanation:

---

# 📊 Phase 9 — Observability Stack — Complete Deep-Dive

---

## 🧠 Big Picture First — What Problem Does Phase 9 Solve?

At the end of Phase 8, everything is secure and running. But **you are flying blind.**

You don't know:
- Is the order-service slow right now?
- Are there errors spiking?
- Is a pod crash-looping at 3am while you're asleep?
- Is one EC2 node about to run out of disk?
- Is the HPA maxed out and unable to scale further?

**Without observability, you find out about problems via angry user reports. That's the worst way to find out.**

Phase 9 builds your **eyes and ears** inside the cluster:

```
               ┌─────────────────────────────────────────┐
               │         Observability Stack             │
               │                                         │
               │  Prometheus  ──── scrapes every pod     │
               │      │             every 15 seconds     │
               │      │                                  │
               │      ▼                                  │
               │  Alert Rules ── (YOU define these)      │
               │      │         "if X > threshold"       │
               │      │                                  │
               │      ▼                                  │
               │  Alertmanager ── routes to Slack/SNS    │
               │                                         │
               │  Grafana ──── dashboards & visualization│
               └─────────────────────────────────────────┘
```

**Phase 9's one deliverable:** The [alert-rules.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/platform/prometheus/alert-rules.yaml:0:0-0:0) file — **YOU define the rules**. Everything else (Prometheus, Grafana, Alertmanager) was already deployed by ArgoCD in Phase 7 via the `prometheus-stack` application.

---

## 🆕 NEW CONCEPT: The Prometheus Monitoring Data Model

Before reading the alert rules, you MUST understand how Prometheus stores and thinks about data. Without this, the `expr:` fields will look like magic.

### Metrics — The Basic Unit

Prometheus stores data as **time-series** — values that change over time. Each time-series is uniquely identified by a **metric name** and **labels** (key-value pairs).

```
metric_name{label1="value1", label2="value2"} = numeric_value  @ timestamp
```

**Real examples from this project:**
```
http_requests_total{status="200", method="GET", path="/healthz", service="order-service"} = 4231
http_requests_total{status="500", method="POST", path="/orders", service="order-service"} = 17
http_request_duration_seconds_bucket{le="0.1", service="order-service"} = 3891
kube_pod_container_status_restarts_total{pod="order-service-abc", namespace="kubeflow-ops"} = 0
```

**Labels are everything.** The same metric name `http_requests_total` has thousands of different time-series — one per unique combination of labels. You filter using `{label="value"}` syntax.

### Metric Types

| Type | What it measures | Example |
|---|---|---|
| **Counter** | Cumulative count that only ever increases | `http_requests_total` — total HTTP requests since pod start |
| **Gauge** | Current value that can go up or down | `memory_usage_bytes` — current RAM used |
| **Histogram** | Distribution of values in buckets | `http_request_duration_seconds_bucket` — how many requests in each latency bucket |

---

## 🆕 NEW CONCEPT: PromQL — Prometheus Query Language

Alert rules are written in **PromQL** — a query language designed specifically for time-series data.

### Key PromQL Functions You'll See:

**`rate(metric[5m])`** — per-second rate of increase averaged over the last 5 minutes
```
rate(http_requests_total[5m])
→ "How many new HTTP requests per second, on average, in the last 5 minutes?"
```
Why `rate` instead of raw value? Raw counters only ever increase. `rate` converts them to a per-second speed — which is meaningful for comparisons and thresholds.

**`sum(metric) by (label)`** — aggregate across multiple time-series, grouping by a label
```
sum(rate(http_requests_total[5m])) by (service)
→ "Total requests/sec grouped by service name"
→ {service="order-service"} = 45.2
→ {service="user-service"} = 12.8
```

**`histogram_quantile(0.95, ...)`** — calculate the 95th percentile from histogram buckets
```
histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le, service))
→ "What latency is 95% of all requests FASTER than?"
→ If p95 = 1.5s → 95% of requests finish in under 1.5 seconds
```

**`increase(metric[15m])`** — total increase over a time window (like `rate` but gives total count, not per-second)
```
increase(http_requests_total{status="201"}[15m])
→ "How many 201 responses happened in the last 15 minutes?"
```

**`offset 10m`** — look at the value 10 minutes ago
```
kube_pod_container_status_restarts_total - kube_pod_container_status_restarts_total offset 10m
→ "How much did restart count increase in the last 10 minutes?"
```

---

## 📄 FILE: [gitops/platform/prometheus/alert-rules.yaml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/platform/prometheus/alert-rules.yaml:0:0-0:0)

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
```

### 🆕 NEW CONCEPT: `kind: PrometheusRule` — Another CRD

Like `kind: Application` (ArgoCD) and `kind: ClusterPolicy` (Kyverno), **`PrometheusRule`** is a CRD installed by the `kube-prometheus-stack` chart in Phase 7.

**Why a CRD instead of just a config file?**
Prometheus is running INSIDE the cluster. The traditional approach was to edit Prometheus' config file and restart it. With `PrometheusRule`, you instead create/update a Kubernetes resource → Prometheus' **operator** (a controller pod) detects the change → automatically hot-reloads Prometheus' config. **No restarts, no downtime, GitOps-friendly.**

**`apiVersion: monitoring.coreos.com/v1`** → The Prometheus Operator's API group. When kube-prometheus-stack is installed, it registers this API group with Kubernetes.

---

```yaml
metadata:
  name: kubeflow-ops-alerts
  namespace: observability     # Same namespace as Prometheus
  labels:
    release: prometheus-stack  # ← CRITICAL label
```

**`namespace: observability`** → This resource must be in the same namespace as Prometheus. Prometheus' operator watches for `PrometheusRule` objects and loads their rules.

**`labels: release: prometheus-stack`** → 🔑 **This is the magic selector.**

In Phase 7's `prometheus-stack.yaml`, we set:
```yaml
# (from prometheus-stack Helm chart defaults)
prometheusSpec:
  ruleSelector:
    matchLabels:
      release: prometheus-stack
```

This means Prometheus only loads `PrometheusRule` objects that have **`release: prometheus-stack`** label. Without this label, you can create a PrometheusRule and Prometheus will silently ignore it. **This is the most common gotcha with PrometheusRule.**

---

```yaml
spec:
  groups:
    - name: application.rules
      rules: ...
    - name: business.rules
      rules: ...
    - name: kubernetes.rules
      rules: ...
    - name: capacity.rules
      rules: ...
```

**`groups:`** → Rules are organized into **groups** — a logical grouping that also controls evaluation timing. All rules in a group are evaluated together at the same time. Groups are just for organization.

**`name: application.rules`** → Human-readable group names. These appear in Prometheus UI and Alertmanager.

---

## 📄 GROUP 1 — `application.rules` — Service-Level Alerts

### ALERT 1: `HighErrorRate`

```yaml
- alert: HighErrorRate
  expr: |
    sum(rate(http_requests_total{status=~"5.."}[5m])) by (service)
    /
    sum(rate(http_requests_total[5m])) by (service)
    > 0.05
  for: 5m
  labels:
    severity: critical
  annotations:
    summary: "High error rate on {{ $labels.service }}"
    description: "{{ $labels.service }} has >5% error rate (current: {{ $value | humanizePercentage }})"
```

**`alert: HighErrorRate`** → The name of this alert. This appears in Alertmanager, Slack messages, and Grafana. Use clear, specific names.

**`expr: |`** → The PromQL expression that triggers the alert when it evaluates to `true` (i.e., returns any result). Let's break this down line by line:

```promql
sum(rate(http_requests_total{status=~"5.."}[5m])) by (service)
```
→ **Numerator (top):** Total 5xx errors per second, grouped by service
- `http_requests_total` — all HTTP requests counter
- `{status=~"5.."}` — filter: only where status matches regex `5..` (500, 502, 503, 504, etc.)
- `[5m]` — look at the last 5 minutes of data
- `rate(...)` — convert to per-second rate
- `sum(...) by (service)` — add up all pods for the same service (order-service might have 3 pods — sum them all)

```promql
/
sum(rate(http_requests_total[5m])) by (service)
```
→ **Denominator (bottom):** Total ALL requests per second, grouped by service (no status filter)

```promql
> 0.05
```
→ **Threshold:** If the ratio (5xx errors / all requests) **exceeds 5% (0.05)** → alert fires

**The full math:** `5xx_rate / total_rate > 0.05` = "error rate is above 5%"

**`for: 5m`** → 🔑 **The pending duration.** The expression must be TRUE for 5 minutes continuously before the alert fires. Without `for:`, a 1-second spike would fire an alert. With `for: 5m`, you need sustained errors for 5 minutes — eliminates false alarms from brief blips.

**`labels.severity: critical`** → Labels on the alert itself. Alertmanager uses these to **route** the alert. You can configure: `severity: critical` → page the on-call engineer via PagerDuty. `severity: warning` → send to Slack only during business hours.

**`annotations:`** → Human-readable information that appears in the alert notification.

**`{{ $labels.service }}`** → **Go template syntax.** At alert fire time, Prometheus fills in the actual value. `$labels` = the Prometheus labels on the metric that triggered the alert (e.g. `service="order-service"`).

**`{{ $value | humanizePercentage }}`** → `$value` = the actual numeric value of the expression (e.g. `0.127` = 12.7%). `| humanizePercentage` = Prometheus template filter that converts `0.127` → `"12.7%"` for human readability.

**What this alert looks like when it fires:**
```
Alert: HighErrorRate [FIRING]
Severity: critical
Summary: "High error rate on order-service"
Description: "order-service has >5% error rate (current: 8.3%)"
```

---

### ALERT 2: `HighLatency`

```yaml
- alert: HighLatency
  expr: |
    histogram_quantile(0.95,
      sum(rate(http_request_duration_seconds_bucket[5m])) by (le, service)
    ) > 2
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "High latency on {{ $labels.service }}"
    description: "P95 latency is {{ $value }}s on {{ $labels.service }}"
```

**The expression breakdown:**

```promql
http_request_duration_seconds_bucket
```
→ A **histogram metric** automatically created by `prometheus-fastapi-instrumentator`. It counts how many requests fall into each latency "bucket."

The buckets look like:
```
duration_bucket{le="0.05"}  = 8450   ← 8450 requests completed in ≤ 50ms
duration_bucket{le="0.1"}   = 9100   ← 9100 requests completed in ≤ 100ms
duration_bucket{le="0.25"}  = 9800   ← 9800 requests completed in ≤ 250ms
duration_bucket{le="0.5"}   = 9950   ← ...
duration_bucket{le="1.0"}   = 9980
duration_bucket{le="2.0"}   = 9995
duration_bucket{le="+Inf"}  = 10000  ← total: 10000 requests
```

**`histogram_quantile(0.95, ...)`** → Calculates the 95th percentile (p95) from these buckets.

**`sum(...) by (le, service)`** → Must include `le` (bucket boundary) in the grouping — that's how histogram_quantile knows about the bucket structure. `service` gives you per-service percentiles.

**`> 2`** → Alert if p95 latency exceeds **2 seconds**.

**`severity: warning`** (not critical) → High latency is bad but not as immediately catastrophic as errors. Different routing: maybe Slack notification during business hours, not a 3am page.

### 🆕 NEW CONCEPT: P95 Latency — Why Not Average?

**Average hides problems.** If 95% of requests are fast (10ms) but 5% are slow (30 seconds), the average might be 1 second — which looks fine. But 5% of users are having terrible experiences.

**P95 (95th percentile)** = "The latency that 95% of requests are FASTER than." So p95 = 2s means: 5% of your users wait MORE than 2 seconds. This is the SLO-aligned way to measure latency.

---

### ALERT 3: `ServiceDown`

```yaml
- alert: ServiceDown
  expr: |
    up{job=~"order-service|user-service|notification-service"} == 0
  for: 2m
  labels:
    severity: critical
  annotations:
    summary: "{{ $labels.job }} is DOWN"
    description: "{{ $labels.job }} has been unreachable for 2+ minutes. Check pod status."
```

**`up`** → 🆕 A **special built-in Prometheus metric**. Every time Prometheus scrapes a target, it creates a metric called `up`:
- `up = 1` → Prometheus reached the target and scraped it successfully
- `up = 0` → Prometheus tried to scrape the target and FAILED (pod is down, not responding, wrong port)

**`{job=~"order-service|user-service|notification-service"}`** → Filter to only your 3 services. `=~` is regex match. `|` means "or". Without this filter, the alert would fire for ANY service going down (including Prometheus itself, node-exporter, etc.).

**`== 0`** → Alert when `up = 0` (service unreachable).

**`for: 2m`** → Only 2 minutes (shorter than other alerts). If a service is truly down, 2 minutes of confirmation is enough. You don't want to wait 5 minutes when a service is completely offline.

**`{{ $labels.job }}`** → `job` is an auto-assigned label from Prometheus' scrape config — it's the name of the monitored service.

---

## 📄 GROUP 2 — `business.rules` — Business Logic Alerts

**Why business alerts?** Technical alerts (errors, latency) tell you something is broken. Business alerts tell you whether your **business is working** — even if all the services are technically up and responding.

### ALERT 4: `OrderCreationFailures`

```yaml
- alert: OrderCreationFailures
  expr: |
    sum(rate(http_requests_total{service="order-service",method="POST",path="/orders",status=~"5.."}[5m]))
    /
    sum(rate(http_requests_total{service="order-service",method="POST",path="/orders"}[5m]))
    > 0.1
  for: 3m
  labels:
    severity: critical
    team: platform
  annotations:
    summary: "Order creation failure rate > 10%"
    description: "{{ $value | humanizePercentage }} of order creation requests are failing"
    runbook: "docs/runbook.md#high-error-rate"
```

**More specific than `HighErrorRate`** — this targets ONLY:
- `service="order-service"` → only order-service
- `method="POST"` → only POST requests
- `path="/orders"` → only the order creation endpoint

The general `HighErrorRate` alert covers all services and endpoints. `OrderCreationFailures` is a **business-specific** drill-down: "specifically, are orders being created successfully?"

**`> 0.1`** → Fire if MORE than 10% of order creation requests fail. (5% for general errors, 10% for this — because some sporadic 5xx is expected; 10% is clearly a systemic problem for this critical path).

**`labels.team: platform`** → Used by Alertmanager to route this alert to the **platform team** specifically. Multiple teams can use the same cluster; labels route alerts to the right team's Slack channel.

**`annotations.runbook: "docs/runbook.md#high-error-rate"`** → 🔑 Links to your **operational runbook** (Phase 10 document). When this alert fires at 3am, the engineer who gets paged sees the link and immediately knows what steps to follow. This is real-world on-call engineering.

---

### ALERT 5: `NoOrdersReceived`

```yaml
- alert: NoOrdersReceived
  expr: |
    sum(increase(http_requests_total{service="order-service",method="POST",path="/orders",status="201"}[15m])) == 0
  for: 15m
  labels:
    severity: warning
  annotations:
    summary: "No orders received in 15 minutes"
    description: "Zero successful order creations in the last 15 minutes. Check if service is reachable."
```

**`increase(...[15m]) == 0`** → The total count of successful order creations (status `201 Created`) in the last 15 minutes equals ZERO.

This is a **business health alert** — technically, every service might be returning 200 OK for health checks. But if no orders are being successfully created, something is wrong upstream (maybe the load balancer is misconfigured, the ingress is broken, the app is stuck in a non-HTTP loop).

**The clever design:** This is NOT about errors — it's about absence of success. Even with 0 errors, if you're seeing 0 orders, that's suspicious. A dead service that isn't connected to traffic won't emit errors; it'll just emit nothing.

**`status="201"`** → HTTP 201 Created. Only count SUCCESSFUL order creations.

**`severity: warning`** (not critical) → Could be middle-of-night with legitimately no traffic, or a real problem. Warrants investigation, not immediate paging.

---

### ALERT 6: `UserServiceLookupFailures`

```yaml
- alert: UserServiceLookupFailures
  expr: |
    sum(rate(http_requests_total{service="order-service",method="GET",path=~"/users/.*",status=~"5.."}[5m]))
    /
    sum(rate(http_requests_total{service="order-service",method="GET",path=~"/users/.*"}[5m]))
    > 0.05
  for: 5m
  labels:
    severity: critical
  annotations:
    summary: "User validation failing (impacts order creation)"
    description: "order-service cannot validate users — {{ $value | humanizePercentage }} lookup failure rate"
```

**`path=~"/users/.*"`** → Regex match. `/users/.*` matches `/users/123`, `/users/456`, any user lookup. This is order-service calling user-service to validate users before creating orders.

**Why this is `critical` even though it's "just" user lookups:** If `user-service` is failing, `order-service` **cannot create orders** (it validates the user first). So this upstream dependency failure immediately blocks the core business function.

**`path=~` regex in labels:** The `=~` operator allows regex patterns in label filters. `.*` = zero or more of any character. This one filter matches all user ID lookup URLs.

---

### ALERT 7: `NotificationProcessingLag`

```yaml
- alert: NotificationProcessingLag
  expr: |
    sum(increase(http_requests_total{service="notification-service",path="/process",status="200"}[5m])) == 0
    and
    sum(increase(http_requests_total{service="order-service",method="POST",path="/orders",status="201"}[5m])) > 0
  for: 10m
  labels:
    severity: warning
  annotations:
    summary: "Notifications not being processed"
    description: "Orders are being created but notification-service is not processing them. Check SQS consumer."
```

### 🆕 NEW CONCEPT: Multi-Condition Alerts with `and`

PromQL supports **logical operators** between expressions:
- `and` → both sides must be true
- `or` → either side is true
- `unless` → left side true but right side false

**This alert logic (careful reading):**
```
Condition A: notification-service processed ZERO messages in last 5 minutes
AND
Condition B: order-service had SUCCESSFUL order creations in last 5 minutes
```

**Why both conditions?** Without Condition B, the alert would fire at night when there's no traffic — of course `notification-service` processes zero messages if zero orders are arriving. That would be a false alarm.

With `and`: "notifications are NOT being processed (A) BUT orders ARE being created (B)" = **orders are going into SQS but notification-service isn't consuming them.** That's a real problem — the SQS consumer is broken.

This is sophisticated business-logic alerting that requires understanding how your services talk to each other.

---

## 📄 GROUP 3 — `kubernetes.rules` — Cluster Health Alerts

### ALERT 8: `PodCrashLoopBackOff`

```yaml
- alert: PodCrashLoopBackOff
  expr: |
    kube_pod_container_status_restarts_total
    - kube_pod_container_status_restarts_total offset 10m > 3
  for: 5m
  labels:
    severity: critical
  annotations:
    summary: "Pod {{ $labels.pod }} is crash-looping"
    description: "Pod {{ $labels.pod }} in {{ $labels.namespace }} has restarted >3 times in 10 minutes"
```

**`kube_pod_container_status_restarts_total`** → A metric from **kube-state-metrics** (part of kube-prometheus-stack, installed in Phase 7). It tracks the total restart count of every container in every pod.

**`- kube_pod_container_status_restarts_total offset 10m`** → Subtracts the restart count from 10 minutes ago. The result = **how many times this container restarted in the last 10 minutes**.

**`> 3`** → Alert if restarts in the last 10 minutes exceed 3.

**Why not use Kubernetes' own CrashLoopBackOff event?** Because Kubernetes fires events but they get deleted after 1 hour. Prometheus keeps this metric over time and you can track the history. Also, Prometheus can aggregate this across ALL pods in a rolling window — much more precise than event-based detection.

**`{{ $labels.pod }}` and `{{ $labels.namespace }}`** → kube-state-metrics automatically adds these labels from Kubernetes metadata. You know exactly which pod in which namespace is crashing.

---

### ALERT 9: `PodNotReady`

```yaml
- alert: PodNotReady
  expr: |
    kube_pod_status_ready{condition="true"} == 0
  for: 5m
  labels:
    severity: warning
```

**`kube_pod_status_ready`** → Another kube-state-metrics metric. `condition="true"` + value `== 0` means: "the pod's ready condition is false" — i.e., the **Readiness probe is failing**.

Remember from Phase 6: when a readiness probe fails, the pod stays out of the Service — no traffic goes to it. If this persists for 5 minutes, something is wrong (dependency check failing, DB unreachable, etc.).

**`severity: warning`** — Pod not ready doesn't mean it's down; it might be starting up or temporarily overloaded. 5 minutes of not-ready is worth investigating.

---

### ALERT 10: `NodeDiskPressure`

```yaml
- alert: NodeDiskPressure
  expr: |
    kube_node_status_condition{condition="DiskPressure",status="true"} == 1
  for: 2m
```

**`kube_node_status_condition`** → kube-state-metrics tracks Kubernetes Node conditions. A Node can have conditions like `DiskPressure`, `MemoryPressure`, `PIDPressure`, `Ready`.

**`condition="DiskPressure", status="true"`** → Kubernetes itself sets DiskPressure when the node's disk drops below a threshold (~10% free by default, configurable). This is Kubernetes' own detection — you're just alerting on it.

**`for: 2m`** → Short pending duration. Disk pressure can cause pod evictions within minutes — this needs fast response.

**`severity: critical`** → Why critical? When a node has DiskPressure, Kubernetes starts **evicting pods** from that node to free space. Pod evictions during production traffic = dropped requests.

---

### ALERT 11: `HighNodeCPU`

```yaml
- alert: HighNodeCPU
  expr: |
    100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 85
  for: 10m
```

**`node_cpu_seconds_total`** → From **node-exporter** (also part of kube-prometheus-stack). Reports how many seconds the CPU spent in each mode: `idle`, `user`, `system`, `iowait`, etc.

**`{mode="idle"}`** → Filter to only the idle time.

**`rate(node_cpu_seconds_total{mode="idle"}[5m])`** → Rate of idle seconds per second = fraction of time the CPU was idle (number between 0 and 1).

**`* 100`** → Convert to percentage (0-100).

**`100 - (...)`** → CPU usage % = `100% - idle%`. If CPU was idle 15% of the time → CPU was USED 85% of the time.

**`avg by(instance)`** → Average across all CPU cores on the same node (`instance` = the EC2 node's IP).

**`> 85`** → Alert if CPU usage on any node exceeds 85% for 10 minutes.

**`for: 10m`** → CPU spikes are normal (a deployment pushes CPU temporarily). 10 minutes of sustained >85% is a real problem.

**`severity: warning`** → At 85% CPU, the node is struggling but not failed. Time to investigate/scale. If it hits 100%, the `HighErrorRate` alert will catch the consequences.

---

## 📄 GROUP 4 — `capacity.rules` — Scaling & Capacity Alerts

### ALERT 12: `HPAMaxedOut`

```yaml
- alert: HPAMaxedOut
  expr: |
    kube_horizontalpodautoscaler_status_current_replicas
    == kube_horizontalpodautoscaler_spec_max_replicas
  for: 15m
  labels:
    severity: warning
  annotations:
    summary: "HPA {{ $labels.horizontalpodautoscaler }} is at max replicas"
    description: "{{ $labels.horizontalpodautoscaler }} has been at max capacity for 15+ minutes. Consider increasing maxReplicas."
```

**`kube_horizontalpodautoscaler_status_current_replicas`** → Current number of pods the HPA is running.

**`kube_horizontalpodautoscaler_spec_max_replicas`** → Max replicas configured in the HPA (e.g., `10` from Phase 6's `values.yaml`).

**`==`** → When current == max → HPA has scaled to the maximum and **cannot scale further**. Traffic is growing but Kubernetes can't add more pods.

**`for: 15m`** → 15 minutes at max replicas. A brief spike to max is fine (HPA handles it). 15 minutes means the load consistently exceeds capacity.

**Why this alert is important:** Without it, you'd only notice when errors start (which is too late). This gives you a **lead indicator** — "you're about to run out of capacity" — before things actually break.

**The action:** Operator increases `maxReplicas` in `values.yaml`, pushes to Git, ArgoCD syncs, HPA gets a higher ceiling.

**`{{ $labels.horizontalpodautoscaler }}`** → The name of the HPA — `order-service`, `user-service`, or `notification-service`.

---

### ALERT 13: `TrafficSpike`

```yaml
- alert: TrafficSpike
  expr: |
    sum(rate(http_requests_total[5m])) by (service)
    > 2 * sum(rate(http_requests_total[1h])) by (service)
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "Traffic spike on {{ $labels.service }}"
    description: "{{ $labels.service }} traffic is 2x above the 1-hour average. HPA should be scaling."
```

**Elegant PromQL design.** This compares two time windows:
- `rate(...[5m])` → current traffic (last 5 minutes)
- `rate(...[1h])` → baseline traffic (last 1 hour average)

**`> 2 * ...`** → Current traffic is MORE THAN 2x the 1-hour average.

**Why this matters:** HPA will be auto-scaling in response. But this alert gives the team **visibility** — "something unusual is driving traffic." Could be:
- Marketing campaign launched → expected spike
- DDoS attack → investigate
- Viral event → scale proactively
- Bug causing retry loops → investigate

**`for: 5m`** → Confirm it's sustained, not a brief burst.

---

### ALERT 14: `PVCNearlyFull`

```yaml
- alert: PVCNearlyFull
  expr: |
    kubelet_volume_stats_used_bytes / kubelet_volume_stats_capacity_bytes > 0.85
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "PVC {{ $labels.persistentvolumeclaim }} is 85% full"
    description: "Volume {{ $labels.persistentvolumeclaim }} in {{ $labels.namespace }} is running low on space"
```

**`kubelet_volume_stats_used_bytes`** → Bytes used in a PVC, reported by the Kubelet (the node agent).
**`kubelet_volume_stats_capacity_bytes`** → Total capacity of the PVC.

**`/ ... > 0.85`** → Used fraction > 85% (PVC is more than 85% full).

**Remember from Phase 7:** Prometheus stores metrics on a 10Gi EBS volume. Alertmanager stores alert state on a 2Gi EBS volume. These volumes fill up over time (metric data for Prometheus, old alert states for Alertmanager).

When Prometheus' disk is 100% full:
- It can't write new metric data
- It starts discarding old data (corrupted state possible)
- Alert rules stop evaluating → complete observability blackout

**85% threshold gives you time to act** before it hits 100%. Actions: expand the PVC, reduce retention, delete old data.

**`{{ $labels.persistentvolumeclaim }}`** → The PVC name, e.g., `prometheus-storage`, `alertmanager-storage`.

---

## 🔄 How The Complete Observability Flow Works

```
Every 15 seconds:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Prometheus → scrapes /metrics on every pod
  → stores metrics as time-series in 10Gi EBS volume

Constantly (every 1 minute):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Prometheus → evaluates ALL alert rules
  → Rule result = true (threshold exceeded, for X minutes)?
     YES: Create "Firing" alert → send to Alertmanager
     NO:  If was firing, send "Resolved" → send to Alertmanager

Alertmanager receives alert:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  → Read labels: severity=critical? → PagerDuty
  → Read labels: severity=warning?  → Slack #alerts channel
  → Read labels: team=platform?     → Slack #platform-alerts
  → If same alert already firing: group/deduplicate (don't spam)
  → If resolved: send "OK" notification

Grafana (always running):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  → Reads from Prometheus via query (same PromQL)
  → Visualizes dashboards: request rate, latency p95, error rate
  → Anyone can browse dashboards in browser: http://grafana:3000
```

---

## 🆕 NEW CONCEPT: Alert States — Pending, Firing, Resolved

Prometheus alerts have 3 states:

| State | Meaning | What's happening |
|---|---|---|
| **Inactive** | Expression is false | No problem detected |
| **Pending** | Expression is true BUT `for:` duration not yet met | Problem detected, waiting to confirm |
| **Firing** | Expression true AND `for:` duration satisfied | Alert sent to Alertmanager |
| **Resolved** | Was Firing, now expression is false | Problem fixed, "resolved" notification sent |

**Example:**
```
15:00:00 → HighErrorRate expr = true → state: PENDING (starts timing 5m)
15:01:00 → still true → state: PENDING (elapsed: 1m)
15:04:00 → drops below 5% → state: INACTIVE (timer resets)
15:05:00 → rises again → state: PENDING (new timer starts)
15:10:00 → still above 5% for 5 whole minutes → state: FIRING
15:10:01 → Alertmanager receives alert → sends to Slack
15:15:00 → error rate drops → state: RESOLVED
15:15:01 → Alertmanager sends "RESOLVED" message to Slack
```

---

## 🆕 NEW CONCEPT: How ArgoCD Deploys These Alert Rules

Same pattern as Phase 8's Kyverno policies — you need an ArgoCD Application pointing to the prometheus folder:

```yaml
# gitops/platform/argocd/applications/prometheus-rules.yaml
source:
  path: gitops/platform/prometheus   # ← This folder with alert-rules.yaml
  # ArgoCD applies alert-rules.yaml → PrometheusRule object created
  # Prometheus Operator detects it → loads rules into Prometheus
  # No Prometheus restart needed
```

Git commit → ArgoCD syncs → new alert rules active in seconds. **GitOps for observability.**

---

## 🔑 Key DevOps Takeaways from Phase 9

| Concept | What You Applied | Why It Matters |
|---|---|---|
| **`PrometheusRule` CRD** | GitOps-managed alert rules | No manual Prometheus config editing, no restarts |
| **`release: prometheus-stack` label** | The selector that activates the rules | Missing this label = silent failure (rules ignored) |
| **`for:` pending duration** | Sustained-problem filter | Eliminates false alarms from brief spikes |
| **`rate()` over counters** | Converts cumulative counts to per-second rates | Raw counters only increase; rate gives meaningful velocity |
| **`sum() by (service)`** | Aggregate across all pods, group by service | Multi-pod services need aggregation |
| **`histogram_quantile(0.95)`** | P95 latency calculation | Average hides tail latency; P95 reflects real user experience |
| **`offset 10m`** | Compare current vs. past value | Detects changes over time (crash restart delta) |
| **`and` operator** | Multi-condition alerts | Prevent false alarms by requiring context (no orders AND orders are being sent) |
| **4 alert groups** | application / business / kubernetes / capacity | Organized scope — infrastructure vs. app vs. business |
| **`severity:` labels** | Route alerts to right team/channel | critical → page on-call, warning → Slack |
| **`team:` labels** | Route to right team | Multi-team clusters need alert routing |
| **`runbook:` annotation** | Link to operational procedure | Engineers at 3am need step-by-step guidance |
| **Business alerts** | `NoOrdersReceived`, `NotificationProcessingLag` | Tech can be "green" while business is broken — must check both |
| **`HPAMaxedOut` lead indicator** | Alert before capacity is fully exhausted | Fix before errors appear, not after |

---

## ✅ Phase 9 Complete — What's Next

After Phase 9, you can SEE everything:
- ✅ 14 alert rules covering application, business, Kubernetes, and capacity health
- ✅ Prometheus scraping all pods every 15 seconds
- ✅ Alertmanager routing alerts to Slack/PagerDuty based on severity and team
- ✅ Grafana dashboards showing real-time request rate, latency, error rate
- ✅ You get paged BEFORE users notice problems (lead indicators like HPAMaxedOut, PVCNearlyFull)

**Phase 10: Runbooks & Documentation** — Now that you have alerts, when one fires at 3am, what does the on-call engineer DO? The runbook is the step-by-step "when this alert fires, do *exactly* this." It's the operational brain of your team — codified into a document. 📋

*Edited relevant file*

### User Input

Okay lets start from Phase 10.
You need to explain each thing line by line for devops prespective, Block by block, I only know basic docker terraform and kubernets basic
So any new topic u need to explain in detail as if beginner.If something is developer work no in depth required, NO seperate Artifact, , share it here in this window

### Planner Response

Let me read all the Phase 10 files first.

*Viewed [runbook.md](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/docs/runbook.md) *

*Viewed [slo-definitions.md](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/docs/slo-definitions.md) *

### Planner Response

I have all the files. Here is the complete Phase 10 explanation:

---

# 📋 Phase 10 — Runbooks & Documentation — Complete Deep-Dive

---

## 🧠 Big Picture First — What Problem Does Phase 10 Solve?

You now have:
- Alerts firing via Prometheus → Alertmanager → Slack/PagerDuty (Phase 9)
- 14 alert rules covering every critical failure scenario

But imagine this: **It's 3am. Your phone buzzes. Alertmanager says `HighErrorRate FIRING - order-service`.** You're half asleep. What do you do?

**Without a runbook:** You wing it. You open the terminal, stare at it, try random `kubectl` commands, take 30 minutes to remember the right approach, make a mistake under pressure, prolong the outage.

**With a runbook:** You open the link in the alert (`docs/runbook.md#high-error-rate`), follow the steps **exactly as written**, fix the issue in 5 minutes, go back to sleep.

> **A runbook is a pre-written, step-by-step response procedure for each specific alert.** It's the on-call engineer's field manual. The goal is: **the person who gets paged at 3am should not need to think. They just follow the steps.**

Phase 10 has **2 documents:**
- [docs/runbook.md](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/docs/runbook.md:0:0-0:0) → Step-by-step incident procedures (tactical: "how to fix it NOW")
- [docs/slo-definitions.md](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/docs/slo-definitions.md:0:0-0:0) → SLI/SLO definitions (strategic: "how do we define and measure success?")

---

## 🆕 NEW CONCEPT: SLI, SLO, SLA, and Error Budget

Before reading the files, you absolutely need to understand these 4 terms. They are **the language of site reliability engineering (SRE)** — the discipline that does operations at scale.

### SLI — Service Level Indicator
**A specific, measurable metric about your service.**

| SLI | What it measures | Example |
|---|---|---|
| Availability | % of requests that succeed | 99.8% of requests returned non-5xx |
| Latency | How fast requests complete | P95 latency = 210ms |
| Error Rate | % of requests that fail | 0.4% of requests returned 5xx |
| Throughput | Requests per second | 450 req/s |

An SLI is just a measurement. It needs a TARGET to be meaningful → that's the SLO.

### SLO — Service Level Objective
**The target value you promise to hit for an SLI — an internal commitment.**

Examples:
- **Availability SLO:** "99.9% of requests should succeed"
- **Latency SLO:** "P95 latency should be below 500ms"
- **Error Rate SLO:** "Error rate should be below 1%"

SLOs are **internal goals** that your team commits to. They drive engineering priorities — if you're close to violating your SLO, you prioritize reliability work over new features.

### SLA — Service Level Agreement
**A contractual commitment to your customers.** If you miss it, there are penalties (refunds, credits).

```
SLI (measurement) → SLO (internal target) → SLA (contract with customers)
```

SLA is typically more relaxed than SLO. Example:
- SLO: 99.95% availability (your internal target)
- SLA: 99.9% availability (what you promise customers with penalties)

The gap between SLO and SLA gives you a safety buffer.

### Error Budget — The Most Important Concept
**The amount of unreliability you're ALLOWED.**

If your SLO is 99.9% availability:
```
Error Budget = 100% - 99.9% = 0.1% of time allowed to be down

In a 30-day month:
30 days × 24 hours × 60 min = 43,200 minutes
0.1% × 43,200 = 43.2 minutes of allowed downtime per month
```

**Error budgets change how engineering teams think:**

| Without Error Budget | With Error Budget |
|---|---|
| "Let's ship as fast as possible" | "We have 20 minutes of budget left this month" |
| "That outage was fine, users survived" | "That outage cost us 15 minutes = 35% of monthly budget" |
| Ops fights Dev: "stop breaking things" | Ops and Dev share the budget: both care equally |
| Reliability work is always deprioritized | When budget is spent → feature work pauses, reliability work takes over |

> **The error budget is the most powerful concept in modern SRE.** It creates alignment between development velocity and operational reliability.

---

## 📄 FILE 1: [docs/slo-definitions.md](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/docs/slo-definitions.md:0:0-0:0) — The Service Agreements

### Header Block

```markdown
## What are SLIs and SLOs?

- SLI (Service Level Indicator): A measurable metric about your service
- SLO (Service Level Objective): A target value for an SLI ("99.9% of requests succeed")
- Error Budget: The allowed amount of unreliability (e.g., 0.1% downtime = ~43 min/month)
```

This is the **definition section** — makes sure any engineer reading this document understands the terminology. Always document your terminology — different companies use these terms differently.

**`0.1% downtime = ~43 min/month`** — This is worth understanding deeply. The math:
```
30 days = 43,200 minutes
0.1% of 43,200 = 43.2 minutes ← your entire monthly downtime budget
```
99.9% sounds very reliable, but it only gives you 43 minutes of downtime per month. If a single deploy goes wrong and takes 45 minutes to roll back, you've **burned through your entire monthly budget** in one incident.

---

### Order Service SLOs

```markdown
## Order Service

| SLI | Measurement | SLO Target | Error Budget |
|---|---|---|---|
| Availability | rate(http_requests_total{status!~"5.."}[30d]) / rate(http_requests_total[30d]) | 99.9% | 43 min/month |
| Latency (P95) | histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) | < 500ms | N/A |
| Error Rate | rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) | < 1% | N/A |
```

**Column by column:**

**`SLI`** → What's being measured.

**`Measurement`** → The exact PromQL query used to measure it. Notice: these are the SAME PromQL expressions as the alert rules in Phase 9, just with different time windows and thresholds. SLOs (long-term targets) use `[30d]` windows. Alerts (short-term triggers) use `[5m]` windows.

**`Availability: rate(http_requests_total{status!~"5.."}[30d]) / rate(http_requests_total[30d])`**

Breaking this down:
- `{status!~"5.."}` → `!~` means "does NOT match regex" → all requests that are NOT 5xx (so 2xx, 3xx, 4xx)
- `[30d]` → 30-day window — this is a **long-term** measurement, not 5 minutes
- Result = (successful requests / total requests) over 30 days = availability percentage

**SLO Target: 99.9%** → 99.9% of requests over the last 30 days must succeed. If it drops below → SLO breach → error budget consumed → engineering escalation.

**Note:** The alert threshold for `HighErrorRate` is `> 5%` error rate for 5 minutes. But the SLO says `< 1%` error rate long-term. That's intentional:
- Alert = "something urgent is happening RIGHT NOW" (5% for 5min = acute incident)
- SLO = "are we reliably serving users over time" (1% over 30d = chronic health)

**`Latency (P95): < 500ms`** — Order-service's P95 latency target is 500ms. Notice the alert fires at 2 seconds (Phase 9). Why the gap?
- SLO (500ms) = what you aspire to as a baseline
- Alert (2s) = when you're in an acute crisis that needs immediate action

The gap gives you space to investigate degradation (500ms → 1s) before it reaches crisis level (2s).

**`Error Budget: 43 min/month`** — Only Availability has an error budget listed because uptime/downtime is time-based (minutes). Latency and Error Rate targets are continuous — they don't translate to "minutes of budget" naturally.

---

### User Service SLOs

```markdown
## User Service

| SLI | Measurement | SLO Target |
|---|---|---|
| Availability | Same formula as above | 99.9% |
| Latency (P95) | Same | < 300ms |
```

**`Latency SLO: < 300ms`** (vs. order-service's 500ms) → User-service is a simpler service — it just reads/writes from a single PostgreSQL table. No SQS, no httpx calls. It should be faster. A tighter SLO (`< 300ms`) reflects this.

This is how SLOs become **service-specific requirements** — they reflect the architecture and expected performance of each service individually.

---

### Notification Service SLOs

```markdown
## Notification Service

| SLI | Measurement | SLO Target |
|---|---|---|
| Availability | Health check success rate | 99.9% |
| Processing Lag | Time from SQS publish to notification processed | < 30 seconds |
| DLQ Rate | Messages in DLQ / total messages | < 0.1% |
```

**Different SLIs than the other services.** Why? Because notification-service works differently — it's not primarily an HTTP service receiving user requests. It's a **SQS consumer** — it polls a queue and processes messages.

**`Processing Lag: < 30 seconds`** — From when `order-service` publishes a message to SQS, to when `notification-service` processes it → this should be under 30 seconds. This is an **end-to-end business SLO** — customers expect near-real-time notifications when they place an order.

**`DLQ Rate: < 0.1%`** — Remember from Phase 3 (docker-compose): messages that fail processing 3 times go to the Dead Letter Queue. If MORE than 0.1% of all messages end up in the DLQ → something is systematically broken in the notification processing logic.

**Why is DLQ rate an SLO?** Because DLQ messages = notifications that were NEVER delivered to customers. Each message in the DLQ is a missed notification. 0.1% means you're allowed to miss 1 notification per 1000. More than that → breach.

---

### Alerting Thresholds Table

```markdown
## Alerting Thresholds

| Alert | Threshold | Severity | Action |
|---|---|---|---|
| HighErrorRate | > 5% for 5 min | Critical | Page on-call → immediate investigation |
| HighLatency | P95 > 2s for 5 min | Warning | Check logs → scale up if needed |
| PodCrashLoop | > 3 restarts in 10 min | Critical | Check logs → rollback deployment |
| DiskPressure | Node disk pressure | Critical | Expand EBS volume or add nodes |
```

**This table is the bridge between SLOs and operational alerts.** It shows:
- SLO target: availability 99.9%, error rate < 1%
- Alert fires at: > 5% error rate (gives time to react before SLO is severely breached)
- Severity: Critical → on-call paged immediately
- Action: what to do → links to the runbook

This table is critical for **new engineers joining the team** — one table tells them "if this fires, it means X, and you should do Y."

---

## 📄 FILE 2: [docs/runbook.md](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/docs/runbook.md:0:0-0:0) — The Step-by-Step Incident Procedures

```markdown
# Incident Response Runbook — KubeFlow Ops
```

### 🆕 NEW CONCEPT: What Makes a Good Runbook?

A good runbook has these properties:
1. **Named after the alert** — easy to find when the alert fires
2. **Severity clearly stated** — sets urgency
3. **Numbered steps** — follow in order, no thinking required
4. **Actual commands you can copy-paste** — no mental overhead
5. **Common causes listed** — helps narrow down quickly
6. **Escalation path** — who to call if you can't fix it

---

### RUNBOOK 1: `HighErrorRate (> 5% HTTP 5xx)`

```markdown
## Alert: HighErrorRate (> 5% HTTP 5xx)
### Severity: Critical

1. Check which service is affected
   kubectl get pods -n kubeflow-ops
   kubectl logs -n kubeflow-ops -l app=<service-name> --tail=100
```

**`kubectl get pods -n kubeflow-ops`** → First thing to run. Lists all pods and their status. You're looking for:
- `CrashLoopBackOff` → pod is crashing
- `OOMKilled` → pod ran out of memory
- `Error` → pod failed to start
- `Pending` → pod can't be scheduled (no node capacity)
- `Running` but errors happening? → look at logs

**`kubectl logs -n kubeflow-ops -l app=<service-name> --tail=100`** → Fetch the last 100 lines of logs from all pods of the service (the `-l app=<name>` is a **label selector** — same labels set in Phase 6's Helm chart):
- `-n kubeflow-ops` → namespace
- `-l app=<service-name>` → filter by label (e.g., `-l app=order-service`)
- `--tail=100` → last 100 log lines (don't dump gigabytes)

---

```markdown
2. Check recent deployments (was something just deployed?)
   kubectl rollout history deployment/<service-name> -n kubeflow-ops
```

**`kubectl rollout history`** → Shows the history of a Deployment — every time a new image was rolled out with a timestamp. This tells you: "did someone deploy in the last 10 minutes?" 

**Why this is Step 2:** The most common cause of sudden error spikes is a bad deployment. A new image with a bug was just pushed. Checking rollout history immediately tells you if that's the case.

**`deployment/<service-name>`** → Replace with `deployment/order-service`, etc.

---

```markdown
3. Rollback if recent deployment caused it
   kubectl rollout undo deployment/<service-name> -n kubeflow-ops
```

**`kubectl rollout undo`** → **This is the emergency stop button.** It immediately rolls the Deployment back to the previous image version — the one that was working before. No need to change any YAML files or git commits.

**How it works:**
```
Before deployment:   image: abc1233 (working)
After deployment:    image: abc1234 (broken - errors!)
kubectl rollout undo → image: abc1233 (working again)
```

Kubernetes starts replacing the new pods with old pods via a rolling update — the same rollout mechanism, but in reverse. **Zero downtime rollback.** In 30-60 seconds, you're back to the working version.

**Important NOTE:** This is an **emergency tactical fix**, not a permanent solution. After the rollback:
1. The error rate drops ✅
2. Alert resolves ✅  
3. Then you investigate WHY the new image was broken (separate task)
4. Fix the code, push a new commit → ArgoCD deploys the fixed version

**ArgoCD and `kubectl rollout undo`:** Here's a nuance — ArgoCD's `selfHeal: true` (Phase 7) will detect the rollback and try to re-apply the Git state (which still has the broken image tag). So after a rollback, you should also update `values.yaml` to point to the last known-good image tag and push to Git — that way both ArgoCD and the cluster agree on the working version.

---

```markdown
4. Check downstream dependencies
   - RDS: aws rds describe-db-instances --db-instance-identifier kubeflow-ops-dev-postgres
   - Redis: Is ElastiCache healthy?
   - SQS: Are messages piling up? aws sqs get-queue-attributes --queue-url <url> --attribute-names All
```

**Why check dependencies?** If the code hasn't changed but errors just started → the problem is likely NOT the code. It's an infrastructure dependency:

**`aws rds describe-db-instances`** → Check the RDS PostgreSQL status. Common issues:
- `status: stopped` → RDS was stopped (cost saving gone wrong)
- `status: incompatible-parameters` → parameter group change in progress
- `DBInstanceStatus: storage-full` → RDS ran out of disk → all writes fail
- High CPU/connection count → RDS is overwhelmed

**`aws sqs get-queue-attributes --attribute-names All`** → Checks SQS queue health. The important attributes to look at:
- `ApproximateNumberOfMessages` → messages waiting to be processed. If this is in the thousands → notification-service is falling behind
- `ApproximateNumberOfMessagesNotVisible` → messages currently being processed
- `ApproximateNumberOfMessagesDelayed` → messages in delay queue

---

```markdown
5. Check Grafana dashboards
   - Open SRE Overview dashboard
   - Look at error rate graph — when did it start?
   - Check pod logs: kubectl logs -n kubeflow-ops -l app=<service-name> --tail=200
```

**`Open SRE Overview dashboard`** → The Grafana dashboard shows historical trends. You can see:
- "Error rate was 0% for 3 weeks, then spiked at 14:32" → correlates with a deployment at 14:30
- "Error rate has been gradually increasing for 48 hours" → a slow memory leak, not a deployment bug

**`when did it start?`** → The time the error started is critical context. It tells you what changed around that time. Check:
- Did a deployment happen? (`kubectl rollout history`)
- Did traffic spike? (Grafana request rate graph)
- Did an AWS maintenance window happen? (AWS console)

---

### RUNBOOK 2: `PodCrashLoopBackOff`

```markdown
## Alert: PodCrashLoopBackOff
### Severity: Critical

1. Identify the crashing pod
   kubectl get pods -n kubeflow-ops | grep CrashLoop
```

**`| grep CrashLoop`** → The `|` is a Linux pipe — takes the output of `kubectl get pods` and filters it through `grep` (text search). Only shows lines containing "CrashLoop". Without `grep`, you'd see all pods. With it, you immediately see only the problematic ones.

**CrashLoopBackOff** means: the pod starts, crashes immediately, Kubernetes waits, tries again, crashes again, waits longer (exponential backoff), tries again... in a loop. The `BackOff` means Kubernetes is waiting between retries (starting at 10s, doubling each time up to 5 minutes).

---

```markdown
2. Check pod logs (including previous crash)
   kubectl logs <pod-name> -n kubeflow-ops --previous
```

**`--previous`** → This is the critical flag for CrashLoop debugging. 

When a pod crashes and restarts, Kubernetes creates a NEW container process. The old container's logs are normally gone. `--previous` fetches the logs from the **last crashed container** — the one that died. Those logs contain the **actual error message** that caused the crash.

Without `--previous`: you see logs from the current restart (which might be brief — just starting up)
With `--previous`: you see the error that caused the last crash

**What you're looking for in the logs:**
```
# Memory too small → OOMKilled
FATAL: Killed (OOMKilled), memory limit: 256Mi

# Can't connect to database → config error
sqlalchemy.exc.OperationalError: could not connect to server: Connection refused
Is the server running on host "postgres" (10.0.1.45) and accepting TCP/IP connections on port 5432?

# Missing environment variable → config error  
KeyError: 'DATABASE_URL'
```

---

```markdown
3. Check events for the pod
   kubectl describe pod <pod-name> -n kubeflow-ops
```

**`kubectl describe pod`** → This is the most detailed pod information command. Shows everything:
- What image is running
- Resource limits/requests
- All environment variables
- All volumes mounted
- **Events** (the most important section) — a timeline of what happened:

```
Events:
  Type     Reason     Message
  ----     ------     -------
  Warning  OOMKilling Container order-service was OOMKilled
  Warning  BackOff    Back-off restarting failed container
  Normal   Pulled     Successfully pulled image "ecr.../order-service:abc1234"
```

**Events tell the story of what happened** — even if the pod logs don't have the error (e.g., OOMKill doesn't show in app logs, it shows in events).

---

```markdown
4. Common causes:
   - OOMKilled → Increase memory limits
   - Config error → Check ConfigMap/Secrets
   - DB connection error → Check RDS security group / credentials
   - Image pull error → Check ECR repository and image tag
```

**`OOMKilled`** (Out of Memory Killed) → The pod exceeded its `resources.limits.memory` (256Mi from Phase 6). Linux kernel killed the process to protect the node.
- Fix: Increase `memory.limits` in `values.yaml` → push to Git → ArgoCD syncs → new pod with higher limit

**`Config error`** → Missing or wrong environment variable. Order-service needs `DATABASE_URL`. If the K8s Secret `db-credentials` doesn't exist yet (ESO hasn't synced it) → pod starts → tries to read the secret → fails → crash.
- Fix: Check `kubectl get secret db-credentials -n kubeflow-ops` — does it exist?

**`DB connection error`** → Pod is running but can't connect to RDS. Common causes:
- Wrong security group (VPC firewall not allowing EKS → RDS) → AWS console fix  
- Wrong credentials (ESO synced wrong values) → check AWS Secrets Manager
- RDS is down → check RDS status in AWS console

**`Image pull error`** → Pod can't pull the Docker image from ECR. Common causes:
- Wrong image tag in `values.yaml` (CI pushed wrong tag)
- ECR repository permissions issue (IRSA misconfigured)
- Image was deleted from ECR

---

### RUNBOOK 3: `HighLatency (P95 > 2s)`

```markdown
## Alert: HighLatency (P95 > 2s)
### Severity: Warning

1. Check current pod count and HPA status
   kubectl get hpa -n kubeflow-ops
   kubectl top pods -n kubeflow-ops
```

**`kubectl get hpa -n kubeflow-ops`** → Shows HPA status for all services:
```
NAME               MINPODS   MAXPODS   REPLICAS   CPU    MEMORY
order-service      2         10        8          78%    45%
user-service       2         10        2          22%    18%
```
- `REPLICAS: 8` with CPU `78%` → HPA is scaling up, load is high
- Is it at MAXPODS? → You might need to manually scale or increase maxReplicas

**`kubectl top pods -n kubeflow-ops`** → Shows **real-time** CPU and memory consumption of each pod (uses the Kubernetes Metrics Server):
```
NAME                           CPU(cores)   MEMORY(bytes)
order-service-abc-123          450m         220Mi
order-service-abc-456          480m         215Mi
```
If pods are near their limits → that's why latency is high. The app is CPU-throttled.

---

```markdown
2. Scale up if needed
   kubectl scale deployment/<service-name> -n kubeflow-ops --replicas=5
```

**`kubectl scale deployment`** → Manually force a higher replica count when HPA isn't scaling fast enough or you need immediate relief.

**When to use this vs. letting HPA handle it:**
- HPA auto-scales based on CPU/memory thresholds (Phase 6 HPA config)
- HPA has a `scaleUp.stabilizationWindow` (60 seconds) — it won't scale instantly
- During an active high-latency incident, you don't want to wait 60+ seconds
- `kubectl scale` gives **immediate** relief while HPA catches up

**Important:** This is temporary. After the incident, HPA will take over management. ArgoCD's `selfHeal` won't immediately revert this (HPA is managing the replica count, not ArgoCD's Deployment template directly).

---

```markdown
3. Check database performance
   - Are there slow queries? Check RDS Performance Insights
   - Is there connection pool exhaustion?
```

**`RDS Performance Insights`** → AWS Console → RDS → Performance Insights. Shows a graph of:
- Average active sessions (AAS) — how many queries are running concurrently
- Top SQL queries by wait time
- Database locks

If p95 latency is high but CPU seems fine → the bottleneck is likely the **database**, not the application. The app is fast, but it's waiting for slow DB queries.

**Connection pool exhaustion** → Each FastAPI app maintains a pool of DB connections (SQLAlchemy). If too many concurrent requests hit the same pod, the pool fills up → new requests wait for a connection → latency spikes. Fix: increase connection pool size in app config OR scale pods (more pods = more connection pools = more total DB connections).

---

```markdown
4. Check pod logs for slow operations
   kubectl logs -n kubeflow-ops -l app=<service-name> --tail=200
```

**`--tail=200`** → Last 200 log lines. For latency issues, you're looking for:
- Slow DB query logs: `WARNING: Query took 2.3s: SELECT * FROM orders WHERE...`
- Timeout errors: `httpx.TimeoutException: Timeout connecting to user-service`
- Lock contention: `DeadlockDetected` or `LockTimeout`

---

### RUNBOOK 4: `NodeDiskPressure`

```markdown
## Alert: NodeDiskPressure
### Severity: Critical

1. Identify the node
   kubectl get nodes -o wide
   kubectl describe node <node-name> | grep -A5 Conditions
```

**`kubectl get nodes -o wide`** → Lists all EKS worker nodes with their IP addresses:
```
NAME                     STATUS   ROLES    AGE   VERSION   INTERNAL-IP
ip-10-0-1-45.ec2...      Ready    <none>   5d    v1.28     10.0.1.45
ip-10-0-2-67.ec2...      Ready    <none>   5d    v1.28     10.0.2.67
```

**`kubectl describe node <node-name> | grep -A5 Conditions`** → Shows the Node Conditions block:
```
Conditions:
  Type                 Status   Message
  ----                 ------   -------
  DiskPressure         True     kubelet has disk pressure  ← This is what fired the alert
  MemoryPressure       False    ...
  PIDPressure          False    ...
  Ready                True     ...
```

**`-A5`** flag in grep → "show 5 lines **After** each match." Shows the condition block neatly.

---

```markdown
2. Clean up disk space
   docker system prune -af   # On the node: prune unused Docker images
```

**This is run ON THE NODE** (the EC2 instance), not just from your laptop via `kubectl`.

**`docker system prune -af`** → Deletes ALL unused Docker resources:
- Stopped containers
- Images not referenced by any container
- Unused networks
- Build cache

**`-a`** → Include all unused images (not just dangling ones)
**`-f`** → Force — don't ask for confirmation

**Why does this help?** EKS nodes accumulate old Docker images over time. Every deploy brings a new image, previous images stay on disk. Over time, `/var/lib/docker` fills up. `prune` clears the old images to free space.

**How to SSH to the node:** (you need this to run docker commands directly)
```bash
# Get the EC2 instance's private IP from kubectl get nodes -o wide
# SSH via Session Manager (no direct SSH needed with SSM)
aws ssm start-session --target <instance-id>
```

---

```markdown
3. If persistent: Increase EBS volume size or let Karpenter provision new nodes
```

**If `docker system prune` isn't enough:** The node's EBS root volume needs to be expanded.

**`Karpenter`** → An automatic node provisioner for Kubernetes (newer alternative to Cluster Autoscaler). If configured, Karpenter automatically adds new EC2 nodes when pods can't be scheduled (not in this project by default, but mentioned as an option).

---

### RUNBOOK 5: General Debugging Commands

```bash
## General Debugging Commands

# Cluster health
kubectl cluster-info             # API server URL, DNS service
kubectl get nodes -o wide        # Node list with IPs, status
kubectl top nodes                # CPU/memory usage per node

# Application status
kubectl get all -n kubeflow-ops  # Everything in the namespace
kubectl get events -n kubeflow-ops --sort-by='.lastTimestamp'  # Events chronologically

# ArgoCD status
kubectl get applications -n argocd  # All ArgoCD applications and sync state
argocd app list                     # Same but in ArgoCD CLI format

# Check all problem pods (not Running and not Completed)
kubectl get pods -A | grep -v Running | grep -v Completed
```

**`kubectl cluster-info`** → Quick sanity check. If this fails, the API server is unreachable — nothing else will work. Verify you have the right kubeconfig.

**`kubectl get all -n kubeflow-ops`** → Shows ALL resource types (pods, services, deployments, HPAs, etc.) in the namespace. Good overview.

**`kubectl get events -n kubeflow-ops --sort-by='.lastTimestamp'`** → Events are like Kubernetes' audit log — every significant action is recorded:
- "pod is OOMKilled"
- "image pulled successfully"
- "failed to schedule pod"
- "deployment rolled out successfully"

**`--sort-by='.lastTimestamp'`** → Sort events newest-last (the most recent events at the bottom, easiest to read). Without sort, events are in random order.

**`kubectl get pods -A | grep -v Running | grep -v Completed`** → 🔑 The most useful "what's wrong right now" command.
- `-A` → All namespaces (not just kubeflow-ops)
- `grep -v Running` → exclude Running pods (they're fine)
- `grep -v Completed` → exclude Completed pods (Jobs that finished successfully — also fine)
- Result: Only shows pods in `Pending`, `CrashLoopBackOff`, `Error`, `OOMKilled`, `Evicted` states

In a healthy cluster, this command returns nothing. When something is broken, it immediately shows you what and where.

**`kubectl get applications -n argocd`** → Shows all ArgoCD Applications and whether they're `Synced` / `Healthy` or `OutOfSync` / `Degraded`. Quick way to check if ArgoCD is aware of any issues.

---

## 🔄 The Complete Incident Response Flow

```
ALERT FIRES: "HighErrorRate - order-service [CRITICAL]"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Slack/PagerDuty notification received
Link in alert: docs/runbook.md#highErrorRate
                    │
                    ▼
Engineer opens runbook (< 30 seconds)
Follows steps 1-5 exactly
                    │
        ┌───────────┴──────────────┐
        │                          │
   Recent deploy?            No recent deploy?
        │                          │
        ▼                          ▼
`kubectl rollout undo`     Check dependencies (RDS/SQS)
  (2-minute fix)           Check Grafana for when it started
        │                  Check pod logs for error pattern
        │                          │
        └───────────┬──────────────┘
                    │
                    ▼
           Alert resolves → "RESOLVED" notification
           Write post-mortem if SLO breached
           Fix root cause properly (separate task)
```

---

## 🆕 NEW CONCEPT: The Post-Mortem (Blameless Culture)

After a critical incident (especially SLO breach):

> **A post-mortem is a written analysis of what happened, why, and what we'll do to prevent it.** The key word: **blameless**. It doesn't matter WHO made the mistake — it matters WHAT systemic process allowed the mistake to happen.

A good post-mortem contains:
1. **Timeline** — exact sequence of events (with timestamps)
2. **Root cause** — the actual technical reason
3. **Contributing factors** — what made it worse/harder to detect
4. **Impact** — how many users, how long, SLO impact, error budget consumed
5. **Action items** — what changes to make to prevent recurrence

In this project: after a `PodCrashLoopBackOff` caused by a missing Secret:
- NOT: "John forgot to create the secret"
- IS: "Our deployment process doesn't verify prerequisites (ESO sync) before deploying. We'll add a smoke test in Phase 11 that checks for required secrets before calling a deploy successful."

---

## 🔑 Key DevOps Takeaways from Phase 10

| Concept | What It Is | Why It Matters |
|---|---|---|
| **SLI** | Measurable metric (availability, latency, error rate) | Quantifies service health objectively |
| **SLO** | Target value for an SLI (99.9%, <500ms) | Sets the standard before incidents happen |
| **SLA** | Customer-facing contract (typically less strict than SLO) | Legal commitment — missing it costs money |
| **Error Budget** | Allowed downtime (e.g., 43 min/month for 99.9%) | Balances velocity vs. reliability at the team level |
| **Runbook** | Step-by-step fix procedure per alert | 3am fix in 5 min vs. 30 min war room |
| **`--previous` flag** | Gets crashed pod's logs | Only way to see why a CrashLoop pod died |
| **`kubectl rollout undo`** | Emergency rollback to previous image | Fastest possible recovery from bad deploy |
| **`kubectl describe pod`** | Full pod details including Events section | Reveals OOMKill, ImagePullError, scheduling failure |
| **`| grep -v Running`** | Filter to only problem pods | One command shows cluster health at a glance |
| **`--sort-by=.lastTimestamp`** | Events in time order | Find what Kubernetes just noticed |
| **DLQ Rate SLO** | % of messages that end up in dead letter queue | Catches broken async processing (not visible in HTTP metrics) |
| **Blameless post-mortem** | Analyze what failed, not who failed | Creates learning culture, improves systems over time |

---

## ✅ Phase 10 Complete — What's Next

After Phase 10, your operations are codified:
- ✅ SLOs defined for every service with specific PromQL measurements
- ✅ Error budgets calculated — teams know how much downtime is acceptable
- ✅ Runbooks cover every critical alert — step-by-step recovery in hand
- ✅ General debugging commands documented — any engineer can investigate
- ✅ Common failure causes documented — OOMKill, bad deploy, DB issue, image pull failure

**Phase 11: Operational Scripts** — The final phase automates the tedious manual steps. Instead of running 10 commands to set up OIDC, or manually creating secrets in AWS SM, Phase 11 gives you shell scripts for: bootstrapping ArgoCD, creating AWS secrets, setting up GitHub-AWS OIDC trust, and running smoke tests after every deployment. 🔧