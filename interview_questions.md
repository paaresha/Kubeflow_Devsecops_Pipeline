# 🎯 30 Production-Level DevSecOps Interview Questions
### Based on the Kubeflow DevSecOps Pipeline Project
> **Stack**: AWS EKS · Terraform · ArgoCD · Helm · GitHub Actions · OIDC · Kyverno · External Secrets Operator · Prometheus · SonarQube · Trivy

---

## 🟢 Entry Level — 0 to 2 Years of Experience
> Focus: Understanding core concepts, debugging basic issues, reading configs correctly

---

### Q1 — GitOps & ArgoCD
**Your team just merged a change to [gitops/apps/order-service/values.yaml](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/apps/order-service/values.yaml) but the pod in the cluster still shows the old image. ArgoCD shows `Synced` status. What do you check first?**

**Expected Answer:**
- Check if `selfHeal: true` is actually set on that Application object — if not, ArgoCD will sync on git changes but won't revert manual drift, and "Synced" just means the last sync succeeded.
- Check the `image.tag` field in the [values.yaml](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/charts/microservice/values.yaml) — the CI pipeline uses `yq` to update it. If the git push from the CI bot failed (e.g., merge conflict with another commit), [values.yaml](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/charts/microservice/values.yaml) may have the old SHA.
- Run `argocd app get <app-name>` and look at the `Status` and `Health` — Synced ≠ Healthy.
- Check ArgoCD's sync history (`argocd app history`) to see if the last sync actually applied the new version or if it was a no-op.

---

### Q2 — CI Pipeline: OIDC & Secret-less Auth
**A new developer asks: "Why don't we just store `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` as GitHub Secrets? It would be simpler." How do you explain the problem and what this pipeline does instead?**

**Expected Answer:**
- Static access keys are long-lived credentials — if they leak (in logs, in a PR, via a compromised action), they can be used by anyone until manually rotated.
- This pipeline uses **OIDC (OpenID Connect)**: GitHub's OIDC provider issues a short-lived JWT for each workflow run. AWS is configured to trust that JWT and allows assuming a specific IAM role only for that run.
- The `id-token: write` permission and `aws-actions/configure-aws-credentials@v4` with `role-to-assume` implement this. No static keys exist anywhere.
- The token is valid only for the duration of that job — minimal blast radius if compromised.

---

### Q3 — Kyverno: Policy Enforcement
**A developer deploys a Pod with `image: nginx:latest`. The pod is rejected. They come to you saying "ArgoCD says it failed to sync". Walk them through the fix.**

**Expected Answer:**
- The `disallow-latest-tag` Kyverno `ClusterPolicy` with `validationFailureAction: Enforce` is blocking the admission.
- They need to replace `:latest` with a specific immutable tag (e.g., a git SHA like `nginx:sha-abc1234`).
- You can verify by running: `kubectl describe pod <pod-name>` or checking events: `kubectl get events -n <namespace>` — the rejection message will say "Image tag 'latest' is not allowed."
- In ArgoCD, the sync error will surface in the `Conditions` tab of the Application.

---

### Q4 — Prometheus Alerts: Reading PromQL
**The `HighErrorRate` alert fires. A junior asks what the PromQL expression actually calculates. Break it down.**

```yaml
sum(rate(http_requests_total{status=~"5.."}[5m])) by (service)
/
sum(rate(http_requests_total[5m])) by (service)
> 0.05
```

**Expected Answer:**
- `rate(...[5m])`: calculates the per-second rate of change over the last 5-minute window (smoothed).
- `{status=~"5.."}`: regex filter — selects only HTTP 500-class responses.
- The numerator = rate of 5xx errors. The denominator = rate of all requests.
- Dividing gives the **error ratio** (e.g., 0.08 = 8% error rate).
- `> 0.05` means the alert fires when more than 5% of requests are errors.
- `by (service)` groups the result per service, so each service alerts independently.

---

### Q5 — Helm: Values Layering
**In the deploy pipeline, Helm is called with two `-f` flags: `-f values.yaml -f values-${ENV}.yaml`. A developer asks why two files? What's the pattern called?**

