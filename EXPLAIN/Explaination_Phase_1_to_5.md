# Chat Conversation

Note: _This is purely the output of the chat conversation and does not contain any raw data, codebase snippets, etc. used to generate the output._

### User Input

Go through The pahse_custom file and whole project . Now you need to Start explaining the Project. Let's start with phase 1 . But no need to explain. App code as it will be given to me by the developer. You only need to tell me what is. Relevant for Devops perspective since this is a Devops project. Now FYI I know the basics of Jenkins, Docker, Kubernetes and Terraform so . , any other technology, any other tool, any other new thing, you need to explain that in detail. Do not skip anything. You need to explain each file. Line by line. And each block. Also make sure you proceed in the exact manner like which a Devops engineer will start. Like you need to choose start with that file which a Devops engineer will start with. For example, you cannot start Terraform before. Docker. So keep everything in order. Also, whatever is already explained before, no need to explain that again, you can just skip that.

### Planner Response

Let me start by reading the `Phases_Custom.md` file and exploring the project structure thoroughly.

_Viewed [Phases_Custom.md](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/Phases_Custom.md)_

_Listed directory [Kubeflow_Devsecops_Pipeline](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline)_

### Planner Response

Now let me explore the `apps/` folder and the Phase 1 relevant files in detail.

_Listed directory [apps](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps)_

_Listed directory [.github](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/.github)_

_Listed directory [order-service](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/order-service)_

_Listed directory [user-service](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/user-service)_

_Listed directory [notification-service](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/notification-service)_

_Viewed [requirements.txt](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/order-service/requirements.txt)_

_Viewed [requirements.txt](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/user-service/requirements.txt)_

_Viewed [requirements.txt](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/notification-service/requirements.txt)_

### Planner Response

Now let me read the tests for each service too:

_Listed directory [tests](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/order-service/tests)_

_Listed directory [tests](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/user-service/tests)_

_Listed directory [tests](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/notification-service/tests)_

_Viewed [test_main.py](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/order-service/tests/test_main.py)_

_Viewed [test_main.py](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/user-service/tests/test_main.py)_

_Viewed [test_main.py](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/notification-service/tests/test_main.py)_

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

### The 3 Services and What They Do

| Service | Port | Role |
|---|---|---|
| `order-service` | `8001` | Takes orders, validates user exists, saves to DB, sends notification to SQS queue |
| `user-service` | `8002` | Manages users (create/read/update/delete) |
| `notification-service` | `8003` | Listens on SQS queue, sends notifications, caches results in Redis |

### How the services talk to each other

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

### What You Now Know (Before Writing Any DevOps Code)

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

### How to Run Tests Locally (what you'd do manually in Phase 1)

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

### The pytest Tool (since you know Jenkins but might not know pytest deeply)

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

_Viewed [Dockerfile](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/order-service/Dockerfile)_

_Viewed [.dockerignore](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/order-service/.dockerignore)_

_Viewed [Dockerfile](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/user-service/Dockerfile)_

_Viewed [.dockerignore](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/user-service/.dockerignore)_

_Viewed [Dockerfile](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/notification-service/Dockerfile)_

_Viewed [.dockerignore](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/notification-service/.dockerignore)_

### Planner Response

I have everything. Let me now give you the full Phase 2 walkthrough.

---

# 🐳 Phase 2 — Dockerfiles & [.dockerignore](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/apps/user-service/.dockerignore:0:0-0:0) (Deep-Dive)

> **Your job as a DevOps Engineer:** You take the developer's code and make it run the same way — on **any machine, any environment, any cloud** — by packaging it into a container image. The Dockerfile is **your** file, not the developer's.

---

## 🧠 Concept You Must Understand First: Multi-Stage Builds

Before reading a single line, you need to understand **why** these Dockerfiles are written the way they are.

### The Problem with a Naive Dockerfile

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

**Lines 33-41:** `# Terraform`, `# GitOps`, `# CI/CD` _(order-service only)_

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

### The Complete File Annotated

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

_Edited relevant file_

### User Input

Lets do Phase 3

### Planner Response

Let me read the [docker-compose.yml](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/docker-compose.yml:0:0-0:0) and any related scripts for Phase 3.

_Viewed [docker-compose.yml](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/docker-compose.yml)_

_Listed directory [scripts](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/scripts)_

_Viewed [localstack-init.sh](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/scripts/localstack-init.sh)_

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

### User Input

Lets do Phase 4

### Planner Response

Let me read all the GitHub Actions workflow files first.

_Listed directory [workflows](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/.github/workflows)_

_Viewed [ci.yml](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/.github/workflows/ci.yml)_

_Viewed [deploy.yml](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/.github/workflows/deploy.yml)_

_Viewed [terraform.yml](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/.github/workflows/terraform.yml)_

### Planner Response

I have all three workflow files. Let me also read the sonarqube config to cover it as part of Phase 4's SonarQube section.

_Listed directory [sonarqube](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/sonarqube)_

_Viewed [sonar-project.properties](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/sonarqube/sonar-project.properties)_

### Planner Response

I have everything needed. This is a deep one — let me break it all down thoroughly.

---

# ⚙️ Phase 4 — GitHub Actions CI/CD Pipelines (Deep-Dive)

> **Your job as a DevOps Engineer in Phase 4:** You now automate everything you did manually in Phases 1–3. Every `git push` kicks off a pipeline that builds, tests, scans, and ships code — without you touching a single thing. This is the core of DevSecOps.

---

## 🧠 Concepts You Must Understand First

### What is GitHub Actions?

GitHub Actions is GitHub's **built-in CI/CD platform**. You know Jenkins — think of GitHub Actions as Jenkins but:

- No server to maintain (GitHub hosts the runners)
- Configuration is YAML files in `.github/workflows/`
- Every push, PR, or manual trigger runs the workflow automatically

**Key terminology:**

| Term | Meaning | Jenkins equivalent |
|---|---|---|
| **Workflow** | The entire automation file (`.yml`) | Jenkinsfile |
| **Trigger (`on:`)** | What event starts the workflow | Build triggers |
| **Job** | A group of steps that run on one machine | Stage |
| **Step** | A single command or action | Step |
| **Action (`uses:`)** | A reusable plugin/script from the marketplace | Shared library |
| **Runner** | The machine that executes the job | Agent/Node |
| **Secret** | Encrypted variable stored in GitHub | Jenkins credentials |
| **`github.sha`** | The git commit SHA (40-char hash) | `${GIT_COMMIT}` |

### The 3 Workflow Files in This Project

| File | Phase | Trigger | Purpose |
|---|---|---|---|
| `ci.yml` | 4a | Push/PR to `main` (apps/ changed) | Build → Test → Scan → Push to ECR → Update GitOps |
| `deploy.yml` | 4b | Manual (`workflow_dispatch`) | Deploy specific image to specific environment |
| `terraform.yml` | 4c | Push/PR to `main` (terraform/ changed) | `terraform plan` on PR, `terraform apply` on merge |

---

## 🧠 New Concept: OIDC Authentication (Critical Security Concept)

> You'll see this in every workflow. Understand it once — don't skip this.

**The Old Way (BAD — Static Keys):**

```yaml
# ❌ NEVER DO THIS
env:
  AWS_ACCESS_KEY_ID: AKIAIOSFODNN7EXAMPLE
  AWS_SECRET_ACCESS_KEY: wJalrXUtnFEMI/K7MDENG
```

Static keys stored in GitHub Secrets:

- Keys never expire unless manually rotated
- If leaked (logs, accidents), they keep working
- Violates the principle of least privilege temporally

**The New Way (GOOD — OIDC):**

**OIDC** = **OpenID Connect**. A standard protocol for identity federation.

```
GitHub Actions Runner
  │
  │  "I am GitHub Actions, running for repo org/repo, on branch main"
  │  (signed JWT token from GitHub's OIDC provider)
  ▼
AWS IAM OIDC Provider
  │  "I trust GitHub's OIDC provider"
  │  "This token is valid and matches my trust policy conditions"
  ▼
AWS STS (Security Token Service)
  │  "Here is a temporary credential valid for 1 hour"
  ▼
GitHub Actions Runner receives: 
  - AWS_ACCESS_KEY_ID (temporary)
  - AWS_SECRET_ACCESS_KEY (temporary)
  - AWS_SESSION_TOKEN (expires in 1 hour)
```

**Why OIDC is superior:**

| Property | Static Keys | OIDC |
|---|---|---|
| Key rotation | Manual, often skipped | Automatic (1h TTL) |
| If leaked | Valid forever | Expired in ≤1h |
| Scope | Whatever the key user can do | Scoped to specific repo, branch |
| Audit trail | "Key was used" | "GitHub Actions on branch main did X" |

**The IAM Trust Policy** (in prod, set up via `scripts/automation/setup-github-oidc.sh` in Phase 11):

```json
{
  "Condition": {
    "StringLike": {
      "token.actions.githubusercontent.com:sub": 
        "repo:your-org/your-repo:ref:refs/heads/main"
    }
  }
}
```

This says: "Only allow GitHub Actions from THIS specific repo, on the `main` branch." A fork or a different branch cannot assume this role. **Extremely precise access control.**

---

## 🧠 New Concept: Amazon ECR

**ECR** = **Elastic Container Registry**. This is AWS's private Docker image registry.

Think of it like Docker Hub but:

- Private (only your AWS account can access it)
- Integrated with AWS IAM (no separate credentials)
- Each image gets a repository in ECR
- Images are stored with tags (in this project, the tag = the git SHA)

**ECR image URL format:**

```
<account-id>.dkr.ecr.<region>.amazonaws.com/<repo-name>:<tag>
Example:
123456789012.dkr.ecr.us-east-1.amazonaws.com/kubeflow-ops-order-service:abc123def456
```

You'll see `$ECR_REGISTRY` in the workflow — this is the `<account-id>.dkr.ecr.<region>.amazonaws.com` part, output by the ECR login action.

---

## 📄 File 1: `.github/workflows/ci.yml` — Line by Line

---

### Header (Lines 1–15)

```yaml
# =============================================================================
# GitHub Actions CI Pipeline — Microservice Build & Push
# ...
# How it works:
#   1. Developer pushes code to apps/order-service/
#   2. GitHub Actions detects the change (path filter below)
#   3. CI builds, tests, scans, and pushes the image
#   4. CI updates the image tag in gitops/ and commits
#   5. ArgoCD watches gitops/ and detects the new image tag
#   6. ArgoCD deploys the new version to the cluster — ZERO manual steps!
```

These comments describe the **full end-to-end GitOps flow**. Steps 5 and 6 will come to life in Phase 7 (ArgoCD). For now: **CI triggers CD** by updating a YAML file in git.

---

### `name:` (Line 17)

```yaml
name: CI — Build & Push
```

The workflow's **display name** shown in the GitHub Actions UI (Actions tab). When multiple workflows exist, this is how you tell them apart.

---

### `on:` — Triggers (Lines 19–27)

```yaml
on:
  push:
    branches: [main]
    paths:
      - "apps/**"
  pull_request:
    branches: [main]
    paths:
      - "apps/**"
```

**`on:`** — The trigger configuration. Defines WHAT events start this workflow.

**`push: branches: [main]`** → Run when code is **pushed to the `main` branch** (a merge from a PR, or a direct push).

**`pull_request: branches: [main]`** → Run when a **Pull Request targeting `main`** is opened, updated, or synchronized (new commit pushed to the PR branch).

**`paths: - "apps/**"`** — The **path filter**. This is critical for efficiency:

- Without it: every push to ANY file triggers the CI — even editing a README
- With it: CI only runs when something inside `apps/` changes
- `**` = recursive glob = matches any file at any depth under `apps/`

**The two-trigger pattern in DevOps:**

```
PR created/updated → CI runs (build, test, scan) → Code Review
                                                          ↓
                                               PR Approved → Merge to main
                                                          ↓
                                          Push to main → CI runs AGAIN + push to ECR + update GitOps
```

- **On PR:** Run tests and scans to gate code review. But **don't push to ECR** (we only push production images from `main`).
- **On push to `main`:** Full pipeline including ECR push and GitOps update.

---

### `concurrency:` (Lines 30–32)

```yaml
concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true
```

**`concurrency:`** — Controls what happens when multiple workflow runs are triggered for the same branch rapidly (e.g., developer pushes 3 commits in 30 seconds).

**`group: ci-${{ github.ref }}`** → Groups runs by the git ref (branch/tag). `${{ github.ref }}` evaluates to something like `refs/heads/main` or `refs/heads/feature/my-pr`. Two runs with the same group are considered competing.

**`cancel-in-progress: true`** → When a new run is queued for a group that already has a run in progress → **cancel the old run** and run the new one.

