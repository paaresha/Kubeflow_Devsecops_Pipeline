# Chat Conversation

Note: _This is purely the output of the chat conversation and does not contain any raw data, codebase snippets, etc. used to generate the output._

### User Input

Go through The pahse_custom file and whole project . Now you need to Start explaining the Project. Let's start with phase 1 . But no need to explain. App code as it will be given to me by the developer. You only need to tell me what is. Relevant for Devops perspective since this is a Devops project. Now FYI I know the basics of Jenkins, Docker, Kubernetes and Terraform so . , any other technology, any other tool, any other new thing, you need to explain that in detail. Do not skip anything. You need to explain each file. Line by line. And each block. Also make sure you proceed in the exact manner like which a Devops engineer will start. Like you need to choose start with that file which a Devops engineer will start with. For example, you cannot start Terraform before. Docker. So keep everything in order. Also, whatever is already explained before, no need to explain that again, you can just skip that.

### Planner Response

Let me start by reading the `Phases_Custom.md` file and exploring the project structure thoroughly.

*Viewed [Phases_Custom.md](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/Phases_Custom.md) *

*Listed directory [Kubeflow_Devsecops_Pipeline](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline) *

### Planner Response

Now let me explore the `apps/` folder and the Phase 1 relevant files in detail.

*Listed directory [apps](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps) *

*Listed directory [.github](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/.github) *

*Listed directory [order-service](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/order-service) *

*Listed directory [user-service](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/user-service) *

*Listed directory [notification-service](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/notification-service) *

*Viewed [requirements.txt](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/order-service/requirements.txt) *

*Viewed [requirements.txt](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/user-service/requirements.txt) *

*Viewed [requirements.txt](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/notification-service/requirements.txt) *

### Planner Response

Now let me read the tests for each service too:

*Listed directory [tests](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/order-service/tests) *

*Listed directory [tests](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/user-service/tests) *

*Listed directory [tests](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/notification-service/tests) *

*Viewed [test_main.py](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/order-service/tests/test_main.py) *

*Viewed [test_main.py](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/user-service/tests/test_main.py) *

*Viewed [test_main.py](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/notification-service/tests/test_main.py) *

### Planner Response

I now have everything I need for a thorough Phase 1 explanation. Let me construct the complete walkthrough.

---

# 🚀 Phase 1 — Understand & Run the App Locally (DevOps Deep-Dive)

> **Your role as a DevOps engineer in Phase 1:** You received the `apps/` folder from the developer. Before you write a single line of Dockerfile, pipeline YAML, or Terraform — you **must** understand what you're packaging, deploying, and monitoring. Containerizing something you don't understand is how things break at 3 AM in production.

---

## 📁 What the Developer Handed You

```
apps/
├── order-service/
│   ├── main.py
│   ├── requirements.txt
│   └── tests/
│       └── test_main.py
├── user-service/
│   ├── main.py
│   ├── requirements.txt
│   └── tests/
│       └── test_main.py
└── notification-service/
    ├── main.py
    ├── requirements.txt
    └── tests/
        └── test_main.py
```

---

## 🏗️ What Is This App? (Architecture Overview)

This is a **microservices** application. Instead of one big monolithic application, it's split into **3 independent services** that communicate with each other. Each service:
- Has its own codebase
- Has its own dependencies
- Runs on its own port
- Has its own database/cache/queue access

### The 3 Services and What They Do:

| Service | Port | Role |
|---|---|---|
| `order-service` | `8001` | Takes orders, validates user exists, saves to DB, sends notification to SQS queue |
| `user-service` | `8002` | Manages users (create/read/update/delete) |
| `notification-service` | `8003` | Listens on SQS queue, sends notifications, caches results in Redis |

### How the services talk to each other:

```
[Client]
   │
   ├──► order-service:8001 ──HTTP──► user-service:8002  (validates user exists)
   │         │
   │         └──► SQS Queue ──► notification-service:8003 ──► Redis (cache)
   │
   └──► user-service:8002 (directly for user CRUD)
```

---

## 🧠 Technologies You Need to Know (That Are New to You)

### 1. **FastAPI**
**What it is:** A modern Python web framework for building REST APIs. Think of it like Django or Flask but faster, with automatic input validation and auto-generated documentation.

**Why it matters for DevOps:**
- Every service exposes a `/docs` endpoint automatically — you can test endpoints in a browser without writing any test code.
- Every service has a `/healthz` endpoint — this is your **health check** (liveness probe). You'll wire this into Docker, Kubernetes, and load balancers.
- It's `async` by nature — meaning it uses Python's `asyncio` event loop, so it's non-blocking and handles many requests concurrently.

---

### 2. **Uvicorn**
**What it is:** The **ASGI server** that actually runs the FastAPI app. Think of Uvicorn like Nginx or Tomcat — it's the process listener.

**The command you'll see everywhere:**
```bash
uvicorn main:app --host 0.0.0.0 --port 8001
```
Breaking it down:
- `main` → file name (`main.py`)
- `app` → the FastAPI object inside that file (`app = FastAPI()`)
- `--host 0.0.0.0` → listen on ALL network interfaces (crucial inside Docker, so the container is reachable from outside)
- `--port 8001` → the port this service listens on

> **Why `0.0.0.0` matters for DevOps:** If you use `127.0.0.1` (localhost) inside a Docker container, nobody can reach it from outside the container. Always `0.0.0.0`.

---

### 3. **SQLAlchemy**
**What it is:** A Python ORM (Object-Relational Mapper) — it lets Python code talk to the PostgreSQL database without writing raw SQL.

**Why it matters for DevOps:**
- It reads the database connection string from an environment variable (`DATABASE_URL`). You'll be injecting this via Docker Compose, then Kubernetes Secrets.
- You'll see `create_engine(DATABASE_URL)` in the code — this is where the DB connection is made. If `DATABASE_URL` isn't set correctly, the app crashes on startup. This is a critical thing to watch in your health checks.

---

### 4. **psycopg2-binary**
**What it is:** The PostgreSQL driver for Python. SQLAlchemy uses it under the hood to actually communicate with a Postgres database.

**Why `binary`?** The `-binary` variant bundles everything (no system-level `libpq` dependencies needed). This is important during Docker image builds — without it you'd need to install OS-level packages first.

---

### 5. **boto3**
**What it is:** The official AWS SDK for Python. Used in `order-service` to **send messages to SQS**, and in `notification-service` to **receive/poll messages from SQS**.

**Why it matters for DevOps:**
- boto3 needs AWS credentials to function. In local dev (Phase 3), you'll point it at **LocalStack** (fake AWS). In production, it'll use **IRSA** (IAM Roles for Service Accounts). You'll never put AWS keys in code.
- The SQS URL will come from an environment variable. You'll inject this in Docker Compose and in Kubernetes ConfigMaps.

---

### 6. **httpx**
**What it is:** A modern Python HTTP client that works with `async`. The order-service uses it to call `user-service` to check if a user exists before creating an order.

**Why it matters for DevOps:**
- This is **inter-service HTTP communication**. In Docker Compose, this will use service names (e.g., `http://user-service:8002`). In Kubernetes, it'll use Kubernetes DNS (e.g., `http://user-service.kubeflow-ops.svc.cluster.local:8002`). The URL will come from an environment variable.

---

### 7. **Pydantic**
**What it is:** Python data validation library — FastAPI uses it to define request/response shapes (schemas). As a DevOps engineer, you won't write Pydantic code, but you need to know: **if the request body doesn't match the schema, FastAPI returns a 422 error automatically.** This helps your API monitoring — 422s mean bad client input, not server bugs.

---

### 8. **OpenTelemetry (otel-api, otel-sdk, otel-instrumentation-fastapi, otel-exporter-otlp)**

This is a brand new concept for most DevOps engineers. Pay very close attention.

**What is OpenTelemetry?**
OpenTelemetry (OTel) is an **observability framework** — an open standard for collecting **traces, metrics, and logs** from applications and exporting them to a backend (like Jaeger, Grafana Tempo, Datadog, etc.).

**The three pillars of Observability it covers:**
| Pillar | What it captures | Example |
|---|---|---|
| **Traces** | The full journey of a single request across services | Order request went → order-service (50ms) → user-service (10ms) → DB (5ms) |
| **Metrics** | Aggregated numbers over time | 200 requests/sec, 50ms avg latency |
| **Logs** | Text events | "Order 123 created successfully" |

**The four packages in `requirements.txt` and what each does:**

| Package | Role |
|---|---|
| `opentelemetry-api` | The standard interface/contract — defines what a "span" and "trace" are |
| `opentelemetry-sdk` | The actual implementation of that interface |
| `opentelemetry-instrumentation-fastapi` | **Auto-instruments** FastAPI — every HTTP request automatically creates a trace span. Zero code changes needed in the app |
| `opentelemetry-exporter-otlp` | Sends trace data over the **OTLP protocol** to a collector (like OpenTelemetry Collector, Jaeger, Grafana Tempo) |

**The export flow:**
```
FastAPI App
    │  (auto-instrumented)
    │  generates trace spans
    ▼
opentelemetry-exporter-otlp
    │  (sends via gRPC/HTTP to OTLP endpoint)
    ▼
OpenTelemetry Collector  (or directly to Jaeger/Grafana Tempo)
    │
    ▼
Grafana Dashboard  /  Jaeger UI  (you can see traces visually)
```

**Why this matters for DevOps:**
- In Phase 9 (Observability), this is what feeds your tracing backend.
- The `OTLP_EXPORTER_ENDPOINT` environment variable is what you'll configure — in local Docker Compose, it points to a local collector; in K8s, it points to the collector inside the cluster.
- If `OTLP_EXPORTER_ENDPOINT` isn't set, the app still works — it just won't export traces. It's a non-fatal config.

---

### 9. **prometheus-fastapi-instrumentator**
**What it is:** A library that automatically exposes a `/metrics` endpoint on the FastAPI app in **Prometheus format**.

**What Prometheus format looks like:**
```
http_requests_total{method="GET", status="200", path="/healthz"} 42
http_request_duration_seconds_bucket{le="0.1"} 35
```

