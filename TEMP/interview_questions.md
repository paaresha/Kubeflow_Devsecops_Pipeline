# 🎯 35 Production-Level DevSecOps Interview Questions
### Based on the Kubeflow DevSecOps Pipeline Project
> **Stack**: AWS EKS · Terraform · ArgoCD · Helm · GitHub Actions · OIDC · Kyverno · External Secrets Operator · Prometheus · SonarQube · Trivy

---

## 🟢 Entry Level — 0 to 2 Years of Experience (Q1–Q20)
> These questions test whether candidates can read real configs, debug actual failures, and explain *why* things are set up the way they are — not just define terms.

---

### Q1 — ArgoCD: Synced But Not Deployed
**You merged a PR that updates `order-service`. ArgoCD shows status `Synced` and `Healthy` but the pod is still running the old image. What do you check?**

**Expected Answer:**
- `Synced` means ArgoCD successfully applied what's in Git. `Healthy` means pods are Running. Neither means the *new* image is deployed.
- Check: did the CI pipeline actually update `gitops/apps/order-service/values.yaml`? The `yq` step does: `yq -i ".image.tag = \"$IMAGE_TAG\"" values.yaml` followed by `git commit && git push`. If the push failed (e.g., no changes to commit), the git SHA in the file is still old.
- Run `argocd app get order-service` and look at the `image:` value in the live manifest vs what's in `values.yaml` on the `main` branch.
- Also check: did the push from the CI bot succeed? Go to the GitHub Actions log and look at the last step "Update image tag in Helm values".

---

### Q2 — GitHub Actions: Why Did Only One Service Build?
**Three microservices exist: `order-service`, `user-service`, `notification-service`. A developer changed only `apps/order-service/app.py`. The CI pipeline ran but only one job appears in the matrix. Is this correct behavior? Explain why.**

**Expected Answer:**
- Yes, this is correct and intentional. The `detect-changes` job uses `dorny/paths-filter@v3` with per-service path filters.
- `order-service` filter watches `apps/order-service/**`. Only this filter returns `true`.
- The matrix strategy then uses `exclude` to drop any service where `changed == "false"`. So only the `order-service` job runs.
- This saves CI minutes and avoids pushing unchanged images with new tags to ECR unnecessarily.

---

### Q3 — Kyverno: Pod Rejected at Deployment
**A developer runs `kubectl apply` on a new deployment. It fails with: `"Image tag 'latest' is not allowed. Use a specific tag like a git SHA."` They say "but it worked last week." What changed and how do you fix it?**

**Expected Answer:**
- The `disallow-latest-tag` Kyverno `ClusterPolicy` with `validationFailureAction: Enforce` is blocking it. This is an admission webhook — it intercepts every Pod create/update request.
- "Worked last week" usually means either: (a) the policy was previously set to `Audit` (warn only) and was recently changed to `Enforce`, or (b) the pod wasn't going through the webhook path (e.g., namespace had a label to skip Kyverno).
- **Fix**: Change the image tag in the deployment spec from `:latest` to a specific, immutable tag — e.g., the git SHA from the CI build: `nginx:sha-a1b2c3d`.
- Confirm: `kubectl describe pod <pod>` or `kubectl get events -n <ns>` will show the rejection reason.

---

### Q4 — Prometheus: Alert Fired — Now What?
**You receive a PagerDuty alert: `HighErrorRate` is firing for `user-service`. The message says "current: 8%". You have `kubectl` access. What are your first 4 commands?**

**Expected Answer:**
```bash
# 1. Check pod health — are pods running or crashing?
kubectl get pods -n kubeflow-ops -l app=user-service

# 2. Read logs from the failing pod
kubectl logs <pod-name> -n kubeflow-ops --tail=100

# 3. Check recent restart count — is it crash-looping?
kubectl describe pod <pod-name> -n kubeflow-ops | grep -A5 "Last State"

# 4. Check recent Kubernetes events
kubectl get events -n kubeflow-ops --sort-by=.lastTimestamp | tail -20
```
- 8% error rate with `for: 5m` means it's been failing for at least 5 minutes. Logs will usually reveal the cause (DB connection refused, upstream timeout, OOM).

---

### Q5 — Trivy: Vulnerability Found
**Trivy scans the `order-service` image and reports a `CRITICAL` CVE. The pipeline still passes and the image gets pushed. Why? Is this acceptable for production?**

**Expected Answer:**
- Because `exit-code: "0"` is set in the Trivy step. This means Trivy reports vulnerabilities in the log but does **not** fail the pipeline step. The build proceeds regardless.
- This is an **observability-only scan**, not a hard gate.
- For production hardening: change `exit-code: "1"` — this makes the step fail (and thus blocks the push) if a HIGH or CRITICAL CVE is found.
- You can also add `ignore-unfixed: true` to only block on CVEs that have a fix available — avoids false positives from OS-level CVEs with no available patch.

---

### Q6 — Terraform: State File Locked
**A colleague ran `terraform apply` and it crashed mid-way (laptop died). Now when you run `terraform plan`, you get: `Error acquiring the state lock`. What do you do?**

**Expected Answer:**
- Terraform uses DynamoDB to manage state locks. The lock entry wasn't released when the apply crashed.
- First: verify the previous run is truly dead (no EC2 instances or CI jobs running it). Never force-unlock a live apply.
- Force-unlock: `terraform force-unlock <LOCK_ID>` — the lock ID is shown in the error message.
- Then: inspect the state to see if the partial apply left infrastructure in an inconsistent state: `terraform plan` will show what's drifted.
- Verify the actual AWS resources match expectations before running `terraform apply` again.