**Expected Answer:**
- This is the **Helm values layering/override pattern**.
- [values.yaml](file:///c:/PROJECTS/Kubeflow_Devsecops_Pipeline/gitops/charts/microservice/values.yaml) contains service-level defaults: image name, port, resource limits, replica count.
- `values-prod.yaml` (or `-dev`, `-staging`) overrides environment-specific values: resource limits, replica counts, ingress hostnames, feature flags.
- Later `-f` files take precedence over earlier ones.
- This avoids duplication — common config lives in one place; only the differences are in environment files.

---

### Q6 — Terraform Basics
**The Terraform pipeline runs `terraform plan` on PRs but `terraform apply` only on merge to `main`. Why is this separation important? What could go wrong if apply ran on every PR?**

**Expected Answer:**
- `plan` is a **read-only, safe** operation — it shows what would change, doesn't touch real infrastructure.
- If `apply` ran on feature branches: multiple parallel PRs could apply conflicting infrastructure changes simultaneously, causing state corruption.
- Infrastructure changes on a PR branch violate the GitOps principle that `main` = production truth.
- The plan output is posted as a PR comment (`actions/github-script`), letting reviewers see exact changes before merging.
- Applying only on `main` ensures a linear, reviewable infrastructure change history.

---

### Q7 — External Secrets Operator
**A pod fails to start with `secret "db-credentials" not found`. How do you debug this using the External Secrets setup in this project?**

**Expected Answer:**
1. Check if the `ExternalSecret` resource exists: `kubectl get externalsecret db-credentials -n kubeflow-ops`
2. Check its status: `kubectl describe externalsecret db-credentials -n kubeflow-ops` — look for `Ready: False` and the error message.
3. Common causes:
   - The IRSA (IAM Roles for Service Accounts) role doesn't have `secretsmanager:GetSecretValue` permission.
   - The secret path `kubeflow-ops/dev/db-credentials` doesn't exist in AWS Secrets Manager.
   - The `ClusterSecretStore` itself is misconfigured — check `kubectl describe clustersecretstore aws-secrets-manager`.
4. Check the operator logs: `kubectl logs -n external-secrets deploy/external-secrets`

---

### Q8 — Docker & Container Basics
**The Trivy scan step in CI runs with `exit-code: "0"`. A junior asks if that means vulnerabilities don't matter. How do you explain the current setup and what a production hardening looks like?**

**Expected Answer:**
- `exit-code: "0"` means Trivy scans and reports vulnerabilities but **does NOT fail the pipeline**, even if CRITICAL ones are found. It's currently set to "observe, don't block."
- In production hardening: set `exit-code: "1"` to fail the build on HIGH/CRITICAL CVEs — this is a hard gate.
- You can also use `ignore-unfixed: true` to only fail on CVEs that have a fix available, avoiding noise from unfixable base OS vulns.
- Some teams use `--severity CRITICAL` only to avoid alert fatigue.

---

### Q9 — Kubernetes: Pod Crashing
**The `PodCrashLoopBackOff` alert fires for the `order-service`. Walk through the first 5 commands you'd run to diagnose it.**

**Expected Answer:**
```bash
# 1. See which pods are crashing
kubectl get pods -n kubeflow-ops

# 2. Get the crash reason (exit code, OOM, etc.)
kubectl describe pod <pod-name> -n kubeflow-ops

# 3. Read the last container logs (before crash)
kubectl logs <pod-name> -n kubeflow-ops --previous

# 4. Check recent events
kubectl get events -n kubeflow-ops --sort-by=.lastTimestamp

# 5. Check if it's a resource issue (OOMKilled)
kubectl top pods -n kubeflow-ops
```
OOMKill = memory limit too low. Exit code 1 = app crash (check logs). Exit code 137 = SIGKILL (usually OOM).

---

### Q10 — Smoke Test & Rollback
**The smoke test job in the deploy pipeline fails with HTTP 503. What does the pipeline do automatically, and what would you then do manually to investigate root cause?**

**Expected Answer:**
- The pipeline runs `kubectl rollout undo deployment/<service> -n kubeflow-ops` — this reverts to the previous ReplicaSet, restoring the last working version.
- Then it runs `kubectl rollout status` to confirm the rollback was successful.
- To investigate manually:
  - `kubectl logs` on the failed pod (the new version) using `--previous` flag since it's already rolled back.
  - `kubectl describe deployment <service>` to see the rollout events.
  - Check if there's a misconfigured env var, failed DB migration, or startup probe issue that caused the /healthz endpoint to return 503.

---
---

## 🟡 Mid Level — 3 to 6 Years of Experience
> Focus: Architecture decisions, debugging complex flows, security depth, system design trade-offs

---

### Q11 — GitOps: Image Update Flow End-to-End
**Explain exactly what happens — from a developer pushing code to `apps/order-service/` to the new pod running in EKS — covering every system involved.**

**Expected Answer (complete flow):**
1. Developer pushes → GitHub detects change in `apps/**` → CI pipeline triggers.
2. `detect-changes` job uses `dorny/paths-filter` → only `order-service` job runs (matrix exclusion).
3. OIDC → IAM role assumed → ECR login.
4. Unit tests run with pytest. SonarQube analysis + Quality Gate checked.
5. Docker image built with `github.sha` as tag.
6. Trivy scans the image (currently non-blocking).
7. Image pushed to ECR with both `:<sha>` and `:latest` tags.
8. `yq` updates `gitops/apps/order-service/values.yaml` → `image.repository` and `image.tag`.
9. `git commit && git push` from the CI bot → the `gitops/` directory changes.
10. ArgoCD detects the diff between the cluster state and the git source → triggers a sync.
11. Helm renders the chart with new values → new Deployment manifest sent to EKS API server.
12. Kubernetes performs a rolling update → new pods start, old pods terminate.
13. The `for: 5m` on Prometheus alerts means transient issues during rollout won't page.

---

### Q12 — Concurrency in CI: Race Condition
**Two developers push to `apps/order-service/` within 30 seconds of each other. Walk through the concurrency behavior of the CI pipeline and describe what could go wrong with the git push step at the end.**

**Expected Answer:**
- `concurrency: group: ci-${{ github.ref }} cancel-in-progress: true` means the second push cancels the first run.
- However, if both runs reach the `git push` step (e.g., the cancel arrived too late), there's a **race condition**: both try to push to the same `gitops/apps/order-service/values.yaml`. The second push will fail with a non-fast-forward error.
- The current `|| echo "No changes"` after `git commit` swallows this silently.
- Production fix: The push step should use `git pull --rebase` before pushing, or use a retry loop. Alternatively, use a dedicated GitOps update tool like `flux image automation` or a separate "update image tag" webhook that serializes writes.

---

### Q13 — IRSA: How It Actually Works
**The External Secrets Operator authenticates with AWS using IRSA, not an access key. Explain the trust chain: from the Kubernetes ServiceAccount to AWS retrieving the secret.**

**Expected Answer:**
1. The ESO pod uses a **Kubernetes ServiceAccount** annotated with `eks.amazonaws.com/role-arn: arn:aws:iam::<account>:role/<role>`.
2. EKS's **OIDC identity provider** issues a projected ServiceAccount token (JWT) mounted into the pod.
3. When ESO calls AWS, the `aws-sdk` exchanges this JWT with AWS STS via `AssumeRoleWithWebIdentity`.
4. AWS validates the JWT signature against the OIDC provider's public keys → verifies the `sub` claim matches the ServiceAccount.
5. STS returns temporary credentials (AccessKeyId, SecretAccessKey, SessionToken) scoped to the IAM role.
6. ESO uses those credentials to call `secretsmanager:GetSecretValue` → pulls the secret → creates the K8s Secret.
7. The `ClusterSecretStore` in this project uses `auth.jwt.serviceAccountRef` to specify which ServiceAccount provides this token.

---

### Q14 — Kyverno: Enforce vs Audit
**The `require-labels` policy uses `validationFailureAction: Audit` while `disallow-privileged` uses `Enforce`. Explain when you'd use each in a production rollout strategy.**

**Expected Answer:**
- **Audit**: Policy violations are logged and reported (via PolicyReport CRDs) but **don't block** the resource from being created. Use for:
  - Rolling out a new policy to an existing cluster where violations already exist.
  - Measuring violation scope before you commit to enforcement.
  - "Soft" policies where operational disruption risk is too high to block.
- **Enforce**: Violations are rejected by the admission webhook — the resource never gets created. Use for:
  - Security-critical policies (no privileged containers, no latest tag).
  - Policies affecting new resources only (not existing ones).
- **Migration path**: Start with Audit → fix violations → switch to Enforce. This is exactly what this project does: labels are Audit (informational), security (privileged containers, resource limits) are Enforce.

---

### Q15 — Prometheus: Alert Tuning
**The `NoOrdersReceived` alert fires at 2am on Saturday. Turns out there are legitimately zero orders overnight. How do you fix this without removing the alert?**

**Expected Answer:**
- Add a **time-based inhibition** in Alertmanager using `time_intervals` (Alertmanager 0.24+):
  ```yaml
  time_intervals:
    - name: business_hours
      time_intervals:
        - weekdays: ['monday:friday']
          times:
            - start_time: '08:00'
              end_time: '20:00'
  ```
- Reference it in the route: `active_time_intervals: [business_hours]`
- OR modify the PromQL to only fire during business hours using `hour()` and `day_of_week()`:
  ```
  ... == 0 and on() (hour() >= 8 < 20) and on() (day_of_week() >= 1 <= 5)
  ```
- Alternatively, lower severity to `info` for off-hours and use Alertmanager routing rules to silence info-level outside business hours.

---

### Q16 — Helm: Release Already Exists
**`helm upgrade --install` was run with `--wait --timeout 5m` and the deployment never becomes Ready. After 5 minutes, the pipeline fails. The Helm release is now in `pending-upgrade` state. How do you recover?**

**Expected Answer:**
- `pending-upgrade` means Helm started an upgrade but it never completed — the release is locked.
- Fix: `helm rollback <release-name> 0 -n kubeflow-ops` → rolls back to the last successful revision.
- Or: `helm history <release-name>` → identify the last successful revision → `helm rollback <release-name> <revision-number>`.
- Root cause investigation: The `--wait` flag waits for all pods to be Ready. Common causes: OOMKill (memory limit too low), failed liveness probe, image pull error (wrong SHA in ECR), failed init container.
- In production: add `--atomic` flag to `helm upgrade`, which automatically rolls back on failure — removing the need for manual recovery.

---

### Q17 — ArgoCD: App-of-Apps + Drift
**Someone runs `kubectl delete deployment order-service -n kubeflow-ops` directly. What happens, and within how long?**

**Expected Answer:**
- ArgoCD's `selfHeal: true` is set on the root Application. ArgoCD continuously compares the live cluster state with git.
- Within **~3 minutes** (default reconciliation interval), ArgoCD detects the missing Deployment as "OutOfSync."
- It automatically re-applies the Helm chart for `order-service`, recreating the Deployment.
- This is the core GitOps guarantee — git is the **single source of truth** and the cluster self-heals.
- You can observe this: `argocd app get order-service` will briefly show `OutOfSync` before flipping back to `Synced`.
- Note: `selfHeal` applies to the **Applications** managed by the root app-of-apps. The root app itself must also have `selfHeal` for this to cascade.

---

### Q18 — Security: SonarQube Quality Gate
**SonarQube Quality Gate is failing on `order-service` because test coverage is below 70%. A PM is pressuring to merge anyway. What are the technical options, and what do you recommend?**

**Expected Answer:**
- **Technical options:**
  1. Bypass: Remove/comment out the `SonarQube Quality Gate` step — bad, defeats the purpose.
  2. Conditional skip: The current pipeline uses `if: ${{ secrets.SONAR_TOKEN != '' }}` — if the secret is removed, the step is skipped (a backdoor).
  3. Change the Quality Gate definition in SonarCloud UI — adjust the coverage threshold for this project.
  4. Add the missing tests to meet the threshold.
- **Recommendation**: Write the missing tests. Coverage gates exist for a reason — low coverage on `order-service` is a business risk, not just a metric.
- If time-critical: Add the tests, or negotiate which specific code paths need coverage. Never silently bypass the gate.

---

### Q19 — EKS Autoscaling: HPA + Cluster Autoscaler
**The `HPAMaxedOut` alert fires for `order-service` — it's been at max replicas for 15 minutes but no new nodes have been added. What's wrong, and how do you investigate?**

**Expected Answer:**
- HPA maxing out doesn't automatically trigger node addition — that's the **Cluster Autoscaler (CA)** or **Karpenter's** job.
- CA only adds nodes when pods are **unschedulable** (Pending). If all pods are running and within the HPA max, no Pending pods exist → no new nodes.
- Investigation:
  ```bash
  kubectl get pods -n kubeflow-ops -o wide     # all scheduled?
  kubectl describe hpa order-service -n kubeflow-ops  # see target vs actual metrics
  kubectl logs -n kube-system deploy/cluster-autoscaler  # CA decisions
  ```
- Fix options: Increase `maxReplicas` in the HPA config (within node capacity), or add more nodes to the node group, or if nodes are full, increase the node group max size in Terraform so CA can provision new nodes.

---

### Q20 — Incident Simulation: Full Outage
**At 3pm, `ServiceDown` and `HighErrorRate` alerts fire simultaneously for `order-service`. PagerDuty pages you. Walk through your incident response process for the first 10 minutes.**

**Expected Answer (STAR format expected):**
1. **Acknowledge** the page — set yourself as incident commander.
2. **Check ArgoCD** first: Is it a deployment-related outage? Check recent syncs: `argocd app history order-service`.
3. **Check Kubernetes**:
   ```bash
   kubectl get pods -n kubeflow-ops
   kubectl describe pod <failing-pod>
   kubectl logs <failing-pod> --previous
   ```
4. **Check metrics in Grafana**: error rate trend, when did it start, which endpoints.
5. **Check recent changes**: Recent image tag update? `kubectl rollout history deployment/order-service`.
6. **Rollback if deploy-related**: `kubectl rollout undo deployment/order-service`.
7. **Communicate**: Post in Slack incident channel with current status every 5 minutes.
8. **Check upstream dependencies**: Is RDS reachable? Is SQS backed up? (`kubectl exec -it <pod> -- nc -vz <db-host> 5432`)
9. Only escalate to DB team or AWS support if infra-level issue confirmed.
10. **Postmortem**: After resolution, document timeline, root cause, and preventive actions.

---
---

## 🔴 Senior Level — 6 to 10 Years of Experience
> Focus: Architecture, security design, scalability limits, multi-cluster, trade-off articulation

---

### Q21 — GitOps at Scale: Monorepo vs Multi-repo
**This project uses a single repo with both application code (`apps/`) and GitOps manifests (`gitops/`). At 50+ microservices, what problems does this create, and how would you architect the migration?**

**Expected Answer:**
- **Problems with monorepo at scale**:
  - `dorny/paths-filter` matrix becomes unwieldy — 50+ services in the matrix.
  - Every CI run checks all paths, even unrelated ones.
  - Git history is polluted with bot commits (CI updates image tags) mixed with developer commits — hard to audit.
  - Blast radius: a broken CI config affects all services.
  - Branch protection becomes complex if different teams own different services.
- **Migration architecture**:
  - **Source repos**: One repo per team or bounded context (e.g., `platform-team/order-service`).
  - **GitOps repo** (config repo): Separate, dedicated `platform-gitops` repo containing only Helm values + ArgoCD Applications. Strict access control.
  - CI in each source repo: on merge, calls the GitOps repo to update the image tag via PR (using a bot token) — reviewed before deployment.
  - ArgoCD watches the dedicated GitOps repo.
  - Use **ArgoCD ApplicationSet** with generators (Git directory generator) to auto-create Applications per service.

---

### Q22 — Security: OIDC Trust Policy Hardening
**Your company's AWS OIDC trust policy for GitHub Actions currently has `"token.actions.githubusercontent.com:sub": "repo:YOUR_ORG/*:*"` — a wildcard for any branch of any repo. What's the security implication and how do you harden it?**

**Expected Answer:**
- **Implication**: Any GitHub Actions run from **any repo in your org**, on **any branch**, can assume this IAM role. A compromised forked repo or a malicious PR workflow could assume production AWS credentials.
- **Hardening** — restrict the `sub` claim:
  ```json
  "token.actions.githubusercontent.com:sub": "repo:YOUR_ORG/kubeflow-devsecops:ref:refs/heads/main"
  ```
  - This restricts to only the `main` branch of a specific repo.
  - For multiple envs, use separate IAM roles per environment, each with tighter trust.
- **Additional controls**:
  - Use `aws:RequestedRegion` condition to restrict which AWS regions the role can operate in.
  - Use resource-level IAM policies on ECR/Secrets Manager rather than broad `*` resources.
  - Enable CloudTrail + AWS Config to audit role assumptions.
- Reference: [GitHub's hardening docs for OIDC](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)

---

### Q23 — Terraform: State Management at Scale
**Your team scales to 5 engineers, all making Terraform changes. Two engineers run `terraform apply` simultaneously on the `dev` environment. What happens, and how is this production system hardened to prevent it?**

**Expected Answer:**
- **Without DynamoDB locking**: Both `apply` operations read the same state file from S3 → both see the current state → both compute their plans → both apply → **state corruption** (the last write wins, losing the other's changes, or producing an inconsistent state file).
- **State locking with DynamoDB**: Terraform writes a lock entry to DynamoDB at the start of `plan` and `apply`. The second engineer's run sees the lock → waits or fails with a clear error. Lock is released on completion.
- **This pipeline's defense**: GitHub Actions `concurrency: cancel-in-progress: false` on the deploy job prevents parallel runs in the same environment group. Combined with S3 backend + DynamoDB lock, it's double-protected.
- **Additional best practices**:
  - Separate state files per environment (dev, staging, prod) → `environments/dev/terraform.tfstate`.
  - Terraform **workspaces** or separate state backends per service for further isolation.
  - `terraform plan -out=tfplan` + `terraform apply tfplan` — the plan file ensures what you reviewed is what gets applied (no TOCTOU).

---

### Q24 — Observability: Alert Gap Analysis
**A user reports the `order-service` was returning 502s for 3 minutes but no alert was triggered. Looking at the Prometheus alerts, find the gap and propose a fix.**

**Expected Answer — finding the gap:**
- `HighErrorRate` has `for: 5m` — this means the alert only fires after the condition has been true for 5 continuous minutes. A 3-minute outage **never triggers** it.
- `ServiceDown` uses `up == 0` which requires the scrape target itself to be down, not just returning errors.
- **The gap**: Application-level errors (502 from a working pod returning 5xx) lasting < 5 minutes are invisible.
- **Fixes**:
  1. Lower `for: 5m` to `for: 2m` for critical services — increases noise but reduces blind window.
  2. Add a **separate alert for sustained burst errors**:
     ```yaml
     expr: sum(increase(http_requests_total{status=~"5.."}[3m])) by (service) > 50
     for: 0m  # fire immediately
     ```
     This fires if >50 errors occurred in 3 minutes, regardless of duration.
  3. Add **SLO-based alerts** (multi-window, multi-burn-rate) using Prometheus recording rules — the industry standard for catching short spikes without alert fatigue.

---

### Q25 — Multi-Environment Promotion Strategy
**Currently, the deploy pipeline deploys directly to any environment via `workflow_dispatch`. Design a proper promotion strategy for prod safety, with automated smoke tests and mandatory staging validation.**

**Expected Answer (architecture):**
- **Remove direct prod deploys from `workflow_dispatch`** with unrestricted environment input.
- **Implement promotion gates**:
  ```
  PR merge → CI builds image → Auto-deploy to dev (ArgoCD auto-sync)
                              ↓
                    Automated integration tests (dev) pass
                              ↓
                    Manual promotion trigger: "promote to staging"
                              ↓
                    Deploy to staging → Automated smoke + regression tests
                              ↓
                    Change approval (JIRA ticket / PR review with 2 approvers)
                              ↓
                    Deploy to prod (only during deployment window, e.g., Tue-Thu 10am-3pm)
                              ↓
                    Automated canary: 5% traffic → smoke test → 100% traffic
  ```
- **GitHub Environment protection rules**: Set `production` environment to require 2 reviewers + only allow deploys from `main`.
- **Canary with ArgoCD Rollouts**: Use `argo-rollouts` for progressive delivery (5% → 25% → 100%) with automatic rollback if error rate exceeds threshold.
- **Image immutability**: The same image SHA promoted through environments — never rebuild for staging/prod.

---

### Q26 — Kyverno: Mutation vs Validation
**A team wants all pods to automatically get a sidecar for log forwarding without developers having to add it manually. Kyverno is already installed. Design the policy.**

**Expected Answer:**
- Use a **Kyverno Mutating Policy** (not Validating) — it modifies the resource before it's stored.
- Example structure:
  ```yaml
  apiVersion: kyverno.io/v1
  kind: ClusterPolicy
  metadata:
    name: inject-log-forwarder
  spec:
    rules:
      - name: inject-sidecar
        match:
          resources:
            kinds: [Pod]
            namespaceSelector:
              matchLabels:
                log-injection: enabled  # Opt-in namespace label
        mutate:
          patchStrategicMerge:
            spec:
              containers:
                - name: log-forwarder
                  image: fluent/fluent-bit:2.1
                  resources:
                    limits:
                      memory: 64Mi
                      cpu: 100m
  ```
- **Important design decisions**:
  - Use a **namespace label selector** for opt-in rather than cluster-wide — avoid injecting into `kube-system`, `argocd`, etc.
  - Ensure the sidecar meets the `require-resource-limits` policy (already in this cluster) — or it'll be rejected immediately.
  - Use `patchStrategicMerge` not `patchesJson6902` for container injection — strategic merge handles arrays correctly.

---

### Q27 — EKS: Networking Deep Dive
**A pod running `order-service` can reach `user-service` via Kubernetes DNS (`user-service.kubeflow-ops.svc.cluster.local`) but cannot reach RDS. Networking is otherwise working. Debug and fix.**

**Expected Answer:**
- **Layer 1 — Kubernetes DNS**: Pod can resolve → DNS works. The issue is not DNS.
- **Layer 2 — Security Groups**: EKS pods use the **VPC CNI plugin** (aws-node). Pod IPs are real VPC IPs. Check:
  - The **RDS security group**: Does it allow inbound on port 5432 from the EKS node security group / pod CIDR?
  - The **EKS node security group**: Does it allow outbound to the RDS SG?
  - If using pod-level security groups (ENABLE_POD_ENI=true): Check the pod's associated security group.
- **Layer 3 — Network Policy**: Is there a NetworkPolicy in `kubeflow-ops` namespace that allows only intra-namespace traffic? Check `kubectl get networkpolicies -n kubeflow-ops`.
- **Layer 4 — Route Tables**: Is the RDS in a private subnet? Are the EKS nodes in the same private subnets (or peered VPC) with correct route table entries?
- **Debug tools**:
  ```bash
  kubectl exec -it <pod> -n kubeflow-ops -- nc -vz <rds-endpoint> 5432
  kubectl exec -it <pod> -n kubeflow-ops -- curl -v telnet://<rds-endpoint>:5432
  ```
  Use AWS VPC Flow Logs to see if packets are reaching the RDS ENI and what's happening.

---

### Q28 — CI/CD: Supply Chain Security (SLSA)
**Your CISO asks about supply chain security for this pipeline. Specifically: how do you guarantee that the image running in production is exactly what was built from the reviewed source code? What's currently missing and what would you add?**

**Expected Answer — current gaps:**
- Currently, the image tag is a `github.sha` — this gives traceability to the commit, but:
  - Docker **digest** (e.g., `sha256:abc...`) is a content hash of the image manifest — the SHA tag could be reassigned (tag mutation).
  - No **provenance attestation** exists. No proof that this specific image came from this specific GitHub Actions run.
- **What to add for SLSA Level 3**:
  1. **Cosign image signing**: Sign the image after build using `cosign sign` with a keyless (Sigstore) or KMS key. Verify signature before deployment.
  2. **SLSA provenance**: Use `slsa-github-generator` to attach a provenance attestation (who built it, from which repo/commit/workflow).
  3. **Pin image digests**: In `values.yaml`, store the full digest (`image@sha256:...`) not just the tag.
  4. **Kyverno policy to verify signatures**: `ClusterPolicy` with a `verifyImages` rule — block any pod that uses an unsigned image from your ECR.
  5. **ECR Image Scanning**: Enable ECR Enhanced Scanning (AWS Inspector) for continuous CVE monitoring post-push.

---

### Q29 — Platform Engineering: Self-Service Onboarding
**A new team wants to onboard their `payment-service` to this platform. Without changing any platform code themselves, what's the minimum set of files they need to create, and in which directories? Walk through the entire process.**

**Expected Answer:**
1. **Application code** (in their team repo or `apps/payment-service/`):
   - `Dockerfile`, `requirements.txt`, `tests/`
2. **GitOps Helm values** (in `gitops/apps/payment-service/`):
   - `values.yaml` — image, port, resources, replicas.
   - `values-dev.yaml`, `values-staging.yaml`, `values-prod.yaml` — env-specific overrides.
3. **ArgoCD Application manifest** (in `gitops/platform/argocd/applications/`):
   - `payment-service.yaml` — ArgoCD Application pointing to `gitops/apps/payment-service/` using the `microservice` Helm chart.
   - Since the root app watches this directory with `prune: true` and `selfHeal: true`, ArgoCD auto-picks it up.
4. **CI path filter** (in `.github/workflows/ci.yml`):
   - Add `payment-service` to the `detect-changes` job and the matrix.
5. **Secrets** (if needed):
   - Add an `ExternalSecret` in `gitops/platform/external-secrets/` or per-app secrets.
   - Ensure the IRSA role has access to the new secret path.
6. **ECR repo** (in Terraform):
   - Add a new ECR module call in `terraform/environments/dev/main.tf`.
- The Kyverno policies apply automatically — no policy changes needed.

---

### Q30 — Architecture: The Hard Trade-off Question
**Someone proposes replacing ArgoCD + Helm + External Secrets + Kyverno + Prometheus (5 tools) with a fully managed solution like AWS App Runner + AWS Systems Manager Parameter Store + AWS CloudWatch. Make the case for and against the current architecture.**

**Expected Answer (demonstrates senior-level trade-off thinking):**

**Case FOR the current architecture:**
- **Vendor Independence**: The entire stack (ArgoCD, Helm, Kyverno, Prometheus) is cloud-agnostic. Migration to GCP or Azure doesn't require rewriting deployment or policy tooling.
- **GitOps Auditability**: Every change to the system is a git commit — immutable audit log, easy rollback, PRs as change requests. AWS-native tools don't natively offer this.
- **Policy as Code with Kyverno**: Centralized, version-controlled, auditable admission control. CloudWatch has no equivalent.
- **Customizability**: PromQL lets you write precise business-metric alerts (OrderCreationFailures, NotificationProcessingLag). CloudWatch Metrics require significant effort to match this.
- **Cost at scale**: Managed services (App Runner) charge per compute + per API call. EKS + open-source tooling is fixed cost beyond a threshold.

**Case AGAINST (when the proposal makes sense):**
- **Operational burden**: This stack requires expertise in 5+ tools. A 3-person startup doesn't need Kyverno policies or custom Prometheus rules.
- **Reliability**: ArgoCD, External Secrets, Kyverno are all potential failure points. AWS managed services have SLAs.
- **Onboarding friction**: App Runner is deploy-in-minutes. This GitOps stack has a steep learning curve.
- **Maintenance**: Helm, ArgoCD, Kyverno all have breaking releases, CVEs, upgrade cycles.

**Senior answer**: The current architecture is right for a team of 10+ engineers running production workloads where compliance, audit trails, cost at scale, and multi-cloud optionality matter. App Runner is right for MVPs or very small teams. The right question is: "What's the team size, compliance requirement, and expected scale?"

---

## 📋 Quick Reference: Technology Coverage per Question

| # | Question Focus | Technologies |
|---|---|---|
| 1 | ArgoCD sync vs healthy | ArgoCD, Helm, GitOps |
| 2 | OIDC vs static keys | GitHub Actions, OIDC, IAM |
| 3 | Kyverno admission rejection | Kyverno, ArgoCD |
| 4 | PromQL math | Prometheus |
| 5 | Helm values layering | Helm |
| 6 | Terraform plan vs apply | Terraform, GitHub Actions |
| 7 | External Secrets debugging | ESO, AWS Secrets Manager, IRSA |
| 8 | Trivy exit codes | Trivy, Docker |
| 9 | Pod crash diagnosis | Kubernetes, kubectl |
| 10 | Smoke test rollback | GitHub Actions, kubectl |
| 11 | E2E GitOps flow | All components |
| 12 | CI race condition | GitHub Actions, Git |
| 13 | IRSA trust chain | IRSA, OIDC, JWT, STS |
| 14 | Kyverno Audit vs Enforce | Kyverno |
| 15 | Alert tuning / time-based | Prometheus, Alertmanager |
| 16 | Helm pending-upgrade | Helm |
| 17 | ArgoCD self-heal | ArgoCD, GitOps |
| 18 | SonarQube quality gate | SonarQube, CI |
| 19 | HPA + Cluster Autoscaler | HPA, EKS, CA |
| 20 | Full incident response | All components |
| 21 | Monorepo scale | GitOps, ArgoCD ApplicationSet |
| 22 | OIDC trust policy security | IAM, OIDC |
| 23 | Terraform state locking | Terraform, DynamoDB, S3 |
| 24 | Alert gap analysis | Prometheus, SLO |
| 25 | Multi-env promotion | ArgoCD Rollouts, GitHub Envs |
| 26 | Kyverno mutation policy | Kyverno |
| 27 | EKS networking debug | EKS, VPC CNI, Security Groups |
| 28 | Supply chain security | Cosign, SLSA, ECR |
| 29 | Platform onboarding self-service | All components |
| 30 | Architecture trade-offs | Full architecture comparison |
