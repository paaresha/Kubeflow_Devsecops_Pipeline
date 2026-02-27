# Chat Conversation

Note: _This is purely the output of the chat conversation and does not contain any raw data, codebase snippets, etc. used to generate the output._

### User Input

Please start from begining , explaining the project block by block, in exact order whihc a devops engineer will write the files from, divide in phases, and explain each block wise, 
Know that , I know only docker , Kubernetes, aws, terraform, so if you are using any other thing, u need to explain in detail as a beginner.

Laslty dont last all at once, move 1 phase at a time.

Also, do tell me how u get what info, assume Devloper only gave me the app directory code.
So need to write all other from scratch like docker file, k8 terarfomr etc..any doubt ask me first

### Planner Response

Let me first look at your project directory to understand what the developer gave you.

*Listed directory [PROJECT_Devsecops_Pipeline](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline) *

*Listed directory [apps](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/apps) *

*Listed directory [gitops](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/gitops) *

*Listed directory [terraform](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform) *

*Listed directory [scripts](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/scripts) *

*Listed directory [order-service](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/apps/order-service) *

*Listed directory [user-service](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/apps/user-service) *

*Listed directory [notification-service](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/apps/notification-service) *

*Listed directory [apps](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/gitops/apps) *

*Listed directory [platform](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/gitops/platform) *

*Viewed [main.py](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/apps/order-service/main.py) *

*Viewed [requirements.txt](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/apps/order-service/requirements.txt) *

*Viewed [Dockerfile](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/apps/order-service/Dockerfile) *

*Viewed [main.py](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/apps/user-service/main.py) *

*Viewed [main.py](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/apps/notification-service/main.py) *

*Viewed [README.md](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/README.md) *

### Planner Response

Now I have a complete picture of the project. Let me give you a thorough, phase-by-phase explanation.

---

# 🗺️ Project: KubeFlow Ops — DevSecOps Pipeline Explained

## How I Got This Information (Your Question First!)

> **"Assume the developer only gave me the `apps/` directory."**

Here's exactly how I reverse-engineered everything else:

| What I read | What I learned |
|---|---|
| `apps/*/main.py` | Language (Python), framework (FastAPI), what databases/services are needed (Postgres, Redis, SQS), what ports each service runs on, what env vars the app expects |
| `apps/*/requirements.txt` | Every Python package = every tool we need to support |
| The `DATABASE_URL`, `SQS_QUEUE_URL`, `REDIS_URL` env vars in code | We need **AWS RDS** (PostgreSQL), **AWS ElastiCache** (Redis), **AWS SQS** — so those become Terraform modules |
| `/healthz` and `/readyz` endpoints in code | We know Kubernetes health probes need these exact paths |
| `/metrics` endpoint from `prometheus_fastapi_instrumentator` | We know we need Prometheus scraping |
| `OTLPSpanExporter` in imports | We know we need Tempo (tracing backend) |
| Port numbers in comments (`8001`, `8002`, `8003`) | These go into Kubernetes Service definitions and Dockerfiles |

**That's how a real DevOps engineer works** — read the app code, extract dependencies, then build the surrounding infrastructure.

---

## 🏗️ Big Picture Architecture (Read This First)

```
┌──────────────────────────────────────────────────────┐
│                   DEVELOPER PUSHES CODE               │
│                   to GitHub                           │
└────────────────────────┬─────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────┐
│               PHASE 2: GitHub Actions (CI)            │
│  1. Run Tests                                         │
│  2. Scan for vulnerabilities (Trivy)                  │
│  3. Build Docker Image                                │
│  4. Push image to AWS ECR                             │
│  5. Update image tag in gitops/ folder                │
└────────────────────────┬─────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────┐
│               PHASE 4: ArgoCD (CD)                    │
│  Watches gitops/ in Git                               │
│  Detects the new image tag                            │
│  Deploys to EKS cluster automatically                 │
└────────────────────────┬─────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────┐
│               PHASE 3: AWS EKS Cluster                │
│  (Created by Terraform in Phase 1)                    │
│                                                       │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────┐ │
│  │ user-service│  │order-service│  │notification  │ │
│  │  :8002      │◄─│  :8001      │─►│  service     │ │
│  └─────────────┘  └──────┬──────┘  │  :8003       │ │
│                           │         └──────┬───────┘ │
│                           ▼                │         │
│                    AWS SQS Queue ──────────┘         │
│  AWS RDS (Postgres) ← used by user + order           │
│  AWS ElastiCache (Redis) ← used by notification      │
└──────────────────────────────────────────────────────┘
```

---

## 📦 The Project has 5 Phases

| Phase | What You Build | Files |
|---|---|---|
| **Phase 1** | Dockerfiles — containerize the apps | `apps/*/Dockerfile` |
| **Phase 2** | Terraform — AWS infrastructure (VPC, EKS, RDS, etc.) | `terraform/` |
| **Phase 3** | Kubernetes Manifests — deploy on EKS | `gitops/` |
| **Phase 4** | GitHub Actions — CI/CD pipeline | `.github/workflows/` |
| **Phase 5** | Monitoring & Security (Prometheus, Kyverno, etc.) | `gitops/platform/` |

---

# 🐳 PHASE 1 — Dockerfiles

> **"Why do we start here?"** Because before anything runs in Kubernetes or AWS, it has to be a Docker image. Docker is the foundation.

## What the developer gave you in `apps/`

```
apps/
├── order-service/
│   ├── main.py          ← the actual Python app
│   └── requirements.txt ← Python packages it needs
├── user-service/
│   ├── main.py
│   └── requirements.txt
└── notification-service/
    ├── main.py
    └── requirements.txt
```

## How YOU figured out what goes in the Dockerfile