---

### Q7 — External Secrets: Secret Not Syncing
**A pod fails to start: `secret "db-credentials" not found`. You check and the `ExternalSecret` resource exists. What's wrong and how do you debug it?**

**Expected Answer:**
```bash
# Check the ExternalSecret status — look for Ready: False
kubectl describe externalsecret db-credentials -n kubeflow-ops
```
Common causes:
1. **Wrong secret path**: The `remoteRef.key` is `kubeflow-ops/dev/db-credentials`. If the secret in AWS Secrets Manager has a different name, the sync fails.
2. **IRSA not configured**: The External Secrets Operator pod uses a ServiceAccount. If that ServiceAccount's IAM role doesn't have `secretsmanager:GetSecretValue` permission, it gets an `AccessDenied`.
3. **ClusterSecretStore not ready**: `kubectl describe clustersecretstore aws-secrets-manager` — check for auth errors.
4. **ESO operator itself is down**: `kubectl get pods -n external-secrets` — verify the operator is running.
5. Check operator logs: `kubectl logs -n external-secrets deploy/external-secrets`

---

### Q8 — Helm: Deployment Timed Out
**`helm upgrade --install` ran with `--wait --timeout 5m` and failed after 5 minutes. The release is stuck in `pending-upgrade`. How do you recover the cluster?**

**Expected Answer:**
- `pending-upgrade` = Helm started an upgrade but the pods never became Ready within the timeout, so Helm didn't mark it as successful. The release state is now locked.
- Recovery:
  ```bash
  # See release history
  helm history order-service -n kubeflow-ops

  # Roll back to last successful revision
  helm rollback order-service <last-good-revision> -n kubeflow-ops
  ```
- Root cause — why did pods not become Ready? Check:
  - `kubectl describe pod <new-pod>` → Look for `ImagePullBackOff` (wrong ECR tag), OOMKilled (limits too low), or failed liveness probe.
  - Fix the root cause, then re-run the deploy.
- **Prevention**: Add `--atomic` flag to `helm upgrade` — it auto-rolls back on failure so the release never gets stuck.

---

### Q9 — CI/CD: Pipeline Passed but Wrong Code in Production
**The CI pipeline passed, the image was pushed to ECR with the git SHA tag, ArgoCD synced — but users report a bug that was supposedly fixed in the last commit. How do you verify what's actually running?**

**Expected Answer:**
```bash
# 1. Check what image tag is in the running pod
kubectl get pod <pod-name> -n kubeflow-ops \
  -o jsonpath='{.spec.containers[0].image}'

# 2. Compare with what's in values.yaml on main branch
cat gitops/apps/order-service/values.yaml | grep tag

# 3. Verify the image content — pull the image and check
aws ecr describe-images \
  --repository-name kubeflow-ops-order-service \
  --image-ids imageTag=<sha>

# 4. In the container — if you need to check the actual binary
kubectl exec -it <pod> -n kubeflow-ops -- python -c "import app; print(app.__version__)"
```
- If the image SHA matches the git commit but the bug is there, the fix wasn't actually in that commit — check git log.

---

### Q10 — Smoke Test: What Exactly Is Being Tested?
**Looking at the smoke test in `deploy.yml`, what does it actually validate? What critical failure scenarios would it miss?**

**Expected Answer — what it tests:**
- It hits `/healthz` on the deployed service and checks for HTTP 200.
- If 200: deployment is considered healthy.
- If not 200: it runs `kubectl rollout undo` and exits with code 1.

**What it misses (important):**
- It only checks the health endpoint — a service can return 200 on `/healthz` while `/orders` endpoint is broken.
- It doesn't test actual business logic (create an order, verify it persists).
- It doesn't check downstream dependencies — the service could be healthy but unable to reach RDS or SQS.
- It waits only 15 seconds for the LB to update — on AWS ALB, this can take 60–90 seconds. The test might hit the old pod.
- **Better approach**: Run a synthetic transaction — POST an order, GET it back, verify the response.

---

### Q11 — Kubernetes: Resource Limits and OOMKill
**A pod keeps restarting every few hours. `kubectl describe pod` shows `OOMKilled` in the last state. The current memory limit in `values.yaml` is `128Mi`. How do you fix this correctly?**

**Expected Answer:**
- `OOMKilled` = the container exceeded its memory limit and the Linux kernel killed it. This is *not* a crash — it's a forced kill.
- **Wrong fix**: Just setting `limit: 1Gi` without understanding usage (over-provisioning wastes money, can starve other pods).
- **Right fix**:
  1. Check actual memory usage: `kubectl top pod <pod-name> -n kubeflow-ops` over time.
  2. Or look at the Grafana dashboard for memory usage trend.
  3. Set the limit to ~2x the observed peak (e.g., if it uses 90Mi normally but spikes to 110Mi, set to `256Mi`).
  4. Set `request` = typical usage, `limit` = spike ceiling.
  5. Also check the app itself — is there a memory leak? A sudden spike in requests causing unbounded caching?

---

### Q12 — ArgoCD: App Shows OutOfSync After Sync
**ArgoCD synced successfully 1 minute ago but immediately shows `OutOfSync` again. You haven't touched Git. What's happening?**

