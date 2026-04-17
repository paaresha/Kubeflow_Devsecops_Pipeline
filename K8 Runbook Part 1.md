# Chat Conversation

Note: _This is purely the output of the chat conversation and does not contain any raw data, codebase snippets, etc. used to generate the output._

### User Input

Can you create a Kubernetes Prodcution level Runbook , in detail - Also tell why and how .
Consider years of experience from 2 - 4
No Artifact, return output in same window
Focus should be K8 mostly

### Planner Response

# 🚀 Kubernetes Production Runbook
### *For Engineers with 2–4 Years of Experience*

---

## 📌 What is a Runbook and Why Does It Exist?

A **Runbook** is a structured set of procedures that an on-call engineer follows when something goes wrong in production. Think of it as your **battle-tested playbook** — not theory, but real operational steps.

**Why it matters:**
- At 2 AM when your pod is crashing, you don't want to think — you want steps.
- Reduces MTTR (Mean Time to Resolution).
- Enables junior engineers to handle incidents independently.
- Ensures consistency across teams.

**How to use this:**
> Each section follows: **What** → **Why it happens** → **How to diagnose** → **How to fix** → **How to prevent**

---

## 🏗️ Section 0 — Prerequisites & Conventions

```bash
# Always set context before any kubectl command
kubectl config current-context
kubectl config get-contexts
kubectl config use-context <your-prod-context>

# Set a working namespace alias
export NS=your-namespace
alias k="kubectl -n $NS"

# Verify you're pointing at the right cluster
kubectl cluster-info
kubectl get nodes
```

**Golden Rules before touching production:**
1. ✅ Confirm you're in the **right cluster and namespace**
2. ✅ Check if there's an **active incident channel** already open
3. ✅ **Never `kubectl delete` a running pod** without understanding why it's in that state
4. ✅ Always **describe before delete**
5. ✅ Open a **change ticket** even for emergency fixes

---

## 🔴 Section 1 — Pod Failures & Crashes

### 1.1 — CrashLoopBackOff

**What:** Pod starts, crashes, Kubernetes restarts it, it crashes again. After a few cycles, K8s backs off (waits longer between restarts).

**Why it happens:**
- Application crashes on startup (bad config, missing env vars)
- OOMKill (Out of Memory)
- Liveness probe failing immediately
- Missing secrets/configmaps referenced in the manifest
- Image entrypoint command is wrong

**Diagnosis Steps:**

```bash
# Step 1: Identify the affected pods
kubectl get pods -n $NS

# Step 2: Check the restart count and reason
kubectl describe pod <pod-name> -n $NS
# Look for: "Last State", "Exit Code", "Reason"

# Step 3: Check the logs — current container
kubectl logs <pod-name> -n $NS

# Step 4: Check the logs — PREVIOUS crashed container (most important!)
kubectl logs <pod-name> -n $NS --previous

# Step 5: Check Events section in describe output
kubectl get events -n $NS --sort-by='.lastTimestamp'

# Step 6: If ENV or ConfigMap issue, inspect them
kubectl get configmap <name> -n $NS -o yaml
kubectl get secret <name> -n $NS -o yaml | base64 -d
```

**Exit Codes Cheat Sheet:**

| Exit Code | Meaning |
|-----------|---------|
| 0 | Success (container exited cleanly, check if it should be running) |
| 1 | General error (app-level crash) |
| 137 | OOMKill or SIGKILL (force killed) |
| 139 | Segmentation fault |
| 143 | SIGTERM — graceful termination |

**Fix:**

```yaml
# If OOMKill: Increase memory limits in your pod spec
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"   # Increase this
    cpu: "500m"
```

```bash
# If bad liveness probe causing premature restarts
# Add initialDelaySeconds to give app time to boot
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 30   # <-- was probably too low
  periodSeconds: 10
  failureThreshold: 3
```

**Prevention:**
- Always set `requests` and `limits` — never run without them in prod
- Test your liveness probes locally before deploying
- Use Helm values validation or Kyverno policies to enforce resource limits

---

### 1.2 — OOMKilled

**What:** Your container exceeded the memory `limit` and the kernel killed it. This is NOT the same as Kubernetes killing it — the OS kernel does this.

**Why:** Memory leak in app, or limits set too low.

```bash
# Confirm OOMKill
kubectl describe pod <pod-name> -n $NS
# Look for: "OOMKilled" in Last State > Reason

# Check actual memory usage trend
kubectl top pod <pod-name> -n $NS
kubectl top pod --sort-by=memory -n $NS

# Check node pressure
kubectl describe node <node-name> | grep -A 5 "Conditions"
```