**Why?** Saves CI minutes (GitHub's paid resource). No point finishing build #203 if build #204 (newer code) already started. The latest commit is what matters.

> **For the deploy.yml, `cancel-in-progress: false`** — you NEVER cancel an in-progress deployment. Cancelling mid-deploy could leave the cluster in a broken half-deployed state.

---

### `env:` (Lines 34–35)

```yaml
env:
  AWS_REGION: us-east-1
```

**Top-level `env:`** → Workflow-level environment variables. Available to **all jobs and steps** in this workflow. `AWS_REGION` is used in multiple places — defining it once avoids repetition and makes it easy to change.

---

### `permissions:` (Lines 39–42)

```yaml
permissions:
  contents: write    # To commit updated image tags
  id-token: write    # For OIDC authentication with AWS (no access keys!)
  pull-requests: write  # To comment scan results on PRs
```

**`permissions:`** — Controls what the **`GITHUB_TOKEN`** (GitHub's auto-generated token for each workflow run) is allowed to do.

By default, GitHub Actions gets a token with broad permissions. Explicitly setting permissions follows **least privilege** — only give the pipeline what it needs:

| Permission | Why needed |
|---|---|
| `contents: write` | The last step commits changed `values.yaml` back to the repo (GitOps update) |
| `id-token: write` | **Required for OIDC.** Without this, GitHub Actions cannot generate the OIDC JWT token to exchange for AWS credentials |
| `pull-requests: write` | To post SonarQube/Trivy scan results as PR comments |

---

### `jobs:` — Job 1: `detect-changes` (Lines 45–63)

```yaml
detect-changes:
  runs-on: ubuntu-latest
  outputs:
    order-service: ${{ steps.filter.outputs.order-service }}
    user-service: ${{ steps.filter.outputs.user-service }}
    notification-service: ${{ steps.filter.outputs.notification-service }}
  steps:
    - uses: actions/checkout@v4
    - uses: dorny/paths-filter@v3
      id: filter
      with:
        filters: |
          order-service:
            - 'apps/order-service/**'
          user-service:
            - 'apps/user-service/**'
          notification-service:
            - 'apps/notification-service/**'
```

**`runs-on: ubuntu-latest`** → The type of runner (virtual machine) to use. `ubuntu-latest` = GitHub's managed Ubuntu Linux runner. This is the most common choice. GitHub manages this machine — you don't provision or maintain it.

**`outputs:`** → Job-level outputs. Values set inside this job's steps can be **passed to other jobs** that depend on it. Here, the outputs are `true` or `false` for each service.

**`uses: actions/checkout@v4`** → The most common Action in GitHub Actions. It checks out your repository's code onto the runner. Without this, the runner has an empty machine — no code.

**`uses: dorny/paths-filter@v3`** — A **third-party Action** from the GitHub Marketplace. This is new — let me explain it fully.

#### 🧠 New Concept: `dorny/paths-filter`

**What problem does it solve?**

The top-level `on.paths: "apps/**"` triggers CI if ANY file in `apps/` changes. But what if only `order-service` changed? Without paths-filter, you'd still build ALL 3 services. That's wasteful — if only `user-service/main.py` changed, why rebuild `order-service`?

**What it does:** It inspects the git diff of the current commit and sets outputs (`true`/`false`) for each defined filter. Then the `build-and-push` job matrix uses those outputs to skip unchanged services.

```yaml
filters: |
  order-service:
    - 'apps/order-service/**'
  user-service:
    - 'apps/user-service/**'
  notification-service:
    - 'apps/notification-service/**'
```

**Result (example):** Developer changed `apps/user-service/main.py`:

```
steps.filter.outputs.order-service       → "false"
steps.filter.outputs.user-service        → "true"
steps.filter.outputs.notification-service→ "false"
```

**`id: filter`** → Assigns an ID to this step so other steps/jobs can reference its outputs via `steps.filter.outputs.*`.

---

### Job 2: `build-and-push` — Strategy/Matrix (Lines 66–84)

```yaml
build-and-push:
  needs: detect-changes
  runs-on: ubuntu-latest
  strategy:
    matrix:
      service:
        - name: order-service
          changed: ${{ needs.detect-changes.outputs.order-service }}
          port: 8001
        - name: user-service
          changed: ${{ needs.detect-changes.outputs.user-service }}
          port: 8002
        - name: notification-service
          changed: ${{ needs.detect-changes.outputs.notification-service }}
          port: 8003
      exclude:
        - service:
            changed: "false"
```

**`needs: detect-changes`** → This job only starts AFTER `detect-changes` completes successfully. This creates the DAG (Directed Acyclic Graph) of job dependencies.

#### 🧠 New Concept: Matrix Strategy

**What is a matrix?** It creates multiple parallel job runs from a single job definition. Instead of writing 3 nearly-identical jobs (one per service), you define the job once and parameterize it.

```
matrix creates:
  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────────────────┐
  │  order-service  │  │  user-service   │  │  notification-service    │
  │  changed: true  │  │  changed: false │  │  changed: true           │
  │  port: 8001     │  │  port: 8002     │  │  port: 8003              │
  └─────────────────┘  └─────────────────┘  └──────────────────────────┘
         RUN                EXCLUDED                   RUN
```

Throughout the job steps, you reference matrix values as `${{ matrix.service.name }}`, `${{ matrix.service.port }}`, etc. Each parallel run substitutes its own values.

**`exclude:`** → Removes specific matrix combinations from execution:

```yaml
exclude:
  - service:
      changed: "false"
```

Any service where `changed` is `"false"` is **excluded from the matrix** — that service's entire build-and-push job is skipped. This is how the paths-filter result gates which services actually build.

---

### Steps Walkthrough (Lines 86–211)

---

#### Step 1: Checkout (Line 87–88)

```yaml
- name: Checkout code
  uses: actions/checkout@v4
```

Same as before — download the repo code onto the runner. Standard first step for every job.

---

#### Step 2: AWS OIDC Auth (Lines 93–97)

```yaml
- name: Configure AWS Credentials (OIDC)
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
    aws-region: ${{ env.AWS_REGION }}
```

**`uses: aws-actions/configure-aws-credentials@v4`** → Official AWS action. This is the action that performs the OIDC dance explained above:

1. GitHub generates a signed JWT (OIDC token) for this workflow run
2. The action sends it to AWS STS
3. AWS STS validates against the OIDC trust policy
4. Returns temporary credentials
5. Sets `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN` as environment variables for the rest of the job

**`role-to-assume: ${{ secrets.AWS_ROLE_ARN }}`** → The ARN of the IAM role to assume. Stored as a GitHub Secret (no hardcoding). Format: `arn:aws:iam::123456789012:role/github-actions-role`.

**`${{ secrets.AWS_ROLE_ARN }}`** → The `secrets` context in GitHub Actions. Secrets are encrypted values stored in GitHub repository settings → Actions secrets. They appear as `***` in logs, never in plaintext.

---

#### Step 3: ECR Login (Lines 100–102)

```yaml
- name: Login to Amazon ECR
  id: ecr-login
  uses: aws-actions/amazon-ecr-login@v2
```

**`aws-actions/amazon-ecr-login@v2`** → Official AWS action. Uses the credentials from step 2 to authenticate Docker to ECR.

Under the hood it runs: `aws ecr get-login-password | docker login --username AWS --password-stdin <ecr-url>`

**`id: ecr-login`** → This step has an ID because it produces an **output**: `registry` = the ECR registry URL (`123456789012.dkr.ecr.us-east-1.amazonaws.com`). Referenced later as `${{ steps.ecr-login.outputs.registry }}`.

---

#### Step 4: Set Up Python (Lines 105–110)

```yaml
- name: Set up Python
  uses: actions/setup-python@v5
  with:
    python-version: "3.12"
    cache: "pip"
    cache-dependency-path: apps/${{ matrix.service.name }}/requirements.txt
```

**`actions/setup-python@v5`** → Installs the specified Python version on the runner. The ubuntu-latest runner has Python pre-installed, but pinning to `"3.12"` ensures the exact version matches the Dockerfile and avoids version drift.

**`cache: "pip"`** → Caches pip's download cache between workflow runs. If `requirements.txt` hasn't changed, pip packages are served from cache instead of re-downloaded from PyPI. Can save 30–60 seconds per service per run.

**`cache-dependency-path`** → The file whose content determines if the cache is valid. If `requirements.txt` changes → cache miss → re-download. Points to the specific service's requirements, not a global one.

---

#### Step 5: Run Unit Tests (Lines 113–118)

```yaml
- name: Run tests
  run: |
    cd apps/${{ matrix.service.name }}
    pip install -r requirements.txt
    pytest tests/ -v --tb=short || true
  continue-on-error: true
```

**`run: |`** → The pipe `|` character in YAML means "multi-line string." Everything indented below runs as a shell script.

**`cd apps/${{ matrix.service.name }}`** → Change directory to the specific service being built in this matrix run. `${{ matrix.service.name }}` = `order-service`, `user-service`, or `notification-service`.

**`pip install -r requirements.txt`** → Install the service's dependencies on the runner (separate from what goes into the Docker image — these are for running the tests).

**`pytest tests/ -v --tb=short`** → Run tests:

- `-v` = verbose (print each test name)
- `--tb=short` = short traceback format on failures (less noise than full tracebacks)

**`|| true`** → Bash: "If pytest exits with non-zero (failure), still exit 0." Prevents the step from marking the job as failed.

**`continue-on-error: true`** → GitHub Actions level equivalent. Even if this step fails, the pipeline continues to the next step.

**Why allow test failures?** This is intentionally lenient during development. In a mature pipeline, you'd remove `|| true` and `continue-on-error: true` so test failures block the build. The comment says "Don't block on test failures in non-main branches" — though in this current form, it doesn't block on main either. This is a common "bootstrap" decision.

---

#### Step 6: SonarQube Analysis (Lines 123–138)

```yaml
- name: SonarQube Analysis
  if: ${{ secrets.SONAR_TOKEN != '' }}
  uses: SonarSource/sonarcloud-github-action@master
  with:
    projectBaseDir: apps/${{ matrix.service.name }}
    args: >
      -Dsonar.projectKey=kubeflow-ops-${{ matrix.service.name }}
      -Dsonar.organization=${{ secrets.SONAR_ORG }}
      -Dsonar.sources=.
      -Dsonar.tests=tests/
      -Dsonar.python.version=3.12
      -Dsonar.python.coverage.reportPaths=coverage.xml
      -Dsonar.exclusions=**/tests/**,**/venv/**,**/__pycache__/**
  env:
    SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

#### 🧠 New Concept: SonarQube / SonarCloud

**What is SonarQube?**
SonarQube is a **Static Application Security Testing (SAST)** and **code quality** platform. It analyzes your source code **without running it** and finds:

- **Bugs** — Logic errors, null pointer risks, resource leaks
- **Security Vulnerabilities** — SQL injection patterns, hardcoded credentials, insecure dependencies
- **Code Smells** — Duplicate code, overly complex functions, poor naming
- **Code Coverage** — What percentage of code is covered by tests

**SonarCloud** = the cloud/SaaS version of SonarQube. The self-hosted version needs a server (Phase 11 or optional). SonarCloud is hosted by Sonarsource — just sign up and connect your GitHub.

**The concept of "Shift-Left Security":**

```
Old way: Code → Build → Deploy → Security Scan → Fix → Redeploy (expensive!)
New way: Code → Security Scan → Build → Deploy (catch issues before they ship)
```

Running SonarQube **in CI, before building the Docker image** is "shifting security left." Issues are caught when they're cheapest to fix.

**`if: ${{ secrets.SONAR_TOKEN != '' }}`** → **Conditional step.** Only runs if the SonarQube secret is configured. If you haven't set up SonarCloud yet, this step is silently skipped. Allows the pipeline to be useful even before SonarCloud is configured.

**`uses: SonarSource/sonarcloud-github-action@master`** → Official SonarCloud action. Runs the SonarScanner tool against your code and uploads results to SonarCloud.

**`args: >`** → The `>` is YAML's **folded scalar** — multi-line string where newlines become spaces. The `-D` flags are SonarQube Scanner arguments:

| Arg | What it sets |
|---|---|
| `-Dsonar.projectKey=kubeflow-ops-order-service` | Unique identifier for this project in SonarCloud |
| `-Dsonar.organization=${{ secrets.SONAR_ORG }}` | Your SonarCloud organization name |
| `-Dsonar.sources=.` | Analyze all source in the `projectBaseDir` |
| `-Dsonar.tests=tests/` | Tell Sonar where test files are (excluded from main analysis) |
| `-Dsonar.python.version=3.12` | Use Python 3.12 analysis rules |
| `-Dsonar.python.coverage.reportPaths=coverage.xml` | Where to find the code coverage report |
| `-Dsonar.exclusions=**/tests/**,...` | Don't analyze test files, venvs, pycache for code quality |

**`GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}`** → `GITHUB_TOKEN` is a **special secret automatically provided by GitHub** — you don't set it manually. SonarCloud uses it to post analysis results as Pull Request comments/annotations.

---

#### Step 7: SonarQube Quality Gate (Lines 141–146)

```yaml
- name: SonarQube Quality Gate
  if: ${{ secrets.SONAR_TOKEN != '' }}
  uses: SonarSource/sonarqube-quality-gate-action@master
  timeout-minutes: 5
  env:
    SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

**`sonarqube-quality-gate-action`** → After SonarCloud analyzes the code, this action **polls SonarCloud for the Quality Gate result**. The Quality Gate is a pass/fail threshold you define in SonarCloud:

From `sonar-project.properties` (line 35-39):

```
# Quality gate — fail if:
#   - Code coverage < 70%
#   - Duplicated lines > 3%
#   - Any critical or blocker bugs
#   - Any critical security vulnerabilities
```

If any condition fails → this step fails → the entire CI job fails → the PR cannot be merged. **This is the hard gate**: no code merges to `main` if it fails SonarQube.

**`timeout-minutes: 5`** → If SonarCloud takes more than 5 minutes to return the result, the step times out (rather than hanging forever).

---

#### Step 8: Build Docker Image (Lines 149–157)

```yaml
- name: Build Docker image
  env:
    ECR_REGISTRY: ${{ steps.ecr-login.outputs.registry }}
    IMAGE_TAG: ${{ github.sha }}
  run: |
    docker build \
      -t $ECR_REGISTRY/kubeflow-ops-${{ matrix.service.name }}:$IMAGE_TAG \
      -t $ECR_REGISTRY/kubeflow-ops-${{ matrix.service.name }}:latest \
      apps/${{ matrix.service.name }}/
```

**`env:` inside a step** → Step-level environment variables (available only to this step).

**`ECR_REGISTRY: ${{ steps.ecr-login.outputs.registry }}`** → The ECR registry URL from the ECR login step output. Example: `123456789012.dkr.ecr.us-east-1.amazonaws.com`.

**`IMAGE_TAG: ${{ github.sha }}`** → The **git commit SHA**. This is the most important tagging strategy in production:

```
github.sha example: a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0
```

**Why use the git SHA as the image tag?**

| Strategy | Problem |
|---|---|
| `:latest` | You can't tell which code is in production. Rolling back is impossible |
| `:v1.2.3` | Requires manual version bumping. Error-prone. |
| `:git-sha` | ✅ Immutable, traceable. You can look at the tag and find the exact commit in git |

**`-t ... :$IMAGE_TAG`** → Tag the image with the full git SHA (unique, immutable).

**`-t ... :latest`** → Also tag it with `latest`. This is for convenience — developers can pull `:latest` to get the most recent build. But **deployments always use the SHA tag**, never `:latest`.

**`docker build ... apps/${{ matrix.service.name }}/`** → Builds using the service's directory as the build context (same as Phase 2 — Docker reads the `Dockerfile` from that path).

---

#### Step 9: Trivy Scan (Lines 160–166)

```yaml
- name: Scan image with Trivy
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: ${{ steps.ecr-login.outputs.registry }}/kubeflow-ops-${{ matrix.service.name }}:${{ github.sha }}
    format: "table"
    severity: "HIGH,CRITICAL"
    exit-code: "0"
```

#### 🧠 New Concept: Trivy (Container Vulnerability Scanner)

**What is Trivy?**
Trivy is an open-source **vulnerability scanner** by Aqua Security. It scans:

- **Container images** — Finds known CVEs (Common Vulnerabilities and Exposures) in OS packages and language libraries inside the image
- **Filesystem/Code** — Scans IaC files (Terraform, Kubernetes YAML) for misconfigurations
- **Git repositories** — Scans for secrets accidentally committed

**How it works for containers:**

```
Docker Image
  │
  ├── OS layer (Debian/slim) → cross-referenced against CVE databases
  │     (NVD, GitHub Advisory, Alpine SecDB, etc.)
  │
  └── Python packages layer (from requirements.txt)
        → cross-referenced against OSV (Open Source Vulnerability DB)
        
Result: List of vulnerabilities with severity (LOW, MEDIUM, HIGH, CRITICAL)
```

**`image-ref:`** → The image to scan. References the locally-built image (pushed to ECR or just locally tagged).

**`format: "table"`** → Output as a human-readable table in the CI logs. Alternative: `json`, `sarif` (for GitHub Security tab integration).

**`severity: "HIGH,CRITICAL"`** → Only report vulnerabilities of HIGH or CRITICAL severity. LOW and MEDIUM are ignored for now (too much noise). DevSecOps principle: focus on critical risks first.

**`exit-code: "0"`** → **Even if vulnerabilities are found, don't fail the pipeline.** This is intentionally lenient (same philosophy as the test step). In a stricter pipeline, you'd set this to `"1"` — any HIGH/CRITICAL CVE fails the build and blocks the merge.

**The DevSecOps progression:**

```
Day 1 (today): exit-code: "0" — see what you have
Week 2: Fix the HIGH/CRITICAL CVEs
Day 30: exit-code: "1" — now hard-gate on CVEs
```

---

#### Step 10: Push to ECR (Lines 169–177)

```yaml
- name: Push to ECR
  if: github.ref == 'refs/heads/main'
  env:
    ECR_REGISTRY: ${{ steps.ecr-login.outputs.registry }}
    IMAGE_TAG: ${{ github.sha }}
  run: |
    docker push $ECR_REGISTRY/kubeflow-ops-${{ matrix.service.name }}:$IMAGE_TAG
    docker push $ECR_REGISTRY/kubeflow-ops-${{ matrix.service.name }}:latest
    echo "✅ Pushed: $ECR_REGISTRY/kubeflow-ops-${{ matrix.service.name }}:$IMAGE_TAG"
```

**`if: github.ref == 'refs/heads/main'`** → **Conditional step.** Only push to ECR when on the `main` branch. On PRs (`github.ref` = `refs/pull/123/merge`), this step is skipped.

**Why?** You don't want every PR to push images to your production ECR registry. Only merged, reviewed code becomes a "real" image.

`docker push` uploads both tags to ECR:

- The SHA-tagged image (permanent, immutable artifact)
- `:latest` (convenience pointer, overwritten each time)

---

#### Step 11: Install `yq` (Lines 180–184)

```yaml
- name: Install yq
  if: github.ref == 'refs/heads/main'
  run: |
    sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
    sudo chmod +x /usr/local/bin/yq
```

#### 🧠 New Concept: `yq`

**What is `yq`?**
`yq` is a command-line YAML processor — like `jq` (which processes JSON) but for YAML. It lets you read and write YAML files from shell scripts without writing Python/Ruby code.

**Installation:**

- `wget -qO /usr/local/bin/yq <url>` → Download the binary from GitHub releases, save it directly to `/usr/local/bin/yq` (`-q` = quiet, `-O` = output file)
- `chmod +x` → Make it executable (Linux file permission)
- `sudo` → Required because `/usr/local/bin` is a system directory

**Why not use `apt-get install yq`?** The apt version is often outdated. The GitHub releases always have the latest version with consistent behavior.

**The `yq` command you'll see next:**

```bash
yq -i ".image.tag = \"abc1234\"" file.yaml
```

- `-i` = in-place edit (modify the file directly, like `sed -i`)
- `.image.tag` = YAML path selector (dot notation = nested keys)
- `= "abc1234"` = set the value

---

#### Step 12: Update Helm Values (GitOps Commit) (Lines 189–211)

```yaml
- name: Update image tag in Helm values
  if: github.ref == 'refs/heads/main'
  env:
    IMAGE_TAG: ${{ github.sha }}
    ECR_REGISTRY: ${{ steps.ecr-login.outputs.registry }}
  run: |
    VALUES_FILE="gitops/apps/${{ matrix.service.name }}/values.yaml"
    FULL_IMAGE="$ECR_REGISTRY/kubeflow-ops-${{ matrix.service.name }}"

    echo "🔄 Updating $VALUES_FILE"
    echo "   image.repository: $FULL_IMAGE"
    echo "   image.tag: $IMAGE_TAG"

    yq -i ".image.repository = \"$FULL_IMAGE\"" "$VALUES_FILE"
    yq -i ".image.tag = \"$IMAGE_TAG\"" "$VALUES_FILE"

    git config user.name "github-actions[bot]"
    git config user.email "github-actions[bot]@users.noreply.github.com"
    git add gitops/
    git commit -m "ci: update ${{ matrix.service.name }} image to $IMAGE_TAG" || echo "No changes"
    git push
```

**This is the GitOps trigger — the most important step.**

**`VALUES_FILE="gitops/apps/${{ matrix.service.name }}/values.yaml"`**
→ The Helm values file for the specific service. Example: `gitops/apps/order-service/values.yaml`.

**`yq -i ".image.repository = \"$FULL_IMAGE\"" "$VALUES_FILE"`**
→ Sets `image.repository` in the YAML file to the full ECR image path.

**`yq -i ".image.tag = \"$IMAGE_TAG\"" "$VALUES_FILE"`**
→ Sets `image.tag` in the YAML file to the git SHA.

**After these two lines, `values.yaml` now looks like:**

```yaml
image:
  repository: 123456789012.dkr.ecr.us-east-1.amazonaws.com/kubeflow-ops-order-service
  tag: a1b2c3d4e5f6...
```

**`git config user.name "github-actions[bot]"`** → Configures git identity for the commit. `github-actions[bot]` is the standard identity for automated commits. Without this, git refuses to commit (no identity set on the runner).

**`git add gitops/`** → Stage the changed `values.yaml` file.

**`git commit -m "ci: update order-service image to a1b2c3d..."` `|| echo "No changes"`**
→ Commit. The `|| echo "No changes"` handles the edge case where the same SHA is being deployed again — git commit fails if there's nothing to commit, which would fail the pipeline. `|| echo "No changes"` makes it exit 0 in that case.

**`git push`** → Pushes the commit back to the repo. This requires `contents: write` permission (set at the top).

**The full GitOps chain:**

```
git push → CI runs → docker push to ECR → yq updates values.yaml → git commit + push
                                                       ↓
                                          ArgoCD detects values.yaml changed
                                                       ↓
                                          ArgoCD renders Helm chart with new image tag
                                                       ↓
                                          Kubernetes rolling update → new pod, old pod gone
```

---

## 📄 File 2: `.github/workflows/deploy.yml` — Line by Line (CD Pipeline)

---

### The Key Difference: `workflow_dispatch` (Lines 15–42)

```yaml
on:
  workflow_dispatch:
    inputs:
      service:
        description: "Service to deploy"
        required: true
        type: choice
        options:
          - order-service
          - user-service
          - notification-service
      image_tag:
        description: "Image tag to deploy (git SHA from CI build)"
        required: true
        type: string
      environment:
        description: "Target environment"
        required: true
        type: choice
        options:
          - dev
          - staging
          - prod
      skip_smoke_test:
        description: "Skip smoke test (emergency deploys only)"
        required: false
        type: boolean
        default: false
```

**`workflow_dispatch:`** → This workflow is **manually triggered** — it does NOT run automatically on push. A human must go to the GitHub Actions tab, find this workflow, click "Run workflow," and fill in parameters.

**`inputs:`** → The input form fields shown to the user when they click "Run workflow":

| Input | Type | Purpose |
|---|---|---|
| `service` | `choice` (dropdown) | Which microservice to deploy |
| `image_tag` | `string` | The exact git SHA to deploy (from a previous CI run) |
| `environment` | `choice` (dropdown) | `dev`, `staging`, or `prod` |
| `skip_smoke_test` | `boolean` (checkbox) | Emergency bypass for smoke tests |

**Why manual CD instead of automatic?** The CI workflow auto-deploys to EKS via GitOps/ArgoCD (Phase 7). This `deploy.yml` is for **controlled manual promotion** — e.g., "promote this exact SHA to production." It gives you control when you need it.

---

### `concurrency:` (Lines 45–47)

```yaml
concurrency:
  group: deploy-${{ github.event.inputs.environment }}
  cancel-in-progress: false
```

**`cancel-in-progress: false`** → Do NOT cancel in-progress deployments. If someone accidentally triggers a second deploy to `prod` while one is running, the second one WAITS — it doesn't kill the first one mid-deploy. Preserves cluster stability.

---

### Job 1: `preflight` — Verify Image Exists in ECR (Lines 59–76)

```yaml
preflight:
  name: Pre-flight — Verify Image Exists
  runs-on: ubuntu-latest
  steps:
    - name: Configure AWS Credentials (OIDC)
      ...
    - name: Verify image exists in ECR
      run: |
        echo "🔍 Checking ECR for: kubeflow-ops-${{ inputs.service }}:${{ inputs.image_tag }}"
        aws ecr describe-images \
          --repository-name kubeflow-ops-${{ inputs.service }} \
          --image-ids imageTag=${{ inputs.image_tag }} \
          --region ${{ env.AWS_REGION }}
        echo "✅ Image verified in ECR"
```

**`inputs.service`** → Refers to the `workflow_dispatch` input. Note: `inputs.` not `github.event.inputs.` — both work, `inputs.` is the newer cleaner syntax.

**`aws ecr describe-images`** → AWS CLI command. Fetches metadata of a specific image in ECR. **If the image doesn't exist, this command exits with a non-zero code → step fails → pipeline stops.** This prevents deploying an image SHA that doesn't exist in ECR (typo in input, image never built, etc.).

This is the **pre-flight check** — fly the plane only if you've verified the fuel tank has the fuel you think it does.

---

### Job 2: `approval` — Production Gate (Lines 79–91)

```yaml
approval:
  name: Production Approval
  needs: preflight
  if: ${{ github.event.inputs.environment == 'prod' }}
  runs-on: ubuntu-latest
  environment: production  # GitHub Environment with required reviewers
  steps:
    - name: Approval received
      run: |
        echo "✅ Production deployment approved by: ${{ github.actor }}"
        echo "Service: ${{ inputs.service }}"
        echo "Tag: ${{ inputs.image_tag }}"
        echo "Time: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
```

**`if: ${{ github.event.inputs.environment == 'prod' }}`** → This entire job only runs if the target environment is `prod`. For `dev`/`staging`, this job is skipped.

**`environment: production`** → THIS is where the magic happens.

#### 🧠 New Concept: GitHub Environments & Required Reviewers

**GitHub Environments** are a feature that lets you define deployment targets (`dev`, `staging`, `production`) and configure protection rules for each:

- **Required Reviewers** — Specify GitHub users/teams who must approve before the job runs
- **Wait Timer** — Delay deployment by N minutes
- **Deployment Branch Rules** — Only allow from specific branches

**How it works:**

```
deploy.yml triggers → approval job starts → 
GitHub sees: environment: production → 
GitHub pauses the job → 
Sends notification to required reviewers →
Reviewer sees: "This job needs your approval" →
Reviewer clicks "Approve" →
Job resumes and runs
```

**The step itself** (`echo "✅ Production approved...`) just logs who approved (identified by `${{ github.actor }}` = the reviewer's GitHub username) and when. The real control is the GitHub Environment configuration, not the shell command.

**This is a mandatory approval gate for prod — ZERO way to bypass it from the pipeline** (unless someone removes the environment protection rules, which requires admin access).

---

### Job 3: `deploy` (Lines 93–149)

```yaml
deploy:
  name: Deploy to ${{ github.event.inputs.environment }}
  needs: [preflight, approval]
  if: |
    always() &&
    needs.preflight.result == 'success' &&
    (needs.approval.result == 'success' || needs.approval.result == 'skipped')
```

**`needs: [preflight, approval]`** → Depends on both.

**`if: always() && ...`** — Complex conditional:

- **`always()`** → Evaluate this condition even if a previous job was skipped (without `always()`, a skipped dependency makes the whole `if` fail)
- `needs.preflight.result == 'success'` → Pre-flight must pass
- `needs.approval.result == 'success' || needs.approval.result == 'skipped'` → Approval either passed (prod) OR was skipped (dev/staging — approval job's `if` was false). This is the key pattern: **deploy runs whether approval was needed or not**.

---

#### Configure kubectl (Lines 116–120)

```yaml
- name: Configure kubectl
  run: |
    aws eks update-kubeconfig \
      --name ${{ env.CLUSTER_PREFIX }}-${{ inputs.environment }} \
      --region ${{ env.AWS_REGION }}
```

**`aws eks update-kubeconfig`** → AWS CLI command that generates/updates the `~/.kube/config` file (the kubeconfig) on the runner with credentials to talk to the specified EKS cluster. After this, all `kubectl` and `helm` commands target that cluster.

**`--name kubeflow-ops-dev`** (or staging/prod) → The EKS cluster name (matches Terraform provisioned cluster name from Phase 5).

---

#### Install Helm (Lines 122–125)

```yaml
- name: Install Helm
  uses: azure/setup-helm@v3
  with:
    version: "v3.14.0"
```

**`azure/setup-helm@v3`** → Microsoft's official Helm setup action (despite "azure" in the name, works for any Kubernetes). Installs Helm CLI version `v3.14.0` on the runner. Pinning to a specific version ensures consistent behavior.

---

#### Deploy with Helm (Lines 127–149)

```yaml
- name: Deploy with Helm
  env:
    ECR_REGISTRY: ${{ steps.ecr-login.outputs.registry }}
  run: |
    FULL_IMAGE="$ECR_REGISTRY/kubeflow-ops-${{ inputs.service }}"
    ENV="${{ inputs.environment }}"

    helm upgrade --install ${{ inputs.service }} \
      gitops/charts/microservice/ \
      --namespace kubeflow-ops \
      --create-namespace \
      -f gitops/apps/${{ inputs.service }}/values.yaml \
      -f gitops/apps/${{ inputs.service }}/values-${ENV}.yaml \
      --set image.repository="$FULL_IMAGE" \
      --set image.tag="${{ inputs.image_tag }}" \
      --wait \
      --timeout 5m
```

**`helm upgrade --install`** → The core Helm deployment command. Breaking down every flag:

| Flag | Meaning |
|---|---|
| `upgrade --install` | If the release exists → upgrade it. If not → install it. Single command for both cases. |
| `${{ inputs.service }}` | The Helm release name (e.g., `order-service`) |
| `gitops/charts/microservice/` | Path to the Helm chart directory |
| `--namespace kubeflow-ops` | Deploy into this Kubernetes namespace |
| `--create-namespace` | Create the namespace if it doesn't exist (idempotent) |
| `-f gitops/apps/order-service/values.yaml` | Base values file (defaults) |
| `-f gitops/apps/order-service/values-dev.yaml` | Environment-specific overrides (replicas, resources) |
| `--set image.repository="..."` | Override inline: the ECR image path |
| `--set image.tag="..."` | Override inline: the specific SHA tag |
| `--wait` | Wait for all pods to become Ready before reporting success |
| `--timeout 5m` | If pods aren't ready in 5 minutes → fail the deploy |

**`-f` flag layering** — Values are merged in order (later overrides earlier):

```
values.yaml          (base defaults for all environments)
  + values-dev.yaml  OR values-prod.yaml (environment-specific)
  + --set flags      (inline overrides from CLI — highest priority)
```

---

### Job 4: `smoke-test` (Lines 152–203)

```yaml
smoke-test:
  needs: deploy
  if: ${{ github.event.inputs.skip_smoke_test != 'true' }}
```

**`skip_smoke_test`** → The emergency bypass input. If someone checks "Skip smoke test" when triggering the workflow, this job is skipped. Should only be used in genuine emergencies (hotfix that can't wait for tests).

**The smoke test logic (Lines 170–203):**

```bash
sleep 15  # Wait for LB to update
```

→ Waits 15 seconds for the AWS Load Balancer to register the new pods. LB health checks have a propagation delay.

```bash
SERVICE_URL=$(kubectl get svc ${{ inputs.service }} \
  -n kubeflow-ops \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || \
  kubectl get svc ${{ inputs.service }} \
  -n kubeflow-ops \
  -o jsonpath='{.spec.clusterIP}')
```

→ Gets the service endpoint. Tries the LoadBalancer hostname first (if it has an external LB), falls back to ClusterIP (if it's internal-only). `jsonpath` is Kubernetes's built-in query language for extracting specific fields from resource YAML.

```bash
HEALTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  "http://${SERVICE_URL}/healthz" --max-time 10 || echo "000")
```

→ Hits the `/healthz` endpoint with curl:

- `-s` = silent (no progress output)
- `-o /dev/null` = discard the response body
- `-w "%{http_code}"` = write only the HTTP status code to stdout
- `--max-time 10` = 10 second timeout

```bash
if [ "${HEALTH_STATUS}" != "200" ]; then
  echo "❌ Smoke test FAILED (HTTP ${HEALTH_STATUS})"
  echo "🔄 Rolling back deployment..."
  kubectl rollout undo deployment/${{ inputs.service }} -n kubeflow-ops
  kubectl rollout status deployment/${{ inputs.service }} -n kubeflow-ops --timeout=300s
  echo "✅ Rollback complete"
  exit 1
fi
```

→ **Auto-rollback on failure.** If `/healthz` doesn't return `200`:

- `kubectl rollout undo deployment/order-service -n kubeflow-ops` → Kubernetes reverts to the PREVIOUS deployment revision (the last known good version)
- `kubectl rollout status ... --timeout=300s` → Waits up to 5 minutes for the rollback to complete and all old pods to be back
- `exit 1` → Fail the pipeline (marks the deployment as failed in GitHub)

**This is one of the most valuable DevSecOps patterns**: automatic rollback means a bad deployment self-heals within ~30 seconds of detection.

---

### Job 5: `notify` (Lines 206–237)

```yaml
notify:
  needs: [deploy, smoke-test]
  if: always()
  steps:
    - name: Notify Slack
      if: ${{ secrets.SLACK_WEBHOOK_URL != '' }}
      run: |
        COLOR="#00FF00"  # green on success
        STATUS="✅ SUCCESS"
        # or
        COLOR="#FF0000"  # red on failure
        STATUS="❌ FAILED"
        
        curl -X POST "${{ secrets.SLACK_WEBHOOK_URL }}" \
          -H 'Content-Type: application/json' \
          -d "{...}"
```

#### 🧠 New Concept: Slack Incoming Webhooks

**Slack Incoming Webhook** = A URL that, when you POST JSON to it, sends a message to a specific Slack channel. No Slack API token or bot setup needed — just a URL.

Setup: Slack → Apps → Incoming Webhooks → Add to channel → Copy webhook URL → Store in GitHub Secret `SLACK_WEBHOOK_URL`.

**`if: always()`** → This job runs **regardless of whether `deploy` or `smoke-test` succeeded or failed**. That's intentional — you want Slack notifications for BOTH success AND failure.

**The JSON payload** sends an "attachment" (Slack's rich message format) with:

- Color indicator (green/red)
- Service name, image tag, environment, who triggered it

**`|| true`** at the end of the curl command → If Slack is unreachable (Slack outage), the notification failure doesn't fail the pipeline.

---

## 📄 File 3: `.github/workflows/terraform.yml` — Full Walkthrough

This is phase 4c — it ties Terraform (Phase 5) into CI but is simpler than the other two.

---

### Trigger (Lines 10–19)

```yaml
on:
  push:
    branches: [main]
    paths:
      - 'terraform/**'
  pull_request:
    branches: [main]
    paths:
      - 'terraform/**'
  workflow_dispatch:  # Allow manual triggering
```

Only runs when `terraform/**` files change. The `workflow_dispatch` allows a human to manually run `terraform apply` without making a fake commit.

---

### `defaults:` (Lines 34–36)

```yaml
defaults:
  run:
    working-directory: ${{ env.TF_WORKING_DIR }}
```

**`defaults.run.working-directory`** → Sets the default working directory for ALL `run:` steps in this job. Every `run:` command will execute from `terraform/environments/dev` without needing `cd` in each step. Set once, applies everywhere.

---

### Terraform Steps (Lines 53–102)

#### Format Check (Lines 54–56)

```yaml
- name: Terraform Format Check
  run: terraform fmt -check -recursive ../../terraform/
  continue-on-error: true
```

**`terraform fmt -check`** → Checks if all `.tf` files are formatted according to Terraform's canonical style. `-check` = don't change files, just report. `-recursive` = check all subdirectories. `continue-on-error: true` = format issues are warnings, not blockers (yet).

#### Init (Lines 59–60)

```yaml
- name: Terraform Init
  run: terraform init -input=false
```

**`terraform init`** → Downloads providers (AWS plugin), initializes the S3 backend (connects to state bucket). `-input=false` = never prompt for input (CI must be non-interactive).

#### Validate (Lines 63–64)

```yaml
- name: Terraform Validate
  run: terraform validate
```

**`terraform validate`** → Syntax + schema check. Verifies all resources and arguments are valid against the provider schema. Does NOT contact AWS — purely local validation.

#### Trivy IaC Scan (Lines 67–73)

```yaml
- name: Scan Terraform with Trivy
  uses: aquasecurity/trivy-action@master
  with:
    scan-type: 'config'
    scan-ref: 'terraform/'
    format: 'table'
    severity: 'HIGH,CRITICAL'
```

Trivy can also scan **Infrastructure as Code** files (not just container images). `scan-type: 'config'` triggers the IaC scanner which checks for:

- S3 buckets without encryption
- Security groups open to the world (0.0.0.0/0)
- RDS databases without encryption at rest
- EKS clusters with public endpoints
- Missing logging configurations

**Same tool (Trivy), different mode** — shows how Trivy is used across the pipeline for both image scanning (ci.yml) and IaC scanning (terraform.yml).

#### Plan + PR Comment (Lines 76–97)

```yaml
- name: Terraform Plan
  id: plan
  run: terraform plan -input=false -no-color -out=tfplan
  continue-on-error: true

- name: Comment Plan on PR
  if: github.event_name == 'pull_request'
  uses: actions/github-script@v7
  with:
    script: |
      const output = `### Terraform Plan 📐
      \`\`\`
      ${{ steps.plan.outputs.stdout }}
      \`\`\`
      *Triggered by @${{ github.actor }}*`;
      github.rest.issues.createComment({
        issue_number: context.issue.number,
        owner: context.repo.owner,
        repo: context.repo.repo,
        body: output
      })
```

**`terraform plan -out=tfplan`** → Runs the plan and saves it to a file `tfplan`. Saving the plan is critical: the `apply` step later uses this exact file — guarantees what was reviewed is exactly what gets applied.

**`-no-color`** → Removes ANSI color codes from the output. In a Markdown code block (PR comment), color codes appear as garbage characters.

**`actions/github-script@v7`** → An action that runs JavaScript with the GitHub API client pre-loaded. Here it creates a PR comment containing the full `terraform plan` output.

- `steps.plan.outputs.stdout` → The captured stdout of the plan step
- `github.rest.issues.createComment(...)` → GitHub API call to post a comment on the Pull Request

**The result:** When a developer opens a PR that changes Terraform → the bot posts a comment showing exactly what AWS infrastructure will be created/changed/destroyed. Reviewers can review infrastructure changes without running Terraform locally.

#### Apply (Lines 99–102)

```yaml
- name: Terraform Apply
  if: github.ref == 'refs/heads/main' && github.event_name == 'push'
  run: terraform apply -auto-approve -input=false tfplan
```

**`terraform apply -auto-approve`** → Applies the saved plan without prompting "yes/no". Only runs on pushes to `main` (merges) — NOT on PRs or `workflow_dispatch`.

**`tfplan`** → Uses the exact plan file saved during the plan step. This is important: it means what was reviewed in the PR comment is exactly what gets applied.

---

## 📄 File 4: `sonarqube/sonar-project.properties`

This is the **fallback configuration** file for when someone runs SonarQube manually from their local machine. In CI, the `-D` flags in `ci.yml` override these values per-service.

```properties
Line 6: sonar.projectKey=kubeflow-ops-order-service
```

→ Unique identifier in SonarCloud. Format: `<org>-<service>`.

```properties
Line 15: sonar.language=py
```

→ Tell Sonar: analyze as Python.

```properties
Lines 22-27: sonar.exclusions=
    **/venv/**,
    **/node_modules/**,
    **/__pycache__/**,
    **/tests/**,
    **/migrations/**
```

→ Don't count test files or venvs in the code quality metrics. Same philosophy as `.dockerignore` — exclude dev-only files from production analysis.

```properties
Lines 35-39: # Quality gate — fail if:
#   - Code coverage < 70%
#   - Duplicated lines > 3%
#   - Any critical or blocker bugs
#   - Any critical security vulnerabilities
```

These are comments defining the Quality Gate thresholds — you configure these in the SonarCloud web UI, not in this file. The comments are documentation of what was configured.

---

## 🔑 Key DevOps Takeaways from Phase 4

| Concept | What You Applied |
|---|---|
| **OIDC instead of static keys** | Zero long-lived credentials in GitHub Actions → eliminates a whole class of credential leak incidents |
| **paths-filter** | Only rebuild changed services → saves CI minutes, faster feedback |
| **Matrix strategy** | One job definition, N parallel runs → DRY principle in CI |
| **Git SHA as image tag** | Immutable, traceable image tagging → know exactly what's in production at all times |
| **Trivy (image + IaC scan)** | Vulnerability scanning before code ships, and before infra applies |
| **SonarQube Quality Gate** | Hard gate on code quality — broken code can't merge to `main` |
| **GitOps commit via yq** | CI auto-updates `values.yaml` → ArgoCD detects → deploys. Zero manual kubectl |
| **Prod approval gate** | GitHub Environments + required reviewers → mandatory human approval for production |
| **Auto-rollback on smoke test fail** | Bad deploys self-heal in <60 seconds |
| **Terraform plan as PR comment** | Infrastructure changes reviewed before they happen |
| **Concurrency groups** | Cancel stale builds (CI), never cancel deploys (CD) |

---

## ✅ Phase 4 Complete — What's Next

You now have **fully automated CI/CD**:

- ✅ Every `git push` → build, test, scan, push to ECR, update GitOps
- ✅ Manual deployments with approval gates and smoke tests
- ✅ Terraform changes reviewed before apply

But the CI pipeline references ECR repositories, an EKS cluster, an S3 state bucket, and DynamoDB lock table — **none of which exist yet**. That's **Phase 5: Terraform** — where you provision ALL the AWS infrastructure those pipelines are trying to use. 🚀

### User Input

You didnt exlpina about helm or u will do it in later phase ?

### Planner Response

## 🧠 What is Helm? (Context for Phase 4)

### The Problem Helm Solves

You know Kubernetes uses YAML files to deploy things. A basic deployment of `order-service` to Kubernetes requires at minimum:

```
Deployment.yaml     → defines the pod, image, replicas, env vars
Service.yaml        → defines networking (how to reach the pod)
HPA.yaml            → defines auto-scaling rules
ConfigMap.yaml      → shared config
```

Now multiply by 3 services × 3 environments (dev, staging, prod):

```
3 services × 4 files × 3 environments = 36 YAML files
```

And 90% of the content is **identical** — only things like `replicas`, `image tag`, `resource limits`, and `namespace` change between environments.

Managing 36 nearly-identical YAMLs is a maintenance nightmare. Change a label? Update it in 36 places.

---

### What Helm IS

**Helm is a package manager + templating engine for Kubernetes.** Think of it like:

- `apt`/`yum` for Linux → Helm for Kubernetes
- A template engine like Jinja2, but the output is Kubernetes YAML

**The three core concepts:**

| Concept | What it is | Analogy |
|---|---|---|
| **Chart** | A directory of templates + default values | An `.rpm` or `.deb` package |
| **Values** | The variables that customize the chart | Config file for the package |
| **Release** | A deployed instance of a chart in a cluster | An installed application |

---

### How It Works (Simplified)

```
gitops/charts/microservice/        ← ONE chart for ALL 3 services
├── templates/
│   ├── deployment.yaml  ← has {{ .Values.image.tag }}, {{ .Values.replicas }}
│   ├── service.yaml     ← has {{ .Values.service.port }}
│   └── hpa.yaml         ← has {{ .Values.hpa.maxReplicas }}
└── values.yaml          ← defaults: replicas: 1, image.tag: latest

gitops/apps/order-service/
├── values.yaml          ← CI writes: image.tag: a1b2c3... (the git SHA)
└── values-prod.yaml     ← prod overrides: replicas: 3, resources: high
```

When you run:

```bash
helm upgrade --install order-service gitops/charts/microservice/ \
  -f gitops/apps/order-service/values.yaml \
  -f gitops/apps/order-service/values-prod.yaml \
  --set image.tag="a1b2c3..."
```

Helm does this internally:

```
template + merged values → rendered Kubernetes YAML → kubectl apply
```

The `{{ .Values.image.tag }}` in the template becomes `a1b2c3...` in the final output. You get correct, environment-specific Kubernetes YAML without ever duplicating the structure.

---

### Why `helm upgrade --install` in deploy.yml Makes Sense Now

```bash
helm upgrade --install order-service \   # release name
  gitops/charts/microservice/ \          # chart (ONE template for all services)
  -f gitops/apps/order-service/values.yaml \       # base values
  -f gitops/apps/order-service/values-dev.yaml \   # env override
  --set image.tag="${{ inputs.image_tag }}"         # runtime override from CI
  --wait          # wait for pods to be Ready
  --timeout 5m    # give up after 5 min
```

- **Same chart** used for `order-service`, `user-service`, `notification-service` — only values differ
- `-f` files layer on top of each other (later overrides earlier)
- `--set` is the highest-priority override — what CI injects at runtime
- `--wait` is what makes the smoke test step meaningful — Helm confirms pods are live before declaring success

---

**Everything else about Helm** — the `Chart.yaml`, `_helpers.tpl`, `deployment.yaml` template syntax, `HPA`, and values file structure — will all be covered **line by line in Phase 6** where the actual files are. By then you'll have the right infrastructure (Phase 5 Terraform/EKS) as the mental foundation too.

Ready to move on to Phase 5 (Terraform) whenever you are! 🚀

### User Input

Lets Do Phase 5

# 🏗️ Phase 5 — Terraform: Infrastructure as Code (Deep-Dive)

> **Your job as a DevOps Engineer in Phase 5:** You provision ALL cloud infrastructure on AWS using Terraform. No clicking in the AWS Console — ever. Every resource is defined as code, version-controlled in Git, reviewed on PRs, and applied automatically by the CI pipeline you built in Phase 4.

---

## 🧠 Concepts You Must Understand First

### The Terraform Module Pattern

You already know Terraform basics. This project uses the **module pattern** — the professional way to organize Terraform code at scale:

```
terraform/
├── modules/          ← Reusable building blocks (each module = one AWS concern)
│   ├── vpc/
│   ├── eks/
│   ├── ecr/
│   ├── rds/
│   ├── elasticache/
│   ├── sqs/
│   ├── irsa/
│   ├── sns/
│   └── cloudwatch/
└── environments/
    └── dev/          ← Calls the modules, passes environment-specific values
        ├── backend.tf
        ├── main.tf
        └── outputs.tf
```

**The analogy:** Modules are like **functions** in programming. The [environments/dev/main.tf](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/environments/dev/main.tf:0:0-0:0) is like `main()` — it calls each function (module) with specific arguments. If you add a `staging` or `prod` environment later, it's just a new folder in `environments/` that calls the same modules with different values (bigger instances, multi-AZ, etc.).

### The Three File Types in Every Module

Every module has the same 3 files:

| File | Purpose |
|---|---|
| [variables.tf](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/modules/vpc/variables.tf:0:0-0:0) | Declares **inputs** — what the caller must/can pass in |
| [main.tf](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/modules/sns/main.tf:0:0-0:0) | The actual resources to create |
| [outputs.tf](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/modules/vpc/outputs.tf:0:0-0:0) | Declares **outputs** — values the caller can use after apply |

The data flows like this:

```
environments/dev/main.tf
  │
  ├── module "vpc" { project_name = "kubeflow-ops" }  ← passes inputs
  │         ↓
  │    modules/vpc/variables.tf  (receives inputs)
  │    modules/vpc/main.tf       (creates resources)
  │    modules/vpc/outputs.tf    (exposes vpc_id, subnet_ids)
  │         │
  └── module "eks" { vpc_id = module.vpc.vpc_id }  ← uses vpc output as eks input
```

### The Provision Order (Dependency Chain)

```
backend.tf Bootstrap (one-time, manual)
       ↓
  1. VPC           (network foundation — everything lives inside it)
       ↓
  2. ECR           (container registry — no VPC dependency, parallel ok)
  2. EKS           (needs VPC's subnet IDs)
       ↓
  3. RDS           (needs VPC + EKS security group ID)
  3. ElastiCache   (needs VPC + EKS security group ID)
  3. SQS           (no VPC needed, pure AWS service)
       ↓
  4. SNS           (no VPC needed, depends on nothing)
  4. CloudWatch    (depends on SNS topic ARNs)
       ↓
  5. IRSA          (depends on EKS OIDC provider ARN + SQS ARN + RDS secret ARN)
```

Terraform resolves this automatically from the `module.X.output_Y` references in [main.tf](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/modules/sns/main.tf:0:0-0:0). You don't need to manually specify the order.

---

## 📄 File 1: [terraform/environments/dev/backend.tf](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/environments/dev/backend.tf:0:0-0:0) — Line by Line

> **Start here. Always.** Before any Terraform can run, the backend must exist. This is the one thing you bootstrap manually.

---

**Lines 1–15:** Comments — Critical bootstrap instructions:

```hcl
# IMPORTANT: You must create the S3 bucket and DynamoDB table FIRST:
#   aws s3 mb s3://kubeflow-ops-terraform-state --region us-east-1
#   aws dynamodb create-table \
#     --table-name kubeflow-ops-terraform-lock \
#     ...
#     --billing-mode PAY_PER_REQUEST
```

**Why create these manually before `terraform init`?** This is the classic chicken-and-egg problem — Terraform needs a place to store its state, but you can't Terraform that storage location because Terraform isn't initialized yet. So these two resources (S3 bucket + DynamoDB table) are the only AWS resources ever created manually. Everything else is Terraform.

### 🧠 New Concept: Terraform Remote State

**What is Terraform State?**
Terraform maintains a **state file** (`terraform.tfstate`) — a JSON file that maps every resource in your [.tf](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/modules/sns/main.tf:0:0-0:0) files to its real AWS resource ID. Without state, Terraform has no memory — it couldn't know what it already created.

**Default (local) state:** `terraform.tfstate` on your laptop. Problems:

- If your laptop breaks → state lost → Terraform doesn't know what exists
- Two engineers run `terraform apply` simultaneously → corrupted state → destructive conflicts

**Remote state (what this project uses):** State stored in S3:

```
S3 bucket: kubeflow-ops-terraform-state
  └── dev/terraform.tfstate    ← encrypted, versioned state file
```

---

**Lines 17–25:** The actual backend configuration:

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

**`terraform { backend "s3" { } }`** → The `terraform` block is a special meta-configuration block. `backend "s3"` selects the S3 backend type.

**`bucket`** → Which S3 bucket stores the state file. Must already exist.

**`key = "dev/terraform.tfstate"`** → The path/filename within the S3 bucket. Organizing by environment (`dev/`, `staging/`, `prod/`) means multiple environments share the same bucket but have separate state files.

**`dynamodb_table = "kubeflow-ops-terraform-lock"`** → The DynamoDB table used for **state locking**.

### 🧠 New Concept: State Locking (DynamoDB)

When someone runs `terraform apply`, Terraform:

1. Creates a **lock record** in DynamoDB (`LockID = "bucket/key"`)
2. Applies changes
3. Deletes the lock record

If a second person tries `terraform apply` while the first is running → they find the lock → they get an error: _"Error acquiring the state lock."_ This prevents two concurrent applies from corrupting the state file.

**`billing-mode PAY_PER_REQUEST`** (in the bootstrap CLI command) → DynamoDB billing mode. Pay per request = zero cost when idle (you only pay when Terraform actually uses it). Perfect for an infrequently written locking table.

**`encrypt = true`** → Enable **server-side encryption** for the state file in S3. The state file contains sensitive data (RDS passwords in plaintext, ARNs, endpoints). Encrypting at rest is mandatory for security compliance.

---

## 📄 File 2: [terraform/environments/dev/main.tf](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/environments/dev/main.tf:0:0-0:0) — Line by Line

---

### The `terraform` Block (Lines 8–25)

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

**`required_version = ">= 1.7.0"`** → Minimum Terraform CLI version. If someone tries to run with Terraform 1.5 → error. Prevents compatibility issues.

**`required_providers`** → Declares which Terraform **providers** this configuration uses. Providers are plugins that know how to talk to specific APIs.

| Provider | Purpose |
|---|---|
| `hashicorp/aws` | Talks to AWS APIs (creates EC2, EKS, S3, etc.) |
| `hashicorp/random` | Generates random values (used for DB password in RDS module) |
| `hashicorp/tls` | TLS certificate operations (used to get EKS OIDC thumbprint) |

**`version = "~> 5.30"`** → Version constraint. `~>` means "compatible with" — allow patch versions (`5.30.x`) but not major/minor bumps. `5.31` is OK, `6.0` is not. This prevents breaking changes from new provider versions.

`terraform init` downloads these providers from the [Terraform Registry](https://registry.terraform.io/) into `.terraform/providers/`.

---

### Provider Configuration (Lines 27–37)

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

**`provider "aws"`** → Configures the AWS provider. `region = var.aws_region` sets the target AWS region for all resources.

**`default_tags`** → **Every single AWS resource created by this Terraform will automatically get these tags.** This is a Terraform 3.38+ feature.

Why tags matter for DevOps:

- **Cost allocation** → AWS Cost Explorer can filter by `Project` tag → see exactly what this project costs
- **Resource identification** → In the AWS console, every resource shows `ManagedBy: terraform` → you know never to delete it manually
- **Compliance** → Many organizations require tags for all resources
- **Automation** → Scripts can find all resources for a project using tag filters

---

### Variables (Lines 39–53)

```hcl
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
```

**Inline variables** (defined in [main.tf](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/modules/sns/main.tf:0:0-0:0) rather than a separate [variables.tf](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/modules/vpc/variables.tf:0:0-0:0)) → allowed in Terraform, just less organized. These are simple defaults for the dev environment.

**`default = "dev"`** → Without a `default`, you'd need to pass the value via `-var` flag or `terraform.tfvars` file. With defaults, running `terraform apply` with no extra flags works for the dev environment.

**`type = string`** → Type constraint. Terraform will error if you pass a non-string value.

---

### Module: VPC (Lines 55–61)

```hcl
module "vpc" {
  source = "../../modules/vpc"

  project_name = var.project_name
  environment  = var.environment
}
```

**`module "vpc"`** → Instantiates the VPC module. The label `"vpc"` is the local name — referenced later as `module.vpc.vpc_id`.

**`source = "../../modules/vpc"`** → Relative path to the module directory. Could also be a remote source (`github.com/org/repo//modules/vpc` or Terraform Registry).

**Only 2 inputs passed** — because the VPC module's [variables.tf](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/modules/vpc/variables.tf:0:0-0:0) has defaults for everything else (`vpc_cidr`, `availability_zones`, `subnet_cidrs`). The caller only needs to provide what's required (no defaults).

---

### Module: EKS (Lines 63–77)

```hcl
module "eks" {
  source = "../../modules/eks"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id           # ← uses VPC output
  private_subnet_ids = module.vpc.private_subnet_ids  # ← uses VPC output

  # Budget-friendly settings for dev
  node_instance_types = ["t3.medium"]
  node_desired_size   = 2
  node_min_size       = 1
  node_max_size       = 4
}
```

**`vpc_id = module.vpc.vpc_id`** → This is how modules chain together. The VPC module's output `vpc_id` (defined in [modules/vpc/outputs.tf](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/modules/vpc/outputs.tf:0:0-0:0)) is passed directly as the EKS module's input. Terraform automatically understands this creates a dependency: EKS must be created AFTER VPC.

**`node_instance_types = ["t3.medium"]`** → Override the EKS module's default with a budget-friendly type. In prod, you'd use `["t3.large"]` or `["m5.xlarge"]`.

**`node_desired_size = 2`** → 2 EC2 instances running as Kubernetes worker nodes. `min=1, max=4` is the autoscaling range.

---

### Module: ECR (Lines 79–86)

```hcl
module "ecr" {
  source = "../../modules/ecr"

  project_name  = var.project_name
  environment   = var.environment
  service_names = ["order-service", "user-service", "notification-service"]
}
```

**`service_names`** → A list of service names. The ECR module uses `for_each` on this list to create one repository per service. Simple, scalable pattern.

---

### Modules: RDS, ElastiCache (Lines 88–110)

```hcl
module "rds" {
  ...
  eks_security_group_id = module.eks.cluster_security_group_id
  instance_class        = "db.t3.micro"
}

module "elasticache" {
  ...
  eks_security_group_id = module.eks.cluster_security_group_id
  node_type             = "cache.t3.micro"
}
```

Both modules take `eks_security_group_id` → the Security Group of the EKS cluster. This is used inside the modules to create a firewall rule: **only EKS pods can access RDS/Redis** — not the public internet, not other AWS services.

`db.t3.micro` and `cache.t3.micro` → smallest available instance sizes. Correct for dev; prod would use `db.t3.small`/`m5.large`.

---

### Module: SNS + CloudWatch (Lines 120–141)

```hcl
module "sns" {
  ...
  alert_email  = ""  # Set to your email: "you@example.com"
}

module "cloudwatch" {
  ...
  sns_critical_topic_arn = module.sns.critical_topic_arn
  sns_warning_topic_arn  = module.sns.warning_topic_arn
  rds_instance_id        = "${var.project_name}-${var.environment}-postgres"
  ...
}
```

CloudWatch depends on SNS (needs the topic ARNs to route alarms to). Terraform auto-detects this from `module.sns.critical_topic_arn`.

**`alert_email = ""`** → Set this to receive alarm emails. Terraform creates an SNS subscription that sends you an email when CloudWatch alarms fire. The empty string means no email subscription (skipped via `count = var.alert_email != "" ? 1 : 0` in the SNS module).

---

### Module: IRSA (Lines 143–154)

```hcl
module "irsa" {
  ...
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  sqs_queue_arn     = module.sqs.queue_arn
  sqs_dlq_arn       = ""
  rds_secret_arn    = module.rds.secret_arn
}
```

IRSA is the last module — it needs outputs from EKS, SQS, and RDS. Terraform applies it last automatically.

---

## 📄 File 3: [terraform/environments/dev/outputs.tf](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/environments/dev/outputs.tf:0:0-0:0) — Line by Line

> Outputs are printed after `terraform apply` completes. They give you the real AWS values you need to configure everything else. Think of them as the "receipts" from infrastructure creation.

**Line 8–11:**

```hcl
output "eks_cluster_name" {
  description = "EKS cluster name (used in: aws eks update-kubeconfig --name <this>)"
  value       = module.eks.cluster_name
}
```

→ After apply, you copy this value into: `aws eks update-kubeconfig --name <this-value>`. This configures your `kubectl` to talk to EKS.

**Line 18–21:**

```hcl
output "ecr_repository_urls" {
  value = module.ecr.repository_urls
}
```

→ Shows all ECR repository URLs. Use these to tag and push Docker images.

**Lines 70–88: IRSA Role ARNs**

```hcl
output "irsa_order_service_role_arn" { ... }
output "irsa_user_service_role_arn" { ... }
output "irsa_notification_service_role_arn" { ... }
output "irsa_external_secrets_role_arn" { ... }
```

→ These ARNs go into your Kubernetes `ServiceAccount` annotations (Phase 6/8). Critical values.

**Lines 90–94: The convenience output**

```hcl
output "configure_kubectl" {
  description = "Run this to configure kubectl"
  value = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}
```

→ Terraform literally prints the exact command you need to run. At this point, you just copy-paste it.

---

## 📄 Module 1: `modules/vpc/` — Full Walkthrough

---

### [variables.tf](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/modules/vpc/variables.tf:0:0-0:0) — Every Variable

```hcl
variable "vpc_cidr" {
  default = "10.0.0.0/16"        # 65,536 IP addresses
}

variable "availability_zones" {
  default = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  default = ["10.0.1.0/24", "10.0.2.0/24"]   # 254 IPs each
}

variable "private_subnet_cidrs" {
  default = ["10.0.10.0/24", "10.0.20.0/24"]  # 254 IPs each
}
```

**CIDR notation** (`10.0.0.0/16`): You know this from networking. `/16` = first 16 bits fixed → 65,536 addresses. `/24` = first 24 bits fixed → 256 addresses (254 usable). The private subnets use higher second octets (`10.0.10.x`, `10.0.20.x`) to avoid overlapping with public (`10.0.1.x`, `10.0.2.x`).

**2 Availability Zones** → EKS requires at least 2 AZs for high availability. `us-east-1a` and `us-east-1b` are two physically separate data centres in N. Virginia.

---

### [main.tf](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/modules/sns/main.tf:0:0-0:0) — Every Resource

---

**Lines 13–23: `aws_vpc`**

```hcl
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
    ...
  }
}
```

**`resource "aws_vpc" "main"`** → Creates a VPC. `aws_vpc` = resource type (maps to AWS API). `"main"` = local name (used as `aws_vpc.main.id`).

**`enable_dns_hostnames = true`** → Required for EKS. EKS nodes get DNS hostnames (e.g., `ip-10-0-10-5.ec2.internal`). Without this, EKS service discovery doesn't work.

**`enable_dns_support = true`** → Enables the AWS DNS resolver inside the VPC. Required for all service-name resolution.

**`${var.project_name}-${var.environment}-vpc`** → Resource naming convention: `kubeflow-ops-dev-vpc`. String interpolation in HCL uses `${}` syntax.

---

**Lines 27–34: `aws_internet_gateway`**

```hcl
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  ...
}
```

**Internet Gateway (IGW)** → The "door to the internet" for a VPC. Without it, nothing inside the VPC can reach the internet (no pulling Docker images, no contacting AWS APIs).

`aws_vpc.main.id` → References the VPC resource's `id` attribute. Terraform knows to create the VPC first because of this reference.

---

**Lines 39–55: `aws_subnet "public"` with `for_each`**

```hcl
resource "aws_subnet" "public" {
  for_each = toset(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.key
  availability_zone       = var.availability_zones[index(var.public_subnet_cidrs, each.key)]
  map_public_ip_on_launch = true

  tags = {
    "kubernetes.io/role/elb"                                      = "1"
    "kubernetes.io/cluster/${var.project_name}-${var.environment}" = "shared"
  }
}
```

**`for_each = toset(var.public_subnet_cidrs)`** → Creates **one subnet resource per CIDR** in the list. `toset()` converts the list to a set (for_each requires sets or maps, not lists).

- First iteration: `each.key = "10.0.1.0/24"` → creates subnet in `us-east-1a`
- Second iteration: `each.key = "10.0.2.0/24"` → creates subnet in `us-east-1b`

**`index(var.public_subnet_cidrs, each.key)`** → Finds the position of the current CIDR in the list (0 or 1) → uses that position to look up the matching AZ from `availability_zones`. This pairs each CIDR with its correct AZ.

**`map_public_ip_on_launch = true`** → Any EC2 instance launched in these public subnets automatically gets a public IP. Needed for the NAT Gateway (it uses an Elastic IP, but instances in public subnets need this set).

**The Kubernetes tags** — Critical:

```hcl
"kubernetes.io/role/elb" = "1"
```

→ Tells the **AWS Load Balancer Controller** (runs inside EKS): "this is a public subnet — put Internet-facing Load Balancers here." Without this tag, the ALB can't find where to deploy.

```hcl
"kubernetes.io/cluster/kubeflow-ops-dev" = "shared"
```

→ Tells EKS: "this subnet is associated with this cluster." Required for EKS to use these subnets.

---

**Lines 60–74: `aws_subnet "private"`**

Same pattern as public, but:

- No `map_public_ip_on_launch` → private instances have NO public IPs
- Tag: `kubernetes.io/role/internal-elb = "1"` → Internal Load Balancers go here (not internet-facing)
- EKS worker nodes live here (private — no direct internet exposure)

---

**Lines 79–98: `aws_eip` + `aws_nat_gateway`**

```hcl
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public["${var.public_subnet_cidrs[0]}"].id

  depends_on = [aws_internet_gateway.main]
}
```

### 🧠 New Concept: NAT Gateway

**The problem:** EKS nodes are in private subnets (no public IPs). But they need to:

- Pull Docker images from ECR (outbound HTTPS)
- Call AWS APIs (S3, SQS, etc.)
- Download OS updates

**NAT Gateway solution:**

```
EKS Node (private subnet, 10.0.10.5)
  │  outbound request to pull image from ECR
  ▼
NAT Gateway (public subnet, has Elastic IP: 52.x.x.x)
  │  translates private IP → public Elastic IP
  ▼
Internet → ECR
  │  response comes back to NAT Gateway
  ▼
NAT Gateway → EKS Node

Nobody on the internet can INITIATE a connection to the EKS node
(NAT is one-way — outbound only)
```

**`aws_eip "nat"`** → **Elastic IP** — a static public IPv4 address. The NAT Gateway needs a permanent public IP so that egress traffic has a consistent source IP (used for security group whitelisting downstream).

**`domain = "vpc"`** → VPC-associated EIP (as opposed to Classic EC2, which is legacy).

**`subnet_id = aws_subnet.public["10.0.1.0/24"].id`** → NAT Gateway lives in a **public** subnet (it needs internet access itself to route traffic out). References the first public subnet using the CIDR as the key (matching the `for_each` key).

**`depends_on = [aws_internet_gateway.main]`** → Explicit dependency. The NAT Gateway can't route internet traffic if the Internet Gateway doesn't exist. Terraform usually infers dependencies automatically, but here there's no attribute reference — so you declare it explicitly.

**"Single NAT Gateway"** comment: Production would have one NAT Gateway per AZ (N. Virginia zone A failure → zone B still working). Dev uses one for cost savings (~$32/month per NAT GW).

---

**Lines 102–148: Route Tables**

```hcl
# Public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

# Private route table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
}
```

**Route Table** = a routing rules table attached to subnets. It answers: "for traffic destined to X, send it to Y."

**`cidr_block = "0.0.0.0/0"`** → Default route ("everything not matched by a more specific route").

- **Public subnets** → `0.0.0.0/0 → Internet Gateway` = can reach internet directly
- **Private subnets** → `0.0.0.0/0 → NAT Gateway` = can reach internet via NAT (outbound only)

```hcl
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}
```

**`for_each = aws_subnet.public`** → Iterates over all public subnets (created with `for_each` earlier). Associates each subnet with the public route table. Without association, a subnet uses the VPC's default route table.

---

### [outputs.tf](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/modules/vpc/outputs.tf:0:0-0:0)

```hcl
output "private_subnet_ids" {
  value = [for s in aws_subnet.private : s.id]
}
```

**`[for s in aws_subnet.private : s.id]`** → A Terraform **for expression** (like a list comprehension). Iterates over all private subnet resources and collects just their IDs into a list. This list is what `module.eks`, `module.rds`, and `module.elasticache` receive as `private_subnet_ids`.

---

## 📄 Module 2: `modules/eks/` — Full Walkthrough

---

### IAM for EKS — Two Roles (Lines 14–44, 117–153)

EKS requires **two separate IAM roles**:

```
aws_iam_role "eks_cluster"   → assumed by the EKS CONTROL PLANE (AWS managed)
aws_iam_role "eks_nodes"     → assumed by EC2 worker NODE instances
```

**Control Plane Role (Lines 16–44):**

```hcl
resource "aws_iam_role" "eks_cluster" {
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}
```

**`assume_role_policy`** → The **trust policy** — who is allowed to assume this role. `Service: "eks.amazonaws.com"` → only the EKS service can assume it (not you, not other services).

**`AmazonEKSClusterPolicy`** → AWS managed policy. Gives the EKS control plane permissions to:

- Create/modify ENIs (network interfaces for pods)
- Write to CloudWatch Logs
- Manage EC2 auto-scaling for nodes

**`AmazonEKSVPCResourceController`** → Allows EKS to configure VPC networking for pods (Security Groups for Pods feature).

---

**Node Group Role (Lines 117–153):**

```hcl
resource "aws_iam_role" "eks_nodes" {
  assume_role_policy = jsonencode({
    Principal = { Service = "ec2.amazonaws.com" }  # ← EC2 instances assume this
  })
}

# Three required policies for worker nodes:
aws_iam_role_policy_attachment "eks_worker_node_policy"
  → AmazonEKSWorkerNodePolicy         (node-to-cluster auth)
aws_iam_role_policy_attachment "eks_cni_policy"
  → AmazonEKS_CNI_Policy              (pod networking/IP assignment)
aws_iam_role_policy_attachment "eks_container_registry"
  → AmazonEC2ContainerRegistryReadOnly (pull images from ECR)
```

**Why 3 policies?**

- **EKSWorkerNodePolicy** → Allows the node to register with the EKS cluster, describe EC2 resources
- **EKS_CNI_Policy** → The VPC CNI plugin manages pod IPs. It needs to create/delete ENIs and assign IPs from the subnet
- **ECRReadOnly** → Nodes must pull Docker images from ECR. Without this, every pod start fails with "ImagePullBackOff"

---

### Security Group for EKS (Lines 46–68)

```hcl
resource "aws_security_group" "eks_cluster" {
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}
```

**`egress` only, no `ingress`** → The Security Group here is for the EKS **control plane**. The API server's inbound rules are managed by EKS itself. The egress rule allows all outbound traffic (`protocol = "-1"` = all protocols).

**`lifecycle { create_before_destroy = true }`** → If Terraform needs to recreate this SG (due to a name change), it creates the new one BEFORE destroying the old one. Without this, destroying first could leave EKS without a security group → downtime. Critical for stateful resources.

---

### EKS Cluster Resource (Lines 70–96)

```hcl
resource "aws_eks_cluster" "main" {
  name     = "${var.project_name}-${var.environment}-eks-cluster"
  version  = var.kubernetes_version
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
    security_group_ids      = [aws_security_group.eks_cluster.id]
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller,
  ]
}
```

**`version = var.kubernetes_version`** → Kubernetes version (default: `1.29`). AWS manages the control plane upgrade path.

**`endpoint_private_access = true`** → Kubernetes API server accessible from **within the VPC** (nodes, CI runners with VPC access).

**`endpoint_public_access = true`** → Also accessible from the **public internet** (your laptop, GitHub Actions runners). In high-security production, you'd set this to `false` and use a VPN.

**`enabled_cluster_log_types = ["api", "audit", "authenticator"]`** → Sends EKS control plane logs to CloudWatch:

- `api` → API server requests
- `audit` → Who did what to which resource (security auditing)
- `authenticator` → IAM authentication attempts (identity troubleshooting)

**`depends_on`** → Explicit dependency on the IAM policy attachments. The cluster can't be created until the IAM role has the required policies attached.

---

### OIDC Provider (Lines 98–115) — THE CRITICAL PIECE

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

**`data "tls_certificate" "eks"`** → A Terraform `data` source (reads existing data, doesn't create anything). Fetches the TLS certificate of the EKS OIDC issuer URL to extract its SHA1 thumbprint.

**`aws_eks_cluster.main.identity[0].oidc[0].issuer`** → The OIDC issuer URL that EKS automatically creates. Looks like: `https://oidc.eks.us-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E`

**`aws_iam_openid_connect_provider "eks"`** → Creates an **IAM OIDC Provider** — registers the EKS cluster's OIDC issuer with AWS IAM. This is the bridge that allows IAM to trust Kubernetes identities.

- **`client_id_list = ["sts.amazonaws.com"]`** → The audience. JWT tokens from this OIDC provider are intended for `sts.amazonaws.com` (AWS Security Token Service — the service that grants temporary credentials).
- **`thumbprint_list`** → The TLS thumbprint of the OIDC endpoint. AWS uses this to verify the OIDC provider's TLS certificate. Prevents MITM attacks on the OIDC token exchange.

**This resource is the prerequisite for the entire IRSA system.** Without it, the `irsa/` module's IAM trust policies can't reference the OIDC provider.

---

### Managed Node Group (Lines 155–192)

```hcl
resource "aws_eks_node_group" "main" {
  cluster_name  = aws_eks_cluster.main.name
  node_role_arn = aws_iam_role.eks_nodes.arn
  subnet_ids    = var.private_subnet_ids

  instance_types = var.node_instance_types
  capacity_type  = "ON_DEMAND"

  scaling_config {
    desired_size = var.node_desired_size   # 2
    min_size     = var.node_min_size       # 1
    max_size     = var.node_max_size       # 4
  }

  update_config {
    max_unavailable = 1   # Roll one node at a time during K8s version upgrades
  }
}
```

**Managed Node Group** → AWS manages the EC2 instances. When you upgrade Kubernetes version or change the AMI, AWS:

1. Adds new node with new version
2. Drains pods from old node (`kubectl drain`)
3. Terminates old node
4. Repeats for each node (one at a time per `max_unavailable`)

vs. **Self-managed nodes** → you manage EC2 lifecycle yourself. More control, much more work.

**`capacity_type = "ON_DEMAND"`** → Reliable, full-price instances. For dev savings, could use `SPOT` (up to 70% cheaper, but can be interrupted at any time — acceptable for stateless pods, risky for stateful workloads).

**`scaling_config`** → The range for the node autoscaler. `desired=2` = current target. The Kubernetes **Cluster Autoscaler** (deployed inside K8s, not here) adjusts `desired` based on pod scheduling needs, within `min/max` bounds.

---

### EKS Add-ons (Lines 194–214)

```hcl
resource "aws_eks_addon" "coredns" { addon_name = "coredns" }
resource "aws_eks_addon" "kube_proxy" { addon_name = "kube-proxy" }
resource "aws_eks_addon" "vpc_cni" { addon_name = "vpc-cni" }
```

**EKS Add-ons** → AWS-managed Kubernetes components installed via the EKS API. AWS keeps these updated and compatible with the cluster version.

| Add-on | What It Does |
|---|---|
| `coredns` | **DNS for Kubernetes.** Service discovery inside the cluster. Every `kubectl get svc` name resolves via CoreDNS. Without this, `user-service.kubeflow-ops.svc.cluster.local` doesn't resolve. |
| `kube-proxy` | Maintains network rules on each node. Enables Service-to-Pod traffic routing. |
| `vpc-cni` | **AWS VPC Container Network Interface.** Assigns real VPC IP addresses to pods (not an overlay network). Pods get IPs from your subnet CIDR directly. |

**`depends_on = [aws_eks_node_group.main]`** → Add-ons need nodes to schedule on. Can't install add-ons before nodes exist.

---

### [outputs.tf](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/modules/vpc/outputs.tf:0:0-0:0)

```hcl
output "oidc_provider_url" {
  value = replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")
}
```

The `replace()` function strips `https://` from the OIDC URL. The IRSA trust policies need the URL **without** the protocol prefix. This is a Terraform built-in string function.

---

## 📄 Module 3: [modules/ecr/main.tf](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/modules/ecr/main.tf:0:0-0:0)

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
}
```

**`for_each = toset(var.service_names)`** → Creates 3 ECR repos:

- `kubeflow-ops-order-service`
- `kubeflow-ops-user-service`
- `kubeflow-ops-notification-service`

**`image_tag_mutability = "IMMUTABLE"`** → Cannot overwrite an existing tag. If tag `abc123` already exists → pushing a different image with the same tag FAILS. This is a security best practice — if you deploy `abc123` and find a bug, you create a new commit (new SHA), not overwrite the old tag. Immutability = auditability.

**`scan_on_push = true`** → Every image pushed to ECR is automatically scanned for vulnerabilities by AWS Inspector (using the same CVE databases as Trivy). Results appear in the ECR console.

**`encryption_type = "AES256"`** → All images stored at rest are encrypted using AES-256. Compliance requirement for most security frameworks.

```hcl
resource "aws_ecr_lifecycle_policy" "services" {
  for_each   = aws_ecr_repository.services
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
      action = { type = "expire" }
    }]
  })
}
```

**Lifecycle Policy** → Automatically deletes old images when more than 10 exist. Without this, every CI build pushes a new image (with git SHA tag) → hundreds of images accumulate → ECR storage costs grow endlessly. 10 images × 3 repos × ~120MB = ~3.6GB maximum storage. Manageable and cheap.

---

## 📄 Module 4: [modules/rds/main.tf](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/modules/rds/main.tf:0:0-0:0) — Key Highlights

---

**Lines 89–115: Random Password + Secrets Manager**

```hcl
resource "random_password" "db_password" {
  length  = 24
  special = false
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name = "${var.project_name}/${var.environment}/db-credentials"
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

**`resource "random_password"`** → Generates a cryptographically secure 24-character random password during `terraform apply`. It's stored in the Terraform state (encrypted in S3) and in Secrets Manager. **You never see it in your terminal** — it's sensitive data.

**`aws_secretsmanager_secret`** → Creates the secret entry in AWS Secrets Manager. Path: `kubeflow-ops/dev/db-credentials`.

**`aws_secretsmanager_secret_version`** → Stores the actual secret VALUE as JSON with all DB connection details. The External Secrets Operator (Phase 8) will read this and create a Kubernetes Secret automatically.

---

**Lines 117–148: RDS Instance**

```hcl
resource "aws_db_instance" "main" {
  engine         = "postgres"
  engine_version = "16.3"
  instance_class = var.instance_class   # db.t3.micro

  allocated_storage     = 20
  max_allocated_storage = 50   # Autoscale up to 50GB

  multi_az            = false   # true in prod
  publicly_accessible = false   # private subnets only
  skip_final_snapshot = true    # false in prod

  backup_retention_period = 7            # 7 days of automated backups
  backup_window           = "03:00-04:00"   # UTC — low-traffic window
  maintenance_window      = "mon:04:00-mon:05:00"
}
```

**`max_allocated_storage = 50`** → **Storage autoscaling**. RDS automatically increases storage (in 5GB+ increments) if free space drops below 10%. No manual intervention → no "DB ran out of disk at 3 AM" incidents.

**`multi_az = false`** → Prod should be `true`: RDS creates a synchronous standby replica in another AZ. If the primary fails → automatic failover to standby in ~60s. For dev, single AZ saves ~2x cost.

**`skip_final_snapshot = true`** → When you run `terraform destroy`, RDS won't create a final backup. Correct for dev (you don't care about dev DB data). **In prod, ALWAYS set `false`** — RDS creates a final snapshot before deleting, protecting against accidental `terraform destroy`.

**`backup_retention_period = 7`** → RDS keeps 7 days of automated backups. You can restore to any point-in-time within those 7 days. Used in the Phase 10 runbook for disaster recovery.

---

## 📄 Module 5: [modules/sqs/main.tf](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/modules/sqs/main.tf:0:0-0:0) — Key Highlights

```hcl
resource "aws_sqs_queue" "order_events" {
  visibility_timeout_seconds = 30
  message_retention_seconds  = 345600   # 4 days
  receive_wait_time_seconds  = 10       # Long polling

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.order_events_dlq.arn
    maxReceiveCount     = 3
  })
}
```

**`visibility_timeout_seconds = 30`** → When `notification-service` receives a message, SQS makes it **invisible** to other consumers for 30 seconds. This prevents double-processing. If the service doesn't delete the message within 30s (e.g., it crashed mid-processing), the message becomes visible again and another consumer can pick it up.

**`receive_wait_time_seconds = 10`** → **Long polling**. Instead of notification-service constantly sending empty `ReceiveMessage` API calls every second (short polling = ~$0.40/million calls), it waits up to 10 seconds for a message to arrive before returning empty. Reduces API costs by ~90% and reduces CPU usage.

**`redrive_policy`** → The DLQ configuration in Terraform. Same concept as the LocalStack init script in Phase 3, but now as real AWS infrastructure.

---

```hcl
resource "aws_iam_policy" "sqs_access" {
  policy = jsonencode({
    Statement = [{
      Action = [
        "sqs:SendMessage",
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
        "sqs:GetQueueUrl",
      ]
      Resource = [aws_sqs_queue.order_events.arn, aws_sqs_queue.order_events_dlq.arn]
    }]
  })
}
```

This IAM policy is created here (in the SQS module) and its ARN is output → referenced in the IRSA module which attaches it to the per-service IAM roles. This is how modules compose: SQS creates the policy, IRSA attaches it to the right roles.

---

## 📄 Module 6: [modules/irsa/main.tf](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/modules/irsa/main.tf:0:0-0:0) — Full Walkthrough (Most Important)

> IRSA is the most important security primitive in the entire project. Read this carefully.

---

### The Pattern (Repeated 4 Times — Once Per Service/Component)

```hcl
resource "aws_iam_role" "order_service" {
  assume_role_policy = jsonencode({
    Statement = [{
      Effect = "Allow"
      Principal = { Federated = var.oidc_provider_arn }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.oidc_provider_url}:sub" = "system:serviceaccount:${var.namespace}:order-service-sa"
          "${var.oidc_provider_url}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}
```

**`Principal = { Federated = var.oidc_provider_arn }`** → Instead of `Service: "ec2.amazonaws.com"` (like the node role), the principal is `Federated` → the EKS OIDC provider. This means: "This role can be assumed by identities vouched for by the EKS OIDC provider."

**`Action = "sts:AssumeRoleWithWebIdentity"`** → The specific IAM action for OIDC-based role assumption (different from `AssumeRole` used by EC2).

**The `Condition` block — This is the precision:**

```hcl
"${var.oidc_provider_url}:sub" = "system:serviceaccount:kubeflow-ops:order-service-sa"
```

- `:sub` = subject claim in the JWT token. For Kubernetes, this is always `system:serviceaccount:<namespace>:<serviceaccount-name>`
- This condition says: **ONLY the Kubernetes ServiceAccount named `order-service-sa` in namespace `kubeflow-ops` can assume this role.**

Not `user-service-sa`. Not any pod without a ServiceAccount. Not any other namespace. Only this exact ServiceAccount.

```hcl
"${var.oidc_provider_url}:aud" = "sts.amazonaws.com"
```

- `:aud` = audience claim. Must match `sts.amazonaws.com` — the intended recipient of the token.

**The result:** When a pod running as `order-service-sa` (annotated with the role ARN) calls `boto3.client("sqs")`:

1. The AWS SDK inside the pod detects the IRSA annotation
2. Fetches a projected service account token from the pod's filesystem
3. Sends it to AWS STS
4. STS validates `:sub` and `:aud` conditions → they match
5. Returns temporary credentials valid for 12 hours
6. SDK uses those credentials to call SQS → no access keys anywhere

---

### Per-Service Policies (What Each Service Can Do)

```hcl
# order-service gets:
"sqs:SendMessage"              # publish events
"secretsmanager:GetSecretValue" # read DB password

# user-service gets:
"secretsmanager:GetSecretValue" # read DB password only

# notification-service gets:
"sqs:ReceiveMessage"           # consume events
"sqs:DeleteMessage"            # acknowledge processed
"sqs:ChangeMessageVisibility"  # extend visibility timeout if processing takes longer
```

This is **least privilege in action** at the pod level:

- `order-service` **cannot** receive SQS messages (only send)
- `notification-service` **cannot** send SQS messages (only receive)
- `user-service` **cannot** touch SQS at all

If `order-service` is compromised → attacker can only send SQS messages, can't drain the queue. This limits blast radius.

---

### External Secrets Role (Lines 222–269)

```hcl
resource "aws_iam_role" "external_secrets" {
  # Only external-secrets ServiceAccount can assume this
  "${var.oidc_provider_url}:sub" = "system:serviceaccount:external-secrets:external-secrets"
}

resource "aws_iam_role_policy" "external_secrets" {
  policy = jsonencode({
    Statement = [{
      Sid    = "SecretsManagerReadAll"
      Action = ["secretsmanager:GetSecretValue", "DescribeSecret", "ListSecrets"]
      Resource = "arn:aws:secretsmanager:*:*:secret:${var.project_name}/*"
    }]
  })
}
```

**External Secrets Operator (ESO)** (covered in Phase 8) needs to read all secrets for this project from AWS Secrets Manager. The resource ARN pattern `secret:kubeflow-ops/*` means: read any secret whose path starts with `kubeflow-ops/`. Only ESO's specific ServiceAccount can assume this role.

---

## 📄 Module 7: [modules/sns/main.tf](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/modules/sns/main.tf:0:0-0:0) — Key Highlights

```hcl
resource "aws_sns_topic" "critical_alerts" {
  name = "${var.project_name}-${var.environment}-critical-alerts"
}
resource "aws_sns_topic" "warning_alerts" { ... }

resource "aws_sns_topic_subscription" "critical_email" {
  count    = var.alert_email != "" ? 1 : 0
  protocol = "email"
  endpoint = var.alert_email
}
```

**`count = var.alert_email != "" ? 1 : 0`** → **Conditional resource** (Terraform ternary). If `alert_email` is set → create 1 subscription. If empty → create 0 (skip). This is how you make optional resources in Terraform.

**`protocol = "email"`** → SQS supports many subscription protocols: `email`, `https`, `sqs`, `lambda`, `sms`. Email sends an alert email; `https` can call PagerDuty/Opsgenie webhooks.

**SNS Topic Policy** (Lines 73–105) → Grants CloudWatch the permission to publish alerts to the SNS topic. Without this, when a CloudWatch alarm fires it can't send to SNS → alerts are never delivered.

---

## 📄 Module 8: [modules/cloudwatch/main.tf](cci:7://file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/terraform/modules/cloudwatch/main.tf:0:0-0:0) — Key Highlights

---

### Dashboard (Lines 59–140)

```hcl
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}-overview"
  dashboard_body = jsonencode({
    widgets = [
      # RDS CPU & Connections widget
      # RDS Storage widget
      # SQS message count widget
      # Redis CPU & Memory widget
    ]
  })
}
```

Creates a **CloudWatch Dashboard** — a web-based monitoring panel in the AWS console. The dashboard is defined as JSON (the `dashboard_body`). Each widget has:

- `type = "metric"` → a time-series graph
- `x, y, width, height` → position and size on the dashboard grid
- `metrics` → which AWS metrics to show (format: `[namespace, metric_name, dimension_name, dimension_value]`)
- `period = 300` → aggregate data every 5 minutes
- `stat = "Average"` → show the average value per period

This is the **AWS-native monitoring** layer. Note the comment in the file: _"Prometheus handles K8s-level metrics; CloudWatch handles AWS-managed service metrics."_ They complement each other:

- **CloudWatch** → RDS CPU, Redis memory, SQS depth (AWS-managed services)
- **Prometheus** (Phase 9) → pod CPU/memory, HTTP request rates, error rates (application-level)

---

### Alarms (Lines 142–269)

**Pattern (same for all alarms):**

```hcl
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  count = var.rds_instance_id != "" ? 1 : 0  # conditional

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3          # Must breach for 3 consecutive periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300        # 5-minute aggregation
  statistic           = "Average"
  threshold           = 80         # 80% CPU

  alarm_actions = [var.sns_critical_topic_arn]  # page on-call when triggered
  ok_actions    = [var.sns_warning_topic_arn]   # notify when recovers
}
```

**`evaluation_periods = 3`** → Must breach the threshold for 3 consecutive 5-minute periods (15 minutes total) before alarming. Prevents false alarms from brief CPU spikes.

**`alarm_actions`** → What to do when the alarm fires → publish to SNS critical topic → email/PagerDuty.

**`ok_actions`** → What to do when the alarm recovers → publish to SNS warning topic → notification that the incident is resolved.

### The Alarms Created

| Alarm | Threshold | Severity | Why |
|---|---|---|---|
| `rds_cpu_high` | CPU > 80% for 15min | Critical | DB under heavy load → slowdowns cascading to all services |
| `rds_storage_low` | Free storage < 5GB | Critical | DB will stop accepting writes when disk full |
| `sqs_dlq_messages` | DLQ > 0 messages | Critical | Any DLQ message = notification failure 3 times = bug in notification-service |
| `sqs_queue_backlog` | Visible > 1000 messages | Warning | Consumer (notification-service) may be down |
| `redis_cpu_high` | CPU > 70% for 15min | Warning | Cache performance degrading |

**The `5368709120` threshold for `rds_storage_low`** = `5GB × 1024³ = 5,368,709,120 bytes`. CloudWatch's `FreeStorageSpace` metric reports in bytes.

---

## 🔑 Key DevOps Takeaways from Phase 5

| Pattern | What You Applied |
|---|---|
| **Remote S3 state + DynamoDB locking** | Team-safe Terraform — no conflicts, no lost state |
| **Module pattern** | Reusable, testable infrastructure blocks. Add `prod/` environment by calling same modules with bigger values |
| **`default_tags`** | Every resource auto-tagged → cost visibility, compliance, searchability |
| **VPC with public/private subnets** | EKS nodes have no public IPs — true network isolation |
| **Single NAT Gateway (dev), Multi-AZ (prod)** | Cost-aware design with explicit prod upgrade path |
| **Kubernetes subnet tags** | Load Balancer Controller can automatically find where to deploy ALBs |
| **Managed Node Group** | AWS handles node upgrades, drain, replace — you just pin Kubernetes version |
| **OIDC Provider on EKS** | Foundation for IRSA — pods get AWS credentials without EC2 IAM roles |
| **IRSA per service** | `order-service` can only SendMessage, not ReceiveMessage — minimum viable permissions |
| **Random password + Secrets Manager** | DB credentials never in Git, never in your terminal, auto-synced to K8s via ESO |
| **ECR lifecycle policy** | Automatic cleanup → bounded storage costs |
| **Immutable ECR tags** | No accidental overwrites of production image |
| **CloudWatch alarms → SNS → Email/PagerDuty** | AWS-layer monitoring, fully automated in code |
| **DLQ alarm threshold = 0** | Any message in DLQ is immediately critical — zero tolerance |

---

## ✅ What Happens When You Run It

```bash
# 1. Bootstrap (ONCE, manually)
aws s3 mb s3://kubeflow-ops-terraform-state --region us-east-1
aws dynamodb create-table --table-name kubeflow-ops-terraform-lock ...

# 2. Initialize
cd terraform/environments/dev
terraform init        # downloads providers, connects to S3 backend

# 3. Preview (~immediate)
terraform plan        # shows: X to add, 0 to change, 0 to destroy

# 4. Apply (~15-20 minutes)
terraform apply       # creates VPC → EKS → RDS → ElastiCache → SQS → SNS → CloudWatch → IRSA

# 5. After apply — use the outputs
terraform output configure_kubectl
# → aws eks update-kubeconfig --region us-east-1 --name kubeflow-ops-dev-eks-cluster
# Run that command → kubectl is now connected to your cluster

terraform output irsa_order_service_role_arn
# → arn:aws:iam::123456789012:role/kubeflow-ops-dev-order-service-role
# → goes into the Kubernetes ServiceAccount annotation in Phase 6
```

---

## ✅ Phase 5 Complete — What's Next

You now have **all AWS infrastructure provisioned**:

- ✅ VPC with public/private subnets across 2 AZs
- ✅ EKS cluster with managed node group + OIDC provider
- ✅ ECR repositories per service (with Trivy scanning + lifecycle policies)
- ✅ RDS PostgreSQL (private, encrypted, backed up, credentials in Secrets Manager)
- ✅ ElastiCache Redis (private, EKS-only access)
- ✅ SQS + DLQ (with long polling, 14-day DLQ retention)
- ✅ SNS alert topics
- ✅ CloudWatch dashboard + alarms for all AWS services
- ✅ IRSA IAM roles (per-service, per-component — least privilege for every pod)

**Phase 6: Helm Charts + GitOps Manifests** — Now that your cluster exists, you define what runs ON it using Helm templates and values files. ArgoCD will read those and deploy your 3 microservices to EKS. 🚀