**Expected Answer:**
- Something in the cluster is being modified immediately after ArgoCD applies — creating a diff between live state and git state.
- Common causes:
  1. **A controller is mutating the resource**: e.g., a webhook (like Kyverno mutation) adds fields that aren't in the Helm template. ArgoCD sees these extra fields as drift.
  2. **Helm generates non-deterministic output**: e.g., a random value in an annotation or a timestamp — each sync produces a slightly different manifest.
  3. **HPA or VPA is modifying replica counts**: If `replicas` is hardcoded in the Helm chart but HPA is changing it, ArgoCD sees `replicas: 3` in live vs `replicas: 1` in git.
- Fix for HPA: Add `ignoreDifferences` in the ArgoCD Application for `spec.replicas` on Deployments.

---

### Q13 — Kyverno: Policy Not Applying to Existing Resources
**You added the `require-resource-limits` policy with `validationFailureAction: Enforce`. Existing pods with no limits are still running. New pods without limits are rejected. Is this expected? Why?**

**Expected Answer:**
- Yes, this is completely expected. Kyverno is an **admission controller** — it intercepts API requests when resources are **created or updated**.
- It does not retroactively kill or modify existing pods that were already admitted before the policy was created.
- The `background: true` setting runs the policy in background mode for audit reporting (it generates `PolicyReport` resources showing which existing resources violate the policy) — but it still doesn't evict them.
- To enforce on existing pods: you'd need to rolling-restart deployments (`kubectl rollout restart deployment -n kubeflow-ops`) — which triggers new pods that go through admission and must comply.

---

### Q14 — GitHub Actions: OIDC Auth Failing
**The CI pipeline fails at "Configure AWS Credentials (OIDC)" with: `Error: Not authorized to perform sts:AssumeRoleWithWebIdentity`. The same pipeline worked yesterday. What do you check?**

**Expected Answer:**
- The GitHub OIDC token is generated per-run. The issue is in the IAM **trust policy** for the role, not the token itself.
- Check the IAM role's trust policy on AWS. Common issues:
  1. The role ARN in `secrets.AWS_ROLE_ARN` points to the wrong role or account.
  2. The trust policy's `sub` condition is too restrictive — e.g., it only allows `ref:refs/heads/main` but this run is on a feature branch.
  3. Someone modified the trust policy (look at CloudTrail: `UpdateAssumeRolePolicy` event).
  4. The OIDC provider's thumbprint expired or was deleted from IAM.
- Verify: check CloudTrail for the failed `AssumeRoleWithWebIdentity` call — it will show the `sub` claim from the JWT and the condition that failed.

---

### Q15 — Docker: Image Builds But Container Crashes Immediately
**Docker image builds successfully in CI. It's pushed to ECR. When Kubernetes starts the pod, it crashes with exit code 1. `kubectl logs` shows nothing. How do you debug?**

**Expected Answer:**
```bash
# 1. Try running the image locally (simulate the container)
docker run --rm -it \
  -e DATABASE_URL="..." \
  <ecr-registry>/kubeflow-ops-order-service:<sha>

# 2. Check if it's an env var issue — missing required variable
kubectl describe pod <pod> -n kubeflow-ops | grep -A20 "Environment"

# 3. Check if secret is correctly mounted
kubectl get secret db-credentials -n kubeflow-ops -o jsonpath='{.data}' | base64 -d

# 4. Check init containers — they run before the main container
kubectl describe pod <pod> | grep -A10 "Init Containers"
```
- Exit code 1 = app started but errored out (Python exception, config error). The logs being empty usually means the crash happens before the logging library initializes.
- Run locally with the same env vars to reproduce.

---

### Q16 — Prometheus: Alert Keeps Firing After Fix
**You fixed the bug causing `HighErrorRate`. Errors stopped. But the alert is still in `FIRING` state 3 minutes later in Alertmanager. Why hasn't it resolved?**

**Expected Answer:**
- Prometheus evaluates the alert expression on every scrape interval (default 15s–1m). Once the expression no longer evaluates to true, the alert transitions to `RESOLVED` — but only after the `for` duration resets.
- The `HighErrorRate` alert has `for: 5m`. This means Prometheus needs to observe the condition continuously for 5 minutes before firing — but on *resolution*, it resolves immediately once the expression is false.
- So 3 minutes is actually *shorter* than the evaluation + Alertmanager re-evaluation cycle. If it's still firing at 3 min, check:
  1. Is the fix actually deployed? Check the pod image tag.
  2. Is Prometheus still scraping error metrics from the old pod (during rolling update, old pods may still be alive)?
  3. Check: `kubectl get pods -n kubeflow-ops -l app=order-service` — are old pods still terminating?

---

### Q17 — Terraform: `apply` Wants to Delete a Database
**During `terraform plan`, you see `-  aws_db_instance.postgres` — Terraform wants to destroy your production RDS instance. You didn't intend this. What do you do immediately, and how do you find the cause?**