**Fix:**
```bash
# Patch the deployment with higher memory limit
kubectl patch deployment <name> -n $NS \
  --patch '{"spec":{"template":{"spec":{"containers":[{"name":"<container-name>","resources":{"limits":{"memory":"1Gi"}}}]}}}}'

# Or edit directly (opens vim/nano in terminal)
kubectl edit deployment <name> -n $NS
```

**Prevention:**
- Set Vertical Pod Autoscaler (VPA) in recommendation mode to get insight
- Monitor with Prometheus `container_memory_working_set_bytes`

---

### 1.3 — ImagePullBackOff / ErrImagePull

**What:** Kubernetes cannot pull the container image from the registry.

**Why:**
- Image tag doesn't exist (typo, wrong tag, deleted)
- Private registry and missing `imagePullSecret`
- Network issue between node and registry
- Registry rate limiting (DockerHub)

```bash
# Diagnose
kubectl describe pod <pod-name> -n $NS
# Look under Events: "Failed to pull image"

# Check if imagePullSecret is attached
kubectl get pod <pod-name> -n $NS -o jsonpath='{.spec.imagePullSecrets}'

# Verify the secret exists
kubectl get secret <secret-name> -n $NS

# If using ECR/GCR/ACR — check if token is expired
kubectl get secret regcred -n $NS -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d
```

**Fix:**

```bash
# Create imagePullSecret for private registry
kubectl create secret docker-registry regcred \
  --docker-server=<your-registry> \
  --docker-username=<username> \
  --docker-password=<password> \
  --docker-email=<email> \
  -n $NS

# Patch the deployment to use it
kubectl patch serviceaccount default -n $NS \
  -p '{"imagePullSecrets": [{"name": "regcred"}]}'
```

---

### 1.4 — Pending Pods (Stuck in Pending)

**What:** Pod is created but not scheduled to any node. It's just sitting there.

**Why:**
- Insufficient CPU/memory on all nodes (resource pressure)
- NodeSelector or Affinity rules can't be satisfied
- Taints on nodes without matching Tolerations
- PVC not bound (if pod needs persistent storage)
- Namespace ResourceQuota exceeded

```bash
# Step 1: Check why it's pending
kubectl describe pod <pod-name> -n $NS
# ALWAYS look at "Events" section at the bottom

# Step 2: Check node resources
kubectl describe nodes | grep -A 5 "Allocated resources"
kubectl top nodes

# Step 3: Check ResourceQuota
kubectl describe resourcequota -n $NS

# Step 4: Check PVC status if storage involved
kubectl get pvc -n $NS
kubectl describe pvc <pvc-name> -n $NS

# Step 5: Check taints on nodes
kubectl describe node <node-name> | grep Taints
```

**Common Events → Root Cause Mapping:**

| Event Message | Root Cause |
|--------------|-----------|
| `Insufficient memory` | Nodes too small or no capacity |
| `node(s) had taints that pod didn't tolerate` | Toleration missing |
| `0/3 nodes available: 3 node(s) didn't match node affinity` | Affinity misconfigured |
| `pod has unbound immediate PersistentVolumeClaims` | PVC not ready |

**Fix for Taint/Toleration:**
```yaml
# Add toleration to pod spec to allow scheduling on tainted node
tolerations:
- key: "dedicated"
  operator: "Equal"
  value: "gpu"
  effect: "NoSchedule"
```

---

## 🟡 Section 2 — Deployment & Rollout Issues

### 2.1 — Rollout Stuck / Deployment Not Progressing

**What:** You deployed a new version. The rollout is stuck — new pods not coming up, or old pods not terminating.

```bash
# Check rollout status
kubectl rollout status deployment/<name> -n $NS

# See rollout history
kubectl rollout history deployment/<name> -n $NS

# Describe the deployment to see conditions
kubectl describe deployment <name> -n $NS
# Look for: "Progressing", "Available" conditions

# Check ReplicaSets
kubectl get rs -n $NS
```

**Rollback Immediately (Emergency):**
```bash
# Rollback to previous version
kubectl rollout undo deployment/<name> -n $NS

# Rollback to a specific revision
kubectl rollout undo deployment/<name> -n $NS --to-revision=3

# Confirm rollback completed
kubectl rollout status deployment/<name> -n $NS
```

**Why rollouts get stuck:**
- New pods in CrashLoopBackOff
- Readiness probe failing (K8s won't terminate old pods if new ones aren't ready)
- minReadySeconds set too high
- Not enough resources to run both old and new pods during rolling update