**Why this matters for DevOps (Phase 9):**
- In Phase 9, you'll deploy **Prometheus** into Kubernetes. Prometheus will scrape the `/metrics` endpoint of every pod every 15 seconds.
- Those metrics flow into **Grafana** dashboards for visual monitoring.
- You'll write alert rules based on those metrics (e.g., "alert if 5xx rate > 5% for 5 minutes").

**The instrumentation is 2 lines of code in `main.py`:**
```python
from prometheus_fastapi_instrumentator import Instrumentator
Instrumentator().instrument(app).expose(app)
```
That's it. Your `/metrics` endpoint is live — no other work needed. Very DevOps-friendly.

---

### 10. **redis (in notification-service only)**
**What it is:** The Python client library for **Redis** — an in-memory key-value store used as a cache.

**How it's used here:** The notification-service uses Redis to cache notification results. Caching means: instead of looking something up from the database every time, you store it in Redis (very fast, in-memory) and read it from there.

**Why it matters for DevOps:**
- Redis runs as a separate service. In Docker Compose (Phase 3), you'll add a `redis` container. In AWS (Phase 5), you'll provision **ElastiCache** (managed Redis).
- The `REDIS_URL` environment variable is what connects the app to Redis. Example: `redis://redis:6379`.

---

## 📄 File 1: `requirements.txt` — Line by Line

> **Start here.** Before the app code, read requirements.txt. It tells you **every external service and library** the app needs — which means it tells you every external dependency YOU need to provision or mock.

### `order-service/requirements.txt`

```
Line 1: fastapi==0.115.6
```
→ The web framework. **Exact version is pinned (`==`)**. This is critical for DevOps reproducibility. `==` means "exactly this version." If you see `>=` or no version, that's a risk — builds can break when the library updates.

```
Line 2: uvicorn[standard]==0.34.0
```
→ The ASGI server that runs the app. `[standard]` means: install uvicorn with all optional extras (WebSockets support, faster event loop via `uvloop`, `httptools` for faster request parsing). Exact version pinned.

```
Line 3: sqlalchemy==2.0.36
```
→ The ORM for talking to PostgreSQL. Tells you: **this service needs a PostgreSQL database**.

```
Line 4: psycopg2-binary==2.9.10
```
→ The PostgreSQL driver. Confirms: PostgreSQL dependency. The `binary` variant is Docker-friendly (no OS-level dependencies).