**Expected Answer:**
- **Do NOT run `terraform apply`.** This would destroy production data.
- Immediate steps:
  1. Stop any pipeline from auto-applying. Check if `terraform apply` is gated to `main` merges (it is in this project's `terraform.yml` — only applies on push to main, not PR).
  2. Run `terraform plan -out=tfplan` and read the full diff carefully.
- Finding the cause:
  - Did someone delete the `rds` module reference from `main.tf`? Check `git diff`.
  - Did someone rename the resource block? Terraform sees rename = destroy + create.
  - Did the RDS module's required variables change, causing an in-place replacement (e.g., `identifier` changed = new RDS = old one gets destroyed)?
- **Fix**:
  - If rename: use `terraform state mv aws_db_instance.old_name aws_db_instance.new_name`.
  - Add a lifecycle rule: `lifecycle { prevent_destroy = true }` to the RDS resource to block accidental destruction.

---

### Q18 — Kubernetes: Service Endpoint Not Reachable
**Inside the `order-service` pod, you try `curl http://user-service.kubeflow-ops.svc.cluster.local:8002/health` and get `Connection refused`. `kubectl get svc user-service -n kubeflow-ops` shows the service exists. What's wrong?**

**Expected Answer:**
- Service exists but connection refused means the **port the service is forwarding to is wrong**, or **no healthy pods are backing the service**.
- Check 1: `kubectl get endpoints user-service -n kubeflow-ops` — if `<none>`, no pods match the selector. The `selector` in the Service doesn't match the pod's labels.
- Check 2: Is `user-service` pod actually listening on port 8002? `kubectl exec -it <user-service-pod> -- ss -tlnp` or `netstat -tlnp`.
- Check 3: Is the pod `Ready`? If readiness probe fails, the endpoint is removed. `kubectl describe pod <user-service-pod>` → check readiness probe.
- Check 4: Port mismatch — the Service's `targetPort` might be `8002` but the container actually listens on `8000`.

---

### Q19 — SonarQube: Quality Gate Green But Bug in Prod
**SonarQube Quality Gate passed (coverage 75%, no critical issues). Two days later, a production bug is found in a code path that supposedly had test coverage. How is this possible?**

**Expected Answer:**
- Coverage % means a line of code was *executed* during tests — not that it was tested *correctly*.
- Example: a test calls `create_order()` and the line runs, but the test doesn't assert the return value or side effects. Coverage = 100% for that line, but behavior is untested.
- SonarQube's quality gate checks: coverage threshold, code smells, security hotspots — but it does **not** verify test quality or assertion coverage.
- SonarQube also can't catch: race conditions, environment-specific behavior, downstream dependency failures, or business logic errors that don't throw exceptions.
- Lesson: coverage is a floor, not a ceiling. It tells you *what* was executed, not *whether it works correctly*.

---

### Q20 — Smoke Test: Rollback Triggered But Service Still Down
**The smoke test ran, detected `/healthz` returning 503, triggered `kubectl rollout undo`, and reported "Rollback complete". But users are still seeing errors 5 minutes later. What do you investigate?**

**Expected Answer:**
- `kubectl rollout undo` reverts to the previous ReplicaSet — but "complete" just means the rollout *started* without errors, not that traffic is fully restored.
- Check 1: `kubectl rollout status deployment/order-service -n kubeflow-ops` — is the rollback actually finished?
- Check 2: Are the old pods actually Ready? `kubectl get pods -n kubeflow-ops -l app=order-service`
- Check 3: Is the **previous image** also broken? If the last 2 releases were bad, rolling back still leaves you with a broken version.
- Check 4: Is there an **AWS Load Balancer** caching the unhealthy target? ALB target deregistration can take 30–60 seconds even after pods are Ready.
- Check 5: Is the issue in a **shared dependency** (RDS, SQS, Secrets Manager) — rolling back the app won't fix an infra outage.

---
---

## 🟡 Mid Level — 3 to 6 Years of Experience (Q21–Q30)
> These questions require connecting multiple systems together, reading PromQL deeply, and making architecture decisions under pressure.

---

### Q21 — End-to-End GitOps Failure: Which System Broke?
**A developer pushed code. CI passed. But 10 minutes later, the new version still isn't in EKS. There are no errors in GitHub Actions. Where do you look next, in order?**

**Expected Answer (ordered debugging path):**
1. **Check if `values.yaml` was actually updated**: `git log --oneline gitops/apps/order-service/values.yaml` — is the bot commit there?
2. **Check ArgoCD**: `argocd app get order-service` — is it `Synced`? If `OutOfSync`, is it syncing?
3. **Check ArgoCD sync status**: `argocd app sync order-service --dry-run` — does it find a diff?
4. **Check the ArgoCD Application's source**: Is `repoURL` pointing to the correct repo and `targetRevision: main`?
5. **Check if ArgoCD's git polling picked up the commit**: ArgoCD polls git every 3 minutes by default. Force a refresh: `argocd app get order-service --refresh`.
6. **Check Helm rendering**: `helm template order-service gitops/charts/microservice/ -f gitops/apps/order-service/values.yaml` — does it render the new image tag?
7. **Check Kyverno**: If the new image tag somehow triggers a policy violation (e.g., tag looks like `latest`), admission will block it silently from ArgoCD's perspective.

---

### Q22 — IRSA: Permission Error in Production Only
**External Secrets works fine in `dev` but in `prod`, the ESO pod logs show `AccessDenied: is not authorized to perform: secretsmanager:GetSecretValue on resource: kubeflow-ops/prod/db-credentials`. Exact same ESO deployment. What's different?**

**Expected Answer:**
- **Root cause is almost always the IAM role**: Dev and prod use different IAM roles (scoped per environment).
- Check 1: The prod ESO ServiceAccount — what IAM role is it annotated with? `kubectl get sa external-secrets -n external-secrets -o yaml | grep role-arn`
- Check 2: Does that IAM role's **policy** allow `secretsmanager:GetSecretValue` on the prod secret path (`kubeflow-ops/prod/*`)? The dev role likely allows `kubeflow-ops/dev/*`.
- Check 3: The `ClusterSecretStore` in prod — is `region` set to `us-east-1`? If the secret is in a different region, the call goes to the wrong endpoint.
- Check 4: Does the IRSA role's **trust policy** allow the prod cluster's OIDC provider? Each EKS cluster has its own OIDC issuer URL — using the dev cluster's OIDC provider URL in a prod IAM trust policy = auth fails.

---

### Q23 — Prometheus PromQL: Write an Alert for This Scenario
**Notification service is consuming from SQS. You need an alert that fires when orders are being created successfully but no notifications are being sent — sustained for 10 minutes. Write the PromQL.**

**Expected Answer:**
```yaml
alert: NotificationProcessingLag
expr: |
  sum(increase(http_requests_total{
    service="notification-service",
    path="/process",
    status="200"
  }[5m])) == 0
  and
  sum(increase(http_requests_total{
    service="order-service",
    method="POST",
    path="/orders",
    status="201"
  }[5m])) > 0
for: 10m
labels:
  severity: warning
  team: platform
annotations:
  summary: "Notifications not being processed"
  description: "Orders are being created but notification-service processed 0 messages in 10 min. Check SQS consumer."
```
- This is the exact `NotificationProcessingLag` alert in `alert-rules.yaml`. The candidate should be able to construct this logic from scratch.
- Key insight: `and` operator in PromQL requires *both sides to match on the same label set*. `on()` may be needed to match across different label sets. Using `on()` forces a scalar-to-vector match when label sets differ.

---

### Q24 — ArgoCD: Multiple Apps Failing After a Platform Change
**You updated the `microservice` Helm chart (added a required field `serviceAccountName`). Now all 3 services (`order-service`, `user-service`, `notification-service`) are `OutOfSync` in ArgoCD. What's your rollout strategy?**

**Expected Answer:**
- Adding a **required** field to a shared chart without defaults is a breaking change. This is a platform-level failure.
- **Immediate**: Don't sync any apps yet — a forced sync will fail for all 3 services because the Helm template will error (missing required value).
- **Fix options**:
  1. **Add a default in `Chart/values.yaml`**: `serviceAccountName: default` — now the chart renders even without the value set per-service. Safest.
  2. **Add the value to each service's `values.yaml`** before triggering any sync.
- **Rollout strategy after fix**:
  1. Sync `dev` services first — verify the chart renders and pods start.
  2. Sync `staging`, observe.
  3. Sync `prod` with manual ArgoCD sync (disable auto-sync temporarily for prod).
- **Prevention**: When modifying shared Helm charts, always provide defaults. Test with `helm template` against all `values.yaml` files before pushing: `helm template ... -f values.yaml --validate`

---

### Q25 — Kyverno: Policy Is Blocking a Legitimate System Pod
**Cluster Autoscaler pods in `kube-system` are failing. `kubectl describe pod cluster-autoscaler -n kube-system` shows: `"CPU and memory limits are required"`. But the CA pods have no limits defined. Fix this without removing the policy.**

**Expected Answer:**
- The `require-resource-limits` policy already has an `exclude` block:
  ```yaml
  exclude:
    any:
      - resources:
          namespaces:
            - kube-system
            - argocd
            - kyverno
            - observability
  ```
- If CA is failing, it means either: (a) the policy was recently changed and `kube-system` was accidentally removed from the exclusion list, or (b) the Cluster Autoscaler is being deployed to a *different* namespace.
- **Fix**: Add back `kube-system` to the `exclude` block in the policy YAML, commit to Git, let ArgoCD sync.
- **Lesson**: Kyverno exclusions should cover all system namespaces. Check any new tool installation — ensure its namespace is in the exclusion list or ensure it ships with proper resource limits.

---

### Q26 — GitHub Actions: Concurrency and the Git Push Race
**Two developers push to `apps/order-service/` within 20 seconds. The concurrency group cancels the first run. The second run reaches the `git push` step and fails with `rejected: non-fast-forward`. Explain why and how you'd fix this permanently.**

**Expected Answer:**
- Both runs start with `actions/checkout@v4` at the same commit. They both build and update `values.yaml` with their respective SHAs.
- Second run's `git push` fails because the *first run's* bot commit (from before it was cancelled) already landed on `main` — making the second run's local branch behind.
- **Why the cancel helps but doesn't fully fix it**: The cancel stops the first run's *future steps*, not steps already completed. If the first run already pushed before the cancel signal, the second run's push is rejected.
- **Fixes**:
  1. Add `git pull --rebase origin main` before `git push` in the CI step.
  2. Add a retry loop: push, if rejected, pull-rebase, push again.
  3. Better: Use a dedicated GitOps update tool that handles serialization (e.g., a webhook that updates the file through a proper API rather than raw git push).

---

### Q27 — Terraform: Plan Shows No Changes But Infrastructure Drifted
**Someone manually deleted an SQS queue through the AWS Console. `terraform plan` shows "No changes. Infrastructure is up-to-date." How is this possible and how do you remediate?**

**Expected Answer:**
- `terraform plan` compares the **Terraform state file** to the desired configuration — NOT to actual AWS resources. If the state file says the queue exists and the config also says it should exist, plan shows "no changes."
- The **state file is stale** — it still has the SQS queue resource recorded as existing.
- Detection: `terraform plan -refresh-only` — this refreshes the state from actual AWS APIs and shows the drift.
- Remediation:
  1. `terraform apply -refresh-only` — updates the state to reflect the real world (queue deleted).
  2. Then `terraform plan` — now it shows "will create SQS queue" (the queue is missing from AWS but wanted by config).
  3. `terraform apply` — recreates the queue.
- **Prevention**: Enable AWS Config + Terraform Drift Detection. Add the SQS queue resource with a `lifecycle { prevent_destroy = true }` if it's critical.

---

### Q28 — Observability: You Need to Debug a Slow API — No APM Installed
**`HighLatency` alert fires: P95 latency > 2s for `order-service`. You have only Prometheus metrics and `kubectl`. No APM, no distributed tracing. Walk through your debugging approach.**

**Expected Answer:**
- **Step 1 — Narrow it down** in Prometheus/Grafana:
  - Filter by endpoint: `histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{service="order-service", path="/orders"}[5m]))` — is it all endpoints or specific ones?
  - Filter by method: POST vs GET latency different?
- **Step 2 — Correlate with resource usage**:
  - Is CPU maxed? `kubectl top pods -n kubeflow-ops`
  - Rate-limited? Check if replicas are at HPA max.
- **Step 3 — Check downstream**:
  - Is the service making slow DB calls? Add `kubectl exec -it <pod> -- python -c "import time; import psycopg2; ..."` to test DB response directly.
  - Is SQS publish slow? Check SQS `NumberOfMessagesSent` latency in CloudWatch.
- **Step 4 — Thread/connection issue**:
  - `kubectl exec -it <pod> -- ss -s` — how many open connections?
  - Is the DB connection pool exhausted?
- **Step 5**: If you can deploy a change — add structured logging with per-request timing at each layer to identify the bottleneck.

---

### Q29 — Security: Secret in Git History
**A developer accidentally committed a real `DATABASE_URL` string (with password) to `apps/order-service/config.py`. They deleted it in the next commit. Is the project now safe? What do you do?**

**Expected Answer:**
- **No, the project is NOT safe.** Deleting code in a new commit doesn't remove it from git history. Anyone with `git clone` access can run `git log -p` or `git show <old-commit>` and read the password.
- **Immediate actions**:
  1. **Rotate the database password immediately** in RDS and in AWS Secrets Manager — treat the credential as fully compromised.
  2. **Rewrite git history** using `git filter-repo` (preferred over deprecated `BFG Repo Cleaner`) to remove the sensitive commit from all branches and tags.
  3. Force-push the rewritten history — coordinate with all team members to re-clone.
  4. Check if any GitHub Actions artifact, PR review, or fork already has the commit cached.
  5. Report the incident — if required by compliance (SOC2, PCI-DSS, GDPR).
- **Prevention**: Add `detect-secrets` as a pre-commit hook. GitHub has native secret scanning that can be enabled at org level and blocks pushes containing secrets.

---

### Q30 — HPA + Load: Autoscaler Not Keeping Up
**`order-service` is under high load. HPA is configured. But response times are climbing. `kubectl get hpa order-service -n kubeflow-ops` shows `REPLICAS: 5/5` (at max). `kubectl get nodes` shows all nodes at 80% CPU. What do you do right now?**

**Expected Answer — immediate triage:**
1. **Increase HPA `maxReplicas`** — if node capacity exists: edit the `values.yaml` in git, push, let ArgoCD sync. This is the fastest fix if nodes have headroom.
2. **If nodes are also full**: Cluster Autoscaler needs to add nodes. Check CA logs: `kubectl logs -n kube-system deploy/cluster-autoscaler | tail -50` — is it trying to scale? Is it blocked by the ASG max size in Terraform?
3. **Check the Terraform module for EKS node group**: `max_size` limits how many nodes CA can add. Temporarily increase it in Terraform if needed.
4. **Short-term relief**: If scaling is too slow, restrict non-critical traffic (circuit breaker, rate limiting, return 503 to low-priority clients).
5. **Post-incident**: The `HPAMaxedOut` alert (in `alert-rules.yaml`) fires after 15 minutes at max replicas — this incident shows that alert threshold is too slow. Lower to 5 minutes and automate a runbook or Karpenter provisioner to handle node scale-out faster.

---
---

## 🔴 Senior Level — 6 to 10 Years of Experience (Q31–Q35)
> These questions require system design, security depth, and trade-off articulation — not just operational knowledge.

---

### Q31 — Architecture: The Git Push Race at Scale
**This project has CI commit back to the same `gitops/` folder after every image build. At 20+ microservices with frequent deploys, this creates constant git conflicts and bot commits polluting the main branch history. Design an architecture that solves this permanently.**

**Expected Answer:**
- **Root cause**: The "image updater as CI step" pattern doesn't scale — CI writes to the same repo it's triggered by, creating feedback loops, race conditions, and noisy history.
- **Solution: Separate the GitOps repo**
  - Create a dedicated `platform-gitops` repo containing *only* Helm values and ArgoCD applications.
  - Source code repos (`order-service`, `user-service`, etc.) trigger CI, build and push images — then call the GitOps repo's API (via a PR or direct push using a machine token with narrow write scope).
  - The GitOps repo has its own PR review process — image tag bumps are PRs, not direct pushes.
- **Solution: ArgoCD Image Updater**
  - Install `argocd-image-updater` — it watches ECR, detects new image tags, and updates `values.yaml` in the GitOps repo automatically without CI involvement.
  - Eliminates the git push step from CI entirely.
- **Solution: Argo Rollouts with digest pinning**
  - Deploy by digest (`sha256:...`) — updater polls ECR for new digests, no git conflict possible since each digest is unique.
- **Trade-off to articulate**: Separate repo = stronger separation of concerns, better access control, cleaner audit trail. Downside = more operational overhead for repo management.

---

### Q32 — Security: OIDC Trust Policy Scope Creep
**You discover the GitHub OIDC trust policy on your production AWS IAM role has `"sub": "repo:YOUR_ORG/*:*"` — a wildcard. A security audit flags this. Explain the risk and design a hardened, multi-environment trust policy architecture.**

**Expected Answer — the risk:**
- Any GitHub Actions workflow in *any repository in your org*, on *any branch*, can assume the production IAM role.
- A compromised package (dependency confusion attack on any repo), a malicious fork, or a misconfigured new repo's workflow = production AWS access.

**Hardened architecture:**
```json
// Production role trust policy — most restrictive
{
  "Condition": {
    "StringEquals": {
      "token.actions.githubusercontent.com:sub":
        "repo:YOUR_ORG/kubeflow-devsecops:ref:refs/heads/main",
      "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
    }
  }
}
```
- **Per environment, separate IAM roles**: `github-actions-dev-role`, `github-actions-staging-role`, `github-actions-prod-role`.
- Prod role: only `main` branch of the deployment repo. Never PR branches.
- Dev role: can be broader — feature branches are fine.
- Add `aws:RequestedRegion` condition to limit role to `us-east-1` only.
- Add `aws:SourceIp` condition if GitHub Actions uses static IPs (they now publish their IP ranges).
- Enable **CloudTrail** + **AWS Config rule** to alert on any change to these trust policies.
- Add IAM **permission boundaries** on the roles — even if the trust policy is ever misconfigured, the permission boundary limits the blast radius.

---

### Q33 — Observability: SLO Design for This System
**The team currently has reactive alerts (fires when already broken). Design an SLO framework for `order-service` that allows you to detect and predict failures *before* they impact users, using only Prometheus.**

**Expected Answer:**
- **Define the SLO**: 99.9% of order creation requests succeed with <1s P95 latency, measured over a 30-day rolling window.
- **Error budget**: 0.1% of requests = ~43 minutes of full downtime equivalent per 30 days.
- **Multi-window, multi-burn-rate alerting (Google SRE approach)**:
  ```yaml
  # Fast burn: consuming error budget 14x faster than normal
  # If this fires, you have ~1 hour before budget exhaustion
  - alert: OrderServiceFastBurnRate
    expr: |
      (
        sum(rate(http_requests_total{service="order-service",status=~"5.."}[1h]))
        / sum(rate(http_requests_total{service="order-service"}[1h]))
      ) > 14 * 0.001  # 14x the error budget burn rate
    for: 2m
    labels:
      severity: critical

  # Slow burn: consuming error budget 3x faster over 6 hours
  # You won't run out today, but will in ~10 days
  - alert: OrderServiceSlowBurnRate
    expr: |
      (
        sum(rate(http_requests_total{service="order-service",status=~"5.."}[6h]))
        / sum(rate(http_requests_total{service="order-service"}[6h]))
      ) > 3 * 0.001
    for: 15m
    labels:
      severity: warning
  ```
- **Recording rules** for the 30-day SLO window (heavy computation, pre-compute):
  ```yaml
  - record: job:order_service_error_rate:30d
    expr: |
      sum(increase(http_requests_total{service="order-service",status=~"5.."}[30d]))
      / sum(increase(http_requests_total{service="order-service"}[30d]))
  ```
- **Dashboards**: Show current error budget remaining, burn rate trend, time until budget exhaustion at current rate.

---

### Q34 — Platform Engineering: Zero-Downtime Migration
**You need to migrate the `order-service` database from RDS PostgreSQL 13 to PostgreSQL 15 with zero downtime and zero data loss. The service is live in production handling 500 req/min. Design the migration strategy using the tools available in this project.**

**Expected Answer:**
- **Zero-downtime constraint** eliminates: stop service → migrate → restart. That's downtime.
- **Strategy: Blue-Green database migration with dual-write**

  **Phase 1 — Provision**:
  - Use Terraform to provision the new RDS PostgreSQL 15 instance (add a new `aws_db_instance` resource, don't modify the existing one).
  - Enable RDS blue-green deployment if available (AWS-native).

  **Phase 2 — Replicate**:
  - Use AWS DMS (Database Migration Service) or logical replication to sync data from PG13 → PG15 continuously (CDC — Change Data Capture).
  - Wait until replication lag is near zero.

  **Phase 3 — Dual-write app code** (if DMS isn't sufficient):
  - Deploy a version of `order-service` that writes to *both* databases simultaneously.
  - This version is deployed via the existing GitOps CI/CD pipeline.

  **Phase 4 — Cutover**:
  - Update `kubeflow-ops/prod/db-credentials` in AWS Secrets Manager to point to the new RDS endpoint.
  - External Secrets Operator syncs this to the K8s Secret within `refreshInterval: 1h` — or trigger an immediate sync.
  - `order-service` pods restart (or the app re-reads credentials) and now connect to PG15.

  **Phase 5 — Validate and clean up**:
  - Monitor error rates in Prometheus for 30 minutes.
  - Run smoke tests.
  - Decommission PG13 (update Terraform to remove it, apply).

---

### Q35 — Architecture: The Hard Trade-Off
**Your VP asks: "Should we replace this entire self-managed Kubernetes platform (EKS + ArgoCD + Helm + Kyverno + ESO + Prometheus) with AWS App Runner + AWS managed services? It would be simpler." Make the complete case for and against and give a final recommendation.**

**Expected Answer (demonstrates senior architectural judgment):**

**Case FOR keeping the current architecture:**
- **Vendor independence**: The entire delivery stack (ArgoCD, Helm, Kyverno, Prometheus) is cloud-agnostic. A future migration to GCP GKE or Azure AKS costs weeks, not months.
- **GitOps audit trail**: Every infrastructure change is a git commit — immutable, reviewable, rollback-able. AWS App Runner has no equivalent.
- **Policy as code (Kyverno)**: Admission control, security guardrails, and compliance rules are version-controlled and auditable. App Runner has no concept of admission policies.
- **Observability depth**: PromQL enables precise business-level alerts (OrderCreationFailures, NotificationProcessingLag). CloudWatch Metrics are coarser and more expensive per custom metric.
- **Cost at scale**: Beyond ~20 services, EKS unit economics beat managed container services. App Runner is priced on vCPU-hours — Kubernetes packs workloads more efficiently.
- **Team expertise**: The team already knows this stack. Migration cost (retraining, rewriting pipelines) is non-trivial.

**Case FOR App Runner / managed services:**
- **Operational overhead is real**: This project needs expertise in 6+ tools. A 3-person team spending 30% of their time on platform maintenance is a product velocity killer.
- **Reliability burden**: ArgoCD, ESO, Kyverno are all failure points. AWS managed services include uptime SLAs.
- **Time-to-market for new services**: App Runner deploys in minutes with zero Kubernetes knowledge. This GitOps stack has multi-week onboarding.
- **Security patching**: EKS control plane is managed, but node AMIs, add-ons (Kyverno, ESO, ArgoCD), and Helm charts need manual upgrades and CVE management.

**Final recommendation (nuanced answer — this is what distinguishes senior candidates):**
> "Keep the current architecture *as the right choice for this stage and scale*. The investment in GitOps, policy-as-code, and observability is paying dividends in auditability and reliability that App Runner cannot match. However, I'd recommend investing in platform automation: Karpenter instead of Cluster Autoscaler, Renovate Bot for automated Helm/image upgrades, and ArgoCD ApplicationSets to reduce onboarding friction. Revisit the 'go managed' question when the team drops below 5 engineers or if a cloud-agnostic requirement disappears."

---

## 📊 Coverage Matrix

| # | Core Skill | Technology Tested |
|---|---|---|
| Q1 | Debugging | ArgoCD, GitOps, yq |
| Q2 | Pipeline logic | GitHub Actions, paths-filter |
| Q3 | Admission control | Kyverno |
| Q4 | Incident response | Prometheus, kubectl |
| Q5 | Security scanning | Trivy, Docker |
| Q6 | IaC recovery | Terraform, DynamoDB |
| Q7 | Secrets debugging | External Secrets, IRSA, AWS SM |
| Q8 | Helm recovery | Helm, Kubernetes |
| Q9 | Deployment verification | kubectl, ECR |
| Q10 | Test design | Smoke tests, rollback |
| Q11 | Coverage edge case | SonarQube |
| Q12 | Real-time incidents | kubectl, Kubernetes |
| Q13 | Policy internals | Kyverno, admission control |
| Q14 | Auth debugging | OIDC, IAM, CloudTrail |
| Q15 | Container debugging | Docker, env vars, K8s |
| Q16 | Alert lifecycle | Prometheus, Alertmanager |
| Q17 | IaC safety | Terraform, state, lifecycle |
| Q18 | Networking | Kubernetes DNS, Services, Endpoints |
| Q19 | Test philosophy | SonarQube, coverage |
| Q20 | Rollback debugging | smoke tests, ALB, kubectl |
| Q21 | System tracing | All GitOps components |
| Q22 | Cross-env auth | IRSA, OIDC, IAM scoping |
| Q23 | PromQL authoring | Prometheus, alert design |
| Q24 | Platform changes | Helm, ArgoCD, rollout strategy |
| Q25 | Policy scoping | Kyverno, system namespaces |
| Q26 | Race conditions | GitHub Actions, git |
| Q27 | State drift | Terraform, AWS Config |
| Q28 | Latency debugging | Prometheus, kubectl, no APM |
| Q29 | Security incident | Git history, credential rotation |
| Q30 | Auto-scaling | HPA, Cluster Autoscaler, Karpenter |
| Q31 | GitOps architecture | ArgoCD, image updater, repo design |
| Q32 | IAM security design | OIDC, trust policies, permission boundaries |
| Q33 | SLO framework | Prometheus, error budgets, burn rates |
| Q34 | DB migration | RDS, Terraform, ESO, zero-downtime |
| Q35 | Architecture trade-offs | Full platform, business judgment |