**Prevention via Deployment Strategy:**
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1          # How many extra pods during update
    maxUnavailable: 0    # Never bring a pod down before new one is ready
```

---

### 2.2 — Zero Downtime Deployment Checklist

Before every production deployment:

```bash
# 1. Ensure you have readiness probe configured
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 5

# 2. Ensure PodDisruptionBudget exists
kubectl get pdb -n $NS

# 3. Set minReadySeconds to avoid premature traffic
minReadySeconds: 30

# 4. Ensure Horizontal Pod Autoscaler (HPA) won't fight your rollout
kubectl get hpa -n $NS
```

---

## 🔵 Section 3 — Networking & Service Issues

### 3.1 — Service Not Reachable

**What:** Your app deployed fine but traffic isn't getting to it. Service returns connection refused or timeouts.

**Why:**
- Label selector mismatch between Service and Pod
- Wrong port in Service definition
- NetworkPolicy blocking traffic
- Endpoint not registered (pod not ready)

```bash
# Step 1: Verify service definition
kubectl get svc <svc-name> -n $NS -o yaml
# Check: selector labels, port, targetPort

# Step 2: Check if endpoints are populated
kubectl get endpoints <svc-name> -n $NS
# If ENDPOINTS is "<none>" — no pods are matching!

# Step 3: Verify pod labels match service selector
kubectl get pods -n $NS --show-labels
# Compare with the selector in the service

# Step 4: Test internal DNS resolution
kubectl run debug --image=busybox --rm -it --restart=Never -- \
  nslookup <svc-name>.<namespace>.svc.cluster.local

# Step 5: Test connectivity from within cluster
kubectl run curl-test --image=curlimages/curl --rm -it --restart=Never -- \
  curl -v http://<svc-name>.<namespace>.svc.cluster.local:<port>/health

# Step 6: Check NetworkPolicies
kubectl get networkpolicy -n $NS
kubectl describe networkpolicy <name> -n $NS
```

**Label Mismatch Fix Example:**
```yaml
# Service selector
selector:
  app: my-api
  version: v2         # <-- This must match pod labels!

# Pod labels (must have BOTH of these)
labels:
  app: my-api
  version: v2
```

---

### 3.2 — Ingress Not Routing Traffic

```bash
# Check ingress resource
kubectl get ingress -n $NS
kubectl describe ingress <name> -n $NS

# Check ingress controller pods are running
kubectl get pods -n ingress-nginx   # or your controller namespace
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller

# Verify annotations are correct
kubectl get ingress <name> -n $NS -o yaml

# Check TLS secret exists if HTTPS
kubectl get secret <tls-secret-name> -n $NS
```

---

## 🟠 Section 4 — Node Issues

### 4.1 — Node Not Ready

**What:** A node shows `NotReady` status. Pods on this node may start being evicted after `pod-eviction-timeout` (default 5 minutes).

```bash
# Identify which nodes are not ready
kubectl get nodes
# STATUS column shows "NotReady"

# Deep inspection
kubectl describe node <node-name>
# Look at: Conditions, Events, Capacity vs Allocatable

# Common conditions to check:
# - MemoryPressure: True  → Node running out of RAM
# - DiskPressure: True    → Node running out of disk
# - PIDPressure: True     → Too many processes
# - Ready: False          → kubelet not reporting in

# Check kubelet logs on the node (requires SSH or node exec)
journalctl -u kubelet -f --since "30 minutes ago"
```

**Actions:**
```bash
# If node needs maintenance — safely drain it first
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# After drain, cordon prevents new pods from scheduling there
kubectl cordon <node-name>

# When node is back and healthy, uncordon
kubectl uncordon <node-name>
```

### 4.2 — DiskPressure on Nodes

**What:** Node is running low on disk. This prevents new pods from being scheduled.

**Common Cause:** Docker/containerd image cache, excessive logging, emptyDir volumes.

```bash
# Check node disk usage (requires node access)
df -h

# Check which images are taking space
crictl images --no-trunc | sort -k 3 -rn

# Prune unused images
crictl rmi --prune