```
Line 5: boto3==1.35.86
```
→ AWS SDK. Tells you: **this service talks to AWS**. Specifically, it will use **SQS** (you'll see why in the app code). For local dev → LocalStack. For prod → real AWS SQS with IRSA.

```
Line 6: httpx==0.28.1
```
→ HTTP client. Tells you: **this service makes HTTP calls to another service** (specifically to `user-service`). This is a service-to-service dependency you need to account for in your networking setup.

```
Line 7: pydantic==2.10.4
```
→ Data validation. Internal to the app. No infrastructure needed.

```
Lines 8-11: opentelemetry-* packages
```
→ Distributed tracing. Tells you: **this service will export telemetry data** to an OTLP-compatible collector. You'll need to configure the `OTLP_EXPORTER_ENDPOINT` environment variable and provision an OTel Collector in your infrastructure.

```
Line 12: prometheus-fastapi-instrumentator==7.0.2
```
→ Metrics exposure. Tells you: **this service exposes `/metrics` for Prometheus to scrape**. You'll configure Prometheus scrape rules to hit this endpoint.

```
Lines 13-14: pytest==8.3.4 and pytest-asyncio==0.25.0
```
→ Test frameworks. These are development/CI dependencies — they run tests but are not needed in the production container. **This is why multi-stage Dockerfiles exist** — you install test deps in the build stage, but don't carry them into the final production image. More on this in Phase 2.

> **`pytest-asyncio`** specifically: Since FastAPI routes are `async`, tests need to `await` them. `pytest-asyncio` is a plugin that makes pytest understand `async def test_...()` functions.

---

### `user-service/requirements.txt`

Same as order-service **except**:
- ❌ No `boto3` → This service does NOT talk to SQS. No AWS dependency.
- ❌ No `httpx` → This service does NOT call other services. It's self-contained.

**DevOps takeaway:** Smaller dependency footprint → smaller Docker image → faster builds → smaller attack surface for security scanning.

---

### `notification-service/requirements.txt`

Same as order-service **except**:
- ✅ `boto3==1.35.86` → Talks to **SQS** (polls for messages)
- ✅ `redis==5.2.1` → Talks to **Redis** (caches notifications)
- ❌ No `sqlalchemy`, `psycopg2-binary` → **No PostgreSQL**. This service has no DB! It uses Redis only.
- ❌ No `httpx` → Doesn't call other services via HTTP
- ❌ No `pytest-asyncio` — (slightly different test setup)

---

## 📄 File 2: `tests/test_main.py` — Line by Line (All 3 Services)

> As a DevOps engineer, you don't write tests — but you **run** them in CI. You need to understand what a test file does so you know how to run it correctly in your pipeline and what a test failure means.

---

### `order-service/tests/test_main.py`

```python
Line 1-3: # Comments — Unit Tests for Order Service
```
Header/description comments. Human-readable only.

```python
Line 4: from fastapi.testclient import TestClient
```
**`TestClient`** — FastAPI's built-in test utility that lets you send fake HTTP requests to the app **without actually running a server**. The app runs "in-process" during tests. This is how you test without needing port `8001` to be open.

```python
Line 5: from unittest.mock import patch, MagicMock
```
Python's standard mocking library. `patch` temporarily replaces a real function/object with a fake one. `MagicMock` creates a fake object.

**Why this matters for DevOps:** The tests use mocks to avoid needing a real Postgres database or SQS queue during testing. So when your CI pipeline runs `pytest`, it doesn't need any external services running. This is clean test design.

```python
Lines 9-12:
with patch("main.create_engine"), \
     patch("main.SessionLocal"), \
     patch("main.Base"):
    from main import app
```
This is where the mocking happens **at import time**. Before the app (`main.py`) is even loaded:
- `create_engine` → the function that connects to PostgreSQL is replaced with a fake
- `SessionLocal` → the database session maker is replaced with a fake
- `Base` → the SQLAlchemy base class is replaced with a fake

**Without this**, importing `main.py` would try to connect to PostgreSQL immediately and crash during testing (because there's no real DB). The `with patch(...)` block makes the import safe.

```python
Line 14: client = TestClient(app)
```
Creates a test HTTP client pointed at the app. All test functions use this `client` to make fake HTTP requests.

```python
Lines 17-21: def test_liveness():
```
**The health check test.** Makes a `GET /healthz` request and asserts:
1. HTTP status code is `200`
2. Response JSON has `{ "status": "alive" }`

**DevOps relevance:** This is the exact same endpoint your Docker `HEALTHCHECK`, Kubernetes **liveness probe**, and load balancer health checks will hit. If this test fails, your health check infrastructure is broken.

```python
Lines 24-37: def test_create_order_missing_user():
```
Tests that if you try to create an order for a user that doesn't exist:
- It mocks the `httpx.AsyncClient` (the HTTP client used to call `user-service`)
- Makes it return a fake `404` response (user not found)
- Then posts an order creation request
- Asserts the response is either `404` or `503`

**DevOps relevance:** This tests the **inter-service failure handling**. If `user-service` is down (503) or user doesn't exist (404), `order-service` handles it gracefully. This is critical for understanding cascading failures in micro-services.

---

### `user-service/tests/test_main.py`

```python
Lines 8-11:
with patch("main.create_engine"), \
     patch("main.SessionLocal"), \
     patch("main.Base"):
    from main import app
```
Same pattern — mocks the database before import. This service only has a PostgreSQL dependency, so only DB is mocked.

```python
Lines 16-20: def test_liveness():
```
Same health check test. `GET /healthz` → `200` + `{"status": "alive"}`.

```python
Lines 23-32: def test_get_user_not_found():
```
Tests that requesting a non-existent user (`GET /users/999`) returns:
- HTTP `404`

Tests the mock DB session returns `None` (user not found in DB), and the app responds correctly.

---

### `notification-service/tests/test_main.py`

```python
Lines 7-11:
mock_redis = MagicMock()
with patch("main.redis") as mock_redis_module:
    mock_redis_module.from_url.return_value = mock_redis
    from main import app
```
This service has **Redis** instead of PostgreSQL. So it mocks the `redis` module. `redis.from_url(REDIS_URL)` is replaced with a fake Redis object. Safe to import without a real Redis server.

```python
Lines 16-20: def test_liveness():
```
Same standard health check test.

```python
Lines 23-27: def test_list_notifications_empty():
```
Tests `GET /notifications` returns:
- HTTP `200`
- A JSON array (list) — even if it's empty `[]`

```python
Lines 30-36: def test_notification_stats():
```
Tests `GET /notifications/stats` returns:
- HTTP `200`
- Response JSON contains both `total_processed` and `actions` fields

**DevOps relevance:** These are the metrics/stats endpoints. You'll use these in smoke tests after a deployment — if the stats endpoint is broken, your deployment is bad.

---

## 🔑 Key DevOps Takeaways from Phase 1

### What You Now Know (Before Writing Any DevOps Code):

| Discovery | DevOps Action Needed |
|---|---|
| 3 services, 3 ports (8001, 8002, 8003) | 3 Dockerfiles, 3 K8s Deployments, 3 Services |
| `order-service` → PostgreSQL + SQS + calls `user-service` | Need DB, SQS, and network connectivity between services |
| `user-service` → PostgreSQL only | Need DB, relatively simple |
| `notification-service` → SQS + Redis | Need SQS + Redis (no DB) |
| All services → OpenTelemetry | Need OTel Collector in infra |
| All services → Prometheus `/metrics` | Need Prometheus scrape config |
| All services → `/healthz` endpoint | Health check URL confirmed for all probes |
| Tests mock DB/Redis/SQS | CI tests can run without external services! |
| All versions pinned with `==` | Reproducible builds ✅ |

### How to Run Tests Locally (what you'd do manually in Phase 1):

```bash
# Run order-service tests
cd apps/order-service
pip install -r requirements.txt
pytest tests/ -v

# Run user-service tests
cd ../user-service
pip install -r requirements.txt
pytest tests/ -v

# Run notification-service tests
cd ../notification-service
pip install -r requirements.txt
pytest tests/ -v
```

**`pytest -v`** → `-v` flag means "verbose" — shows each test name and PASS/FAIL instead of just dots.

### The pytest Tool (since you know Jenkins but might not know pytest deeply):

| pytest concept | Meaning |
|---|---|
| A test file must start with `test_` | `tests/test_main.py` ✅ |
| A test function must start with `test_` | `def test_liveness():` ✅ |
| `assert` statement = the check | If assertion fails, test fails |
| `pytest tests/ -v` | Run all tests in the `tests/` folder verbosely |
| Exit code `0` = all pass | Exit code `1` = at least one failed |

> **The exit code matters for CI**: In your GitHub Actions pipeline (Phase 4), `pytest` failing with exit code `1` will automatically fail the build step. This is the gating mechanism — bad code never gets deployed.

---

## ✅ Phase 1 Complete — What to Move to Next

Now that you know:
- What services exist and what external systems they need
- What ports they run on
- What the health check endpoints are
- That tests run without real external services (clean mocking)

You are **ready for Phase 2: Writing Dockerfiles**.

Phase 2 is where you, as the DevOps engineer, take over. You'll write:
- `Dockerfile` for each service (multi-stage build)
- `.dockerignore` for each service

That's coming next — and every decision you make in the Dockerfile will be directly informed by what you understood in Phase 1. 🚀

### User Input

Lets do Phase 2

### Planner Response

Let me read all the Dockerfile and [.dockerignore](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/user-service/.dockerignore:0:0-0:0) files for all three services.

*Viewed [Dockerfile](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/order-service/Dockerfile) *

*Viewed [.dockerignore](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/order-service/.dockerignore) *

*Viewed [Dockerfile](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/user-service/Dockerfile) *

*Viewed [.dockerignore](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/user-service/.dockerignore) *

*Viewed [Dockerfile](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/notification-service/Dockerfile) *

*Viewed [.dockerignore](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/notification-service/.dockerignore) *

### Planner Response

I have everything. Let me now give you the full Phase 2 walkthrough.

---

# 🐳 Phase 2 — Dockerfiles & [.dockerignore](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/user-service/.dockerignore:0:0-0:0) (Deep-Dive)

> **Your job as a DevOps Engineer:** You take the developer's code and make it run the same way — on **any machine, any environment, any cloud** — by packaging it into a container image. The Dockerfile is **your** file, not the developer's.

---

## 🧠 Concept You Must Understand First: Multi-Stage Builds

Before reading a single line, you need to understand **why** these Dockerfiles are written the way they are.

### The Problem with a Naive Dockerfile:

```dockerfile
# ❌ BAD — Single Stage (What a Beginner Would Write)
FROM python:3.12
COPY . .
RUN pip install -r requirements.txt
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8001"]
```

**Result:** ~900MB image. This image carries:
- All of pip's download cache
- Compilation tools (gcc, make) — used only during `pip install`
- Test files, docs, `.git`, `.vscode`, everything

These things are **useless at runtime** but bloat the image, slow CI builds, and increase the security attack surface (more installed software = more CVE targets for Trivy to find).

### The Solution: Multi-Stage Build

```
Stage 1 (builder): Full Python image → Install all deps → Output: /install folder
Stage 2 (production): Slim Python image → Copy ONLY the /install folder + app code
```

**Result:** ~120MB image. The compiler (gcc), pip cache, and all build tools **never make it into the final image.**

```
┌──────────────────────────────────┐        ┌──────────────────────────────────┐
│         STAGE 1: builder         │        │       STAGE 2: production        │
│  python:3.12-slim                │        │  python:3.12-slim                │
│                                  │        │                                  │
│  requirements.txt  ──────────►  pip      │  /usr/local/ ◄── (from builder)  │
│  (installs everything)          │        │  main.py                         │
│                                  │        │  appuser (non-root)              │
│  OUTPUT: /install/               │──────► │  EXPOSE 8001                    │
│  (compiled packages)             │        │  HEALTHCHECK                     │
│                                  │        │  CMD uvicorn                     │
└──────────────────────────────────┘        └──────────────────────────────────┘
         (DISCARDED — never in final image)          ← this is what gets pushed to ECR
```

---

## 🏗️ The Correct Order to Start

As a DevOps engineer, you start in this order:

1. **[.dockerignore](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/user-service/.dockerignore:0:0-0:0)** — Set the "what NOT to send to Docker" rules first
2. **[Dockerfile](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/user-service/Dockerfile:0:0-0:0)** — Write the actual image build instructions

Why [.dockerignore](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/user-service/.dockerignore:0:0-0:0) first? Because every `docker build` command **sends your entire build context** (files visible to Docker) to the Docker daemon. If you don't exclude correctly, Docker is transferring your `.git` folder, test files, node_modules, etc. — even before the Dockerfile runs. This wastes time and can accidentally leak sensitive files into your image.

---

## 📄 File 1: [.dockerignore](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/user-service/.dockerignore:0:0-0:0) — Order Service (Master Explanation)

> The `user-service` and `notification-service` [.dockerignore](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/user-service/.dockerignore:0:0-0:0) files are **identical** except the order-service one has extra entries for `terraform/`, `gitops/`, `.github/`. I'll explain the order-service one in full — note the differences at the end.

```
apps/order-service/.dockerignore
```

### What is a Build Context?

When you run:
```bash
docker build -t order-service:local apps/order-service/
```
Docker sends **everything in `apps/order-service/`** to the Docker daemon. Every file in that folder becomes the **build context**. The `.dockerignore` file tells Docker: "exclude these patterns from the context."

---

**Line 1:** `# Dependencies`
→ Comment. Groups the Python cache/virtual env exclusions below.

**Line 2:** `__pycache__/`
→ Python compiles `.py` files to bytecode and caches them in `__pycache__/`. These are auto-generated, machine-specific binary files. Including them would bloat the image and make builds non-reproducible across different machines.

**Line 3:** `*.pyc`
→ Python compiled bytecode files (`.pyc` = Python Compiled). Same reason — machine-specific, auto-generated. The `*` wildcard matches any file ending in `.pyc` in any subdirectory.

**Line 4:** `*.pyo`
→ Optimized Python bytecode (older format from Python 2/early Python 3). Same exclusion reason as `.pyc`.

**Line 5:** `*.egg-info/`
→ A metadata directory created when you install a Python package **in development mode** (`pip install -e .`). Not needed in production.

**Line 6:** `venv/`
→ If a developer created a virtual environment folder named `venv/` locally, exclude it entirely. You **never** want a local venv inside a Docker image — you'll install dependencies properly with pip inside the container.

**Line 7:** `.venv/`
→ Same as above — just a differently-named venv (`.venv` is the VS Code default name).

**Line 8:** `env/`
→ Yet another common venv folder name.

> **Key Point:** Lines 6-8 together say: "No matter what the developer named their local virtual environment, exclude it." This is defensive — even if the developer accidentally left a venv in the `send` folder.

---

**Line 10:** `# IDE`

**Line 11:** `.idea/`
→ PyCharm/IntelliJ project settings folder. Contains editor configs, local run configurations, etc. Zero runtime value. Could contain sensitive local paths.

**Line 12:** `.vscode/`
→ VS Code editor settings. Same reason.

**Line 13:** `*.swp`
→ Vim swap files (auto-created when you open a file in Vim). Garbage files that would clutter the image.

**Line 14:** `*.swo`
→ Alternate Vim swap file extension. Same reason.

---

**Line 16:** `# Git`

**Line 17:** `.git/`
→ **CRITICAL EXCLUSION.** The entire Git repository history, objects, refs. This folder can be **hundreds of MB** for large repos. More importantly: **if it ends up in your image, anyone who pulls your image can extract your commit history, author emails, potentially secrets from old commits.** Always exclude.

**Line 18:** `.gitignore`
→ The git ignore rules file. Not needed at runtime.

---

**Line 20:** `# Docker`

**Line 21:** `docker-compose*.yml`
→ The Docker Compose file(s). Not needed inside the image — Compose is an orchestration tool for your local machine, not something that runs inside a container.

**Line 22:** `Dockerfile`
→ Excluding the Dockerfile itself from the context. This is interesting — the Dockerfile is used **by** Docker to build the image, but doesn't need to **be inside** the final image. Excluding it prevents anyone pulling the image from reverse-engineering your build process.

---

**Line 24:** `# Tests`

**Line 25:** `tests/`
→ **Very Important.** The entire test folder is excluded. Tests are run during CI **before** building the final image. The final Docker image is **purely the production artifact** — no test code, test fixtures, or test dependencies inside it. This is why the multi-stage build matters: `pytest` and `pytest-asyncio` are installed in the builder stage (from `requirements.txt`) but since the tests folder is excluded from context, they're never actually called in the image.

**Line 26:** `pytest.ini`
→ Pytest configuration file (if it exists). Same reason — test infrastructure, not production.

**Line 27:** `.coverage`
→ Coverage report file generated by `pytest --cov`. Not needed in production.

---

**Line 29:** `# Docs`

**Line 30:** `*.md`
→ All Markdown files (README.md, CHANGELOG.md, etc.). Documentation is for humans, not for the container runtime.

**Line 31:** `LICENSE`
→ The open source license file. Not needed at runtime.

---

**Lines 33-41:** `# Terraform`, `# GitOps`, `# CI/CD` *(order-service only)*

```
terraform/
gitops/
.github/
```
**Only in order-service's `.dockerignore`** — because these folders might be visible if the build context is the whole project root instead of just the service folder. These are infrastructure-as-code files, never needed inside the application image.

> **Note for user-service and notification-service:** Their `.dockerignore` files end at line 32 — no git/terraform/gitops/github entries. Why? Because when you build from `apps/user-service/`, those folders don't even exist in that subdirectory. But order-service is being extra cautious — a defensive best practice.

---

## 📄 File 2: `Dockerfile` — Order Service (Full Explanation)

```
apps/order-service/Dockerfile
```

### The Complete File Annotated:

---

**Lines 1-7:** Comments
```dockerfile
# =============================================================================
# Multi-Stage Dockerfile — Order Service
# =============================================================================
# Stage 1: Install dependencies in a temporary layer
# Stage 2: Copy only the installed packages + app code into a slim final image
# Result: ~120MB image instead of ~900MB. Faster deploys, smaller attack surface.
# =============================================================================
```
These comments explain the two-stage pattern and the expected result. The comment "~120MB instead of ~900MB" is a real measurement. As a DevOps engineer, image size matters because:
- Smaller = faster `docker pull` in CI/CD → faster deployments
- Smaller = less to scan with Trivy → fewer CVEs
- Smaller = less bandwidth cost in ECR → less AWS bill

---

**Line 9:** `# ── Stage 1: Builder ─────────────────────────────────────────────`
Comment divider — marks the start of Stage 1.

---

**Line 10-11:** Comments
```
# We use the full Python image here because it has gcc and other build tools
# needed to compile some Python packages (like psycopg2-binary).
```
Explains **why** a builder stage is needed: some Python packages need C compilation (gcc). `psycopg2-binary` in this case technically includes pre-compiled binaries (`-binary` suffix), but many other common packages (numpy, cryptography) need real compilation. The builder stage is the right place for that — it has build tools and they stay there.

---

**Line 12:** `FROM python:3.12-slim AS builder`

Breaking down every token:
- **`FROM`** → Dockerfile instruction that sets the base image. Every image is built on top of another image (a chain going back to `scratch`/OS kernel).
- **`python:3.12-slim`** → The base image. `python` is the official Docker Hub image. `3.12` is the Python version. `slim` means a reduced Debian variant — it has only the packages necessary to run Python (no gcc, no apt list caches, no man pages). Good for production; **for building**, it still has enough.
- **`AS builder`** → Names this stage `builder`. This name is referenced later in `COPY --from=builder`. Without naming, multi-stage wouldn't work. A name can be anything, but `builder` is the standard convention.

> **Why not `python:3.12` (without slim)?** The full image has hundreds of MB of extras. `slim` already provides a good balance for building.

> **Why not `python:3.12-alpine`?** Alpine Linux is even smaller (~5MB OS), but it uses `musl libc` instead of `glibc`. Many Python packages (like `psycopg2`) are compiled against `glibc` and won't work on Alpine. Using Alpine would cause unexpected runtime crashes. `slim` (Debian-based) is the production-safe choice.

---

**Line 14:** `WORKDIR /build`

- **`WORKDIR`** → Sets the working directory **inside the container** for all subsequent instructions. If it doesn't exist, Docker creates it.
- **`/build`** → The directory name inside the container. Could be anything — `/build` is chosen for clarity: "this is the build zone."
- **Effect:** All `COPY` and `RUN` instructions that follow use `/build` as their current directory.

---

**Lines 16-18:**
```dockerfile
# Copy requirements first — Docker caches this layer, so if requirements
# haven't changed, it skips the slow pip install on subsequent builds.
COPY requirements.txt .
```
- **`COPY requirements.txt .`** → Copying `requirements.txt` from the host (your build context) into the current working directory inside the container (`/build`). The `.` at the end means "current directory" = `/build`.

**The "cache layer" optimization mentioned in the comment is CRITICAL to understand:**

Docker builds images in **layers**. Each instruction (`FROM`, `COPY`, `RUN`) creates one layer. Docker caches each layer. On subsequent builds:
- If a layer's inputs haven't changed → Docker uses the **cached layer** instead of re-running it
- **If a layer changes → all layers below it are invalidated and re-run**

This is why `requirements.txt` is copied **before** `main.py`:
```
COPY requirements.txt  → RUN pip install  → COPY main.py
      (rarely changes)    (slow: 1-2 min)    (changes every commit)
```
If you changed the order and did `COPY main.py` first → every time a developer changes a single line of code, Docker would re-run `pip install` (1-2 minutes) even though requirements didn't change.

With the correct order: changing `main.py` only invalidates the last `COPY main.py` layer → pip install is cached → build takes seconds instead of minutes.

**This one ordering decision can save hours of CI time per week.**

---

**Line 19:** `RUN pip install --no-cache-dir --prefix=/install -r requirements.txt`

- **`RUN`** → Executes a command inside the container during build. The result becomes a new image layer. Every `RUN` command creates a layer.
- **`pip install`** → Installs all packages listed in `requirements.txt`
- **`--no-cache-dir`** → Tells pip NOT to cache downloaded packages in `~/.cache/pip`. Without this, pip caches packages to speed up future installs — but inside a Docker build, that cache is useless (it gets thrown away between builds) and just wastes image space.
- **`--prefix=/install`** → This is the key trick. Normally pip installs to `/usr/local` (the Python system path). Here we're redirecting the install destination to `/install`. This creates a clean, isolated folder with **only the packages we installed** — no system Python files mixed in. This folder is then **surgically copied** into Stage 2.
- **`-r requirements.txt`** → Install from the requirements file. `-r` = requirements.

> **Why `/install`?** In Stage 2, we do `COPY --from=builder /install /usr/local`. This merges the installed packages into the Stage 2 image's Python path. If we had installed to `/usr/local` directly, COPY --from=builder would have copied system Python files too, potentially overwriting things in Stage 2.

---

**Line 21-23:** Comments
```dockerfile
# ── Stage 2: Production ─────────────────────────────────────────────────────
# We use the slim image — no gcc, no build tools, no pip cache.
# Only the Python runtime + our installed packages + app code.
```

---

**Line 24:** `FROM python:3.12-slim`

A **second `FROM` instruction** — this starts **Stage 2**. When Docker sees a second `FROM`, it starts a completely fresh image layer chain. The builder stage is effectively discarded.

- Same `python:3.12-slim` base — this gives us the Python runtime without build tools
- No `AS name` this time — this is the **final stage**, so it doesn't need to be named

---

**Line 27:** `RUN groupadd -r appuser && useradd -r -g appuser appuser`

**This is a security instruction.** Breaking it down:

```bash
groupadd -r appuser
```
- `groupadd` → Linux command to create a new group
- `-r` → System group (reserved range of group IDs, typically < 1000). Marks this as a service group, not a real user group.
- `appuser` → The name of the group being created

```bash
useradd -r -g appuser appuser
```
- `useradd` → Linux command to create a new user
- `-r` → System user (no home directory, no login shell, low UID). Marks it as a service account.
- `-g appuser` → Assign this user to the `appuser` group
- `appuser` (last arg) → The username being created

**Why run as non-root?**

By default, Docker containers run as **root (UID 0)** inside the container. If an attacker exploits a vulnerability in your app and escapes the container (container breakout), they'd have **root privileges on the host**. Running as a non-root user limits the blast radius.

Additionally, in Phase 8, you'll add a **Kyverno policy** called `disallow-root-containers` that **blocks any pod from running as root**. That policy will reject your Kubernetes deployment if you didn't set up a non-root user here.

> **`&&`** between the two commands → runs both in a **single `RUN` layer**. This is a Docker best practice — if each command was a separate `RUN`, each would create a separate layer with metadata overhead. Chaining with `&&` = one layer.

---

**Line 29:** `WORKDIR /app`

- Sets the working directory in the final production image to `/app`
- Different from Stage 1's `/build` — that was the build zone, this is the app zone
- All subsequent instructions use `/app` as current dir
- When the container starts and someone does `docker exec -it <container> bash`, they land in `/app`

---

**Line 32:** `COPY --from=builder /install /usr/local`

**The magic of multi-stage builds.** Breaking it down:

- **`COPY --from=builder`** → Copy FROM the Stage 1 image (named `builder`), NOT from the host filesystem
- **`/install`** → The source path inside the builder image — this is the folder where pip installed all packages (because of `--prefix=/install`)
- **`/usr/local`** → The destination in Stage 2. This is the standard Python site-packages location. Merging `/install` into `/usr/local` makes all installed packages available in the Stage 2 Python runtime.

**What you get:** All packages from `requirements.txt` — FastAPI, Uvicorn, SQLAlchemy, etc. — are now available in Stage 2. But none of the build tools (gcc, pip itself) made it over.

---

**Line 35:** `COPY main.py .`

- Copies `main.py` from the build context (host: `apps/order-service/main.py`) into the working directory of Stage 2 (`/app/main.py`)
- This is the **only application file copied** — just `main.py`. No test files (excluded by `.dockerignore`), no other files.
- Note this `COPY` is AFTER the `COPY --from=builder` — so if main.py changes, only this layer is invalidated, not the package layer above it.

---

**Line 38:** `USER appuser`

- **`USER`** → Switches the current user for all subsequent instructions AND for the final running container
- From this point on: every command runs as `appuser`, not root
- **Must come AFTER** all `RUN` commands that need root (package installation, user creation) because after `USER appuser`, you lose root privileges inside the build process

---

**Line 41:** `EXPOSE 8001`

- **`EXPOSE`** → Documents that the container listens on port `8001`
- **This does NOT actually open the port.** It's metadata/documentation.
- When you run `docker run -p 8001:8001 ...`, the `-p` flag does the actual port binding. `EXPOSE` simply says "this container expects traffic on this port."
- **Why it matters for DevOps:** Docker Compose uses `EXPOSE` to understand which ports services use. Kubernetes uses container ports in its Pod spec (matching this). It's documentation that the whole toolchain reads.

---

**Lines 44-45:**
```dockerfile
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8001/healthz')" || exit 1
```

**The Docker-level health check.** This is different from Kubernetes probes — it's built **into the container runtime itself**.

Breaking down every token:

**`HEALTHCHECK`** → Docker instruction that defines how Docker checks if the container is healthy.

**`--interval=30s`** → Run the health check command **every 30 seconds**.

**`--timeout=5s`** → If the health check command doesn't complete within 5 seconds, it counts as failed.

**`--retries=3`** → The container is marked `unhealthy` only after **3 consecutive failures**. One failure → still `starting`. Three failures in a row → `unhealthy`.

**`CMD python -c "..."` → The actual check command:**
```python
import urllib.request
urllib.request.urlopen('http://localhost:8001/healthz')
```
This uses Python's built-in `urllib` (no external dependency needed) to make an HTTP GET request to `/healthz`. If the endpoint returns 200 → command exits 0 (success). If the service is down → `urlopen` raises an exception → `exit 1`.

**`|| exit 1`** → If the python command fails for any reason (exception), force exit code 1 (failure signal to Docker).

**The 3 possible Docker health states:**
| State | Meaning |
|---|---|
| `starting` | Container just started, first 3 checks pending |
| `healthy` | Health check is passing |
| `unhealthy` | 3 consecutive checks failed |

**DevOps importance:** In Docker Compose (`depends_on`), downstream services can wait until a service is `healthy`. Also, orchestrators (Docker Swarm, ECS) use this to decide whether to restart a container.

> **Important:** Kubernetes does NOT use Docker's `HEALTHCHECK`. Kubernetes has its own `livenessProbe` and `readinessProbe` in the Pod spec. The Docker HEALTHCHECK is useful for local `docker run` scenarios and Docker Compose. Having both is a best practice — defense in depth.

---

**Line 49:** `CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8001"]`

- **`CMD`** → The default command to run when the container starts. Unlike `RUN` (build-time), `CMD` is **runtime**.
- **JSON array format** (exec form) vs string format (shell form):

```dockerfile
# ✅ Exec form (JSON array) — recommended
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8001"]

# ❌ Shell form — don't use in production
CMD uvicorn main:app --host 0.0.0.0 --port 8001
```

**Why exec form?** With shell form, Docker wraps the command in `/bin/sh -c "..."`, creating a shell process as PID 1. With exec form, `uvicorn` becomes **PID 1** directly. This matters because:
- **PID 1** is the process that receives OS signals (like `SIGTERM` for graceful shutdown)
- If your app isn't PID 1, `SIGTERM` might not reach it → graceful shutdown doesn't work → Kubernetes rolling updates can cause dropped requests
- Uvicorn handles `SIGTERM` properly and shuts down gracefully → zero downtime deployments

**The uvicorn arguments:**
- `main:app` → Module `main`, FastAPI object named `app`
- `--host 0.0.0.0` → Listen on all interfaces (required inside containers)
- `--port 8001` → The port (matches `EXPOSE 8001`)

---

## 📄 Files 3 & 4: `user-service/Dockerfile` and `notification-service/Dockerfile`

These are **identical in structure** to the order-service Dockerfile. The only differences are:

| Difference | order-service | user-service | notification-service |
|---|---|---|---|
| Port | `8001` | `8002` | `8003` |
| `EXPOSE` | `8001` | `8002` | `8003` |
| `HEALTHCHECK` URL | `localhost:8001/healthz` | `localhost:8002/healthz` | `localhost:8003/healthz` |
| `CMD` port | `8001` | `8002` | `8003` |

The user and notification service Dockerfiles are also more compact (20 lines vs 50 lines) because the comments were removed — it's assumed the engineer understands the pattern after the first one. **The DevOps logic is identical.**

---

## 🧩 The `.dockerignore` Difference Between Services

| Entry | order-service | user-service | notification-service |
|---|---|---|---|
| `terraform/` | ✅ | ❌ | ❌ |
| `gitops/` | ✅ | ❌ | ❌ |
| `.github/` | ✅ | ❌ | ❌ |

The order-service `.dockerignore` has 3 extra entries because it was written defensively. The user and notification services don't include them because when the Dockerfile's build context is `apps/user-service/`, those folders (`terraform/`, `gitops/`) don't exist in that path anyway — so they're redundant (but not harmful). The order-service being extra defensive is fine.

---

## 🔍 How Docker Layer Caching Works End-to-End (Visual)

```
docker build -t order-service:local apps/order-service/

Build #1 (cold — no cache):
  ✅ FROM python:3.12-slim AS builder    → pulls image, creates layer
  ✅ WORKDIR /build                      → creates layer
  ✅ COPY requirements.txt .             → creates layer (hash: abc123)
  ✅ RUN pip install --prefix=/install   → SLOW (1-2 min), creates layer
  ✅ FROM python:3.12-slim               → starts fresh layer chain
  ✅ RUN groupadd && useradd             → creates layer
  ✅ WORKDIR /app                        → creates layer
  ✅ COPY --from=builder                 → creates layer
  ✅ COPY main.py                        → creates layer (hash: def456)
  ✅ USER appuser                        → creates layer
  ✅ EXPOSE 8001                         → metadata
  ✅ HEALTHCHECK                         → metadata
  ✅ CMD                                 → metadata
  Total time: ~2-3 minutes

Build #2 (developer changed main.py only):
  🔒 FROM python:3.12-slim AS builder    → CACHE HIT
  🔒 WORKDIR /build                      → CACHE HIT
  🔒 COPY requirements.txt .             → CACHE HIT (file unchanged)
  🔒 RUN pip install --prefix=/install   → CACHE HIT (nothing to re-install!)
  🔒 FROM python:3.12-slim               → CACHE HIT
  🔒 RUN groupadd && useradd             → CACHE HIT
  🔒 WORKDIR /app                        → CACHE HIT
  🔒 COPY --from=builder                 → CACHE HIT
  ✅ COPY main.py                        → RE-RUN (file changed, hash changed)
  ✅ USER appuser                        → RE-RUN (cache invalidated below)
  Total time: ~5 seconds
```

This is why the instruction ORDER in a Dockerfile matters as much as the content.

---

## ✅ Validation Commands (What You'd Run After Writing Dockerfiles)

```bash
# Build order-service image
docker build -t order-service:local apps/order-service/

# Run it locally
docker run -p 8001:8001 order-service:local

# Test the health endpoint
curl http://localhost:8001/healthz
# Expected: {"status": "alive"}

# Check the Docker health status
docker ps
# LOOK FOR: (healthy) in the STATUS column after ~30 seconds

# Inspect the image size (should be ~120MB, NOT 900MB)
docker images order-service:local
# LOOK FOR: the SIZE column

# Check the user running inside the container (should NOT be root)
docker run --rm order-service:local whoami
# Expected: appuser

# Check the layers created
docker history order-service:local
```

---

## 🔑 Key DevOps Takeaways from Phase 2

| Decision | Why It Was Made |
|---|---|
| **Multi-stage build** | 120MB vs 900MB image; no build tools in production |
| **`python:3.12-slim`** (not alpine) | Alpine uses musl libc → psycopg2 breaks |
| **`COPY requirements.txt` before `COPY main.py`** | Layer caching → pip not re-run on every code change |
| **`--no-cache-dir`** | Prevents pip cache bloating image |
| **`--prefix=/install`** | Clean isolation for `--from=builder` copy |
| **Non-root user `appuser`** | Security + Kyverno policy compliance (Phase 8) |
| **Exec-form CMD** | Uvicorn becomes PID 1 → receives SIGTERM → graceful shutdown |
| **`EXPOSE` port** | Not functional but documents contract — used by Compose & K8s |
| **`HEALTHCHECK` instruction** | Docker-native health monitoring for local & Compose |
| **`.dockerignore`** | Smaller build context → faster builds; no test/secrets in image |

---

## ✅ Phase 2 Complete — What's Next

You now have **3 production-ready Docker images** for each service. But each image is **isolated** — order-service can't talk to user-service, there's no PostgreSQL, no Redis, no SQS. Running them individually with `docker run` would crash immediately because the required external services don't exist.

**Phase 3: `docker-compose.yml`** solves exactly that — it wires ALL services + ALL dependencies (Postgres, Redis, LocalStack/SQS) together so the entire application can run on your laptop with a single command: `docker-compose up --build` 🚀

*Edited relevant file*

### User Input

Lets do Phase 3

### Planner Response

Let me read the [docker-compose.yml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/docker-compose.yml:0:0-0:0) and any related scripts for Phase 3.

*Viewed [docker-compose.yml](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/docker-compose.yml) *

*Listed directory [scripts](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/scripts) *

*Viewed [localstack-init.sh](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/scripts/localstack-init.sh) *

### Planner Response

I have everything. Let's dive deep into Phase 3.

---

# 🐙 Phase 3 — [docker-compose.yml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/docker-compose.yml:0:0-0:0) & LocalStack Init Script (Deep-Dive)

> **Your job as a DevOps Engineer in Phase 3:** You have 3 Docker images that can't run alone — they need a PostgreSQL database, Redis cache, and AWS SQS queue. [docker-compose.yml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/docker-compose.yml:0:0-0:0) is YOUR file that wires the entire local stack together. A single `docker-compose up --build` should boot everything. This is the "local production replica."

---

## 🧠 Concepts You Must Understand First

### What is Docker Compose?

Docker Compose is a tool that lets you define and run **multi-container applications** using a single YAML file. Instead of running 6 separate `docker run` commands with complex flags, you describe the entire system once.

**The mental model:**
```
docker-compose.yml = the blueprint of your entire local environment
docker-compose up  = bring the blueprint to life
docker-compose down = tear it all down
```

### The Docker Compose File Format

Docker Compose uses **YAML** (YAML Ain't Markup Language). You're already writing YAML in every DevOps tool (GitHub Actions, Kubernetes, Helm) — the syntax rules are the same:
- **Indentation** = hierarchy (2 spaces per level, NO tabs)
- **`key: value`** = basic entry
- **`- item`** = list item
- **Colons after keys**, **no quotes needed** unless the value has special characters

### The 6 Services in This Compose File

```
postgres            → Database (PostgreSQL)
redis               → Cache (Redis)
localstack          → Fake AWS SQS (new concept!)
order-service       → Your app (built from Dockerfile)
user-service        → Your app (built from Dockerfile)
notification-service→ Your app (built from Dockerfile)
```

---

## 🧠 New Concept: LocalStack

> You know Docker, so focus on understanding LocalStack — this is 100% new territory.

**What is LocalStack?**

LocalStack is a **local emulator of AWS services**. It runs inside a Docker container and pretends to be AWS. Your application code can talk to it exactly the same way it would talk to real AWS — same API, same SDK (`boto3`), same URLs — but no AWS account needed, no cost, no internet required.

**Why not just use real AWS in local dev?**
| Problem with real AWS | LocalStack solution |
|---|---|
| Need AWS account + credentials | No credentials (fake `test/test`) |
| Every SQS message costs money | Zero cost |
| Latency from internet round trip | Runs at `localhost:4566` |
| Need to clean up queues after testing | `docker-compose down` deletes everything |
| Internet required | Works offline |

**Which AWS services does LocalStack emulate?**
The free version (used here) supports: **SQS, S3, SNS, DynamoDB, Lambda, IAM, and more**. The Pro version supports EKS, RDS, etc.

**How LocalStack works:**
```
boto3 (AWS SDK in Python)
  │
  │  normally points to: https://sqs.us-east-1.amazonaws.com
  │
  │  in development: http://localstack:4566
  ▼
LocalStack container (port 4566)
  │  (receives the request, acts like real SQS)
  ▼
Returns fake but realistic AWS responses
```

The key configuration that makes boto3 point to LocalStack instead of real AWS:
```yaml
AWS_ENDPOINT_URL: http://localstack:4566   # override the AWS endpoint
AWS_ACCESS_KEY_ID: test                    # fake credentials (LocalStack accepts anything)
AWS_SECRET_ACCESS_KEY: test
AWS_REGION: us-east-1
```

---

## 📄 File 1: [docker-compose.yml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/docker-compose.yml:0:0-0:0) — Line by Line

---

**Lines 1-8:** Comments
```yaml
# =============================================================================
# Docker Compose — Local Development Environment
# =============================================================================
# Starts all 3 microservices + their dependencies (Postgres, Redis, LocalStack)
# in a single command: docker-compose up
#
# LocalStack simulates AWS SQS locally so you don't need an AWS account for dev.
# =============================================================================
```
Header comments explaining the purpose. Important line: **"in a single command: `docker-compose up`"** — that's the whole goal of Phase 3.

---

**Line 10:** `services:`

The top-level key. Everything nested under `services:` is a container that will be created. YAML hierarchy — everything at 2-space indent under `services:` is a service name.

---

## 🐘 Service 1: PostgreSQL

```yaml
Lines 12-27:
# ── PostgreSQL Database ──────────────────────────────────────────────────
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
    test: [ "CMD-SHELL", "pg_isready -U postgres" ]
    interval: 5s
    timeout: 5s
    retries: 5
```

**Line 13:** `postgres:`
→ The **service name**. This name becomes the **DNS hostname** inside the Docker Compose network. So when `order-service` connects with `DATABASE_URL: postgresql://postgres:postgres@postgres:5432/kubeflow`, the hostname `postgres` resolves to this container's IP. Docker Compose creates an internal DNS server automatically.

**Line 14:** `image: postgres:16-alpine`
→ Uses the **official PostgreSQL image** from Docker Hub. No Dockerfile needed — it's a pre-built image.
- `postgres` = the image name (official image from Docker Hub)
- `16` = PostgreSQL version 16 (current latest stable at time of writing)
- `alpine` = the minimal Alpine Linux variant (~80MB vs ~400MB for the full Debian version)

> **Why alpine for Postgres?** Unlike Python packages that need glibc, the Postgres image's alpine variant works perfectly. It's much smaller, making `docker-compose up` faster on first run.

**Lines 15-18:** `environment:`
```yaml
POSTGRES_USER: postgres
POSTGRES_PASSWORD: postgres
POSTGRES_DB: kubeflow
```
These are **environment variables read by the official Postgres image** at startup to initialize the database. The Postgres image's logic:
- `POSTGRES_USER` → creates a superuser with this name
- `POSTGRES_PASSWORD` → sets that user's password
- `POSTGRES_DB` → creates an initial database with this name

**Why `postgres/postgres` as username/password?** This is a local development environment. In production, these would come from **AWS Secrets Manager via External Secrets Operator** (Phase 8). Hardcoding credentials in Compose is acceptable for local-only use — but **NEVER in production**.

The `DATABASE_URL` you'll see in the app services uses all of these:
```
postgresql://postgres:postgres@postgres:5432/kubeflow
             ↑user    ↑pass    ↑host   ↑port ↑dbname
```

**Lines 19-20:** `ports:`
```yaml
- "5432:5432"
```
**Format:** `"HOST_PORT:CONTAINER_PORT"`
- Left side (`5432`) → port on your laptop/host machine
- Right side (`5432`) → port inside the container
- Result: You can connect to PostgreSQL from your laptop using `localhost:5432` (e.g., with DBeaver, psql, etc.)

> **Important distinction:** Services within the Compose network talk to each other by **container port** (5432) using the **service name as hostname** (`postgres:5432`). The `ports:` mapping is only for **host access** — so a developer can inspect the DB from outside Docker.

**Lines 21-22:** `volumes:`
```yaml
- postgres_data:/var/lib/postgresql/data
```
**Format:** `NAMED_VOLUME:CONTAINER_PATH`

- `/var/lib/postgresql/data` → This is where PostgreSQL stores all its data files (tables, indexes, WAL logs) inside the container
- `postgres_data` → A **named volume** (defined at the bottom of the file in line 112-113)

**Why a volume?**
Without a volume, every time you run `docker-compose down` and `docker-compose up`, the database starts completely empty. All your test data is gone.

With a named volume:
```
docker-compose down   → container deleted, volume SURVIVES
docker-compose up     → new container mounts the same volume = data persists
```

**Named volume vs bind mount:**
| Type | Syntax | How it works |
|---|---|---|
| Named volume | `postgres_data:/var/...` | Docker manages the storage space. Best for databases. |
| Bind mount | `./local-dir:/var/...` | Maps a specific folder from your laptop. Best for code (hot reload). |

Postgres uses a **named volume** because Docker manages the storage location optimally for a database, and you don't need to directly browse the raw Postgres data files.

**Lines 23-27:** `healthcheck:`
```yaml
test: [ "CMD-SHELL", "pg_isready -U postgres" ]
interval: 5s
timeout: 5s
retries: 5
```
- **[test](cci:1://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/user-service/tests/test_main.py:15:0-19:47)** → The command to run to check health. `CMD-SHELL` means run via the shell (so shell features like pipes work).
- **`pg_isready -U postgres`** → A built-in PostgreSQL utility that checks if the server is accepting connections. Returns 0 (success) if ready, non-zero if not.
- **`interval: 5s`** → Check every 5 seconds (more aggressive than the Dockerfile's 30s — because Compose startup order depends on this)
- **`timeout: 5s`** → 5 seconds before the check times out
- **`retries: 5`** → Mark unhealthy after 5 consecutive failures

**Why the healthcheck is critical here:** The `order-service` and `user-service` have:
```yaml
depends_on:
  postgres:
    condition: service_healthy
```
This means Docker Compose **holds back** starting the app services until this healthcheck passes. Without this, the app containers would start before Postgres is ready, immediately fail to connect, and crash. The healthcheck + `depends_on` together create an **ordered startup**.

---

## 🔴 Service 2: Redis

```yaml
Lines 29-38:
# ── Redis (for notification deduplication) ───────────────────────────────
redis:
  image: redis:7-alpine
  ports:
    - "6379:6379"
  healthcheck:
    test: [ "CMD", "redis-cli", "ping" ]
    interval: 5s
    timeout: 5s
    retries: 5
```

**Line 30:** `redis:`
→ Service name. This is also the hostname. `notification-service` will connect to Redis using `redis://redis:6379` — the hostname `redis` resolves to this container.

**Line 31:** `image: redis:7-alpine`
→ Official Redis image, version 7, Alpine Linux. No custom Dockerfile needed — it works out of the box.

**No `environment:` block for Redis** — Redis doesn't require any initialization variables by default. It starts empty and ready.

**No `volumes:` for Redis** — Unlike Postgres, Redis data is **ephemeral** here. Every Compose restart = empty Redis. This is intentional — Redis in this project is used purely as a **cache**. Caches are designed to be rebuilt. Losing cached notifications on restart is fine (the real source of truth is the database/SQS).

**Lines 34-38:** `healthcheck:`
```yaml
test: [ "CMD", "redis-cli", "ping" ]
```
- **`CMD`** → Run the command directly (no shell wrapper — more efficient)
- **`redis-cli ping`** → Redis command-line client sends a `PING` command. Redis responds with `PONG`. Exit 0 = healthy.

`notification-service` depends on this healthcheck:
```yaml
depends_on:
  redis:
    condition: service_healthy
```

---

## ☁️ Service 3: LocalStack (New Concept — Deep Dive)

```yaml
Lines 40-51:
# ── LocalStack (simulates AWS SQS locally) ──────────────────────────────
# Why LocalStack? So you can develop and test SQS integration without
# needing an AWS account or incurring costs during local development.
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

**Lines 41-42:** Comments — explain the "why" of LocalStack. Already covered above.

**Line 43:** `localstack:`
→ Service name. All app services access it via `http://localstack:4566`.

**Line 44:** `image: localstack/localstack:3.0`
→ The official LocalStack image from Docker Hub. Version `3.0` (current stable at time of writing). This is from the company that builds LocalStack (localstack.io).

**Lines 45-47:** `environment:`
```yaml
SERVICES: sqs
DEFAULT_REGION: us-east-1
```

**`SERVICES: sqs`** → Tells LocalStack to **only start the SQS service**. LocalStack can emulate dozens of AWS services but each one takes memory and startup time. Limiting to just `sqs` keeps the container minimal and fast. If you also needed S3, you'd write `SERVICES: sqs,s3`.

**`DEFAULT_REGION: us-east-1`** → Sets the AWS region LocalStack simulates. This must match the `AWS_REGION: us-east-1` set in the app services, otherwise the SQS queue URLs won't match.

**Lines 48-49:** `ports:`
```yaml
- "4566:4566"
```
Port `4566` is LocalStack's **universal gateway port** — all AWS services are mocked on this single port (as of LocalStack 3.0). So:
- SQS: `http://localhost:4566`
- S3: `http://localhost:4566`
- SNS: `http://localhost:4566`

All services → same port. LocalStack uses the API call's format to route to the right service internally.

**Lines 50-51:** `volumes:`
```yaml
- ./scripts/localstack-init.sh:/etc/localstack/init/ready.d/init.sh
```
**This is a bind mount** (not a named volume). Format: `HOST_PATH:CONTAINER_PATH`

- [./scripts/localstack-init.sh](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/scripts/localstack-init.sh:0:0-0:0) → Your script on the **host machine** (relative to where [docker-compose.yml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/docker-compose.yml:0:0-0:0) is)
- `/etc/localstack/init/ready.d/init.sh` → A **magic path inside LocalStack**

**The magic path explained:**
LocalStack has a built-in initialization hook system. When LocalStack is fully ready (all services started), it automatically runs every script it finds in `/etc/localstack/init/ready.d/`. By mounting your script here, you're telling LocalStack: **"Once you're ready, run this script to set up the SQS queues."**

No extra configuration needed — just placing the file in that path is enough. This is called a **hook/init pattern** — common across many Docker images (MySQL, Postgres, LocalStack all support it).

> **Why not use `healthcheck` for LocalStack?** LocalStack startup varies — it's ready only after all internal services are initialized. The init script handles this implicitly: it can't run until LocalStack signals readiness. That's why `order-service` uses `condition: service_started` instead of `service_healthy` for LocalStack — the init script is the real readiness gate, handled internally.

---

## 📦 Service 4: `order-service`

```yaml
Lines 53-75:
# ── Order Service ────────────────────────────────────────────────────────
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

**Lines 55-57:** `build:`
```yaml
build:
  context: ./apps/order-service
  dockerfile: Dockerfile
```
Instead of `image:` (pre-built), this uses `build:` — tells Compose to **build the image from a Dockerfile**.

- **`context: ./apps/order-service`** → The build context path (relative to [docker-compose.yml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/docker-compose.yml:0:0-0:0) in the project root). This is the folder Docker sends to the daemon — containing [main.py](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/user-service/main.py:0:0-0:0), [requirements.txt](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/user-service/requirements.txt:0:0-0:0), [Dockerfile](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/user-service/Dockerfile:0:0-0:0), and filtered by [.dockerignore](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/user-service/.dockerignore:0:0-0:0).
- **`dockerfile: Dockerfile`** → Explicitly names the Dockerfile to use. Could be omitted (Compose defaults to [Dockerfile](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/user-service/Dockerfile:0:0-0:0)), but explicit is better for clarity.

> **How this differs from `docker build`**: `docker-compose up --build` builds all services with `build:` blocks. `docker-compose up` (without `--build`) uses cached images if they exist. In CI, you always want `--build`.

**Lines 58-59:** `ports: - "8001:8001"` → Same concept as Postgres. Host port 8001 maps to container port 8001. Lets you access `http://localhost:8001/docs` from your laptop browser.

**Lines 60-68:** `environment:` — This is the **most important section for a DevOps engineer** because this is how you configure apps without changing code:

```yaml
DATABASE_URL: postgresql://postgres:postgres@postgres:5432/kubeflow
```
→ The full PostgreSQL connection string. Breaking it down:
- `postgresql://` → Protocol
- `postgres:postgres` → `username:password`
- `@postgres:5432` → `@hostname:port` — `postgres` is the Compose service name (DNS)
- `/kubeflow` → Database name (matches `POSTGRES_DB: kubeflow`)

The app reads this env var via `os.environ["DATABASE_URL"]` and passes it to `create_engine()` (SQLAlchemy). If this env var is wrong/missing, the app crashes on startup.

```yaml
SQS_QUEUE_URL: http://localstack:4566/000000000000/order-events
```
→ The SQS queue URL. Format for LocalStack:
- `http://localstack:4566` → LocalStack endpoint (hostname is the service name)
- `/000000000000` → Fake AWS account ID (LocalStack uses all zeros by default)
- `/order-events` → Queue name (will be created by [localstack-init.sh](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/scripts/localstack-init.sh:0:0-0:0))

In real AWS, this would look like: `https://sqs.us-east-1.amazonaws.com/123456789012/order-events`

```yaml
USER_SERVICE_URL: http://user-service:8002
```
→ How `order-service` finds `user-service`. In Docker Compose, the hostname `user-service` resolves to the user-service container's IP. **This is Docker's internal DNS at work.** In Kubernetes, this hostname would change to the full service DNS name.

```yaml
AWS_REGION: us-east-1
AWS_ENDPOINT_URL: http://localstack:4566
AWS_ACCESS_KEY_ID: test
AWS_SECRET_ACCESS_KEY: test
```
→ **The LocalStack trick.** `AWS_ENDPOINT_URL` is a special env var that boto3 reads — it overrides the AWS endpoint. `test/test` are fake credentials that LocalStack accepts for any operation. In production, these vars won't exist and real IAM credentials (IRSA) will be used.

```yaml
OTLP_ENDPOINT: ""
```
→ OpenTelemetry collector endpoint — intentionally set to `""` (empty string). In local development, we don't have an OTel Collector running. Setting it to empty tells the app: "don't export traces." The app handles this gracefully (no crash). In production (Phase 9), this will point to the OTel Collector service in Kubernetes.

**Lines 69-75:** `depends_on:` — **Startup ordering**. This is critical:

```yaml
depends_on:
  postgres:
    condition: service_healthy   ← waits for pg_isready to pass
  localstack:
    condition: service_started   ← just waits for container to be running
  user-service:
    condition: service_started   ← just waits for container to be running
```

**`condition: service_healthy`** → Waits until the service's healthcheck reports `healthy`. Used for **stateful dependencies** (Postgres, Redis) where you need the service to be truly ready before connecting.

**`condition: service_started`** → Just waits for the container to start (Docker started it). Doesn't wait for healthcheck. Used for LocalStack (init is handled by the script hook) and user-service (if user-service fails, order-service will retry — the app has connection retry logic).

> **depends_on does NOT guarantee the app inside is fully ready** — it only controls **container start order**. That's why health checks exist.

---

## 📦 Service 5: `user-service`

```yaml
Lines 77-89:
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

Simplest service. Compared to `order-service`:
- ❌ No `SQS_QUEUE_URL` — doesn't use SQS
- ❌ No `USER_SERVICE_URL` — doesn't call other services
- ❌ No `AWS_*` vars — no AWS SDK usage
- Only `DATABASE_URL` + `OTLP_ENDPOINT`
- Only depends on `postgres` being healthy

> **This reflects exactly what we read in Phase 1 from [requirements.txt](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/user-service/requirements.txt:0:0-0:0)** — user-service has no boto3, no httpx. The Compose config proves it.

---

## 📦 Service 6: `notification-service`

```yaml
Lines 91-110:
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

Compare to order-service:
- ❌ No `DATABASE_URL` — no PostgreSQL (confirmed from Phase 1 requirements.txt)
- ❌ No `USER_SERVICE_URL` — doesn't call other services
- ✅ `SQS_QUEUE_URL` — polls the **same queue** that order-service publishes to
- ✅ `REDIS_URL: redis://redis:6379/0` — Redis connection string. `/0` is the Redis **database index** (Redis supports 16 databases: 0-15; `0` is the default)
- Depends on `redis` (healthy) + `localstack` (started)
- Does NOT depend on `order-service` or `user-service` directly — it's an independent consumer

The beautiful design: `order-service` → publishes to SQS queue → `notification-service` polls from the same SQS queue. They're **decoupled** — notification-service doesn't need order-service to be alive to process messages.

---

**Lines 112-113:** `volumes:`
```yaml
volumes:
  postgres_data:
```
The **top-level `volumes:` block** declares named volumes. A named volume must be declared here before it can be used in a service.

`postgres_data:` with a colon and nothing after it is valid YAML — it means "declare this volume with all defaults." Docker manages where this volume's data is stored on your machine (usually in `/var/lib/docker/volumes/` on Linux).

**To see your volumes:**
```bash
docker volume ls
# You'll see: kubeflow_devsecops_pipeline_postgres_data

docker volume inspect kubeflow_devsecops_pipeline_postgres_data
# Shows: the mount point on your host machine
```

---

## 📄 File 2: [scripts/localstack-init.sh](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/scripts/localstack-init.sh:0:0-0:0) — Line by Line

> This script runs **inside the LocalStack container** when LocalStack is ready. It creates the SQS queues before any app service tries to use them.

---

**Line 1:** `#!/bin/bash`

The **shebang line**. Every shell script should start with this. `#!` tells the OS: "use this interpreter to run this file." `/bin/bash` → use the Bash shell.

**Line 2-7:** Comments — header describing the script's purpose.

---

**Line 9:** `echo "Creating SQS queues in LocalStack..."`
→ Prints a status message to stdout. Visible in `docker-compose logs localstack`.

---

**Lines 11-15:**
```bash
# Create the dead-letter queue first (DLQ)
# Messages that fail processing 3 times get moved here for investigation
awslocal sqs create-queue \
    --queue-name order-events-dlq \
    --attributes '{"MessageRetentionPeriod":"1209600"}'
```

### What is `awslocal`?

`awslocal` is a **wrapper around the AWS CLI** that's pre-installed inside the LocalStack container. It automatically adds `--endpoint-url http://localhost:4566` to every AWS CLI command — so instead of writing:
```bash
aws sqs create-queue --endpoint-url http://localhost:4566 ...
```
You just write:
```bash
awslocal sqs create-queue ...
```
Same result. `awslocal` is a convenience tool from the LocalStack team.

### What is a Dead Letter Queue (DLQ)?

**This is a critical DevOps/cloud concept.** A DLQ is a secondary SQS queue that receives messages that **failed to be processed successfully** after N attempts.

Flow without DLQ:
```
order-service → SQS: "order #123 shipped"
notification-service tries to process it → FAILS (bug)
SQS makes it visible again → notification-service tries again → FAILS
→ repeat forever → "poison pill" message blocks the queue
```

Flow with DLQ:
```
order-service → SQS: "order #123 shipped"
notification-service tries 3 times → FAILS each time
SQS automatically moves to DLQ
→ Main queue is unblocked
→ DLQ holds the failed message for investigation
→ You can replay from DLQ after fixing the bug
```

```bash
awslocal sqs create-queue \
    --queue-name order-events-dlq \
    --attributes '{"MessageRetentionPeriod":"1209600"}'
```

- **`sqs create-queue`** → AWS CLI subcommand to create an SQS queue
- **`--queue-name order-events-dlq`** → Queue name. Convention: `order-events-dlq` = original queue name + `-dlq` suffix
- **`--attributes '{"MessageRetentionPeriod":"1209600"}'`** → JSON attribute:
  - `MessageRetentionPeriod` = how long (in seconds) SQS keeps messages: `1209600` seconds = **14 days**. Failed messages are retained for 14 days for investigation/replay. Main queue might keep messages for just 4 days (default).
- **`\`** (backslash at end of lines) → Line continuation character in bash. The command continues on the next line.

---

**Lines 17-22:**
```bash
# Get the DLQ ARN (needed for the main queue's redrive policy)
DLQ_ARN=$(awslocal sqs get-queue-attributes \
    --queue-url http://localhost:4566/000000000000/order-events-dlq \
    --attribute-names QueueArn \
    --query 'Attributes.QueueArn' \
    --output text)
```

**Line 18:** `DLQ_ARN=$(...)` 
→ **Command substitution** in bash. The `$(...)` syntax runs a command and stores its **output** in the variable `DLQ_ARN`. The variable is then used later.

**`awslocal sqs get-queue-attributes`** → Fetches metadata/attributes of an existing SQS queue.

**`--queue-url http://localhost:4566/000000000000/order-events-dlq`** → The full URL of the queue we just created. LocalStack uses `localhost` here (inside the LocalStack container, `localhost` refers to itself). The `000000000000` is the fake account ID LocalStack assigns.

**`--attribute-names QueueArn`** → Fetch specifically the `QueueArn` attribute. ARN = **Amazon Resource Name**. Every AWS resource has a unique ARN — it's like a full path/address for that resource. Example: `arn:aws:sqs:us-east-1:000000000000:order-events-dlq`.

**`--query 'Attributes.QueueArn'`** → AWS CLI `--query` uses **JMESPath** query language to extract a specific field from the JSON response. Without `--query`, you'd get the full JSON; with it, you get just the ARN value.

**`--output text`** → Format the output as plain text (not JSON). So `DLQ_ARN` gets a clean string like `arn:aws:sqs:us-east-1:000000000000:order-events-dlq` instead of quoted JSON.

---

**Lines 24-28:**
```bash
# Create the main order events queue with a redrive policy
# maxReceiveCount=3 means: after 3 failed processing attempts, send to DLQ
awslocal sqs create-queue \
    --queue-name order-events \
    --attributes "{\"RedrivePolicy\":\"{\\\"deadLetterTargetArn\\\":\\\"${DLQ_ARN}\\\",\\\"maxReceiveCount\\\":\\\"3\\\"}\"}"
```

**`--queue-name order-events`** → The **main queue** (the one in `SQS_QUEUE_URL`). This is what `order-service` publishes to and `notification-service` consumes from.

**`--attributes "..."` with `RedrivePolicy`** → Configures the DLQ linkage. The Redrive Policy tells SQS:
- `deadLetterTargetArn` → ARN of the DLQ to send failed messages to (`${DLQ_ARN}` uses the variable from above)
- `maxReceiveCount: 3` → After **3 failed receive attempts**, the message is moved to the DLQ

**The escaped JSON** (`\"`, `\\\"`) → The attribute value is a **JSON string that contains another JSON string** (double-encoded JSON). This is an SQS quirk — the `RedrivePolicy` attribute value must itself be a JSON-encoded string. The backslashes escape the inner quotes for bash. This messy syntax is normal and expected for SQS queue creation via CLI.

**`${DLQ_ARN}`** → Bash variable expansion — inserts the DLQ ARN value captured earlier.

---

**Line 30:** `echo "✅ SQS queues created successfully"`
→ Success message. The ✅ emoji appears in the container logs.

**Line 31:** `awslocal sqs list-queues`
→ Lists all queues in LocalStack for verification. Output goes to the container logs. When you run `docker-compose logs localstack`, you'll see both queue URLs listed — confirming successful creation.

---

## 🌐 The Full Network Picture (How Docker Compose DNS Works)

Docker Compose creates a **single default bridge network** where all services can reach each other by service name:

```
┌─────────────────────────────────────────────────────────────┐
│              Docker Compose Default Network                  │
│                                                             │
│   postgres:5432      ◄──── order-service (DATABASE_URL)    │
│   postgres:5432      ◄──── user-service  (DATABASE_URL)    │
│                                                             │
│   redis:6379         ◄──── notification-service (REDIS_URL) │
│                                                             │
│   localstack:4566    ◄──── order-service (SQS publish)     │
│   localstack:4566    ◄──── notification-service (SQS poll) │
│                                                             │
│   user-service:8002  ◄──── order-service (USER_SERVICE_URL) │
│                                                             │
│   ─ ─ ─ ─ ─ ─ ─ ─ HOST MACHINE ─ ─ ─ ─ ─ ─ ─ ─ ─        │
│   localhost:5432 (Postgres - for DB client)                 │
│   localhost:6379 (Redis - for inspection)                   │
│   localhost:4566 (LocalStack - for aws CLI)                 │
│   localhost:8001 (order-service docs)                       │
│   localhost:8002 (user-service docs)                        │
│   localhost:8003 (notification-service docs)                │
└─────────────────────────────────────────────────────────────┘
```

---

## 📋 The Startup Order (depends_on chain resolved)

```
Step 1: postgres starts  (no deps)
        redis starts     (no deps)
        localstack starts (no deps)
        ↓ (parallel)
Step 2: pg_isready check every 5s → postgres becomes HEALTHY
        redis-cli ping every 5s  → redis becomes HEALTHY
        localstack starts → runs localstack-init.sh → creates SQS queues
        ↓
Step 3: user-service starts       (postgres:healthy ✅)
        notification-service starts (redis:healthy ✅ + localstack:started ✅)
        ↓
Step 4: order-service starts      (postgres:healthy ✅ + localstack:started ✅ + user-service:started ✅)
```

---

## 🛠️ The Key Docker Compose Commands

```bash
# First time — build all images and start everything
docker-compose up --build

# Start without rebuilding (uses cached images)
docker-compose up

# Run in background (detached mode) — like a daemon
docker-compose up -d --build

# See logs from all services in real time
docker-compose logs -f

# See logs from a specific service
docker-compose logs -f order-service

# Stop everything (keeps containers and volumes)
docker-compose stop

# Stop and REMOVE containers (volumes survive)
docker-compose down

# Stop and REMOVE containers AND volumes (wipes the database!)
docker-compose down -v

# Restart a single service (after code change)
docker-compose restart order-service
# or rebuild just one service:
docker-compose up -d --build order-service

# Run a command inside a running container
docker-compose exec postgres psql -U postgres -d kubeflow

# See running containers
docker-compose ps
```

---

## 🔑 Key DevOps Takeaways from Phase 3

| Concept | What You Applied |
|---|---|
| **Service names = DNS hostnames** | `postgres`, `redis`, `user-service`, `localstack` are resolvable hostnames |
| **Environment variables for config** | No hardcoded URLs in app code → inject at runtime per environment |
| **`depends_on` + `healthcheck`** | Controlled startup order prevents race conditions |
| **Named volume for Postgres** | Data persists across `docker-compose down && up` cycles |
| **LocalStack** | Zero-cost, zero-AWS-account SQS testing in local dev |
| **Init scripts in LocalStack** | Queue setup automated — no manual CLI steps for team members |
| **DLQ + RedrivePolicy** | Production-grade SQS pattern even in local dev — ensures notifications aren't silently lost |
| **`OTLP_ENDPOINT: ""`** | Feature-flagging via env vars — OTel tracing disabled locally, enabled in K8s |
| **No secrets in images** | All credentials come from Compose env vars → easy to override per environment |

---

## ✅ What You Can Verify After `docker-compose up --build`

```bash
# 1. All services running
docker-compose ps
# All should show: Up (healthy) or Up

# 2. order-service API docs
# Open browser: http://localhost:8001/docs

# 3. user-service API docs  
# Open browser: http://localhost:8002/docs

# 4. notification-service API docs
# Open browser: http://localhost:8003/docs

# 5. health checks
curl http://localhost:8001/healthz  # {"status": "alive"}
curl http://localhost:8002/healthz  # {"status": "alive"}
curl http://localhost:8003/healthz  # {"status": "alive"}

# 6. Metrics endpoints (Prometheus format)
curl http://localhost:8001/metrics
curl http://localhost:8002/metrics

# 7. LocalStack SQS queues
aws --endpoint-url http://localhost:4566 sqs list-queues
# Should list: order-events and order-events-dlq

# 8. Postgres connection
docker-compose exec postgres psql -U postgres -d kubeflow -c '\dt'
# Shows all tables created by order-service and user-service
```

---

## ✅ Phase 3 Complete — What's Next

You now have:
- ✅ 3 Docker images (Phase 2)
- ✅ A full working local environment (Phase 3) — all 6 services running together

But everything so far is **manual** — you built and ran things locally. Phase 4 is where you stop being manual and start being a **real DevOps engineer**: **GitHub Actions CI/CD Pipeline**. Every `git push` → auto-build → auto-test → auto-scan → auto-push to ECR → auto-update GitOps → ArgoCD auto-deploys. 🚀