You read `main.py` and found:
- It's Python → base image: `python:3.12-slim`
- It runs with `uvicorn` (in `requirements.txt`) → CMD will use uvicorn
- Order service port = **8001**, User service = **8002**, Notification = **8003** (from comments in code)
- Security requirement: run as non-root (you'll enforce this later with Kyverno)

## The Dockerfile — Block by Block

Here's the **order-service Dockerfile** explained line by line:

```dockerfile
# ══ STAGE 1: Builder ══
FROM python:3.12-slim AS builder
```
> **What:** `FROM` picks the base image. `python:3.12-slim` is a minimal Linux image with Python pre-installed. `AS builder` names this stage — it's temporary.
> **Why slim?** Smaller = fewer security vulnerabilities. The full `python:3.12` image is ~900MB. `slim` is ~130MB.
> **Why "AS builder"?** This is called a **multi-stage build**. Stage 1 is just for installing packages. We'll throw it away at the end.

```dockerfile
WORKDIR /build
```
> **What:** Sets the working directory inside the container. All subsequent commands run from `/build`.
> Think of it like `cd /build` inside the container.

```dockerfile
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt
```
> **What:** Copies your `requirements.txt` into the container, then installs all Python packages.
> **Key trick:** `--prefix=/install` installs packages into `/install` folder (not the system Python). We do this so we can copy *just* these packages into Stage 2.
> **`--no-cache-dir`:** Don't save pip's download cache → smaller image.
> **Why copy requirements FIRST, then code?** Docker **caches layers**. If requirements haven't changed, Docker skips the slow `pip install` step next time. If you copied all code first, every code change would re-run pip install. Huge time saver.

```dockerfile
# ══ STAGE 2: Production Image ══
FROM python:3.12-slim
```
> **What:** Start fresh from a clean slim Python image. No build tools, no pip cache, no garbage from Stage 1.
> **Why:** This is what actually ships to production. It's clean, small, and secure.

```dockerfile
RUN groupadd -r appuser && useradd -r -g appuser appuser
```
> **What:** Creates a Linux user called `appuser`. By default, Docker containers run as **root** — which is dangerous. If an attacker breaks in, they'd have full system access.
> **Why:** Running as non-root is a security best practice. Later, Kyverno will *enforce* this — any pod trying to run as root will be rejected.

```dockerfile
WORKDIR /app
COPY --from=builder /install /usr/local
COPY main.py .
```
> **What:**
> - Set working dir to `/app`
> - Copy the installed Python packages from Stage 1's `/install` to the production image's `/usr/local` (where Python expects them)
> - Copy the actual app code

```dockerfile
USER appuser
```
> **What:** Switch from root to our non-root user. All commands after this run as `appuser`.

```dockerfile
EXPOSE 8001
```
> **What:** Documents that this container listens on port 8001. This is just metadata — doesn't actually open the port. Kubernetes Services do that.

```dockerfile
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8001/healthz')" || exit 1
```
> **What:** Docker's built-in health check. Every 30 seconds, it calls `/healthz`. If it fails 3 times, Docker marks the container as unhealthy.
> **Note:** In Kubernetes, we use K8s probes instead, but this is good belt-and-suspenders practice.

```dockerfile
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8001"]
```
> **What:** The command that runs when the container starts.
> - `uvicorn` = production web server for Python async apps (like Nginx but for Python)
> - `main:app` = file `main.py`, variable `app` (the FastAPI object)
> - `--host 0.0.0.0` = listen on all network interfaces (required inside containers — `localhost` alone won't work)
> - `--port 8001` = listen on port 8001

---

## 🔤 How the 3 Dockerfiles differ

| Service | Port | Key difference |
|---|---|---|
| `order-service` | 8001 | Standard — talks to Postgres + SQS |
| `user-service` | 8002 | Simplest — only needs Postgres |
| `notification-service` | 8003 | Has Redis + SQS consumer background thread |

The Dockerfiles are **identical in structure**, only the port changes. You write the same pattern 3 times with a different port number.

---

## 🗂️ What `docker-compose.yml` is for (Local Dev only)

> **"What's `docker-compose.yml` at the root?"**

This is for **local development only** — it runs all 3 services + Postgres + Redis + **LocalStack** on your laptop without needing AWS.

**LocalStack** = a tool that pretends to be AWS on your local machine. Free to use. It simulates SQS so you can test the notification service without an actual AWS account.

> **Important:** `docker-compose.yml` is **NOT used in production**. In production, Kubernetes does the orchestration.

---

## ✅ Phase 1 Summary

```
What you built:         3 Dockerfiles (one per microservice)
What it does:           Packages Python apps into lightweight, secure Docker images
Why you built it first: Everything else (K8s, CI/CD) depends on images existing
Next step:              Build AWS infrastructure to run these images on
```

---

**Ready to move to Phase 2 (Terraform — AWS Infrastructure)?**

That's where things get really interesting — I'll walk you through each Terraform module (VPC, EKS, RDS, ElastiCache, SQS, ECR) block by block, explaining **exactly how I knew we needed each one** from reading the app code.

Just say **"continue"** and we'll go! 🚀

### User Input

No, I said explain block by block and u missed docker compose so do that first

### Planner Response

You're right, my bad! Let me read the [docker-compose.yml](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/docker-compose.yml:0:0-0:0) first.

*Viewed [docker-compose.yml](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/docker-compose.yml) *

*Viewed [localstack-init.sh](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/scripts/localstack-init.sh) *

### Planner Response

Good, I have everything. Now let me walk you through it **completely, block by block**.

---

# 🐳 [docker-compose.yml](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/docker-compose.yml:0:0-0:0) — Complete Block-by-Block Explanation

## First — What Is Docker Compose & Why Do We Need It?

When the developer hands you 3 Python apps, each one needs:
- A **database** (PostgreSQL)
- A **cache** (Redis)
- An **AWS SQS queue** (for passing messages between services)

In production, those live in AWS. But locally, during development, you don't want to:
- Pay AWS money for every test
- Need internet access to develop
- Set up a real AWS account just to run the app

**Docker Compose** solves this. It's a tool that lets you define multiple containers and run them all together with one command: `docker-compose up`

Think of it as: **"Run my entire local environment in one shot."**

---

## 📐 The Top-Level Structure

```yaml
services:
  postgres: ...
  redis: ...
  localstack: ...
  order-service: ...
  user-service: ...
  notification-service: ...

volumes:
  postgres_data:
```

Every entry under `services:` = one container. There are **6 containers** total:

| Container | What it is | Why it's needed |
|---|---|---|
| `postgres` | Database server | Stores users + orders (found `DATABASE_URL` in the app code) |
| `redis` | Cache server | Stores processed message IDs (found `REDIS_URL` in notification service) |
| `localstack` | Fake AWS | Simulates SQS locally (found `SQS_QUEUE_URL` pointing to localstack in code) |
| `order-service` | Your app | Handles orders |
| `user-service` | Your app | Handles users |
| `notification-service` | Your app | Processes events from SQS |

> **How did I know we needed all these?** I read the env vars in [main.py](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/apps/user-service/main.py:0:0-0:0) — `DATABASE_URL`, `REDIS_URL`, `SQS_QUEUE_URL`, `AWS_ENDPOINT_URL`. Each one tells you "this service needs X to exist."

---

## 🔷 Block 1 — PostgreSQL (Lines 13–27)

```yaml
postgres:
  image: postgres:16-alpine
  environment:
    POSTGRES_USER: postgres
    POSTGRES_PASSWORD: postgres
    POSTGRES_DB: kubeflow
  ports:
    - "5432:5432"
  volumes:
    - postgres_data:/var/lib/postgresql/data
  healthcheck:
    test: ["CMD-SHELL", "pg_isready -U postgres"]
    interval: 5s
    timeout: 5s
    retries: 5
```

**Line by line:**

| Line | What it does | Why |
|---|---|---|
| `image: postgres:16-alpine` | Use the official Postgres 16 Docker image. `alpine` = tiny Linux base, smaller image. | We don't need to install Postgres — the image has it pre-built |
| `POSTGRES_USER / PASSWORD / DB` | These env vars tell Postgres what credentials and database name to create on first start | Matches exactly what's in [main.py](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/apps/user-service/main.py:0:0-0:0): `postgresql://postgres:postgres@localhost:5432/kubeflow` |
| `ports: "5432:5432"` | Format is `HOST_PORT:CONTAINER_PORT`. Maps your laptop's port 5432 to the container's port 5432 | So you can connect with a DB tool like TablePlus from your laptop on `localhost:5432` |
| `volumes: postgres_data:/var/lib/postgresql/data` | Saves the database files to a **named volume** (persistent storage managed by Docker) | Without this, every time you run `docker-compose down`, all your data is gone forever. This keeps data between restarts. |
| `healthcheck` | Runs `pg_isready` (Postgres's own built-in check) every 5 seconds | Other services (like order-service) use `depends_on: condition: service_healthy` — they won't start until this passes. Prevents "DB not ready" crashes on startup. |

---

## 🔷 Block 2 — Redis (Lines 30–38)

```yaml
redis:
  image: redis:7-alpine
  ports:
    - "6379:6379"
  healthcheck:
    test: ["CMD", "redis-cli", "ping"]
    interval: 5s
    timeout: 5s
    retries: 5
```

**Line by line:**

| Line | What it does | Why |
|---|---|---|
| `image: redis:7-alpine` | Official Redis 7 image, Alpine (small) | Redis is the in-memory cache. No config needed — defaults work fine |
| `ports: "6379:6379"` | Exposes Redis port to your host machine | You can inspect Redis with tools like RedisInsight on `localhost:6379` |
| `healthcheck: redis-cli ping` | Sends a `PING` command to Redis. Redis replies `PONG` if healthy | Notification service depends on Redis being ready before starting |

> **No `volumes:` here** — Redis is used for *temporary* deduplication (24hr TTL). If it resets between restarts, that's fine. The notification service will just re-check.

---

## 🔷 Block 3 — LocalStack (Lines 43–51)

```yaml
localstack:
  image: localstack/localstack:3.0
  environment:
    SERVICES: sqs
    DEFAULT_REGION: us-east-1
  ports:
    - "4566:4566"
  volumes:
    - ./scripts/localstack-init.sh:/etc/localstack/init/ready.d/init.sh
```

**What is LocalStack?** It's a tool that runs on your machine and pretends to be AWS. It implements the same API as real AWS, so your code thinks it's talking to AWS but it's actually talking to a local process.

**Line by line:**

| Line | What it does | Why |
|---|---|---|
| `image: localstack/localstack:3.0` | Official LocalStack image | Free, runs offline, simulates AWS services |
| `SERVICES: sqs` | Only start the SQS simulation (not all of AWS) | Faster startup. We only need SQS, so why load the rest? |
| `DEFAULT_REGION: us-east-1` | Sets the fake AWS region | Must match `AWS_REGION: us-east-1` set in the app services |
| `ports: "4566:4566"` | LocalStack exposes all fake-AWS APIs on port 4566 | The app code points to `http://localstack:4566` or `http://localhost:4566` |
| `volumes: ./scripts/localstack-init.sh:/etc/localstack/init/ready.d/init.sh` | **This is the key line.** Mounts our init script into LocalStack's "run-on-startup" folder | LocalStack automatically runs any [.sh](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/scripts/localstack-init.sh:0:0-0:0) file placed in `/etc/localstack/init/ready.d/` when it's ready. So our script creates the SQS queues automatically. |

> **Why do we need to create SQS queues?** Real AWS SQS queues must be created before you use them. LocalStack is the same — the queue doesn't exist until we create it. The [localstack-init.sh](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/scripts/localstack-init.sh:0:0-0:0) script does that.

---

## 🔷 Block 3a — [scripts/localstack-init.sh](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/scripts/localstack-init.sh:0:0-0:0) (The Init Script)

```bash
#!/bin/bash
# Create the dead-letter queue first (DLQ)
awslocal sqs create-queue \
    --queue-name order-events-dlq \
    --attributes '{"MessageRetentionPeriod":"1209600"}'

# Get the DLQ ARN
DLQ_ARN=$(awslocal sqs get-queue-attributes \
    --queue-url http://localhost:4566/000000000000/order-events-dlq \
    --attribute-names QueueArn \
    --query 'Attributes.QueueArn' \
    --output text)

# Create the main queue pointing to the DLQ
awslocal sqs create-queue \
    --queue-name order-events \
    --attributes "{\"RedrivePolicy\":...}"
```

**New Term — `awslocal`:** This is just `aws` CLI but pre-configured to talk to LocalStack instead of real AWS (it automatically points to `http://localhost:4566`). It's bundled inside the LocalStack container.

**New Term — DLQ (Dead Letter Queue):** Imagine a message arrives in your main SQS queue. The notification service tries to process it and fails — maybe Redis is down. SQS will retry. After **3 failed attempts** (`maxReceiveCount: 3`), SQS gives up and moves the message to the **Dead Letter Queue**. This is your "parking lot for broken messages". You can investigate them later without losing data.

**Flow:**

```
Order created → message sent to [order-events queue]
                    ↓
           notification-service reads it
                    ↓
           If fails 3 times → moved to [order-events-dlq]
                    ↓
           Engineer investigates why it failed
```

| Line | What it does |
|---|---|
| `awslocal sqs create-queue --queue-name order-events-dlq` | Creates the dead-letter queue first (must exist before the main queue references it) |
| `MessageRetentionPeriod: 1209600` | Keep failed messages for 14 days (1209600 seconds) so you have time to debug |
| `DLQ_ARN=$(awslocal sqs get-queue-attributes ...)` | Gets the DLQ's unique ID (ARN = Amazon Resource Name) — needed to link it to the main queue |
| `awslocal sqs create-queue --queue-name order-events` | Creates the main working queue |
| `RedrivePolicy: maxReceiveCount: 3` | "After 3 failed attempts, send to DLQ" |

---

## 🔷 Block 4 — Order Service (Lines 54–75)

```yaml
order-service:
  build:
    context: ./apps/order-service
    dockerfile: Dockerfile
  ports:
    - "8001:8001"
  environment:
    DATABASE_URL: postgresql://postgres:postgres@postgres:5432/kubeflow
    SQS_QUEUE_URL: http://localstack:4566/000000000000/order-events
    USER_SERVICE_URL: http://user-service:8002
    AWS_REGION: us-east-1
    AWS_ENDPOINT_URL: http://localstack:4566
    AWS_ACCESS_KEY_ID: test
    AWS_SECRET_ACCESS_KEY: test
    OTLP_ENDPOINT: ""
  depends_on:
    postgres:
      condition: service_healthy
    localstack:
      condition: service_started
    user-service:
      condition: service_started
```

**Line by line:**

| Line | What it does | Why |
|---|---|---|
| `build: context: ./apps/order-service` | Tells Compose to **build** the image from source using the Dockerfile in that folder | Instead of pulling a pre-built image, it builds fresh from your code |
| `ports: "8001:8001"` | Exposes app on `localhost:8001` | You can open `http://localhost:8001/docs` in your browser |
| `DATABASE_URL: ...@postgres:5432/...` | Connection string for Postgres | Note: `@postgres` (not `@localhost`) — inside Docker network, services talk to each other by **service name**, not `localhost` |
| `SQS_QUEUE_URL: http://localstack:4566/...` | Points to the fake SQS in LocalStack | `000000000000` is a fake AWS account ID LocalStack uses |
| `USER_SERVICE_URL: http://user-service:8002` | Where to find the user-service | Order service calls this to check if a user exists before creating an order |
| `AWS_ACCESS_KEY_ID: test` / `AWS_SECRET_ACCESS_KEY: test` | Fake credentials | LocalStack doesn't validate them — any string works. Never put real AWS keys here! |
| `OTLP_ENDPOINT: ""` | Disables OpenTelemetry tracing | Tempo (the tracing server) isn't running locally, so we just disable it to avoid errors |
| `depends_on: postgres: condition: service_healthy` | **Wait for postgres to pass its healthcheck before starting** | Without this, order-service starts, tries to connect to Postgres which isn't ready yet, and crashes |
| `depends_on: user-service: condition: service_started` | Wait for user-service to at least start | Order-service needs to call user-service — if it's not up, the first request will fail |

---

## 🔷 Block 5 — User Service (Lines 78–89)

```yaml
user-service:
  build:
    context: ./apps/user-service
    dockerfile: Dockerfile
  ports:
    - "8002:8002"
  environment:
    DATABASE_URL: postgresql://postgres:postgres@postgres:5432/kubeflow
    OTLP_ENDPOINT: ""
  depends_on:
    postgres:
      condition: service_healthy
```

This is the **simplest service**. It only needs:
- PostgreSQL (to store users)
- No Redis, no SQS, no AWS

> **How did I know?** User service's [main.py](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/apps/user-service/main.py:0:0-0:0) only imports `sqlalchemy` (DB) — no boto3 (AWS), no redis. Only one env var needed: `DATABASE_URL`.

---

## 🔷 Block 6 — Notification Service (Lines 92–110)

```yaml
notification-service:
  build:
    context: ./apps/notification-service
    dockerfile: Dockerfile
  ports:
    - "8003:8003"
  environment:
    SQS_QUEUE_URL: http://localstack:4566/000000000000/order-events
    REDIS_URL: redis://redis:6379/0
    AWS_REGION: us-east-1
    AWS_ENDPOINT_URL: http://localstack:4566
    AWS_ACCESS_KEY_ID: test
    AWS_SECRET_ACCESS_KEY: test
    OTLP_ENDPOINT: ""
  depends_on:
    redis:
      condition: service_healthy
    localstack:
      condition: service_started
```

> **How did I know these env vars?** I looked at [notification-service/main.py](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/apps/notification-service/main.py:0:0-0:0) lines 34–40 and listed every `os.getenv(...)` call. That's your complete list of env vars needed.

Key difference from order-service:
- Needs **Redis** (for deduplication), not Postgres
- Needs **SQS** (to consume messages), not to call user-service
- No `DATABASE_URL` — notification service doesn't store anything in Postgres

---

## 🔷 Block 7 — Volumes (Line 112–113)

```yaml
volumes:
  postgres_data:
```

This **declares** the named volume `postgres_data`.

Think of named volumes like Docker-managed disk partitions. Docker creates a folder somewhere on your system, manages it, and mounts it into the container.

- **Without volumes:** Stop container → all data gone forever
- **With `postgres_data` volume:** Stop container → data survives → restart → data is still there

> **Why only for Postgres and not Redis?** Redis data is temporary by design (24hr TTL on processed message IDs). Losing it on restart is acceptable. Losing your database on restart is not.

---

## 🌐 The Docker Internal Network — Critical Concept

One thing that confuses beginners:

```yaml
# Inside container, you talk to other services by SERVICE NAME
DATABASE_URL: postgresql://postgres:postgres@postgres:5432/kubeflow
#                                                  ^^^^^^^^
#                                        This is the service name, not "localhost"

USER_SERVICE_URL: http://user-service:8002
#                          ^^^^^^^^^^^^
#                          Service name again
```

Docker Compose automatically creates a **private network** for all services in the file. Every service can reach every other service using its **service name** as a hostname.

```
┌─────────────────── Docker Private Network ──────────────────┐
│                                                              │
│  order-service ──── postgres:5432  ──────► [postgres]       │
│       │                                                      │
│       └──── user-service:8002 ──────────► [user-service]    │
│       │                                                      │
│       └──── localstack:4566 ────────────► [localstack]      │
│                                                              │
│  notification-service ── redis:6379 ────► [redis]           │
│                       ── localstack:4566► [localstack]       │
└──────────────────────────────────────────────────────────────┘

From your laptop browser:  localhost:8001, localhost:8002, localhost:8003
```

---

## ✅ Complete Flow When You Run `docker-compose up`

```
Step 1: Docker starts postgres → waits for healthcheck to pass
Step 2: Docker starts redis   → waits for healthcheck to pass
Step 3: Docker starts localstack → starts up
Step 4: localstack-init.sh runs → creates order-events + order-events-dlq queues
Step 5: user-service starts (postgres is healthy now)
Step 6: order-service starts (postgres healthy + user-service started)
Step 7: notification-service starts (redis healthy + localstack started)

Now everything is up. You can:
→ Open http://localhost:8001/docs → Create an order
→ Order service calls user-service to validate user
→ Order service sends event to SQS (LocalStack)
→ Notification service polls SQS, finds the event, logs it
→ Open http://localhost:8003/notifications → See it processed
```

---

## 📋 Phase 1 Complete Summary

```
Files in Phase 1:
├── apps/order-service/Dockerfile        ← Build order-service image
├── apps/user-service/Dockerfile         ← Build user-service image
├── apps/notification-service/Dockerfile ← Build notification-service image
├── docker-compose.yml                   ← Run everything locally
└── scripts/localstack-init.sh           ← Create SQS queues on startup

Purpose: Run all 3 services + all dependencies locally with one command
Does NOT touch AWS — everything is local
```

---

**Ready to move to Phase 2 — Terraform (AWS Infrastructure)?**

That's where we build the real AWS environment: VPC, EKS cluster, RDS (real Postgres), ElastiCache (real Redis), SQS (real queues), and ECR (Docker image registry). I'll go module by module. Just say **"continue"**! 🚀

### User Input

Lets go

### Planner Response

Let me read ALL the Terraform files first before explaining.

*Listed directory [modules](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/modules) *

*Listed directory [environments](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/environments) *

*Listed directory [dev](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/environments/dev) *

*Listed directory [vpc](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/modules/vpc) *

*Listed directory [eks](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/modules/eks) *

*Viewed [backend.tf](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/environments/dev/backend.tf) *

*Viewed [main.tf](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/environments/dev/main.tf) *

*Viewed [outputs.tf](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/environments/dev/outputs.tf) *

*Viewed [main.tf](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/modules/vpc/main.tf) *

*Viewed [variables.tf](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/modules/vpc/variables.tf) *

*Viewed [outputs.tf](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/modules/vpc/outputs.tf) *

*Viewed [main.tf](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/modules/eks/main.tf) *

*Viewed [variables.tf](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/modules/eks/variables.tf) *

*Viewed [outputs.tf](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/modules/eks/outputs.tf) *

*Viewed [main.tf](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/modules/ecr/main.tf) *

*Viewed [main.tf](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/modules/rds/main.tf) *

*Viewed [main.tf](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/modules/elasticache/main.tf) *

*Viewed [main.tf](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/modules/sqs/main.tf) *

### Planner Response

Now I have everything. Full block-by-block explanation:

---

# 🏗️ PHASE 2 — Terraform (AWS Infrastructure)

## What is Terraform? (Beginner Explanation)

You already know AWS. You know you can go to the AWS Console and click buttons to create a VPC, an EKS cluster, etc.

**Terraform** does the exact same thing — but through code, not clicking. You write files that describe what you want, and Terraform figures out what API calls to make to AWS.

**Why is this better than clicking?**
- Reproducible — run it again, get the exact same infrastructure
- Version controlled — stored in Git, you see every change
- Destroyable — `terraform destroy` removes everything cleanly
- No human error — no "I forgot to enable encryption" mistakes

---

## 📁 Terraform Folder Structure

```
terraform/
├── environments/
│   └── dev/
│       ├── backend.tf   ← Where to store Terraform's state file
│       ├── main.tf      ← Calls all modules, wires them together
│       └── outputs.tf   ← What to print after apply
└── modules/
    ├── vpc/             ← Network
    ├── eks/             ← Kubernetes cluster
    ├── ecr/             ← Docker image registry
    ├── rds/             ← PostgreSQL database
    ├── elasticache/     ← Redis cache
    └── sqs/             ← Message queue
```

> **Why separate `modules/` from `environments/`?**
> Modules are **reusable Lego bricks**. You build them once, then [environments/dev/main.tf](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/environments/dev/main.tf:0:0-0:0) assembles them. Tomorrow, if you add `environments/prod/main.tf`, it uses the exact same modules with different settings (bigger machines, multi-AZ, etc.).

---

## Every Module Has 3 Files — Learn This Pattern Once

| File | Purpose |
|---|---|
| [variables.tf](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/modules/eks/variables.tf:0:0-0:0) | Inputs — what the module needs to know |
| [main.tf](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/modules/rds/main.tf:0:0-0:0) | The actual AWS resources to create |
| [outputs.tf](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/modules/vpc/outputs.tf:0:0-0:0) | What the module exposes to other modules |

Think of a module like a **function**:
- [variables.tf](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/modules/eks/variables.tf:0:0-0:0) = function **parameters**
- [main.tf](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/modules/rds/main.tf:0:0-0:0) = function **body**
- [outputs.tf](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/modules/vpc/outputs.tf:0:0-0:0) = function **return value**

---

## 🔷 File 1 — [environments/dev/backend.tf](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/environments/dev/backend.tf:0:0-0:0) (Where Terraform saves its state)

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

**New Concept — Terraform State:**
Terraform needs to remember what it already created. It keeps a file called `terraform.tfstate` that maps "this Terraform resource" → "this real AWS resource ID". Without it, Terraform wouldn't know if the VPC already exists or not.

**Why store it in S3 and not locally?**
If it's on your laptop only, your teammate can't run Terraform. If your laptop dies, the state is gone. S3 is safe, shared, and permanent.

**Line by line:**

| Line | What it does | Why |
|---|---|---|
| `backend "s3"` | Store state in AWS S3 instead of a local file | Shared across your whole team |
| `bucket = "kubeflow-ops-terraform-state"` | Which S3 bucket to use | Must be created manually first (see README) |
| `key = "dev/terraform.tfstate"` | The path/filename inside the bucket | `dev/` prefix lets you have `prod/terraform.tfstate` in the same bucket |
| `dynamodb_table = "kubeflow-ops-terraform-lock"` | **The lock.** When someone runs `terraform apply`, this DynamoDB row is set. Anyone else trying to run simultaneously gets blocked | Prevents two people from corrupting the state at the same time |
| `encrypt = true` | Encrypt the state file at rest in S3 | State contains passwords and secrets — must be encrypted |

> ⚠️ **Before you run `terraform init`, you must manually create the S3 bucket and DynamoDB table.** That's the one thing Terraform can't create for itself (because it needs them to exist before it starts).

---

## 🔷 File 2 — [environments/dev/main.tf](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/environments/dev/main.tf:0:0-0:0) (The Assembler)

### Block A — Terraform version + providers

```hcl
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
```

**New Concept — Providers:**
Terraform itself doesn't know how to talk to AWS. A **provider** is a plugin that speaks AWS's API. Think of it like a driver. You download it once (`terraform init`) and Terraform uses it to make API calls.

| Line | What it does |
|---|---|
| `required_version = ">= 1.7.0"` | Your Terraform CLI must be this version or higher. Prevents bugs from version mismatches |
| `aws provider ~> 5.30` | Download the AWS provider plugin, version 5.30.x. `~>` means "5.30 or newer patch, but not 6.x" |
| `random provider` | Generates random values (used to create a random DB password) |
| `tls provider` | Reads TLS certificates (used to set up OIDC for EKS) |

---

### Block B — AWS Provider config

```hcl
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
```

| Line | What it does |
|---|---|
| `region = var.aws_region` | All AWS resources go to `us-east-1` (from the variable below) |
| `default_tags` | **Every single AWS resource** created by this Terraform gets these tags automatically — no need to repeat them in every resource |

> **Why tags matter:** In AWS, you pay per resource. Tags let you filter cost reports: "How much did the `dev` environment cost this month?" Without tags, you're guessing.

---

### Block C — Variables

```hcl
variable "project_name" { default = "kubeflow-ops" }
variable "environment"  { default = "dev" }
variable "aws_region"   { default = "us-east-1" }
```

These are the **global settings** for this environment. Every module gets these values passed in, so all resource names follow the pattern `kubeflow-ops-dev-[resource]`.

---

### Block D — Calling the Modules

```hcl
module "vpc" {
  source       = "../../modules/vpc"
  project_name = var.project_name
  environment  = var.environment
}

module "eks" {
  source             = "../../modules/eks"
  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id          # ← OUTPUT from vpc module
  private_subnet_ids = module.vpc.private_subnet_ids  # ← OUTPUT from vpc module
  node_instance_types = ["t3.medium"]
  node_desired_size   = 2
  node_min_size       = 1
  node_max_size       = 4
}
```

**This is the key wiring pattern.** Notice how `eks` uses `module.vpc.vpc_id` — the output of the VPC module becomes the input of the EKS module. Terraform figures out the order automatically: it knows VPC must be created first.

The full dependency chain:
```
VPC → EKS (needs vpc_id + subnet_ids)
VPC → RDS (needs vpc_id + subnet_ids)
VPC → ElastiCache (needs vpc_id + subnet_ids)
EKS → RDS (needs eks_security_group_id to allow DB access)
EKS → ElastiCache (needs eks_security_group_id to allow Redis access)
ECR → (standalone, needs nothing)
SQS → (standalone, needs nothing)
```

---

## 🔷 Module 1 — VPC (`modules/vpc/`)

> **Why do we need a VPC?** AWS requires all resources to live inside a Virtual Private Cloud — your private network slice in AWS. Nothing is exposed to the internet unless you explicitly allow it.

### The network layout we're building:

```
AWS Region: us-east-1
└── VPC: 10.0.0.0/16  (65,536 private IP addresses)
    │
    ├── us-east-1a
    │   ├── Public Subnet:  10.0.1.0/24   ← ALB, NAT Gateway live here
    │   └── Private Subnet: 10.0.10.0/24  ← EKS nodes, RDS, Redis here
    │
    └── us-east-1b
        ├── Public Subnet:  10.0.2.0/24
        └── Private Subnet: 10.0.20.0/24
```

> **How did I know we need 2 AZs?** EKS requires a minimum of 2 Availability Zones for high availability. Also visible in [variables.tf](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/modules/eks/variables.tf:0:0-0:0): `default = ["us-east-1a", "us-east-1b"]`

### [main.tf](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/modules/rds/main.tf:0:0-0:0) — Block by block:

**Block 1 — VPC**
```hcl
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr       # 10.0.0.0/16
  enable_dns_hostnames = true
  enable_dns_support   = true
}
```
| Line | Why |
|---|---|
| `cidr_block = "10.0.0.0/16"` | Your private address space. `/16` = 65,536 IPs. All your subnets carve out of this. |
| `enable_dns_hostnames = true` | EKS nodes need to resolve DNS names. Required for EKS to work. |
| `enable_dns_support = true` | Same reason — AWS DNS resolver must be enabled. |

---

**Block 2 — Internet Gateway**
```hcl
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}
```
The **door to the internet** for your VPC. Without this, nothing in the VPC can reach the outside world at all. Public subnets route traffic through this.

---

**Block 3 — Public Subnets**
```hcl
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)  # Creates 2 subnets
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    "kubernetes.io/role/elb" = "1"  # ← critical tag for AWS Load Balancer
  }
}
```

| Line | Why |
|---|---|
| `count = 2` | Creates 2 subnets — one per AZ |
| `map_public_ip_on_launch = true` | Anything launched here gets a public IP automatically |
| `"kubernetes.io/role/elb" = "1"` | **This tag tells the AWS Load Balancer Controller** "use these subnets for public-facing load balancers." Without this tag, your Kubernetes Ingress will fail to create an ALB. |

---

**Block 4 — Private Subnets**
```hcl
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  # No map_public_ip_on_launch — these are PRIVATE

  tags = {
    "kubernetes.io/role/internal-elb"  = "1"
  }
}
```
EKS nodes, RDS, and Redis live here. No direct internet access — safer. They reach internet via NAT Gateway.

---

**Block 5 — Elastic IP + NAT Gateway**
```hcl
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id  # ← NAT lives in PUBLIC subnet

  depends_on = [aws_internet_gateway.main]
}
```

**NAT Gateway** = one-way door for private subnets. EKS nodes need to pull Docker images from ECR (outbound internet), but you don't want the internet reaching them directly (no inbound). NAT Gateway allows outbound-only internet.

**Elastic IP (EIP)** = a fixed, permanent public IP address for the NAT Gateway. AWS requires NAT Gateway to have one.

> `depends_on = [aws_internet_gateway.main]` — NAT Gateway can't work without the Internet Gateway existing first. Terraform creates IGW first because of this.

---

**Block 6 — Route Tables**
```hcl
# Public: send all internet traffic through Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"           # "all internet traffic"
    gateway_id = aws_internet_gateway.main.id
  }
}

# Private: send all internet traffic through NAT Gateway
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
}

# Wire subnets to their route tables
resource "aws_route_table_association" "public"  { ... }
resource "aws_route_table_association" "private" { ... }
```

A **Route Table** is like a GPS for network traffic: "If the destination is `0.0.0.0/0` (internet), send it via X."

```
Public subnet traffic → Internet Gateway → Internet (2-way)
Private subnet traffic → NAT Gateway → Internet Gateway → Internet (outbound only)
```

---

## 🔷 Module 2 — EKS (`modules/eks/`)

> **Why do we need Terraform for EKS?** EKS is not just "launch a Kubernetes cluster". It needs IAM roles, security groups, OIDC providers, node groups, and addons. Without Terraform, this is dozens of manual console clicks.

### Block 1 — EKS Cluster IAM Role

```hcl
resource "aws_iam_role" "eks_cluster" {
  name = "kubeflow-ops-dev-eks-cluster-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action    = "sts:AssumeRole"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}
```

**New Concept — IAM Role:**
AWS won't let any service do anything without permission. The EKS **control plane** (the Kubernetes API server — managed by AWS) needs permission to manage EC2 instances, networking, etc. on your behalf.

- `assume_role_policy` — "Who is allowed to use this role?" Answer: the `eks.amazonaws.com` service
- `AmazonEKSClusterPolicy` — AWS's pre-built policy that gives EKS exactly what it needs

---

### Block 2 — Security Group for EKS

```hcl
resource "aws_security_group" "eks_cluster" {
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"         # All protocols
    cidr_blocks = ["0.0.0.0/0"]  # To anywhere
  }
}
```

A **Security Group** = a virtual firewall around a resource. This one allows all outbound traffic from the EKS cluster (so pods can reach RDS, Redis, SQS, etc.) but we control inbound separately. The ID of this SG is passed to the RDS and Redis modules as `eks_security_group_id` — that's how RDS knows "only allow traffic from EKS."

---

### Block 3 — The EKS Cluster itself

```hcl
resource "aws_eks_cluster" "main" {
  name     = "kubeflow-ops-dev-eks-cluster"
  version  = "1.29"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true   # So YOU can use kubectl from laptop
    security_group_ids      = [aws_security_group.eks_cluster.id]
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator"]
}
```

| Line | Why |
|---|---|
| `subnet_ids = private_subnet_ids` | EKS control plane runs in **private** subnets — not exposed to internet |
| `endpoint_public_access = true` | Lets you run `kubectl` from your laptop. In stricter production, you'd set this to `false` and use a VPN |
| `enabled_cluster_log_types` | Sends EKS API logs to CloudWatch. Good for auditing: "who deleted that pod?" |

---

### Block 4 — OIDC Provider (The Clever Security Trick)

```hcl
data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
}
```

**New Concept — IRSA (IAM Roles for Service Accounts):**

Problem: Your `order-service` pod needs to talk to SQS. How does it get AWS credentials?

**Bad way:** Put `AWS_ACCESS_KEY_ID` in the code or a secret. If anyone gets that key, they can do anything.

**Good way (IRSA):** The Kubernetes pod has a **ServiceAccount**. The OIDC provider lets that ServiceAccount "become" an IAM Role — just for this specific pod. The pod gets temporary, auto-rotating credentials. If compromised, they expire in 1 hour.

```
Kubernetes Pod (order-service)
   └── has ServiceAccount (order-service-sa)
         └── annotated with IAM Role ARN
               └── OIDC Provider proves "this K8s SA = this IAM Role"
                     └── IAM Role has SQS permissions
                           └── Pod can call SQS ✅
```

No hardcoded keys. No secrets to rotate. Auto-expires. This is the modern way.

---

### Block 5 — Node Group IAM Role + Policies

```hcl
resource "aws_iam_role" "eks_nodes" { ... }  # For EC2 worker nodes

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}
resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}
resource "aws_iam_role_policy_attachment" "eks_container_registry" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
```

Worker nodes are EC2 instances. They need permissions to:
- `AmazonEKSWorkerNodePolicy` — Join the EKS cluster, receive pod assignments
- `AmazonEKS_CNI_Policy` — Manage pod networking (assign IPs to pods)
- `AmazonEC2ContainerRegistryReadOnly` — Pull Docker images from ECR

---

### Block 6 — Managed Node Group

```hcl
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = var.private_subnet_ids
  instance_types  = ["t3.medium"]
  capacity_type   = "ON_DEMAND"

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 4
  }

  update_config {
    max_unavailable = 1   # Roll one node at a time during updates
  }
}
```

| Line | Why |
|---|---|
| `instance_types = ["t3.medium"]` | 2 vCPU, 4GB RAM — affordable for dev. Prod would use `m5.large` or bigger |
| `scaling_config` | Auto-scaling: start with 2 nodes, scale between 1–4 automatically based on pod demand |
| `max_unavailable = 1` | During a rolling update/upgrade, only 1 node is down at a time. Your other node keeps serving traffic |

---

### Block 7 — EKS Add-ons

```hcl
resource "aws_eks_addon" "coredns"    { ... }
resource "aws_eks_addon" "kube_proxy" { ... }
resource "aws_eks_addon" "vpc_cni"    { ... }
```

These are **built-in Kubernetes system components** that EKS manages for you:

| Addon | What it does |
|---|---|
| `coredns` | DNS resolution inside the cluster. Without this, `order-service` can't resolve `user-service` by name |
| `kube_proxy` | Handles `Service` routing — when a pod calls `user-service:8002`, kube-proxy directs it to the right pod |
| `vpc_cni` | Assigns real AWS VPC IP addresses to each pod. This is what lets pods communicate with RDS/Redis directly |

---

## 🔷 Module 3 — ECR (`modules/ecr/`)

> **What is ECR?** ECR (Elastic Container Registry) is AWS's Docker Hub. You push your built images here, and EKS pulls them from here. It's private — only your AWS account can access it.

> **How did I know we need ECR?** The CI pipeline needs somewhere to push images. Kubernetes needs somewhere to pull images from. In AWS, that's ECR.

```hcl
resource "aws_ecr_repository" "services" {
  for_each = toset(["order-service", "user-service", "notification-service"])

  name                 = "kubeflow-ops-${each.value}"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}
```

| Line | Why |
|---|---|
| `for_each = toset(...)` | Creates **3 repositories** with one block — one per service. This is Terraform's looping mechanism |
| `image_tag_mutability = "IMMUTABLE"` | Once you push `v1.2.3`, that tag can never be overwritten. Ensures what you deployed is what runs — no surprise overwrites |
| `scan_on_push = true` | **Security!** When you push an image, ECR automatically scans it for CVEs (known vulnerabilities). You'll see results in the AWS console |
| `encryption_type = "AES256"` | Images are encrypted at rest. A must for any production system |

```hcl
resource "aws_ecr_lifecycle_policy" "services" {
  for_each = aws_ecr_repository.services

  policy = jsonencode({
    rules = [{
      description  = "Keep only last 10 images"
      selection    = { countType = "imageCountMoreThan", countNumber = 10 }
      action       = { type = "expire" }
    }]
  })
}
```

Without this, every CI build pushes a new image and they **never get deleted**. After 6 months you have 500 images costing you money. This policy auto-deletes images beyond the 10 most recent.

---

## 🔷 Module 4 — RDS (`modules/rds/`)

> **How did I know we need RDS?** [main.py](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/apps/user-service/main.py:0:0-0:0) in user-service and order-service has: `DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://...")`. They need a real Postgres in production.

### Block 1 — Subnet Group

```hcl
resource "aws_db_subnet_group" "main" {
  name       = "kubeflow-ops-dev-db-subnet"
  subnet_ids = var.private_subnet_ids
}
```

AWS RDS must be told which subnets it's allowed to use. This group says "RDS can live in our private subnets." RDS then picks one AZ to actually run in (with `multi_az=false` for dev).

---

### Block 2 — Security Group (The Fence)

```hcl
resource "aws_security_group" "rds" {
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.eks_security_group_id]  # ← ONLY from EKS
  }
}
```

This is **critical security**. RDS port 5432 (PostgreSQL) is open **only** to traffic coming from the EKS cluster's security group. Not from the internet. Not from your laptop. Only from EKS pods.

If you compare this to [docker-compose.yml](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/docker-compose.yml:0:0-0:0) where Postgres was on `localhost:5432` accessible from anywhere — this is the production version with a proper fence around it.

---

### Block 3 — Random Password + Secrets Manager

```hcl
resource "random_password" "db_password" {
  length  = 24
  special = false
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name = "kubeflow-ops/dev/db-credentials"
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_string = jsonencode({
    username = "kubeflow_admin"
    password = random_password.db_password.result
    host     = aws_db_instance.main.address
    url      = "postgresql://kubeflow_admin:PASSWORD@HOST:5432/kubeflow"
  })
}
```

| Step | What happens |
|---|---|
| `random_password` | Terraform generates a 24-character random password. You never see it, never type it |
| `aws_secretsmanager_secret` | Creates a secret "slot" in AWS Secrets Manager |
| `aws_secretsmanager_secret_version` | Puts the actual credentials (JSON) into that slot |

Later, the **External Secrets Operator** in Kubernetes reads this secret from Secrets Manager and creates a Kubernetes Secret automatically. Your app reads the Kubernetes Secret as an env var. The password **never appears in your code or Git**.

---

### Block 4 — RDS Instance

```hcl
resource "aws_db_instance" "main" {
  engine         = "postgres"
  engine_version = "16.3"
  instance_class = "db.t3.micro"

  allocated_storage     = 20    # GB, starting size
  max_allocated_storage = 50    # GB, auto-scale up to here

  multi_az            = false   # true in production = standby in another AZ
  publicly_accessible = false   # private subnet ONLY
  skip_final_snapshot = true    # dev convenience - set false in prod

  backup_retention_period = 7          # Keep 7 days of automatic backups
  backup_window           = "03:00-04:00"   # Backup at 3am
  maintenance_window      = "mon:04:00-mon:05:00"  # Patch at 4am Monday
}
```

| Setting | Dev value | Prod value | Why |
|---|---|---|---|
| `instance_class` | `db.t3.micro` | `db.r6g.large` | Costs ~$15/mo vs ~$200/mo |
| `multi_az` | `false` | `true` | `true` = automatic failover in 60s if AZ fails |
| `skip_final_snapshot` | `true` | `false` | `false` = take a final backup before destroy |
| `allocated_storage` | 20GB | 100GB+ | Start small, auto-scales up |

---

## 🔷 Module 5 — ElastiCache Redis (`modules/elasticache/`)

> **How did I know?** [notification-service/main.py](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/apps/notification-service/main.py:0:0-0:0) line 35: `REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")` — identical pattern to Postgres.

```hcl
resource "aws_elasticache_cluster" "main" {
  cluster_id           = "kubeflow-ops-dev-redis"
  engine               = "redis"
  engine_version       = "7.1"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1        # Single node for dev
  parameter_group_name = "default.redis7"
  port                 = 6379

  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [aws_security_group.redis.id]
}
```

Structure is **identical in pattern** to RDS:
- Subnet group → which private subnets to use
- Security group → only EKS can connect on port 6379
- Cluster → the actual Redis instance

`num_cache_nodes = 1` is fine for dev. In production you'd use a **Replication Group** with a primary + replica for high availability.

---

## 🔷 Module 6 — SQS (`modules/sqs/`)

> **How did I know?** The order-service code: `SQS_QUEUE_URL = os.getenv("SQS_QUEUE_URL", ...)` + `boto3` being used to `send_message`. The notification-service does `receive_message` + `delete_message`.

### Block 1 — Dead Letter Queue first

```hcl
resource "aws_sqs_queue" "order_events_dlq" {
  name                      = "kubeflow-ops-dev-order-events-dlq"
  message_retention_seconds = 1209600  # 14 days
}
```
Create the DLQ **first** because the main queue references its ARN. This is the exact same pattern you saw in [localstack-init.sh](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/scripts/localstack-init.sh:0:0-0:0).

---

### Block 2 — Main queue

```hcl
resource "aws_sqs_queue" "order_events" {
  name                       = "kubeflow-ops-dev-order-events"
  visibility_timeout_seconds = 30
  message_retention_seconds  = 345600   # 4 days
  receive_wait_time_seconds  = 10       # Long polling

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.order_events_dlq.arn
    maxReceiveCount     = 3
  })
}
```

| Setting | What it does |
|---|---|
| `visibility_timeout_seconds = 30` | When a consumer (notification-service) picks up a message, it disappears from other consumers for 30s. If not deleted in 30s (crash?), it reappears for retry |
| `receive_wait_time_seconds = 10` | **Long polling** — the consumer waits up to 10s for messages instead of constantly calling the API. Reduces API costs by ~95% |
| `maxReceiveCount = 3` | After 3 failed attempts → move to DLQ |

---

### Block 3 — IAM Policy for SQS access (for IRSA)

```hcl
resource "aws_iam_policy" "sqs_access" {
  policy = jsonencode({
    Statement = [{
      Effect = "Allow"
      Action = [
        "sqs:SendMessage",
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
        "sqs:GetQueueUrl",
      ]
      Resource = [
        aws_sqs_queue.order_events.arn,
        aws_sqs_queue.order_events_dlq.arn,
      ]
    }]
  })
}
```

This IAM policy will later be **attached to the EKS ServiceAccount** via IRSA. Only the pods with that ServiceAccount can call SQS — no other pods, no humans, no external access. Least-privilege principle in action.

---

## 🔷 File 3 — [environments/dev/outputs.tf](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/environments/dev/outputs.tf:0:0-0:0)

```hcl
output "eks_cluster_name"    { value = module.eks.cluster_name }
output "ecr_repository_urls" { value = module.ecr.repository_urls }
output "rds_endpoint"        { value = module.rds.endpoint }
output "rds_secret_arn"      { value = module.rds.secret_arn }
output "redis_url"           { value = module.elasticache.redis_url }
output "sqs_queue_url"       { value = module.sqs.queue_url }

output "configure_kubectl" {
  value = "aws eks update-kubeconfig --region us-east-1 --name kubeflow-ops-dev"
}
```

After `terraform apply` finishes, these values are **printed to your terminal**. You use them to:
- Configure `kubectl` → connect to your new EKS cluster
- Set GitHub Actions secrets → ECR repo URLs for the CI pipeline
- Configure Kubernetes manifests → RDS endpoint → goes into ConfigMap

---

## ✅ Phase 2 Complete Summary

```
What Terraform creates (in dependency order):
1. VPC + Subnets + NAT Gateway + Route Tables
2. EKS Cluster + IAM Roles + OIDC Provider
3. EKS Node Group (EC2 workers)
4. ECR Repositories (3, one per service)
5. RDS PostgreSQL (+ password in Secrets Manager)
6. ElastiCache Redis
7. SQS Queues (main + DLQ) + IAM policy

Run order:
$ aws s3 mb s3://kubeflow-ops-terraform-state     # Pre-step (manual)
$ cd terraform/environments/dev
$ terraform init    # Download providers, connect to S3 backend
$ terraform plan    # Dry-run: see what will be created
$ terraform apply   # Actually create everything (~15 mins)
```

---

**Ready for Phase 3 — Kubernetes Manifests (GitOps folder)?**

That's where you take the Docker images from ECR and tell Kubernetes **how** to run them on the EKS cluster — Deployments, Services, ConfigMaps, HPA, secrets. Just say **"continue"**! 🚀

### User Input

Bro you are skipping lot of things..I said block by block where is module 3 output- 
Now start from module 3 output block and then module 4, then when I let go then proceed with mode 5

### Planner Response

You're right, my bad. Let me read the ECR outputs file first.

*Searched filesystem*

### Planner Response

Noted — ECR module only has [main.tf](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/modules/ecr/main.tf:0:0-0:0) (no separate [variables.tf](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/modules/vpc/variables.tf:0:0-0:0) / [outputs.tf](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/modules/vpc/outputs.tf:0:0-0:0) — they're all in one file, which I already read). Let me re-do this properly. I'll now go through **every single block** of Module 3 (ECR) top to bottom, then Module 4 (RDS) the same way.

---

# 🔷 Module 3 — ECR — Full Block by Block

> **File:** [terraform/modules/ecr/main.tf](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/modules/ecr/main.tf:0:0-0:0)
> Everything is in one file — variables, resources, and outputs.

---

## ECR Block 1 — Variables (Lines 8–20)

```hcl
variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "service_names" {
  description = "List of microservice names to create repos for"
  type        = list(string)
  default     = ["order-service", "user-service", "notification-service"]
}
```

**Every variable explained:**

| Variable | Type | Default | Where it comes from |
|---|---|---|---|
| `project_name` | string | none (required) | Passed from [environments/dev/main.tf](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/environments/dev/main.tf:0:0-0:0) → `var.project_name` = `"kubeflow-ops"` |
| `environment` | string | none (required) | Passed from [environments/dev/main.tf](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/environments/dev/main.tf:0:0-0:0) → `var.environment` = `"dev"` |
| `service_names` | list of strings | `["order-service", "user-service", "notification-service"]` | You can override, but the default already matches what the developer gave us |

> **How did I know the service names?** I looked at the `apps/` folder — there were exactly 3 subdirectories: `order-service`, `user-service`, `notification-service`. One ECR repo per service = 3 repos.

---

## ECR Block 2 — ECR Repositories (Lines 23–42)

```hcl
resource "aws_ecr_repository" "services" {
  for_each = toset(var.service_names)

  name                 = "${var.project_name}-${each.value}"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = "${var.project_name}-${each.value}"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
```

**Line by line:**

**`for_each = toset(var.service_names)`**
- `for_each` is Terraform's loop. Instead of writing 3 identical `aws_ecr_repository` blocks, you write one and loop over the list
- `toset()` converts the list into a **set** (no duplicates, unordered) — `for_each` requires a set or map, not a plain list
- This creates 3 resources:
  - `aws_ecr_repository.services["order-service"]`
  - `aws_ecr_repository.services["user-service"]`
  - `aws_ecr_repository.services["notification-service"]`

**`name = "${var.project_name}-${each.value}"`**
- `each.value` is the current item in the loop — on the first iteration it's `"order-service"`, second `"user-service"`, etc.
- Result: repos named `kubeflow-ops-order-service`, `kubeflow-ops-user-service`, `kubeflow-ops-notification-service`

**`image_tag_mutability = "IMMUTABLE"`**
- **"IMMUTABLE"** = once you push an image tagged `v1.2.3`, you **cannot overwrite it** with another image using the same tag
- Why? Imagine CI pushes `v1.2.3` and your cluster is running it. If someone accidentally pushes a broken image also tagged `v1.2.3`, your running pods still have the old layers cached — but the next pod restart would pull the broken version silently
- With IMMUTABLE tags, that push would **fail with an error** — protecting you
- Alternative is `MUTABLE` which allows overwriting — never use for production

**`image_scanning_configuration { scan_on_push = true }`**
- Every time GitHub Actions pushes an image to ECR, ECR **automatically runs a security scan** against it
- It checks the image layers against the CVE database (Common Vulnerabilities and Exposures)
- Results appear in the ECR console per-image. You can also add a policy: "if critical CVE found, block the deployment"
- **This is free** with ECR Basic scanning

**`encryption_configuration { encryption_type = "AES256" }`**
- Docker images stored in ECR are encrypted at rest using AES-256
- Without this, if someone somehow accessed the S3 bucket underlying ECR, they'd see your images in plaintext
- `AES256` uses AWS-managed keys. For stricter control, `KMS` lets you use your own key

---

## ECR Block 3 — Lifecycle Policy (Lines 47–66)

```hcl
resource "aws_ecr_lifecycle_policy" "services" {
  for_each = aws_ecr_repository.services

  repository = each.value.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep only last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}
```

**`for_each = aws_ecr_repository.services`**
- This loops over the **already created repositories** (not the service name list — this iterates the actual Terraform resource objects)
- Creates one lifecycle policy per repo

**`repository = each.value.name`**
- `each.value` here is the full repository resource object (not just the name string like before)
- `.name` gets the repository name from it

**The policy JSON explained:**

```
IF   tagStatus   = "any"              ← applies to all images regardless of tag
AND  countType   = "imageCountMoreThan"  ← when total count exceeds...
     countNumber = 10                 ← ...10 images
THEN action = "expire"               ← delete the oldest images
```

So: always keep the newest 10. The 11th oldest gets automatically deleted. Without this, a team running CI 10x/day would accumulate 300 images per month costing real money.

---

## ECR Block 4 — Outputs (Lines 68–77)

```hcl
output "repository_urls" {
  description = "Map of service name to ECR repository URL"
  value       = { for k, v in aws_ecr_repository.services : k => v.repository_url }
}

output "registry_id" {
  description = "The registry ID (AWS account ID)"
  value       = values(aws_ecr_repository.services)[0].registry_id
}
```

**`output "repository_urls"`**

The expression `{ for k, v in aws_ecr_repository.services : k => v.repository_url }` is a **for expression** that builds a map. It walks through all 3 repos and produces:

```hcl
{
  "order-service"        = "123456789.dkr.ecr.us-east-1.amazonaws.com/kubeflow-ops-order-service"
  "user-service"         = "123456789.dkr.ecr.us-east-1.amazonaws.com/kubeflow-ops-user-service"
  "notification-service" = "123456789.dkr.ecr.us-east-1.amazonaws.com/kubeflow-ops-notification-service"
}
```

- The calling file ( [environments/dev/outputs.tf](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/environments/dev/outputs.tf:0:0-0:0)) prints this as `ecr_repository_urls`
- GitHub Actions uses these URLs to know where to push the built Docker images
- Kubernetes Deployment manifests use these URLs to know where to pull from

**`output "registry_id"`**
- The registry ID is just your **AWS account ID** (e.g. `123456789012`)
- ECR needs this when you run `aws ecr get-login-password` to authenticate Docker to push images
- `values(aws_ecr_repository.services)[0].registry_id` — all repos share the same registry (same account), so we just take the first one

---

# 🔷 Module 4 — RDS — Full Block by Block

> **Files:** [terraform/modules/rds/main.tf](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/modules/rds/main.tf:0:0-0:0) (everything in one file — variables, resources, outputs)

---

## RDS Block 1 — Variables (Lines 8–42)

```hcl
variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "eks_security_group_id" {
  description = "SG of EKS cluster — only this SG can access RDS"
  type        = string
}

variable "instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_name" {
  type    = string
  default = "kubeflow"
}

variable "db_username" {
  type    = string
  default = "kubeflow_admin"
}
```

**Every variable explained:**

| Variable | Type | Default | Why needed |
|---|---|---|---|
| `project_name` | string | — | Used in all resource names |
| `environment` | string | — | Used in all resource names |
| `vpc_id` | string | — | RDS must be placed inside the VPC. Comes from `module.vpc.vpc_id` |
| `private_subnet_ids` | list(string) | — | RDS goes in private subnets. Comes from `module.vpc.private_subnet_ids` |
| `eks_security_group_id` | string | — | **The fence**. Only traffic from this SG can reach RDS port 5432. Comes from `module.eks.cluster_security_group_id` |
| `instance_class` | string | `db.t3.micro` | The size of the database server. `t3.micro` = cheapest (~$15/mo) |
| `db_name` | string | `kubeflow` | The database schema name. Matches `DATABASE_URL` in our app code: `.../kubeflow` |
| `db_username` | string | `kubeflow_admin` | The DB login username. Password is generated separately (never hardcoded) |

> **How did I know `db_name = "kubeflow"`?** Read [main.py](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/apps/user-service/main.py:0:0-0:0) → `DATABASE_URL = "postgresql://postgres:postgres@localhost:5432/kubeflow"` → the last part is the database name.

> **No `db_password` variable** — passwords are **never** passed as variables. They're auto-generated by Terraform in the next block.

---

## RDS Block 2 — DB Subnet Group (Lines 44–53)

```hcl
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-db-subnet"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name        = "${var.project_name}-${var.environment}-db-subnet"
    Environment = var.environment
  }
}
```

**What is a DB Subnet Group?**
AWS RDS doesn't just accept `subnet_id` directly. You must first create a **DB Subnet Group** — a named collection of subnets — and then tell RDS to use that group.

Why? Because RDS needs to know which AZs it's allowed to place the database in. By giving it both private subnets (one in `us-east-1a`, one in `us-east-1b`), it can:
- Place the primary DB in `us-east-1a`
- If you enable `multi_az = true` later, automatically place the standby replica in `us-east-1b`

**`subnet_ids = var.private_subnet_ids`**
- These are the **private** subnets from the VPC module
- Private = no direct internet access = RDS is invisible from the internet
- Only things inside the VPC that have the right Security Group can reach it

---

## RDS Block 3 — Security Group (Lines 55–86)

```hcl
resource "aws_security_group" "rds" {
  name_prefix = "${var.project_name}-${var.environment}-rds-"
  vpc_id      = var.vpc_id
  description = "Allow PostgreSQL access from EKS only"

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.eks_security_group_id]
    description     = "PostgreSQL from EKS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-rds-sg"
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}
```

**Line by line:**

**`name_prefix`** (not `name`)
- Using `name_prefix` instead of `name` means Terraform appends a random suffix: `kubeflow-ops-dev-rds-a1b2c3`
- Why? Because you can't reuse the exact same SG name if you destroy and recreate. `name_prefix` avoids name collision errors during rebuilds

**`ingress` block — the lock on the door**
```hcl
ingress {
  from_port       = 5432      ← PostgreSQL default port
  to_port         = 5432      ← same (single port, not a range)
  protocol        = "tcp"     ← PostgreSQL uses TCP
  security_groups = [var.eks_security_group_id]   ← ONLY from EKS SG
}
```
- `security_groups = [eks_sg_id]` means: **only traffic originating from a resource that has the EKS security group attached** can connect to port 5432
- Your EKS nodes have the EKS SG. So pods on those nodes can reach RDS
- Your laptop does NOT have the EKS SG. So you **cannot** connect to RDS from your laptop directly (good — that's the point)
- The internet does NOT have the EKS SG. So RDS is invisible to the internet even though it has a DNS hostname

**`egress` block — the way out**
```hcl
egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"           ← all protocols
  cidr_blocks = ["0.0.0.0/0"] ← to anywhere
}
```
- Allows RDS to make outbound connections (e.g., to AWS's own services for backups, updates)
- `-1` means "all protocols" in AWS SG language

**`lifecycle { create_before_destroy = true }`**
- If you ever modify this SG in Terraform, it creates the **new** SG first, switches resources to it, then destroys the old one
- Without this: Terraform destroys the old SG first → RDS loses its firewall momentarily → potential downtime

---

## RDS Block 4 — Random Password (Lines 88–92)

```hcl
resource "random_password" "db_password" {
  length  = 24
  special = false
}
```

**`resource "random_password"`**
- This uses the `random` Terraform provider (declared back in [environments/dev/main.tf](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/environments/dev/main.tf:0:0-0:0))
- On first `terraform apply`, generates a cryptographically random 24-character string
- Terraform **stores this in the state file** (which is encrypted in S3, remember)
- On subsequent `terraform apply` runs, it reuses the same password (doesn't regenerate each time)

**`special = false`**
- By default, `random_password` includes characters like `!@#$%^&*()`
- Some PostgreSQL connection libraries / drivers have bugs with special characters in URLs (they break the URL parsing)
- `false` = only letters and digits — universally safe for connection strings

**Why not just hardcode a password?**
- Hardcoded = goes into Git = security breach
- Auto-generated = never in Git, never in code, only in encrypted S3 state + Secrets Manager

---

## RDS Block 5 — AWS Secrets Manager (Lines 94–115)

```hcl
resource "aws_secretsmanager_secret" "db_credentials" {
  name = "${var.project_name}/${var.environment}/db-credentials"

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
    host     = aws_db_instance.main.address
    port     = 5432
    dbname   = var.db_name
    url      = "postgresql://${var.db_username}:${random_password.db_password.result}@${aws_db_instance.main.address}:5432/${var.db_name}"
  })
}
```

**Two separate resources — why?**
AWS Secrets Manager separates the **secret container** (the name/metadata) from the **secret value** (the actual data). This is by design — you can rotate the value without touching the container, and you can control access to the container separately.

**`aws_secretsmanager_secret` — the container**
- `name = "kubeflow-ops/dev/db-credentials"` — the path-style name. Slashes are just a naming convention, not actual folders — but they help organize secrets
- Creates an empty "slot" in Secrets Manager

**`aws_secretsmanager_secret_version` — the value**
- `secret_id = aws_secretsmanager_secret.db_credentials.id` — links to the container above
- `secret_string = jsonencode({ ... })` — stores the credentials as a JSON string:

```json
{
  "username": "kubeflow_admin",
  "password": "xK9mPqR7nJwL4vDs2eAyBt",
  "host":     "kubeflow-ops-dev-postgres.abc123.us-east-1.rds.amazonaws.com",
  "port":     5432,
  "dbname":   "kubeflow",
  "url":      "postgresql://kubeflow_admin:xK9mPqR7nJwL...@kubeflow-ops-dev-postgres....:5432/kubeflow"
}
```

**Why store `url` separately if all the parts are already there?**
Convenience. The app just reads `url` as a single `DATABASE_URL` string. The `username`/`password`/`host` fields are there for tools that need them individually (e.g., database migration scripts).

**How does the app actually get this?**
Later, the **External Secrets Operator** (installed in Kubernetes) reads this Secrets Manager secret and creates a Kubernetes Secret from it. The app reads it as the `DATABASE_URL` environment variable. The password **never touches your terminal, never appears in Git, never in any manifest file.**

---

## RDS Block 6 — The RDS Instance (Lines 117–148)

```hcl
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-${var.environment}-postgres"

  engine         = "postgres"
  engine_version = "16.3"
  instance_class = var.instance_class

  allocated_storage     = 20
  max_allocated_storage = 50

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az            = false
  publicly_accessible = false
  skip_final_snapshot = true

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"

  tags = {
    Name        = "${var.project_name}-${var.environment}-postgres"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
```

**Every line explained:**

**`identifier`** — The unique name of the RDS instance inside AWS. This is what shows in the RDS console. Different from `db_name` — `identifier` is the AWS resource name, `db_name` is the database schema inside Postgres.

**`engine = "postgres"` + `engine_version = "16.3"`**
— Tells AWS which database software to install. We're using PostgreSQL 16.3 (matches what we used in docker-compose: `postgres:16-alpine`)

**`instance_class = var.instance_class`** → `"db.t3.micro"`

AWS RDS instance sizes follow the pattern `db.[family].[size]`:

| Class | vCPU | RAM | Monthly Cost | Use case |
|---|---|---|---|---|
| `db.t3.micro` | 2 | 1GB | ~$15 | Dev/test |
| `db.t3.medium` | 2 | 4GB | ~$60 | Small prod |
| `db.r6g.large` | 2 | 16GB | ~$200 | Production |

**`allocated_storage = 20`** — Start with 20 GB of SSD storage

**`max_allocated_storage = 50`** — **Storage autoscaling**. If the DB fills up past 90% of 20GB, AWS automatically expands it up to 50GB. You don't need to do anything. Prevents "disk full" crashes at 3am.

**`db_name = var.db_name`** → `"kubeflow"` — The initial database/schema created when RDS boots. Matches `DATABASE_URL` in the app.

**`username = var.db_username`** → `"kubeflow_admin"` — The superuser login

**`password = random_password.db_password.result`** — The auto-generated password from Block 4. `.result` extracts the actual string value.

**`db_subnet_group_name = aws_db_subnet_group.main.name`** — Puts RDS into the private subnets you defined in Block 2

**`vpc_security_group_ids = [aws_security_group.rds.id]`** — Attaches the firewall from Block 3

**`multi_az = false`**
- `false` for dev: single database instance in one AZ. If that AZ has an outage, DB is down.
- `true` for prod: AWS automatically maintains a **standby replica in a different AZ**. If the primary fails, failover takes ~60 seconds automatically. Costs 2x.

**`publicly_accessible = false`**
- `false` = the RDS instance gets no public IP, lives only in your private subnet
- Even though it has a DNS hostname, that hostname resolves to a private IP only reachable inside the VPC
- This is non-negotiable for any database in production

**`skip_final_snapshot = true`**
- Before deleting an RDS instance, AWS normally forces you to take a final backup snapshot
- For **dev**, `true` = skip that safety net so `terraform destroy` doesn't get stuck asking for a snapshot name
- For **prod**, always `false` — you want that final backup

**`backup_retention_period = 7`**
- AWS automatically takes a daily backup and keeps the last 7 days
- `0` = disable backups (never do this in prod)
- You can restore to any point-in-time within those 7 days (PITR)

**`backup_window = "03:00-04:00"`** — Run the daily backup at 3am UTC (low traffic time)

**`maintenance_window = "mon:04:00-mon:05:00"`** — AWS applies patches/updates on Monday at 4am UTC. If you set no window, AWS picks one for you, potentially during business hours.

---

## RDS Block 7 — Outputs (Lines 150–167)

```hcl
output "endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.address
}

output "port" {
  value = aws_db_instance.main.port
}

output "db_name" {
  value = aws_db_instance.main.db_name
}

output "secret_arn" {
  description = "ARN of the Secrets Manager secret containing DB credentials"
  value       = aws_secretsmanager_secret.db_credentials.arn
}
```

**`output "endpoint"`**
- `aws_db_instance.main.address` → the DNS hostname of the RDS instance
- Example: `kubeflow-ops-dev-postgres.abc123xyz.us-east-1.rds.amazonaws.com`
- This gets used by the [environments/dev/outputs.tf](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/environments/dev/outputs.tf:0:0-0:0) and printed after `terraform apply`
- The **External Secrets Operator** later reads the full URL from Secrets Manager (which already has the endpoint embedded inside it from Block 5)

**`output "port"`**
- Always `5432` for PostgreSQL
- Exposed as output anyway for completeness and for any scripts that need it separately

**`output "db_name"`**
- Always `"kubeflow"` — the schema name
- Used by any migration scripts or admin tools

**`output "secret_arn"`**
- The **ARN** (unique identifier) of the Secrets Manager secret
- Example: `arn:aws:secretsmanager:us-east-1:123456789:secret:kubeflow-ops/dev/db-credentials-AbCdEf`
- This ARN is what you put into the **ExternalSecret** Kubernetes manifest later — it tells the External Secrets Operator "go read THIS specific secret from Secrets Manager"
- Also printed in [environments/dev/outputs.tf](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/environments/dev/outputs.tf:0:0-0:0) so you can copy it for GitHub Actions secrets

---

## 📋 Module 3 + 4 Complete Picture

```
Module 3 (ECR) creates:
  ├── aws_ecr_repository ["order-service"]        → URL to push/pull images
  ├── aws_ecr_repository ["user-service"]          → URL to push/pull images
  ├── aws_ecr_repository ["notification-service"]  → URL to push/pull images
  └── aws_ecr_lifecycle_policy (×3)               → auto-delete old images

Module 4 (RDS) creates:
  ├── aws_db_subnet_group    → tells RDS which private subnets to use
  ├── aws_security_group     → firewall: only EKS can connect on 5432
  ├── random_password        → auto-generates 24-char password
  ├── aws_secretsmanager_secret         → the vault slot
  ├── aws_secretsmanager_secret_version → the actual credentials JSON
  └── aws_db_instance        → the actual PostgreSQL 16.3 server
```

---

Say **"continue"** and we'll go through **Module 5 — ElastiCache (Redis)** the exact same way, block by block! 🚀

### User Input

Lets do Module 5

### Planner Response

I already have the ElastiCache file content from earlier. Let me go through it completely, zero skipping.

---

# 🔷 Module 5 — ElastiCache (Redis) — Full Block by Block

> **File:** [terraform/modules/elasticache/main.tf](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/modules/elasticache/main.tf:0:0-0:0)
> (Everything in one file — variables, resources, outputs)

---

## Why Does This Module Exist?

Before touching any line of code — **how did I know we need Redis in AWS?**

I opened [apps/notification-service/main.py](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/apps/notification-service/main.py:0:0-0:0) and saw:

```python
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")
redis_client = redis.from_url(REDIS_URL, decode_responses=True)
```

The `REDIS_URL` env var exists. In [docker-compose.yml](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/docker-compose.yml:0:0-0:0) it pointed to the local Redis container. In production on EKS, it needs to point to a **real, managed Redis** — that's AWS ElastiCache.

> **What is ElastiCache?** It's AWS's managed Redis/Memcached service. Just like RDS is managed Postgres, ElastiCache is managed Redis. AWS handles backups, patches, restarts, monitoring — you just connect to it.

---

## Elasticache Block 1 — Variables (Lines 8–31)

```hcl
variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "eks_security_group_id" {
  type = string
}

variable "node_type" {
  type    = string
  default = "cache.t3.micro"
}
```

**Every variable explained:**

| Variable | Type | Default | Why needed |
|---|---|---|---|
| `project_name` | string | — | Used in naming all resources: `kubeflow-ops-dev-redis` |
| `environment` | string | — | Same — part of every resource name and tag |
| `vpc_id` | string | — | Redis must live inside the same VPC as EKS, so pods can reach it. Comes from `module.vpc.vpc_id` |
| `private_subnet_ids` | list(string) | — | Redis goes in private subnets — same private subnets the EKS nodes are in. Comes from `module.vpc.private_subnet_ids` |
| `eks_security_group_id` | string | — | The same EKS security group used for RDS. Only EKS pods can reach Redis on port 6379. Comes from `module.eks.cluster_security_group_id` |
| `node_type` | string | `"cache.t3.micro"` | The size of the Redis server |

**On `node_type = "cache.t3.micro"`:**

Redis instance sizes follow the pattern `cache.[family].[size]`:

| Type | RAM | Cost/mo | Use case |
|---|---|---|---|
| `cache.t3.micro` | 0.5 GB | ~$12 | Dev |
| `cache.t3.medium` | 3.09 GB | ~$50 | Small prod |
| `cache.r6g.large` | 13.07 GB | ~$150 | High-traffic prod |

For our notification service, we're just storing processed SQS message IDs (tiny strings). `t3.micro` is more than enough for dev.

> **Notice:** No `password` or `db_name` variable here — unlike RDS, we're not giving Redis a password in this basic setup. In production you'd add `auth_token` for Redis AUTH. For dev, the security group fence is enough protection.

---

## ElastiCache Block 2 — Subnet Group (Lines 33–41)

```hcl
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-redis-subnet"
  subnet_ids = var.private_subnet_ids

  tags = {
    Environment = var.environment
  }
}
```

**This is the exact same pattern as RDS Block 2.** AWS requires every managed data service (RDS, ElastiCache, etc.) to have a **subnet group** before it can be placed inside a VPC.

**`name = "kubeflow-ops-dev-redis-subnet"`**
- The logical name for this subnet group inside AWS
- Unlike `name_prefix` (which adds random suffix), `name` here is fixed — subnet groups don't have the same name collision issue as security groups

**`subnet_ids = var.private_subnet_ids`**
- Hands ElastiCache the same two private subnets (one in `us-east-1a`, one in `us-east-1b`) that we gave RDS
- ElastiCache will pick one AZ to actually run in
- If you ever enable cluster mode or replication groups, it can spread across both AZs

**Why private subnets specifically?**
Redis holds your processed message ID cache. If it were in a public subnet with `map_public_ip_on_launch = true`, anyone with the endpoint could attempt to connect. Private subnet = only reachable from inside the VPC = only your EKS pods can ever get to it.

---

## ElastiCache Block 3 — Security Group (Lines 43–72)

```hcl
resource "aws_security_group" "redis" {
  name_prefix = "${var.project_name}-${var.environment}-redis-"
  vpc_id      = var.vpc_id
  description = "Allow Redis access from EKS only"

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [var.eks_security_group_id]
    description     = "Redis from EKS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-redis-sg"
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}
```

**This is the same structure as the RDS security group.** Let's go through the differences:

**`name_prefix = "kubeflow-ops-dev-redis-"`**
- Adds a random suffix → e.g., `kubeflow-ops-dev-redis-a1b2c3`
- Same reason as RDS: prevents name collision if you destroy and recreate

**`ingress` block:**
```hcl
ingress {
  from_port       = 6379        ← Redis default port (vs 5432 for Postgres)
  to_port         = 6379
  protocol        = "tcp"
  security_groups = [var.eks_security_group_id]
}
```
- Port `6379` is the default Redis port
- `security_groups = [eks_security_group_id]` — the exact same SG ID you used for RDS
- This means: **only EKS pods** can reach Redis. Same fence, different gate.

**`egress` block:**
```hcl
egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}
```
- Allows Redis to make outbound connections (needed for AWS internal operations like parameter sync, health checks)
- `protocol = "-1"` = all protocols
- `cidr_blocks = ["0.0.0.0/0"]` = to anywhere (exits go through the private subnet → NAT Gateway → internet)

**`lifecycle { create_before_destroy = true }`**
- Same as RDS SG — if Terraform needs to replace this SG, it creates the new one first, migrates the ElastiCache cluster to it, then destroys the old one
- Without this: destroy old → brief moment where Redis has no firewall → then create new. Not acceptable.

---

## ElastiCache Block 4 — The Redis Cluster (Lines 74–92)

```hcl
resource "aws_elasticache_cluster" "main" {
  cluster_id           = "${var.project_name}-${var.environment}-redis"
  engine               = "redis"
  engine_version       = "7.1"
  node_type            = var.node_type
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379

  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [aws_security_group.redis.id]

  tags = {
    Name        = "${var.project_name}-${var.environment}-redis"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
```

**Every line explained:**

**`cluster_id = "kubeflow-ops-dev-redis"`**
- The unique name of this ElastiCache cluster in AWS
- Shows up in the console and in CloudWatch metrics
- Must be lowercase, hyphens allowed, max 50 chars

**`engine = "redis"`**
- ElastiCache supports two engines: `redis` and `memcached`
- We use `redis` because the notification-service code explicitly uses `redis.from_url(REDIS_URL)` — Python's `redis` library
- Memcached doesn't support the `SETEX` (set with TTL) command that the app uses for deduplication

**`engine_version = "7.1"`**
- Redis 7.1 — matches what we used in docker-compose: `redis:7-alpine`
- Consistency between local and production is important — avoid surprises from version differences

**`node_type = var.node_type`** → `"cache.t3.micro"`
- The instance class (passes through from variables)
- This is the physical RAM/CPU of the Redis server

**`num_cache_nodes = 1`**
- Single Redis node — no replication for dev
- **Important:** `aws_elasticache_cluster` with `num_cache_nodes = 1` is a **standalone** Redis instance
- For production, you'd switch to `aws_elasticache_replication_group` which supports:
  - Primary + read replicas
  - Automatic failover
  - Multi-AZ

Why not use `aws_elasticache_replication_group` now?
- It's significantly more complex to configure
- Costs 2x+ more (minimum 2 nodes)
- Dev doesn't need HA — if Redis restarts, notification deduplication just resets (acceptable for dev)

**`parameter_group_name = "default.redis7"`**
- A **parameter group** is a collection of Redis configuration settings (like `maxmemory-policy`, `timeout`, etc.)
- `default.redis7` is AWS's pre-built default settings for Redis 7 — no custom tuning needed for our use case
- In production you might create a custom parameter group to set `maxmemory-policy allkeys-lru` (evict least-recently-used keys when memory fills up)

**`port = 6379`**
- The port Redis listens on
- Must match what the security group `ingress` allows (also 6379)
- Must match what the app connects to via `REDIS_URL = "redis://...:6379/0"`

**`subnet_group_name = aws_elasticache_subnet_group.main.name`**
- Connects the cluster to the subnet group from Block 2
- Terraform resolves the reference automatically — it knows to create the subnet group first

**`security_group_ids = [aws_security_group.redis.id]`**
- Attaches the firewall from Block 3
- `[...]` is a list — you can attach multiple SGs if needed, but one is enough here

---

## ElastiCache Block 5 — Outputs (Lines 94–107)

```hcl
output "endpoint" {
  description = "Redis endpoint address"
  value       = aws_elasticache_cluster.main.cache_nodes[0].address
}

output "port" {
  value = aws_elasticache_cluster.main.cache_nodes[0].port
}

output "redis_url" {
  description = "Full Redis URL for application config"
  value       = "redis://${aws_elasticache_cluster.main.cache_nodes[0].address}:${aws_elasticache_cluster.main.cache_nodes[0].port}/0"
}
```

**`output "endpoint"`**

```hcl
value = aws_elasticache_cluster.main.cache_nodes[0].address
```

- `cache_nodes` is a **list** — even with `num_cache_nodes = 1`, AWS returns a list with one element
- `[0]` gets the first (and only) node
- `.address` gives the DNS hostname, e.g.:
  `kubeflow-ops-dev-redis.abc123.0001.use1.cache.amazonaws.com`
- This is a private DNS name — only resolves inside the VPC

**`output "port"`**

```hcl
value = aws_elasticache_cluster.main.cache_nodes[0].port
```

- Always `6379` for Redis
- Stored as output anyway so other configs don't need to hardcode it

**`output "redis_url"`**

```hcl
value = "redis://${address}:${port}/0"
```

This builds the full `REDIS_URL` connection string:
```
redis://kubeflow-ops-dev-redis.abc123.0001.use1.cache.amazonaws.com:6379/0
```

Breaking it apart:
```
redis://          ← scheme (protocol)
HOST              ← the ElastiCache endpoint
:6379             ← port
/0                ← Redis database number (Redis has 16 DBs: 0-15, we use 0)
```

> **Why expose `redis_url` as an output?**
> This gets printed after `terraform apply` (via [environments/dev/outputs.tf](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/environments/dev/outputs.tf:0:0-0:0)). You copy this URL and store it in **AWS Secrets Manager** (or directly in a Kubernetes ConfigMap). The notification-service reads it as `REDIS_URL` at runtime.
>
> In this project, the RDS credentials go into Secrets Manager automatically (Terraform does it). But Redis has no password — so the URL is less sensitive and can go into a **Kubernetes ConfigMap** directly (plain text, not a secret).

---

## 📋 Module 5 Complete Picture

```
ElastiCache module creates (in dependency order):

1. aws_elasticache_subnet_group
   └── "which private subnets can Redis use?"

2. aws_security_group (redis)
   └── "only EKS pods can connect on port 6379"

3. aws_elasticache_cluster
   └── "the actual Redis 7.1 server"
       ├── lives in private subnet
       ├── guarded by security group
       └── accessible ONLY from EKS

Outputs:
├── endpoint  → "kubeflow-ops-dev-redis.xxx.cache.amazonaws.com"
├── port      → 6379
└── redis_url → "redis://kubeflow-ops-dev-redis.xxx.cache.amazonaws.com:6379/0"
                 ↑ this goes into the notification-service as REDIS_URL env var
```

---

## Side-by-Side: Local (docker-compose) vs Production (ElastiCache)

| | Local | Production |
|---|---|---|
| Image/Engine | `redis:7-alpine` (Docker) | `engine_version = "7.1"` (ElastiCache) |
| Host | `redis` (Docker service name) | AWS DNS hostname |
| Port | `6379` | `6379` |
| Auth | None | None (SG fence is the protection) |
| Persistence | Lost on `docker-compose down` | Survives — managed by AWS |
| HA | No | Optional with replication group |
| URL | `redis://redis:6379/0` | `redis://HOST.cache.amazonaws.com:6379/0` |

**The app code changes nothing.** It just reads `REDIS_URL` from an env var. Locally that env var points to the Docker container. In Kubernetes it points to ElastiCache. **Same app, different infrastructure.**

---

Ready for **Module 6 — SQS** block by block? Just say **"continue"**! 🚀

### User Input

Module 6

### Planner Response

I already have the SQS file content. Let me go through every single block.

---

# 🔷 Module 6 — SQS (Message Queue) — Full Block by Block

> **File:** [terraform/modules/sqs/main.tf](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/modules/sqs/main.tf:0:0-0:0)
> (Everything in one file — variables, resources, outputs)

---

## Why Does This Module Exist?

Before any code — **how did I know we need SQS?**

I opened [apps/order-service/main.py](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/apps/order-service/main.py:0:0-0:0) and saw:

```python
SQS_QUEUE_URL = os.getenv("SQS_QUEUE_URL", "http://localhost:4566/000000000000/order-events")

def publish_order_event(...):
    sqs = get_sqs_client()
    sqs.send_message(QueueUrl=SQS_QUEUE_URL, MessageBody=json.dumps(message))
```

And in [apps/notification-service/main.py](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/apps/notification-service/main.py:0:0-0:0):

```python
response = sqs.receive_message(QueueUrl=SQS_QUEUE_URL, ...)
sqs.delete_message(QueueUrl=SQS_QUEUE_URL, ReceiptHandle=msg["ReceiptHandle"])
```

Two services talk over a message queue:
- `order-service` → **PRODUCER** → sends messages to SQS
- `notification-service` → **CONSUMER** → reads and deletes messages from SQS

In [docker-compose.yml](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/docker-compose.yml:0:0-0:0) that queue lived in LocalStack (fake AWS). In production, we need **real AWS SQS**.

---

## SQS Block 1 — Variables (Lines 9–15)

```hcl
variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}
```

**Why only 2 variables?**

Compare this to RDS (7 variables) and ElastiCache (6 variables). SQS is simpler because:

- No VPC placement needed — SQS is a **managed AWS service with no VPC requirement**. It's accessed over HTTPS from anywhere in your AWS account
- No subnet group needed
- No security group needed — access is controlled by **IAM policies** instead (which is actually more secure and flexible)
- No instance size — SQS is serverless. There's no server to size. You pay per message, not per hour.

| Variable | Type | Default | Where it comes from |
|---|---|---|---|
| `project_name` | string | — | `"kubeflow-ops"` from [environments/dev/main.tf](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/environments/dev/main.tf:0:0-0:0) |
| `environment` | string | — | `"dev"` from [environments/dev/main.tf](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/environments/dev/main.tf:0:0-0:0) |

Both are just used for naming/tagging. That's it.

---

## SQS Block 2 — Dead Letter Queue (Lines 17–29)

```hcl
resource "aws_sqs_queue" "order_events_dlq" {
  name                      = "${var.project_name}-${var.environment}-order-events-dlq"
  message_retention_seconds = 1209600

  tags = {
    Name        = "${var.project_name}-${var.environment}-order-events-dlq"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
```

**Why is DLQ created FIRST, before the main queue?**

The main queue needs to reference the DLQ's ARN in its `redrive_policy`. In Terraform (and in real life), you can't reference something that doesn't exist yet. So the DLQ must be created first.

Terraform figures out this dependency automatically because `aws_sqs_queue.order_events` references `aws_sqs_queue.order_events_dlq.arn`. Terraform builds a dependency graph and creates DLQ first — you don't write any `depends_on` here.

**`name = "kubeflow-ops-dev-order-events-dlq"`**

Notice the `-dlq` suffix. This is a naming convention so you can immediately tell:
- `kubeflow-ops-dev-order-events` → the working queue
- `kubeflow-ops-dev-order-events-dlq` → the failure parking lot

---

**`message_retention_seconds = 1209600`**

How long SQS keeps a message before deleting it automatically.

```
1209600 seconds ÷ 60 ÷ 60 ÷ 24 = 14 days
```

Why 14 days for the DLQ (vs 4 days for the main queue)?

| Queue | Retention | Why |
|---|---|---|
| Main queue (`order-events`) | 4 days (345600s) | Messages should be processed in seconds/minutes. 4 days is already extremely generous |
| DLQ (`order-events-dlq`) | 14 days (1209600s) | These are **broken messages** that failed 3 times. You need time to: notice the alert, investigate the cause, fix the bug, replay the messages. 14 days gives you breathing room |

> **Max SQS retention is 14 days** — that's why DLQs always use 1209600 as their retention.

---

## SQS Block 3 — Main Queue (Lines 31–48)

```hcl
resource "aws_sqs_queue" "order_events" {
  name                       = "${var.project_name}-${var.environment}-order-events"
  visibility_timeout_seconds = 30
  message_retention_seconds  = 345600
  receive_wait_time_seconds  = 10

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.order_events_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-order-events"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
```

**Every line explained:**

---

**`name = "kubeflow-ops-dev-order-events"`**

The working queue name. This is what `order-service` sends to and `notification-service` reads from.

> Quick note on SQS queue types: there are **Standard** queues and **FIFO** queues.
> - Standard = at-least-once delivery, best-effort ordering, unlimited throughput
> - FIFO = exactly-once delivery, strict ordering, limited throughput, name ends in `.fifo`
>
> We're using **Standard** (no `.fifo` suffix) because:
> 1. Higher throughput
> 2. The notification-service already handles duplicates via Redis idempotency check — so at-least-once delivery is fine
> 3. Order of notifications doesn't matter (we don't care if "order delivered" arrives before "order shipped" in our simple demo)

---

**`visibility_timeout_seconds = 30`**

This is one of the most important SQS settings to understand. Here's exactly what it does:

```
1. notification-service calls ReceiveMessage
2. SQS hands out the message to notification-service
3. The message DISAPPEARS from the queue for 30 seconds
   └── Other consumers can't see or receive it during this time
4. Two outcomes:
   ├── A) notification-service processes it successfully
   │      └── calls DeleteMessage → message gone forever ✅
   └── B) notification-service crashes mid-processing
             └── after 30s, message becomes VISIBLE again
                 └── notification-service (once restarted) reads it again → retry ♻️
```

**Why 30 seconds?**

It should be longer than the time it takes to process one message. Our notification-service does:
- Redis lookup (< 1ms)
- JSON parsing (< 1ms)
- Redis setex (< 1ms)
- SQS delete (< 100ms)

→ Total: well under 1 second. 30 seconds is generous.

If you set it too short (e.g., 5 seconds) and processing takes 6 seconds, the message reappears mid-processing and gets processed **twice** — a bug. If set too long (e.g., 12 hours) and the consumer crashes, the message is invisible for 12 hours before retrying — your system looks broken.

---

**`message_retention_seconds = 345600`**

```
345600 seconds ÷ 60 ÷ 60 ÷ 24 = 4 days
```

If a message is never picked up (consumer is down for 4 days), it auto-deletes. This prevents an endlessly growing queue if the consumer is broken.

---

**`receive_wait_time_seconds = 10`**

This is **Long Polling** — a huge cost optimization.

**Short polling (default, `receive_wait_time_seconds = 0`):**
```
Consumer: "Any messages?"
SQS:      "Nope"   (charged for this API call)
Consumer: "Any messages?"  (0.1 seconds later)
SQS:      "Nope"   (charged again)
... repeats thousands of times per hour even when queue is empty
```

**Long polling (`receive_wait_time_seconds = 10`):**
```
Consumer: "Any messages? I'll wait up to 10 seconds"
SQS:      ... waits ...
SQS:      "Yes! Here's a message" (returns immediately when one arrives)
           OR
SQS:      "Nothing arrived in 10 seconds" (one API call for 10 seconds)
```

Benefits:
- **~95% fewer API calls** when queue is mostly empty
- **Lower latency** — message arrives instantly when it appears, not on next poll
- **Lower cost** — SQS charges per API call

The `notification-service` code already uses this:
```python
response = sqs.receive_message(
    WaitTimeSeconds=10,  # ← matches this setting
    MaxNumberOfMessages=10,
)
```

---

**`redrive_policy` — The DLQ Link**

```hcl
redrive_policy = jsonencode({
  deadLetterTargetArn = aws_sqs_queue.order_events_dlq.arn
  maxReceiveCount     = 3
})
```

`jsonencode({...})` converts a Terraform object into a JSON string — because SQS expects the policy as a JSON string, not a structured object.

The result looks like:
```json
{
  "deadLetterTargetArn": "arn:aws:sqs:us-east-1:123456789:kubeflow-ops-dev-order-events-dlq",
  "maxReceiveCount": 3
}
```

**`deadLetterTargetArn`**
- Points to the DLQ we created in Block 2
- `aws_sqs_queue.order_events_dlq.arn` — Terraform resolves this reference, which is why DLQ must exist first

**`maxReceiveCount = 3`**
- How many times can a consumer fail to process a message before it gets moved to the DLQ?

Full failure flow:
```
Attempt 1: notification-service receives message, crashes
           → visibility timeout expires → message reappears
           → ReceiveCount = 1

Attempt 2: notification-service receives it again, crashes
           → visibility timeout expires → message reappears
           → ReceiveCount = 2

Attempt 3: notification-service receives it again, crashes
           → ReceiveCount = 3 = maxReceiveCount
           → SQS automatically moves message to DLQ
           → CloudWatch alarm fires (you set this up separately)
           → Engineer investigates
```

Why 3? It's a balance:
- `1` = one crash and it goes to DLQ immediately. Transient errors (brief Redis downtime) would cause false positives
- `3` = gives the system 3 chances. Transient errors usually recover. Real bugs consistently fail 3 times.
- `10+` = too many retries. You're flooding your system with a broken message for too long

---

## SQS Block 4 — IAM Policy (Lines 50–76)

```hcl
resource "aws_iam_policy" "sqs_access" {
  name        = "${var.project_name}-${var.environment}-sqs-access"
  description = "Allow send/receive on order events SQS queue"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
        ]
        Resource = [
          aws_sqs_queue.order_events.arn,
          aws_sqs_queue.order_events_dlq.arn,
        ]
      }
    ]
  })
}
```

**This is different from all previous modules.** RDS and ElastiCache used **Security Groups** as their fence. SQS is different — it uses **IAM policies**. Why?

RDS and ElastiCache are **network-level services** — they have IP addresses, ports, and you connect via TCP. Security groups are the right tool.

SQS is an **API-level service** — there's no "connection" to SQS. You make HTTPS API calls to `https://sqs.us-east-1.amazonaws.com/...`. There's no port to block. Authorization happens via IAM.

---

**`name = "kubeflow-ops-dev-sqs-access"`**
- The IAM policy name — appears in the IAM console
- This policy is **not attached to anything yet** in this module
- It gets attached to a Kubernetes ServiceAccount via **IRSA** (the OIDC mechanism we set up in the EKS module)

---

**The policy document — every part explained:**

**`Version = "2012-10-17"`**
- This is a literal required field in all AWS IAM policies
- `"2012-10-17"` is the current IAM policy language version — always use this. The older `"2008-10-17"` version lacks features like condition operators

**`Effect = "Allow"`**
- Either `"Allow"` or `"Deny"`
- IAM defaults to **deny everything**. You only write Allow statements to grant permissions
- You don't need to write Deny for things you didn't Allow — they're automatically denied

**`Action` — The 5 SQS operations permitted:**

| Action | Used by | Why |
|---|---|---|
| `sqs:SendMessage` | `order-service` | Posts an event to the queue |
| `sqs:ReceiveMessage` | `notification-service` | Reads messages from the queue |
| `sqs:DeleteMessage` | `notification-service` | Removes a message after successful processing |
| `sqs:GetQueueAttributes` | Both services | Reads queue metadata (needed by boto3 internally) |
| `sqs:GetQueueUrl` | Both services | Resolves queue name → URL (boto3 uses this) |

**Principle of least privilege:** We only gave exactly the 5 actions these services need. We did NOT give:
- `sqs:DeleteQueue` — would let a bug wipe the entire queue
- `sqs:CreateQueue` — not needed at runtime
- `sqs:PurgeQueue` — would let a bug delete all messages
- `sqs:*` (wildcard) — never do this

**`Resource` — The two queues:**

```hcl
Resource = [
  aws_sqs_queue.order_events.arn,
  aws_sqs_queue.order_events_dlq.arn,
]
```

This policy ONLY works on **these two specific queues**. Not any other SQS queue in your AWS account. Even if someone injected a different `SQS_QUEUE_URL` env var into the pod, the IAM policy would reject it.

Why include the DLQ ARN? The notification-service reads from the DLQ to replay failed messages (a common operational task). Without DLQ access, you couldn't investigate failed messages.

---

**How this IAM policy gets used (IRSA flow):**

```
Terraform creates:
  ├── aws_iam_policy.sqs_access  ← this block
  └── aws_iam_openid_connect_provider.eks  ← from EKS module

Later, in Kubernetes manifests (Phase 3):
  ├── ServiceAccount for order-service
  │     └── annotation: eks.amazonaws.com/role-arn = arn:aws:iam::...:role/order-service-role
  └── IAM Role for order-service
        ├── Trust policy: "trust tokens from OIDC provider for order-service ServiceAccount"
        └── Policy attachment: aws_iam_policy.sqs_access

Result:
  When the order-service pod starts, AWS SDK automatically gets temporary credentials
  Those credentials can ONLY do the 5 SQS actions above
  Credentials expire every hour and auto-rotate
  No secrets to manage
```

---

## SQS Block 5 — Outputs (Lines 78–97)

```hcl
output "queue_url" {
  description = "URL of the order events SQS queue"
  value       = aws_sqs_queue.order_events.url
}

output "queue_arn" {
  description = "ARN of the order events SQS queue"
  value       = aws_sqs_queue.order_events.arn
}

output "dlq_url" {
  description = "URL of the dead-letter queue"
  value       = aws_sqs_queue.order_events_dlq.url
}

output "sqs_policy_arn" {
  description = "ARN of the IAM policy for SQS access (attach via IRSA)"
  value       = aws_iam_policy.sqs_access.arn
}
```

**`output "queue_url"`**

```
https://sqs.us-east-1.amazonaws.com/123456789012/kubeflow-ops-dev-order-events
```

This is what goes into the `SQS_QUEUE_URL` environment variable for both services. Compare to local dev where it was `http://localstack:4566/000000000000/order-events` — the URL format is identical, just different host. The app code doesn't change at all.

This gets printed after `terraform apply` via [environments/dev/outputs.tf](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/terraform/environments/dev/outputs.tf:0:0-0:0):
```hcl
output "sqs_queue_url" {
  value = module.sqs.queue_url
}
```

---

**`output "queue_arn"`**

```
arn:aws:sqs:us-east-1:123456789012:kubeflow-ops-dev-order-events
```

**ARN** = Amazon Resource Name — a globally unique identifier for any AWS resource.

Format: `arn:aws:[service]:[region]:[account-id]:[resource]`

This ARN is used in the IAM policy (Block 4) as the `Resource` value. We also expose it as output in case other Terraform modules (e.g., a future Lambda trigger) need to reference this queue.

---

**`output "dlq_url"`**

```
https://sqs.us-east-1.amazonaws.com/123456789012/kubeflow-ops-dev-order-events-dlq
```

Used for:
- CloudWatch alarm configuration: "alert me if message count in DLQ > 0"
- Operational scripts to replay DLQ messages back to the main queue after fixing a bug

---

**`output "sqs_policy_arn"`**

```
arn:aws:iam::123456789012:policy/kubeflow-ops-dev-sqs-access
```

This ARN is what you use in Phase 3 (Kubernetes) when setting up IRSA. You create an IAM Role for the service's ServiceAccount and attach this policy to it. The output makes it easy to copy-paste.

---

## 📋 Module 6 Complete Picture

```
SQS module creates (in dependency order):

1. aws_sqs_queue.order_events_dlq  (created first)
   └── name: kubeflow-ops-dev-order-events-dlq
   └── retention: 14 days
   └── no redrive policy (it IS the dead end)

2. aws_sqs_queue.order_events  (references DLQ, created second)
   └── name: kubeflow-ops-dev-order-events
   └── visibility_timeout: 30s
   └── retention: 4 days
   └── long polling: 10s
   └── redrive: after 3 fails → move to DLQ

3. aws_iam_policy.sqs_access  (standalone, no deps)
   └── allows: SendMessage, ReceiveMessage, DeleteMessage,
              GetQueueAttributes, GetQueueUrl
   └── on: both queues (main + DLQ)
   └── used later by IRSA ServiceAccount annotations

Outputs:
├── queue_url      → "https://sqs.us-east-1.amazonaws.com/.../order-events"
│                    ↑ goes into SQS_QUEUE_URL env var
├── queue_arn      → "arn:aws:sqs:us-east-1:...:order-events"
├── dlq_url        → "https://sqs.us-east-1.amazonaws.com/.../order-events-dlq"
└── sqs_policy_arn → "arn:aws:iam::...:policy/kubeflow-ops-dev-sqs-access"
                     ↑ attached to ServiceAccount IAM Role via IRSA
```

---

## 🔄 Full Message Flow (Local vs Production)

```
LOCAL (docker-compose):
  order-service → LocalStack:4566/order-events → notification-service
  (fake SQS, no auth required, no DLQ in prod sense)

PRODUCTION (AWS):
  order-service
    └─ (has IRSA role with sqs:SendMessage)
    └─ sends to: https://sqs.us-east-1.amazonaws.com/.../kubeflow-ops-dev-order-events
         │
         ├─ if processed OK → notification-service deletes it
         │
         └─ if fails 3 times → auto-moved to kubeflow-ops-dev-order-events-dlq
                                    └─ CloudWatch alarm fires → engineer alert
```

---

## ✅ Phase 2 (Terraform) — All 6 Modules Complete

```
terraform/
├── environments/dev/
│   ├── backend.tf   ← S3 state + DynamoDB lock
│   ├── main.tf      ← wires all 6 modules together
│   └── outputs.tf   ← prints useful values after apply
└── modules/
    ├── vpc/         ✅ VPC, subnets, IGW, NAT Gateway, route tables
    ├── eks/         ✅ IAM roles, EKS cluster, OIDC, node group, addons
    ├── ecr/         ✅ 3 repos, scan-on-push, lifecycle policy
    ├── rds/         ✅ Postgres 16, security group, Secrets Manager
    ├── elasticache/ ✅ Redis 7.1, security group, subnet group
    └── sqs/         ✅ Main queue + DLQ, long polling, IAM policy
```

---

Ready for **Phase 3 — Kubernetes Manifests (the `gitops/` folder)**?

That's where you take what Terraform built (EKS cluster, RDS, Redis, SQS) and write the YAML files that tell Kubernetes **how to run your apps** — Deployments, Services, ConfigMaps, Secrets via External Secrets, and HPA. Say **"continue"**! 🚀

### User Input

Phase 3 - Part 1

### Planner Response

Let me read all the gitops files first before explaining anything.

*Listed directory [common](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/gitops/apps/common) *

*Listed directory [order-service](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/gitops/apps/order-service) *

*Listed directory [user-service](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/gitops/apps/user-service) *

*Listed directory [notification-service](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/gitops/apps/notification-service) *

*Listed directory [base](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/gitops/apps/order-service/base) *

*Listed directory [base](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/gitops/apps/user-service/base) *

*Listed directory [base](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/gitops/apps/notification-service/base) *

*Viewed [namespace.yaml](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/gitops/apps/common/namespace.yaml) *

*Viewed [service-account.yaml](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/gitops/apps/common/service-account.yaml) *

*Viewed [configmap.yaml](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/gitops/apps/common/configmap.yaml) *

*Viewed [ingress.yaml](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/gitops/apps/common/ingress.yaml) *

*Viewed [deployment.yaml](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/gitops/apps/order-service/base/deployment.yaml) *

*Viewed [service.yaml](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/gitops/apps/order-service/base/service.yaml) *

*Viewed [hpa.yaml](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/gitops/apps/order-service/base/hpa.yaml) *

*Viewed [kustomization.yaml](file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/gitops/apps/order-service/base/kustomization.yaml) *

### Planner Response

Good. Now I have everything for Part 1. Let me explain it all completely.

---

# 🚀 PHASE 3 — Kubernetes Manifests (GitOps folder)

## What Is This Phase and Why Does It Exist?

Terraform created the **infrastructure** — VPC, EKS cluster, RDS, Redis, SQS. Now EKS is an empty Kubernetes cluster. Nothing is running on it yet.

Phase 3 is where you write YAML files that tell Kubernetes:
- **What to run** → your Docker images from ECR
- **How to run it** → how many copies, how much CPU/RAM
- **How to expose it** → what port, what URL path
- **How to scale it** → automatically add pods under load
- **How to configure it** → env vars from ConfigMaps and Secrets

These YAML files live in the `gitops/` folder. ArgoCD watches this folder in Git. Any change you push here → ArgoCD applies it to the cluster automatically.

---

## 📁 The GitOps Folder Structure

```
gitops/
└── apps/
    ├── common/                   ← Shared by ALL 3 services
    │   ├── namespace.yaml        ← The "room" all services live in
    │   ├── service-account.yaml  ← IRSA identity for pods
    │   ├── configmap.yaml        ← Non-secret config (URLs, region)
    │   └── ingress.yaml          ← The front door (external traffic routing)
    │
    ├── order-service/base/
    │   ├── deployment.yaml       ← How to run order-service pods
    │   ├── service.yaml          ← Internal DNS for order-service
    │   ├── hpa.yaml              ← Auto-scaling rules
    │   └── kustomization.yaml    ← Groups the above 3 files
    │
    ├── user-service/base/
    │   └── all.yaml              ← Deployment + Service + HPA in one file
    │
    └── notification-service/base/
        └── all.yaml              ← Deployment + Service + HPA in one file
```

> **Why does order-service have separate files but user/notification have [all.yaml](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/gitops/apps/user-service/base/all.yaml:0:0-0:0)?**
> Same content — different organization styles. Splitting into files makes it easier to navigate for larger services. Combining into one [all.yaml](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/gitops/apps/user-service/base/all.yaml:0:0-0:0) is simpler for smaller ones. Both patterns are valid.

---

## Part 1 — The `common/` Folder

These 4 files are applied **once**, not per service. They set up shared infrastructure that all 3 services use.

**Order you'd apply them:**
```
1. namespace.yaml      ← must exist before anything else
2. service-account.yaml ← must exist before Deployments reference it
3. configmap.yaml      ← must exist before Deployments read from it
4. ingress.yaml        ← routes traffic to Services (Services must exist first)
```

---

## 📄 File 1 — [namespace.yaml](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/gitops/apps/common/namespace.yaml:0:0-0:0)

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: kubeflow-ops
  labels:
    app.kubernetes.io/part-of: kubeflow-ops
    prometheus.io/scrape: "true"
```

### What is a Namespace?

Think of a Kubernetes cluster like an **office building**. The building is the cluster. A **Namespace** is a **floor** in that building. Every resource in Kubernetes belongs to a namespace.

**Why not use the `default` namespace?**

| | `default` namespace | `kubeflow-ops` namespace |
|---|---|---|
| Isolation | None — everything mixed together | All our resources are grouped |
| Access control | Hard to apply RBAC | Easy: "give this team access to `kubeflow-ops` only" |
| Resource quotas | Hard to set | Easy: "this namespace gets max 4 CPU" |
| Cleanup | Need to know all resource names | `kubectl delete namespace kubeflow-ops` — deletes everything at once |

---

**Line by line:**

**`apiVersion: v1`**
- Every Kubernetes object starts with `apiVersion` and `kind`
- `v1` is the core API group — it contains basic objects like Namespace, Pod, Service, ConfigMap, Secret
- For more advanced objects (Deployments, HPA) you'll see `apps/v1`, `autoscaling/v2`, etc.

**`kind: Namespace`**
- Tells Kubernetes "create a namespace"
- Other kinds you'll see: `Deployment`, `Service`, `ConfigMap`, `Ingress`, `HorizontalPodAutoscaler`

**`metadata:`**
- Metadata is information **about** the object — not the object's behaviour
- `name: kubeflow-ops` — the namespace name. All other objects reference this: `namespace: kubeflow-ops`

**`labels:`**
```yaml
labels:
  app.kubernetes.io/part-of: kubeflow-ops
  prometheus.io/scrape: "true"
```

Labels are **key-value tags** on any Kubernetes object. Two uses:

1. `app.kubernetes.io/part-of: kubeflow-ops` — a standard Kubernetes label convention. Means "this resource belongs to the kubeflow-ops application". Used by dashboards and ArgoCD to group things visually.

2. `prometheus.io/scrape: "true"` — This is a **Prometheus annotation/label convention**. Prometheus is configured to look for pods in namespaces with this label and automatically scrape their `/metrics` endpoint. Without this, Prometheus wouldn't know to collect metrics from your pods.

> **How did I know we'd need `prometheus.io/scrape`?** The [main.py](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/apps/user-service/main.py:0:0-0:0) files use `prometheus_fastapi_instrumentator` which exposes `/metrics`. We need Prometheus to actually find and scrape that endpoint. The label tells it where to look.

---

## 📄 File 2 — [service-account.yaml](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/gitops/apps/common/service-account.yaml:0:0-0:0)

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

### What is a ServiceAccount?

A **ServiceAccount** is a Kubernetes identity for a **pod** (not a human). Humans have user accounts. Pods have ServiceAccounts.

Every pod in Kubernetes automatically has a ServiceAccount. If you don't specify one, it uses the `default` ServiceAccount — which has no permissions to anything.

We're creating a **named ServiceAccount** that is linked to an AWS IAM Role via the annotation.

---

**Line by line:**

**`kind: ServiceAccount`**
- A core Kubernetes object (in `v1` API group)
- Created before Deployments, because Deployments reference it by name

**`name: kubeflow-ops-sa`**
- The ServiceAccount name. In the Deployment you'll see:
  ```yaml
  spec:
    serviceAccountName: kubeflow-ops-sa
  ```
  This is how the pod "wears" this identity.

**`namespace: kubeflow-ops`**
- ServiceAccounts are namespace-scoped — they only exist in the namespace where they're created

**`annotations:`**

Annotations are different from labels:
- **Labels** → used by Kubernetes itself for selection, grouping
- **Annotations** → used by external tools/operators to attach metadata

```yaml
annotations:
  eks.amazonaws.com/role-arn: "arn:aws:iam::ACCOUNT_ID:role/kubeflow-ops-dev-app-role"
```

This annotation is read by the **aws-node** DaemonSet (EKS's IRSA implementation). When a pod starts using this ServiceAccount, the IRSA system:

1. Sees the `eks.amazonaws.com/role-arn` annotation
2. Contacts the OIDC provider (which Terraform set up in the EKS module)
3. Issues temporary AWS credentials for that IAM role
4. Injects them into the pod as environment variables (`AWS_ROLE_ARN`, `AWS_WEB_IDENTITY_TOKEN_FILE`)
5. The AWS SDK inside the pod automatically picks them up — no code change needed

**`ACCOUNT_ID` is a placeholder** — after `terraform apply`, you replace it with your actual 12-digit AWS account ID.

> **Connection back to Terraform:** In the EKS module, we set up the OIDC provider. In the SQS module, we created the IAM policy. Here, we create the Kubernetes identity (ServiceAccount) that bridges the two. In production you'd also create the IAM Role itself in Terraform and annotate this ServiceAccount with its ARN.

---

## 📄 File 3 — [configmap.yaml](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/gitops/apps/common/configmap.yaml:0:0-0:0)

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

### What is a ConfigMap?

A **ConfigMap** stores **non-sensitive** configuration as key-value pairs. Pods read these values as environment variables. It keeps config **out of your Docker images** — the same image runs in dev, staging, and prod, just with different ConfigMaps.

**The Golden Rule of Kubernetes Config:**
```
ConfigMap  = non-sensitive data (URLs, region names, feature flags)
Secret     = sensitive data (passwords, API keys, tokens)
```

---

**Line by line:**

**`kind: ConfigMap`**
- Core Kubernetes object (`v1`)
- Purely a data store — no behaviour

**`name: app-config`**
- The ConfigMap name. Deployments reference it like:
  ```yaml
  configMapKeyRef:
    name: app-config
    key: sqs-queue-url
  ```

**`data:` section — the 3 keys:**

**`aws-region: "us-east-1"`**
- The AWS region where SQS and other services live
- Read by the app as `AWS_REGION` env var
- Why not hardcode in the app? If you ever move regions, change one ConfigMap — not rebuild all 3 Docker images

**`sqs-queue-url: "PLACEHOLDER_AFTER_TERRAFORM_APPLY"`**
- After `terraform apply`, you copy the `sqs_queue_url` output value here
- Example final value:
  ```
  https://sqs.us-east-1.amazonaws.com/123456789012/kubeflow-ops-dev-order-events
  ```
- Both `order-service` and `notification-service` read this
- **Not a secret** — the URL is not sensitive. Access is controlled by IAM (IRSA)

**`redis-url: "PLACEHOLDER_AFTER_TERRAFORM_APPLY"`**
- After `terraform apply`, copy the `redis_url` output value here
- Example final value:
  ```
  redis://kubeflow-ops-dev-redis.xxx.cache.amazonaws.com:6379/0
  ```
- Only `notification-service` reads this
- **Not a secret** — Redis in this setup has no password (protected by Security Group)

> **Why are these PLACEHOLDERs instead of real values?**
> Because Terraform must run first to create these resources and generate the URLs. This is the "chicken and egg" moment in GitOps — you commit the initial files, apply Terraform, then update the ConfigMap with real values and push again. ArgoCD will pick up the update and inject the real URLs into pods.

---

## 📄 File 4 — [ingress.yaml](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/gitops/apps/common/ingress.yaml:0:0-0:0)

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
  labels:
    app.kubernetes.io/part-of: kubeflow-ops
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
            pathType: ImplementationSpecific
            backend:
              service:
                name: user-service
                port:
                  number: 8002
          - path: /api/notifications(/|$)(.*)
            pathType: ImplementationSpecific
            backend:
              service:
                name: notification-service
                port:
                  number: 8003
```

### What is an Ingress?

This is the **front door** to your cluster from the outside world.

Think of the traffic flow as a building:
```
Internet
   ↓
AWS Load Balancer (created automatically by NGINX Ingress Controller)
   ↓
NGINX Ingress Controller (a pod running in the cluster)
   ↓  reads this Ingress YAML to know routing rules
   ├── /api/orders/*       → order-service Service (port 8001)
   ├── /api/users/*        → user-service Service (port 8002)
   └── /api/notifications/* → notification-service Service (port 8003)
```

**What is NGINX Ingress Controller?**
A new concept. It's a pod running inside Kubernetes that:
1. Watches for `Ingress` resources in the cluster
2. Configures itself as an HTTP reverse proxy based on the rules
3. Creates an AWS Load Balancer in front of itself

Without Ingress, each service would need its own Load Balancer ($$$). With Ingress, **one** Load Balancer handles all 3 services.

---

**Line by line:**

**`apiVersion: networking.k8s.io/v1`**
- Networking objects are in the `networking.k8s.io` API group, not the core `v1` group

**`kind: Ingress`**
- Tells Kubernetes "this is a routing rule"

**`annotations:` — 4 NGINX-specific settings:**

**`nginx.ingress.kubernetes.io/rewrite-target: /$2`**
- The URL path rewriting rule
- Client requests: `GET /api/orders/123`
- NGINX strips the prefix and sends to order-service: `GET /123`
- The `$2` captures whatever comes after `/api/orders/` using the regex group [(.*)](cci:2://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/apps/order-service/main.py:82:4-83:30)
- Why? Your app only knows about `/orders/123` not `/api/orders/123`. The `/api/orders` prefix is just for external routing.

**`nginx.ingress.kubernetes.io/use-regex: "true"`**
- Enables regex patterns in the `path:` fields
- Required for the [(/|$)(.*)](cci:2://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/apps/order-service/main.py:82:4-83:30) capture groups to work

**`nginx.ingress.kubernetes.io/limit-rps: "50"`**
- **Rate limiting** — max 50 requests per second per client IP
- Prevents a single bad actor (or a bug in a client) from overwhelming your services
- Goes beyond this → NGINX returns `429 Too Many Requests`

**`nginx.ingress.kubernetes.io/limit-burst-multiplier: "5"`**
- Allows burst traffic up to `50 × 5 = 250 req/s` for a short time
- Handles legitimate traffic spikes (e.g., a flash sale) without immediately rate-limiting
- After the burst, drops back to 50 req/s limit

**`spec.ingressClassName: nginx`**
- Tells Kubernetes which Ingress controller should handle this rule
- You can have multiple Ingress controllers (NGINX + AWS ALB) — this picks NGINX
- If you omit this, no controller claims the Ingress and nothing happens

**`rules:` — the 3 routing rules:**

```yaml
- path: /api/orders(/|$)(.*)
  pathType: ImplementationSpecific
  backend:
    service:
      name: order-service
      port:
        number: 8001
```

**`path: /api/orders(/|$)(.*)`**
- Regex: match `/api/orders` followed by either `/` or end of string, then capture anything
- Matches: `/api/orders`, `/api/orders/`, `/api/orders/123`, `/api/orders/123/status`
- The [(.*)](cci:2://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/apps/order-service/main.py:82:4-83:30)  at the end is capture group 2 → gets passed to `rewrite-target: /$2`

**`pathType: ImplementationSpecific`**
- Lets the ingress controller (NGINX) handle path matching however it wants — needed because we're using regex. Standard `Prefix` or `Exact` types don't support regex.

**`backend.service.name: order-service`**
- The **Kubernetes Service** name to forward traffic to
- Must match exactly the `metadata.name` in [service.yaml](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/gitops/apps/order-service/base/service.yaml:0:0-0:0)
- Kubernetes DNS: `order-service.kubeflow-ops.svc.cluster.local`

**`backend.service.port.number: 8001`**
- The port on the Service to hit
- Must match `spec.ports[].port` in [service.yaml](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/gitops/apps/order-service/base/service.yaml:0:0-0:0)

---

## 📄 File 5 — [order-service/base/deployment.yaml](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/gitops/apps/order-service/base/deployment.yaml:0:0-0:0)

This is the most important and complex file. Let's go block by block.

### What is a Deployment?

A **Deployment** tells Kubernetes: "I want X copies of this container running at all times. If one dies, create a new one. When I update the image, do a rolling replacement."

---

### Deployment Block 1 — Identity (Lines 12–20)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-service
  namespace: kubeflow-ops
  labels:
    app: order-service
    team: platform
    version: v1
```

**`apiVersion: apps/v1`**
- Deployments live in the `apps` API group, not core `v1`
- `apps/v1` also contains StatefulSets, DaemonSets, ReplicaSets

**`kind: Deployment`**
- Tells Kubernetes "manage a set of pods with rolling update support"

**`metadata.labels:`**
```yaml
app: order-service    ← used by Service selector to find these pods
team: platform        ← for organizational purposes / RBAC
version: v1           ← for canary deployments (send 10% traffic to v2)
```

---

### Deployment Block 2 — ReplicaSet spec (Lines 21–25)

```yaml
spec:
  replicas: 2
  selector:
    matchLabels:
      app: order-service
```

**`replicas: 2`**
- Always run exactly 2 copies of the order-service pod
- If one crashes, Kubernetes immediately starts a replacement
- If the node dies, Kubernetes reschedules them on other nodes
- The HPA we'll see later can override this number dynamically

**`selector.matchLabels:`**
- This tells the Deployment which pods it "owns" and manages
- It looks for pods with the label `app: order-service`
- **Must match** the `template.metadata.labels` below — otherwise the Deployment can't find its own pods

---

### Deployment Block 3 — Pod Template (Lines 26–36)

```yaml
  template:
    metadata:
      labels:
        app: order-service
        team: platform
        version: v1
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8001"
        prometheus.io/path: "/metrics"
```

Everything under `template:` is the **blueprint for each pod**. The Deployment stamps out pods using this template — `replicas: 2` means it creates 2 identical pods from this template.

**`template.metadata.labels:`**
- These labels go on every pod created from this template
- `app: order-service` → matches the `selector.matchLabels` above ✅
- `app: order-service` → also matched by the Service's `selector` to route traffic ✅

**`annotations:`**
```yaml
prometheus.io/scrape: "true"   ← "yes, please collect metrics from me"
prometheus.io/port: "8001"     ← "my metrics are on port 8001"
prometheus.io/path: "/metrics" ← "specifically at /metrics endpoint"
```
Prometheus reads these annotations from running pods and adds them to its scrape targets. This is how Prometheus knows to collect metrics from your pods without you manually listing every pod IP.

> **How did I know these annotations?** The app code uses `prometheus_fastapi_instrumentator` which exposes `/metrics` at port 8001. We tell Prometheus exactly where to look.

---

### Deployment Block 4 — Pod Security (Lines 37–44)

```yaml
    spec:
      serviceAccountName: kubeflow-ops-sa
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
```

**`serviceAccountName: kubeflow-ops-sa`**
- Every pod created by this Deployment will use the `kubeflow-ops-sa` ServiceAccount
- This is how IRSA kicks in — the ServiceAccount has the IAM role annotation → pod gets AWS credentials
- Without this, the pod would use the `default` ServiceAccount and have NO AWS access → SQS calls would fail

**`securityContext:`** — pod-level security settings

**`runAsNonRoot: true`**
- Kubernetes will **refuse to start the pod** if the container tries to run as root (uid 0)
- Kyverno (Phase 5) will also enforce this as a cluster-wide policy
- Matches the Dockerfile: `USER appuser` — we already set up the non-root user

**`runAsUser: 1000`**
- Run all processes in this pod as Linux user ID 1000
- This corresponds to the `appuser` we created in the Dockerfile with `useradd`
- UID 1000 is a common convention for the first non-root application user

**`fsGroup: 1000`**
- Any files written to mounted volumes will have group ownership set to GID 1000
- Ensures the `appuser` can read/write files on any mounted volumes

---

### Deployment Block 5 — Container Spec (Lines 45–51)

```yaml
      containers:
        - name: order-service
          image: IMAGE_PLACEHOLDER
          ports:
            - containerPort: 8001
              name: http
              protocol: TCP
```

**`containers:` is a list** — a pod can run multiple containers (sidecars). Here we have just one.

**`name: order-service`**
- The container name within the pod. Used in `kubectl logs order-service-xyz-abc -c order-service`

**`image: IMAGE_PLACEHOLDER`**
- This is the **only line the CI pipeline changes** when you push new code
- The GitHub Actions workflow builds the image, pushes to ECR, then replaces this placeholder with the real ECR URL + new tag:
  ```
  123456789.dkr.ecr.us-east-1.amazonaws.com/kubeflow-ops-order-service:a1b2c3d
  ```
- ArgoCD sees this change in Git → deploys the new image → rolling update happens

**`containerPort: 8001`**
- Documents that the container listens on port 8001
- `name: http` — gives this port a name. Other places in the file refer to `port: http` instead of `port: 8001` — more readable and less error-prone

---

### Deployment Block 6 — Environment Variables (Lines 53–74)

```yaml
          env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: db-credentials
                  key: url

            - name: SQS_QUEUE_URL
              valueFrom:
                configMapKeyRef:
                  name: app-config
                  key: sqs-queue-url

            - name: USER_SERVICE_URL
              value: "http://user-service.kubeflow-ops.svc.cluster.local:8002"

            - name: AWS_REGION
              valueFrom:
                configMapKeyRef:
                  name: app-config
                  key: aws-region

            - name: OTLP_ENDPOINT
              value: "tempo.observability.svc.cluster.local:4317"
```

**3 ways to set env vars in Kubernetes:**

**Method 1 — Direct value:**
```yaml
- name: USER_SERVICE_URL
  value: "http://user-service.kubeflow-ops.svc.cluster.local:8002"
```
- Hardcoded string — fine for values that are the same everywhere
- The full Kubernetes DNS name: `[service-name].[namespace].svc.cluster.local:[port]`
- This is how `order-service` calls `user-service` inside the cluster — by DNS name, not IP (pod IPs change on restart)

**Method 2 — From ConfigMap:**
```yaml
- name: SQS_QUEUE_URL
  valueFrom:
    configMapKeyRef:
      name: app-config      ← the ConfigMap name
      key: sqs-queue-url    ← the key inside that ConfigMap
```
- Pulls from the `app-config` ConfigMap we saw in File 3
- If you update the ConfigMap value, pods on next restart get the new value

**Method 3 — From Secret:**
```yaml
- name: DATABASE_URL
  valueFrom:
    secretKeyRef:
      name: db-credentials  ← a Kubernetes Secret object
      key: url              ← the key inside that Secret
```
- `db-credentials` is a Kubernetes Secret that the **External Secrets Operator** creates automatically by reading from AWS Secrets Manager
- The actual database URL (with password) never appears in Git
- Flow: `AWS Secrets Manager` → `External Secrets Operator` → `Kubernetes Secret` → `Pod env var`

**`OTLP_ENDPOINT`:**
```yaml
value: "tempo.observability.svc.cluster.local:4317"
```
- Points to Grafana Tempo running in the `observability` namespace
- This is how the order-service sends distributed traces — we saw `OTLPSpanExporter` in the app code
- In docker-compose it was set to `""` (disabled). In Kubernetes, Tempo is running so we enable it

---

### Deployment Block 7 — Resources (Lines 76–85)

```yaml
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 256Mi
```

**`requests:` — the minimum the scheduler guarantees**

When Kubernetes schedules a pod, it looks for a node with at least this much free capacity:
- `cpu: 100m` → 100 millicores = 0.1 CPU cores
- `memory: 128Mi` → 128 Mebibytes RAM

The pod is **guaranteed** to always have at least this much. Other pods can't steal it.

**`limits:` — the maximum it's allowed to use**

| Resource | If exceeded |
|---|---|
| `cpu: 500m` | Container is **throttled** (slowed down, not killed) |
| `memory: 256Mi` | Container is **OOM-killed** (killed immediately, restarted) |

**Why set both?**

Without `requests`: The scheduler places pods randomly — some nodes overflow, others sit idle.

Without `limits`: One buggy pod (memory leak) eats all RAM on a node, killing every other pod on that node (noisy neighbor problem).

**Unit conversions:**
```
CPU:    1000m = 1 CPU core    100m = 10% of one core
Memory: 1Mi = 1 Mebibyte      128Mi ≈ 134 MB
```

---

### Deployment Block 8 — Health Probes (Lines 87–118)

```yaml
          startupProbe:
            httpGet:
              path: /healthz
              port: http
            initialDelaySeconds: 5
            periodSeconds: 5
            failureThreshold: 30

          livenessProbe:
            httpGet:
              path: /healthz
              port: http
            periodSeconds: 15
            timeoutSeconds: 5
            failureThreshold: 3

          readinessProbe:
            httpGet:
              path: /readyz
              port: http
            periodSeconds: 10
            timeoutSeconds: 5
            failureThreshold: 3
```

Three probes, three different purposes:

**`startupProbe` — "Is the app done starting up?"**

During startup, your app is importing modules, creating DB tables, starting background threads. This takes time — maybe 5–30 seconds.

The startupProbe keeps checking `/healthz` every 5 seconds. Until it passes, **liveness and readiness probes don't run**. This prevents Kubernetes from killing a slow-starting pod as "unresponsive."

```
Max startup time = failureThreshold × periodSeconds = 30 × 5 = 150 seconds
```

If the app hasn't started in 150 seconds → definitely broken → Kubernetes kills it and restarts.

**`livenessProbe` — "Is the process still alive and not deadlocked?"**

Once started, Kubernetes checks `/healthz` every 15 seconds. The app returns `{"status": "alive"}` immediately — it's a trivial check, just proving the process is responding.

If it fails 3 consecutive times (45 seconds of silence) → Kubernetes **restarts the container**. This handles:
- Process crashed silently
- Process deadlocked (stuck in infinite loop)
- Out-of-memory kill (Docker kills it, K8s restarts it)

**`readinessProbe` — "Is this pod ready to serve traffic?"**

Checks `/readyz` every 10 seconds. The order-service's `/readyz` actually queries the database:
```python
db.execute(text("SELECT 1"))
```
If the DB connection is broken, it returns 503 → pod fails readiness.

**When readiness fails:**
- Kubernetes **removes this pod from the Service's endpoint list**
- New requests go to the other healthy pod
- The unhealthy pod is NOT restarted — just taken out of rotation
- When DB connection recovers → `/readyz` passes → pod comes back into rotation

| Probe | Path | Fail action |
|---|---|---|
| `startupProbe` | `/healthz` | Kill + restart (during startup only) |
| `livenessProbe` | `/healthz` | Kill + restart |
| `readinessProbe` | `/readyz` | Remove from Service rotation (no restart) |

---

### Deployment Block 9 — Pod Anti-Affinity (Lines 120–135)

```yaml
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
                        - order-service
                topologyKey: kubernetes.io/hostname
```

**What problem does this solve?**

Without this, Kubernetes might place both `replicas: 2` pods on the **same node**. If that node dies, both pods die → service is down.

Anti-affinity says: **"Try not to place pods with `app: order-service` on the same node."**

**Line by line:**

**`podAntiAffinity`** — repulsion rule. The opposite is `podAffinity` (attract pods together).

**`preferredDuringSchedulingIgnoredDuringExecution`**
- `preferred` = soft rule. Kubernetes **tries** to spread pods but won't fail if it can't (e.g., only 1 node available)
- The alternative `requiredDuringSchedulingIgnoredDuringExecution` is a hard rule — pod stays `Pending` forever if it can't be satisfied. Too strict for dev.

**`weight: 100`**
- Score for following this rule (1–100)
- `100` = maximum preference. Scheduler strongly prefers spreading these pods.

**`labelSelector.matchExpressions:`**
```yaml
- key: app
  operator: In
  values:
    - order-service
```
"Find other pods that have label `app` with value `order-service`" — i.e., find other copies of myself.

**`topologyKey: kubernetes.io/hostname`**
- The "dimension" to spread across
- `kubernetes.io/hostname` = spread across different **nodes** (each node has a unique hostname)
- Other options: `topology.kubernetes.io/zone` = spread across different AWS AZs

**Result:**
```
Node 1: order-service-pod-1   ✅
Node 2: order-service-pod-2   ✅ (spread across nodes)
vs
Node 1: order-service-pod-1   ❌
Node 1: order-service-pod-2   ❌ (both on same node — dies together)
```

---

## 📄 File 6 — [service.yaml](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/gitops/apps/order-service/base/service.yaml:0:0-0:0)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: order-service
  namespace: kubeflow-ops
  labels:
    app: order-service
spec:
  type: ClusterIP
  selector:
    app: order-service
  ports:
    - name: http
      port: 8001
      targetPort: http
      protocol: TCP
```

### What is a Service?

Pods are **ephemeral** — they die and get new IP addresses constantly. A **Service** gives you a **stable DNS name and IP** that never changes, regardless of how many pods are behind it or their IPs.

```
user-service wants to call order-service:
  1. DNS lookup: "order-service.kubeflow-ops.svc.cluster.local" → 10.100.x.x (stable ClusterIP)
  2. kube-proxy intercepts: routes to one of the healthy pods behind it
  3. Pod IPs can change all day — the Service IP never does
```

---

**Line by line:**

**`type: ClusterIP`**
- The Service is only accessible **inside the cluster**
- External traffic can't reach it directly — that goes through the Ingress
- Other service types:
  - `NodePort`: exposes on each node's IP (for external access, not production-grade)
  - `LoadBalancer`: creates an AWS ELB per service (expensive, too many ELBs)
  - `ClusterIP`: internal only, use with Ingress ← correct choice

**`selector: app: order-service`**
- The Service finds pods using this label selector
- Matches the Deployment's pod template labels: `app: order-service`
- Kubernetes continuously watches for pods with this label — as pods come and go (restarts, scaling), the Service automatically updates its list

**`ports:`**
```yaml
- name: http
  port: 8001        ← the port clients call (on the Service)
  targetPort: http  ← the port the pod actually listens on
  protocol: TCP
```

- `port: 8001` — what other services call: `http://order-service:8001`
- `targetPort: http` — refers to the container's named port `http` (which is `8001` from the Deployment)
- They're the same number here, but they can differ. Example: Service on port 80, pod on port 8080.

---

## 📄 File 7 — [hpa.yaml](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/gitops/apps/order-service/base/hpa.yaml:0:0-0:0)

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: order-service-hpa
  namespace: kubeflow-ops
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: order-service
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Pods
          value: 1
          periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
        - type: Pods
          value: 4
          periodSeconds: 60
```

### What is an HPA?

**Horizontal Pod Autoscaler** = automatic scaling. Every minute, it checks CPU/memory usage across all pods and decides whether to add or remove pods.

"Horizontal" = add/remove **more copies** of the same pod. The opposite "Vertical" = give the same pod more CPU/RAM.

---

**Line by line:**

**`apiVersion: autoscaling/v2`**
- `v2` supports multiple metrics (CPU + memory + custom). The older `v1` only supports CPU.

**`scaleTargetRef:`**
```yaml
scaleTargetRef:
  apiVersion: apps/v1
  kind: Deployment
  name: order-service
```
Tells the HPA "control this specific Deployment." The HPA **overrides** the `replicas: 2` in the Deployment dynamically. The Deployment's `replicas` field then becomes just the initial value at creation time.

**`minReplicas: 2`**
- Never go below 2 pods — even at zero traffic
- Why not 1? If you have 1 pod and it restarts for any reason (deploy, crash, node maintenance), you have 0 pods serving traffic for a few seconds = downtime

**`maxReplicas: 10`**
- Never exceed 10 pods — puts a ceiling on cost
- Even during a massive traffic spike, you won't accidentally spin up 500 pods and bankrupt yourself

**`metrics:` — 2 triggers for scaling:**

**CPU metric:**
```yaml
name: cpu
target:
  type: Utilization
  averageUtilization: 70
```
- When **average CPU across all pods exceeds 70%** of their `requests.cpu` (100m each) → scale up
- At 70% it can still handle bursts. At 100% everything is at capacity and response times degrade.

**Memory metric:**
```yaml
name: memory
target:
  type: Utilization
  averageUtilization: 80
```
- When **average memory across all pods exceeds 80%** of their `requests.memory` (128Mi each) → scale up
- Unlike CPU, memory can't be throttled — it OOM-kills. Scaling at 80% prevents hitting 100%.

**`behavior:` — controls the rate of scaling:**

**`scaleDown:`**
```yaml
stabilizationWindowSeconds: 300   # Look back 5 minutes before scaling down
policies:
  - type: Pods
    value: 1
    periodSeconds: 60             # Remove max 1 pod per minute
```

Without `scaleDown` behavior, HPA would aggressively remove pods the moment CPU drops — then traffic spikes again → scale up → traffic drops → scale down → **flapping** (constant thrashing).

`stabilizationWindowSeconds: 300` = look at the last 5 minutes of metrics. Only scale down if CPU has been low for the **entire** 5 minutes. Prevents flapping.

`value: 1, periodSeconds: 60` = remove at most 1 pod per minute. At this rate, going from 10 → 2 pods takes 8 minutes minimum — safe and gradual.

**`scaleUp:`**
```yaml
stabilizationWindowSeconds: 60   # Only 1 minute lookback before scaling up
policies:
  - type: Pods
    value: 4
    periodSeconds: 60            # Add up to 4 pods per minute
```

Scale up is **fast** on purpose — traffic spikes need immediate response. `60s` lookback means if CPU is high for 1 minute, start adding pods. Up to 4 per minute so a burst can go from 2 → 10 pods in 2 minutes.

---

## 📄 File 8 — [kustomization.yaml](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/gitops/apps/order-service/base/kustomization.yaml:0:0-0:0)

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml
  - hpa.yaml

commonLabels:
  app.kubernetes.io/name: order-service
  app.kubernetes.io/part-of: kubeflow-ops
```

### What is Kustomize?

**New Concept.** Kustomize is a tool built into `kubectl` that lets you manage Kubernetes YAML files without templating engines.

[kustomization.yaml](cci:7://file:///c:/PROJECTS/PROJECT_Devsecops_Pipeline/gitops/apps/order-service/base/kustomization.yaml:0:0-0:0) is the **index file** for a Kustomize directory. It lists which YAML files belong together. When ArgoCD points at `gitops/apps/order-service/base/`, it reads this file to know which manifests to apply.

**`resources:`** — the list of files in this directory group
```yaml
resources:
  - deployment.yaml
  - service.yaml
  - hpa.yaml
```
`kubectl apply -k ./` applies all 3 files in the right order.

**`commonLabels:`**
```yaml
commonLabels:
  app.kubernetes.io/name: order-service
  app.kubernetes.io/part-of: kubeflow-ops
```
Kustomize automatically **adds these labels to every resource** in the `resources:` list. Without this you'd have to add these labels manually in every file — DRY principle.

---

## ✅ Part 1 Complete Summary

```
gitops/apps/common/ — Applied once, shared by all services:
├── namespace.yaml        → Creates "kubeflow-ops" namespace
├── service-account.yaml  → IRSA identity + AWS IAM role link
├── configmap.yaml        → Non-secret config (SQS URL, Redis URL, region)
└── ingress.yaml          → Routes /api/orders, /api/users, /api/notifications
                            with path rewriting + rate limiting (50 req/s)

gitops/apps/order-service/base/ — Per-service manifests:
├── deployment.yaml → 2 replicas, ECR image, env vars from ConfigMap+Secret,
│                     3 health probes, resource limits, anti-affinity
├── service.yaml    → ClusterIP, stable DNS name, selects pods by label
├── hpa.yaml        → Auto-scale 2–10 pods on CPU 70% / Memory 80%
│                     Slow scale-down (1 pod/min), Fast scale-up (4 pods/min)
└── kustomization.yaml → Groups the 3 files above for ArgoCD/kubectl
```

---

Ready for **Part 2**? That covers the `user-service` and `notification-service` manifests, then the `gitops/platform/` folder (ArgoCD, External Secrets, Prometheus, Kyverno). Say **"continue"**! 🚀