#!/bin/bash
# =============================================================================
# Cluster Health Check Script
# =============================================================================
# Runs a comprehensive health check on the EKS cluster and all services.
# Use this as a quick diagnostic tool during incidents or before deployments.
#
# Usage:
#   ./scripts/ops/check_cluster_health.sh
#   ./scripts/ops/check_cluster_health.sh --namespace kubeflow-ops
#   ./scripts/ops/check_cluster_health.sh --verbose
# =============================================================================

set -euo pipefail

NAMESPACE="${1:---all-namespaces}"
VERBOSE="${2:-}"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
}

print_ok()   { echo -e "${GREEN}  ✅ $1${NC}"; }
print_warn() { echo -e "${YELLOW}  ⚠️  $1${NC}"; }
print_fail() { echo -e "${RED}  ❌ $1${NC}"; }

EXIT_CODE=0

# ── 1. Cluster Connectivity ──────────────────────────────────────────────────
print_header "1. Cluster Connectivity"
if kubectl cluster-info &>/dev/null; then
    CLUSTER_NAME=$(kubectl config current-context)
    print_ok "Connected to cluster: ${CLUSTER_NAME}"
else
    print_fail "Cannot connect to cluster!"
    exit 1
fi

# ── 2. Node Health ───────────────────────────────────────────────────────────
print_header "2. Node Health"
TOTAL_NODES=$(kubectl get nodes --no-headers | wc -l)
READY_NODES=$(kubectl get nodes --no-headers | grep -c " Ready" || true)
NOT_READY=$(kubectl get nodes --no-headers | grep -v " Ready" || true)

if [ "$TOTAL_NODES" -eq "$READY_NODES" ]; then
    print_ok "All ${TOTAL_NODES} nodes are Ready"
else
    print_fail "${READY_NODES}/${TOTAL_NODES} nodes Ready"
    echo "$NOT_READY" | while read -r line; do
        print_warn "  NOT READY: $line"
    done
    EXIT_CODE=1
fi

# Node resource usage
echo ""
echo "  Node Resource Usage:"
kubectl top nodes 2>/dev/null || print_warn "Metrics server not available"

# ── 3. Pod Health ────────────────────────────────────────────────────────────
print_header "3. Pod Health (kubeflow-ops)"
TOTAL_PODS=$(kubectl get pods -n kubeflow-ops --no-headers 2>/dev/null | wc -l || echo 0)
RUNNING_PODS=$(kubectl get pods -n kubeflow-ops --no-headers 2>/dev/null | grep -c "Running" || echo 0)
FAILED_PODS=$(kubectl get pods -n kubeflow-ops --no-headers 2>/dev/null | grep -E "Error|CrashLoopBackOff|ImagePullBackOff|OOMKilled" || true)

if [ "$TOTAL_PODS" -eq "0" ]; then
    print_warn "No pods found in kubeflow-ops namespace"
elif [ "$TOTAL_PODS" -eq "$RUNNING_PODS" ]; then
    print_ok "All ${TOTAL_PODS} pods are Running"
else
    print_warn "${RUNNING_PODS}/${TOTAL_PODS} pods Running"
    EXIT_CODE=1
fi

if [ -n "$FAILED_PODS" ]; then
    print_fail "Unhealthy pods found:"
    echo "$FAILED_PODS" | while read -r line; do
        echo -e "${RED}    $line${NC}"
    done
    EXIT_CODE=1
fi

# ── 4. Service Endpoints ────────────────────────────────────────────────────
print_header "4. Service Endpoints"
for SVC in order-service user-service notification-service; do
    ENDPOINTS=$(kubectl get endpoints "${SVC}" -n kubeflow-ops -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null || echo "")
    if [ -n "$ENDPOINTS" ]; then
        COUNT=$(echo "$ENDPOINTS" | wc -w)
        print_ok "${SVC}: ${COUNT} endpoint(s) — ${ENDPOINTS}"
    else
        print_fail "${SVC}: NO endpoints (service has no healthy pods!)"
        EXIT_CODE=1
    fi
done

# ── 5. HPA Status ───────────────────────────────────────────────────────────
print_header "5. HPA Status"
kubectl get hpa -n kubeflow-ops 2>/dev/null || print_warn "No HPAs found"

# ── 6. Recent Events ────────────────────────────────────────────────────────
print_header "6. Recent Warning Events (last 10)"
WARNINGS=$(kubectl get events -n kubeflow-ops --field-selector type=Warning \
    --sort-by='.lastTimestamp' 2>/dev/null | tail -10 || echo "")
if [ -n "$WARNINGS" ]; then
    echo "$WARNINGS"
else
    print_ok "No warning events"
fi

# ── 7. Deployments ──────────────────────────────────────────────────────────
print_header "7. Deployment Status"
kubectl get deployments -n kubeflow-ops -o wide 2>/dev/null || print_warn "No deployments found"

# ── 8. ArgoCD Application Status ────────────────────────────────────────────
print_header "8. ArgoCD Application Status"
if kubectl get applications -n argocd &>/dev/null; then
    kubectl get applications -n argocd -o custom-columns=\
'NAME:.metadata.name,STATUS:.status.sync.status,HEALTH:.status.health.status' 2>/dev/null
else
    print_warn "ArgoCD not installed or not accessible"
fi

# ── Summary ──────────────────────────────────────────────────────────────────
print_header "Summary"
if [ "$EXIT_CODE" -eq 0 ]; then
    print_ok "Cluster is HEALTHY ✅"
else
    print_fail "Cluster has ISSUES — see above ❌"
fi

exit $EXIT_CODE
