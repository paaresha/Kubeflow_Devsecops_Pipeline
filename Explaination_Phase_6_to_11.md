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