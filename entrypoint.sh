#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Validate required environment variables
if [[ -z "${REGION_CODE:-}" ]]; then
    log_error "REGION_CODE environment variable is not set"
    exit 1
fi

if [[ -z "${CLUSTER_NAME:-}" ]]; then
    log_error "CLUSTER_NAME environment variable is not set"
    exit 1
fi

log_info "Configuring kubectl for EKS cluster: ${CLUSTER_NAME} in region: ${REGION_CODE}"

# Fetch EKS cluster information
log_info "Retrieving cluster certificate authority..."
export CA_CERT=$(aws eks describe-cluster \
    --region "${REGION_CODE}" \
    --name "${CLUSTER_NAME}" \
    --query "cluster.certificateAuthority.data" \
    --output text 2>/dev/null)

if [[ -z "${CA_CERT}" ]]; then
    log_error "Failed to retrieve cluster CA certificate"
    exit 1
fi

log_info "Retrieving cluster endpoint..."
export ENDPOINT_URL=$(aws eks describe-cluster \
    --region "${REGION_CODE}" \
    --name "${CLUSTER_NAME}" \
    --query "cluster.endpoint" \
    --output text 2>/dev/null)

if [[ -z "${ENDPOINT_URL}" ]]; then
    log_error "Failed to retrieve cluster endpoint"
    exit 1
fi

log_info "Generating kubeconfig..."
envsubst < /config.template > /opt/kubernetes/config

if [[ ! -f /opt/kubernetes/config ]]; then
    log_error "Failed to generate kubeconfig file"
    exit 1
fi

export KUBECONFIG=/opt/kubernetes/config

log_info "Verifying cluster connectivity..."
if kubectl version --client &>/dev/null; then
    log_info "kubectl client configured successfully"
else
    log_warn "kubectl client check failed, but continuing..."
fi

log_info "Configuration complete. Starting command: $*"

exec "$@"