# Check container log sizes
du -sh /var/log/containers/*
```

**Prevention:**
```yaml
# Set log rotation in pod spec
containers:
- name: app
  # Use structured logging with size limits at node level
  # Configure containerd log rotation in /etc/containerd/config.toml
```

---

## 🟣 Section 5 — Storage (PVC) Issues

### 5.1 — PVC Stuck in Pending

```bash
# Check PVC status
kubectl get pvc -n $NS
kubectl describe pvc <pvc-name> -n $NS

# Check if StorageClass exists
kubectl get storageclass

# Check if default StorageClass is set
kubectl get storageclass | grep default

# Check CSI driver/provisioner pod status
kubectl get pods -n kube-system | grep csi
```

**Common Fix:**
```yaml
# Ensure PVC requests match available StorageClass
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: standard   # Must match existing StorageClass
  resources:
    requests:
      storage: 5Gi
```

### 5.2 — PVC Stuck in Terminating

```bash
# PVC has finalizers blocking deletion
kubectl get pvc <name> -n $NS -o yaml | grep finalizers

# Force remove finalizers
kubectl patch pvc <name> -n $NS \
  -p '{"metadata":{"finalizers":null}}'
```

---

## ⚙️ Section 6 — Resource Management & Autoscaling

### 6.1 — HPA Not Scaling

**What:** Load is high but HPA isn't adding pods.

```bash
# Check HPA status
kubectl get hpa -n $NS
kubectl describe hpa <name> -n $NS
# Look for: "unable to fetch metrics", ScaleUp/ScaleDown conditions

# Check metrics-server is running
kubectl get pods -n kube-system | grep metrics-server
kubectl top pods -n $NS   # If this works, metrics-server is fine
```

**Common HPA Issues:**

| Problem | Fix |
|---------|-----|
| Metrics server not installed | Deploy metrics-server |
| `targetCPUUtilizationPercentage` not met | Lower threshold or check actual load |
| `requests` not set on pods | HPA REQUIRES resource requests to calculate % |
| cooldown period active | Wait for `--scale-down-stabilization-window` |

```yaml
# Correct HPA configuration
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: my-app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

---

## 🔐 Section 7 — RBAC & Security Issues

### 7.1 — Forbidden / Unauthorized Errors

```bash
# Error: "Error from server (Forbidden): pods is forbidden"

# Check what permissions the service account has
kubectl auth can-i list pods -n $NS --as=system:serviceaccount:$NS:my-sa

# Check what ClusterRoles/Roles are bound to a service account
kubectl get rolebindings,clusterrolebindings -n $NS -o wide | grep my-sa

# Check the role details
kubectl describe role <role-name> -n $NS
kubectl describe clusterrole <clusterrole-name>
```

**Fix — Create minimal RBAC:**
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: production
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pod-reader-binding
  namespace: production
subjects:
- kind: ServiceAccount
  name: my-service-account
  namespace: production
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

---

## 📊 Section 8 — Observability & Debugging Toolkit

### 8.1 — The Golden Debugging Commands

```bash
# ===========================================
# THE FIRST 5 COMMANDS IN ANY INCIDENT
# ===========================================

# 1. What's broken?
kubectl get pods -n $NS -o wide

# 2. Why is it broken?
kubectl describe pod <pod-name> -n $NS

# 3. What did it say before dying?
kubectl logs <pod-name> -n $NS --previous --tail=100

# 4. What's happening cluster-wide?
kubectl get events -n $NS --sort-by='.lastTimestamp' | tail -20

# 5. Is it a node problem?
kubectl get nodes && kubectl top nodes
```

### 8.2 — Advanced Debugging

```bash
# Debug with ephemeral container (K8s 1.23+)
kubectl debug -it <pod-name> -n $NS \
  --image=busybox \
  --target=<container-name>

# Copy pod and override entrypoint to debug startup issues
kubectl debug -it <pod-name> -n $NS \
  --copy-to=debug-pod \
  --image=busybox \
  -- sh

# Execute into a running container
kubectl exec -it <pod-name> -n $NS -- /bin/sh

# Port-forward to test locally
kubectl port-forward pod/<pod-name> 8080:8080 -n $NS
kubectl port-forward svc/<svc-name> 8080:80 -n $NS

# Check API server response for a specific resource
kubectl get pod <pod-name> -n $NS -o json | jq '.status'
```

### 8.3 — Networking Debug Pod

```bash
# Launch a network debug pod
kubectl run netdebug \
  --image=nicolaka/netshoot \
  --rm -it \
  --restart=Never \
  -n $NS \
  -- bash

# Inside the pod you can:
# ping, curl, nslookup, dig, tcpdump, ss, netstat, traceroute
```

---

## 🔄 Section 9 — etcd, Control Plane Health

### 9.1 — API Server / etcd Issues

**Note:** At 2-4 years of experience, you may not have direct etcd access in managed clusters (EKS/GKE/AKS) — but you should know how to recognize these issues.

```bash
# Check API server responsiveness
kubectl get --raw /healthz
kubectl get --raw /readyz
kubectl get --raw /livez

# Check component status (deprecated but still useful)
kubectl get componentstatuses

# Check kube-system components
kubectl get pods -n kube-system
kubectl logs -n kube-system pod/kube-apiserver-<node> --tail=50

# On self-managed clusters, check etcd health
ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint health
```

---

## 📋 Section 10 — Production Checklists

### 10.1 — Pre-Deployment Checklist

```
[ ] Image tag is NOT "latest" — use a specific SHA or semver
[ ] Resource requests and limits are defined
[ ] Readiness and liveness probes configured
[ ] Secrets not hardcoded in image or manifest
[ ] PodDisruptionBudget exists for critical workloads
[ ] HPA configured with sane min/max
[ ] Anti-affinity rules to spread pods across nodes
[ ] NetworkPolicy defined (not open to all)
[ ] RBAC with least privilege for the ServiceAccount
[ ] Horizontal scaling tested in staging first
```

### 10.2 — Post-Deployment Verification

```bash
# Run these AFTER every deployment
# 1. Verify rollout completed
kubectl rollout status deployment/<name> -n $NS

# 2. Check pod count matches desired
kubectl get deployment <name> -n $NS

# 3. Spot check pod logs for errors
kubectl logs deployment/<name> -n $NS --tail=20

# 4. Verify endpoints updated
kubectl get endpoints <svc-name> -n $NS

# 5. Run application health check
curl -sk https://your-app.com/health
```

### 10.3 — Incident Response Template (Mental Model)

```
1. DETECT   → Alert fires or user reports issue
2. TRIAGE   → Is it P1 (down) or P2 (degraded)?
3. ISOLATE  → Which pod/node/namespace is affected?
4. DIAGNOSE → kubectl describe, logs, events
5. MITIGATE → Rollback, scale up, restart pod
6. CONFIRM  → Verify fix, check metrics
7. DOCUMENT → Write incident report with timeline
8. PREVENT  → What alert/check would catch this earlier?
```

---

## 🧠 Section 11 — Key Mental Models for 2–4 Years Experience

### When to Restart vs Rollback vs Scale

| Situation | Action |
|----------|--------|
| Single pod crashing, others fine | `kubectl delete pod <name>` (it'll reschedule) |
| New deployment broke things | `kubectl rollout undo deployment/<name>` |
| Traffic spike, pods healthy | `kubectl scale deployment/<name> --replicas=N` |
| Node unhealthy | `kubectl drain <node>` then investigate |
| Config change needed fast | `kubectl edit configmap <name>` + rolling restart |

### Pod Restart After ConfigMap/Secret Change:

```bash
# ConfigMaps and Secrets don't auto-reload into running pods
# Use rolling restart to pick up changes
kubectl rollout restart deployment/<name> -n $NS
```

---

## 🔧 Section 12 — Useful Aliases & Tools for Daily Ops

```bash
# ~/.bashrc or ~/.zshrc aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgn='kubectl get nodes'
alias kdp='kubectl describe pod'
alias kaf='kubectl apply -f'
alias kdf='kubectl delete -f'
alias klogs='kubectl logs --tail=100 -f'
alias kctx='kubectl config use-context'

# kubectl plugins via krew (install once)
kubectl krew install ctx       # switch contexts easily
kubectl krew install ns        # switch namespaces easily
kubectl krew install neat       # clean yaml output
kubectl krew install tree       # see resource tree
kubectl krew install stern      # tail logs from multiple pods
```

**Tools to know at this level:**
- **k9s** — Terminal UI for Kubernetes (game changer)
- **Lens** — Desktop GUI for cluster management
- **Stern** — Tail logs from multiple pods simultaneously
- **Popeye** — Cluster sanitizer, finds misconfigurations
- **kube-score** — Static analysis of K8s manifests

---

## 📌 Quick Reference Card

```
Pod Stuck?          → describe + logs --previous + events
ImagePullBackOff?   → check tag exists + imagePullSecret
Pending?            → describe → check Events for reason
CrashLoop?          → logs --previous + check exit code
Service down?       → check endpoints + label selectors
Rollout stuck?      → rollout status → rollout undo
Node NotReady?      → describe node + drain + investigate
PVC Pending?        → check StorageClass + describe pvc
HPA not scaling?    → check metrics-server + resource requests
RBAC Forbidden?     → auth can-i + check rolebindings
```

---

> 💡 **The 2–4 Year Mindset Shift:** At this stage, you should move from "how do I fix this" to **"how do I prevent this, detect it earlier, and make it self-healing."** Think PodDisruptionBudgets, HPA, alerting rules in Prometheus, and GitOps via ArgoCD for every change — so you have an audit trail of what changed and when.