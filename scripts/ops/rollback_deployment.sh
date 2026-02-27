#!/bin/bash
# =============================================================================
# Rollback Deployment Script
# =============================================================================
# Rolls back a deployment to the previous revision. Optionally rolls back to
# a specific revision number. Also handles ArgoCD sync if ArgoCD is managing
# the deployment.
#
# Usage:
#   ./scripts/ops/rollback_deployment.sh order-service
#   ./scripts/ops/rollback_deployment.sh order-service --revision 3
#   ./scripts/ops/rollback_deployment.sh order-service --dry-run
# =============================================================================

set -euo pipefail

NAMESPACE="kubeflow-ops"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ── Parse Arguments ──────────────────────────────────────────────────────────
SERVICE_NAME="${1:-}"
REVISION=""
DRY_RUN=false

if [ -z "$SERVICE_NAME" ]; then
    echo -e "${RED}Usage: $0 <service-name> [--revision N] [--dry-run]${NC}"
    echo ""
    echo "Available services:"
    kubectl get deployments -n "$NAMESPACE" -o custom-columns='NAME:.metadata.name' --no-headers 2>/dev/null || true
    exit 1
fi

shift
while [[ $# -gt 0 ]]; do
    case $1 in
        --revision)
            REVISION="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# ── Pre-flight ───────────────────────────────────────────────────────────────
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Rollback: ${SERVICE_NAME}${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"

# Check deployment exists
if ! kubectl get deployment "$SERVICE_NAME" -n "$NAMESPACE" &>/dev/null; then
    echo -e "${RED}❌ Deployment '${SERVICE_NAME}' not found in namespace '${NAMESPACE}'${NC}"
    exit 1
fi

# Show current state
echo ""
echo -e "${YELLOW}Current state:${NC}"
kubectl get deployment "$SERVICE_NAME" -n "$NAMESPACE" -o wide
echo ""

# Show rollout history
echo -e "${YELLOW}Rollout history:${NC}"
kubectl rollout history deployment/"$SERVICE_NAME" -n "$NAMESPACE"
echo ""

# Show current image
CURRENT_IMAGE=$(kubectl get deployment "$SERVICE_NAME" -n "$NAMESPACE" \
    -o jsonpath='{.spec.template.spec.containers[0].image}')
echo -e "${YELLOW}Current image:${NC} ${CURRENT_IMAGE}"

# ── Dry Run Check ────────────────────────────────────────────────────────────
if [ "$DRY_RUN" = true ]; then
    echo ""
    echo -e "${YELLOW}DRY RUN — would execute:${NC}"
    if [ -n "$REVISION" ]; then
        echo "  kubectl rollout undo deployment/${SERVICE_NAME} -n ${NAMESPACE} --to-revision=${REVISION}"
    else
        echo "  kubectl rollout undo deployment/${SERVICE_NAME} -n ${NAMESPACE}"
    fi
    exit 0
fi

# ── Confirm ──────────────────────────────────────────────────────────────────
echo ""
if [ -n "$REVISION" ]; then
    echo -e "${YELLOW}⚠️  Rolling back to revision ${REVISION}${NC}"
else
    echo -e "${YELLOW}⚠️  Rolling back to PREVIOUS revision${NC}"
fi
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Cancelled.${NC}"
    exit 0
fi

# ── Execute Rollback ─────────────────────────────────────────────────────────
echo ""
echo -e "${BLUE}🔄 Executing rollback...${NC}"

if [ -n "$REVISION" ]; then
    kubectl rollout undo deployment/"$SERVICE_NAME" -n "$NAMESPACE" --to-revision="$REVISION"
else
    kubectl rollout undo deployment/"$SERVICE_NAME" -n "$NAMESPACE"
fi

# Wait for rollout
echo -e "${BLUE}⏳ Waiting for rollout to complete...${NC}"
if kubectl rollout status deployment/"$SERVICE_NAME" -n "$NAMESPACE" --timeout=300s; then
    NEW_IMAGE=$(kubectl get deployment "$SERVICE_NAME" -n "$NAMESPACE" \
        -o jsonpath='{.spec.template.spec.containers[0].image}')
    echo ""
    echo -e "${GREEN}✅ Rollback complete!${NC}"
    echo -e "${GREEN}   Previous image: ${CURRENT_IMAGE}${NC}"
    echo -e "${GREEN}   Current image:  ${NEW_IMAGE}${NC}"
else
    echo -e "${RED}❌ Rollback failed — rollout did not complete in 5 minutes${NC}"
    echo -e "${RED}   Check pod status: kubectl get pods -n ${NAMESPACE} -l app=${SERVICE_NAME}${NC}"
    exit 1
fi

# ── ArgoCD Sync ──────────────────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}Note: If ArgoCD manages this deployment, it may revert the rollback.${NC}"
echo -e "${YELLOW}To prevent this, update the image tag in gitops/ and push to Git.${NC}"
echo ""

if command -v argocd &>/dev/null; then
    echo -e "${BLUE}ArgoCD detected. Pausing auto-sync to prevent revert...${NC}"
    argocd app set "$SERVICE_NAME" --sync-policy none 2>/dev/null || true
    echo -e "${YELLOW}⚠️  Auto-sync PAUSED for ${SERVICE_NAME}. Re-enable after investigation:${NC}"
    echo -e "${YELLOW}   argocd app set ${SERVICE_NAME} --sync-policy automated${NC}"
fi
