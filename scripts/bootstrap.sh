#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-03f3b99e-3f4f-4159-afa3-c1dd44374397}"
RG_NAME="${RG_NAME:-rg-ct-framework}"
AKS_NAME="${AKS_NAME:-aks-ct-framework}"
REPO_URL="${REPO_URL:-https://github.com/Dorigao-LTDA/central-gitops.git}"
SERVICES_REPO_URL="${SERVICES_REPO_URL:-https://github.com/Dorigao-LTDA/continuous-testing-framework.git}"
ARGOCD_DOMAIN="${ARGOCD_DOMAIN:-argocd.dorigao.dev.br}"
INGRESS_PUBLIC_IP="${INGRESS_PUBLIC_IP:-20.197.180.231}"
ARGOCD_BASIC_AUTH="${ARGOCD_BASIC_AUTH:-}"
ARGOCD_TLS_CERT_FILE="${ARGOCD_TLS_CERT_FILE:-$REPO_ROOT/certs/argocd/argocd.crt}"
ARGOCD_TLS_KEY_FILE="${ARGOCD_TLS_KEY_FILE:-$REPO_ROOT/certs/argocd/argocd.key}"
O11Y_DEPLOY="${O11Y_DEPLOY:-}"
ARGOCD_REPO_TOKEN="${ARGOCD_REPO_TOKEN:-${GITHUB_TOKEN:-}}"

if [[ -z "$SUBSCRIPTION_ID" ]]; then
  echo "SUBSCRIPTION_ID is required" >&2
  exit 1
fi

if [[ -z "$REPO_URL" ]]; then
  echo "REPO_URL is required" >&2
  exit 1
fi

if [[ -z "$SERVICES_REPO_URL" ]]; then
  echo "SERVICES_REPO_URL is required" >&2
  exit 1
fi

if [[ -z "$ARGOCD_DOMAIN" ]]; then
  echo "ARGOCD_DOMAIN is required" >&2
  exit 1
fi

if [[ -z "$INGRESS_PUBLIC_IP" ]]; then
  echo "INGRESS_PUBLIC_IP is required" >&2
  echo "Create it manually with: az network public-ip create -g rg-ct-framework-networking -n ingress-ct-framework --sku Standard --allocation-method Static" >&2
  exit 1
fi

if ! command -v az >/dev/null 2>&1; then
  echo "az CLI not found" >&2
  exit 1
fi

if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform not found" >&2
  exit 1
fi

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl not found" >&2
  exit 1
fi

if ! command -v helm >/dev/null 2>&1; then
  echo "helm not found" >&2
  exit 1
fi

ensure_repo_secret() {
  local secret_name="$1"
  local repo_url="$2"
  local token="$3"

  if [[ -z "$token" ]]; then
    return 0
  fi

  kubectl -n argocd create secret generic "$secret_name" \
    --from-literal=url="$repo_url" \
    --from-literal=username=git \
    --from-literal=password="$token" \
    --dry-run=client -o yaml \
    | kubectl apply -f - >/dev/null 2>&1 || true

  kubectl -n argocd label secret "$secret_name" \
    argocd.argoproj.io/secret-type=repository --overwrite >/dev/null 2>&1 || true
}

wait_for_argocd_app() {
  local app_name="$1"
  local timeout_seconds="${2:-600}"
  local start_time

  start_time=$(date +%s)
  while true; do
    if kubectl -n argocd get application "$app_name" >/dev/null 2>&1; then
      local sync_status
      local health_status
      sync_status=$(kubectl -n argocd get application "$app_name" -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "")
      health_status=$(kubectl -n argocd get application "$app_name" -o jsonpath='{.status.health.status}' 2>/dev/null || echo "")

      if [[ "$sync_status" == "Synced" && "$health_status" == "Healthy" ]]; then
        echo "Argo CD app '$app_name' is Synced/Healthy."
        return 0
      fi
    fi

    if (( $(date +%s) - start_time > timeout_seconds )); then
      echo "ERROR: Timed out waiting for Argo CD app '$app_name' to become Synced/Healthy." >&2
      return 1
    fi

    sleep 10
  done
}

wait_for_deployment() {
  local namespace="$1"
  local deployment_name="$2"
  local timeout_seconds="${3:-600}"
  local start_time

  start_time=$(date +%s)
  while true; do
    if kubectl -n "$namespace" get deployment "$deployment_name" >/dev/null 2>&1; then
      return 0
    fi

    if (( $(date +%s) - start_time > timeout_seconds )); then
      echo "ERROR: Timed out waiting for deployment '$deployment_name' in namespace '$namespace'." >&2
      return 1
    fi

    sleep 5
  done
}

debug_ingress_nginx() {
  echo "== Ingress NGINX diagnostics =="
  kubectl -n ingress-nginx get pods -o wide || true
  kubectl -n ingress-nginx describe deployment/ingress-nginx-controller || true
  kubectl -n ingress-nginx get events --sort-by=.lastTimestamp | tail -n 50 || true
}

echo "== Azure login =="
if ! az account show --only-show-errors >/dev/null 2>&1; then
  az login --use-device-code --only-show-errors
fi
az account set --subscription "$SUBSCRIPTION_ID"

if [[ -z "$ARGOCD_BASIC_AUTH" ]]; then
  ARGOCD_BASIC_AUTH_PASSWORD="$(openssl rand -base64 18)"
  ARGOCD_BASIC_AUTH="admin:$(openssl passwd -apr1 "$ARGOCD_BASIC_AUTH_PASSWORD")"
  echo "Generated Argo CD basic auth password: $ARGOCD_BASIC_AUTH_PASSWORD"
fi

if [[ ! -f "$ARGOCD_TLS_CERT_FILE" || ! -f "$ARGOCD_TLS_KEY_FILE" ]]; then
  mkdir -p "$(dirname "$ARGOCD_TLS_CERT_FILE")"
  openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
    -keyout "$ARGOCD_TLS_KEY_FILE" \
    -out "$ARGOCD_TLS_CERT_FILE" \
    -subj "/CN=$ARGOCD_DOMAIN" \
    -addext "subjectAltName=DNS:$ARGOCD_DOMAIN" \
    >/dev/null 2>&1
fi

pushd "$REPO_ROOT/infra/terraform" >/dev/null
  echo "== Terraform apply =="
  terraform init -upgrade
  terraform plan -out tfplan
  terraform apply -auto-approve tfplan
popd >/dev/null

echo "== AKS credentials =="
az aks get-credentials --resource-group "$RG_NAME" --name "$AKS_NAME" --overwrite-existing

for ns in argocd observability app chaos-testing ingress-nginx; do
  kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
done

echo "== Argo CD via Terraform (Helm) =="
# Wait for Argo CD API
kubectl rollout status deployment/argocd-server -n argocd --timeout=300s

# Configure repo credentials if token is provided (fallback if External Secrets is disabled)
if [[ "${SKIP_BOOTSTRAP_REPO_SECRET:-}" != "1" ]]; then
  ensure_repo_secret "argocd-repo-gitops" "$REPO_URL" "$ARGOCD_REPO_TOKEN"
  ensure_repo_secret "argocd-repo-services" "$SERVICES_REPO_URL" "$ARGOCD_REPO_TOKEN"
fi

# Apply root app (core) with environment-specific values
kubectl apply -k "$REPO_ROOT/deploy/gitops/overlays/corporate"

# Wait for Argo CD to sync core apps
wait_for_argocd_app "ct-framework" 600

echo "== Deploy Ingress NGINX app =="
kubectl apply -f "$REPO_ROOT/deploy/gitops/apps-core/ingress-nginx.yaml"

# Wait for the Ingress NGINX app to be created and synced before checking rollout
wait_for_argocd_app "ingress-nginx" 600

# Relax ingress-nginx admission webhook if certs are not yet trusted
kubectl patch validatingwebhookconfiguration ingress-nginx-admission --type json \
  -p='[{"op":"replace","path":"/webhooks/0/failurePolicy","value":"Ignore"}]' \
  >/dev/null 2>&1 || true

# Register AKS nodes with Load Balancer backend pool (via VMSS association)
echo "== Registering AKS nodes with Load Balancer =="
LB_POOL_ID=$(terraform -chdir="$REPO_ROOT/infra/terraform" output -raw loadbalancer_backend_pool_id 2>/dev/null || echo "")
if [[ -z "$LB_POOL_ID" ]]; then
  echo "WARNING: Load Balancer backend pool ID not found. Skipping node registration."
else
  NODE_RG=$(az aks show -g "$RG_NAME" -n "$AKS_NAME" --query nodeResourceGroup -o tsv 2>/dev/null || echo "")
  if [[ -z "$NODE_RG" ]]; then
    echo "WARNING: Could not resolve AKS node resource group. Skipping node registration."
  else
    VMSS_LIST=$(az vmss list -g "$NODE_RG" --query "[].name" -o tsv 2>/dev/null || echo "")
    if [[ -z "$VMSS_LIST" ]]; then
      echo "WARNING: No VMSS found in node resource group '$NODE_RG'."
    else
      for vmss in $VMSS_LIST; do
        echo "Associating VMSS '$vmss' with backend pool..."
        az vmss update -g "$NODE_RG" -n "$vmss" \
          --add virtualMachineProfile.networkProfile.networkInterfaceConfigurations[0].ipConfigurations[0].loadBalancerBackendAddressPools id="$LB_POOL_ID" \
          --only-show-errors || true
        az vmss update-instances -g "$NODE_RG" -n "$vmss" --instance-ids '*' --only-show-errors || true
      done

      if [[ "${SKIP_BOOTSTRAP_NSG_RULE:-}" != "1" ]]; then
        NSG_NAME=$(az network nsg list -g "$NODE_RG" --query "[0].name" -o tsv 2>/dev/null || echo "")
        if [[ -n "$NSG_NAME" ]]; then
          az network nsg rule create -g "$NODE_RG" --nsg-name "$NSG_NAME" \
            -n allow-ingress-nodeports \
            --priority 300 \
            --direction Inbound \
            --access Allow \
            --protocol Tcp \
            --source-address-prefixes Internet \
            --destination-port-ranges 32212 31200 \
            --only-show-errors >/dev/null 2>&1 || true
        fi
      fi
    fi
  fi
fi

# Wait for NGINX to be ready
echo "== Waiting for NGINX Ingress Controller =="
wait_for_deployment "ingress-nginx" "ingress-nginx-controller" 600
if ! kubectl rollout status deployment/ingress-nginx-controller -n ingress-nginx --timeout=600s; then
  debug_ingress_nginx
  exit 1
fi

# Ensure Argo CD ingress app is ready before finishing
wait_for_argocd_app "argocd-access" 600

if git -C "$REPO_ROOT/deploy/gitops" status --porcelain | grep -q .; then
  echo "WARNING: GitOps repo has uncommitted changes in deploy/gitops."
  echo "Commit and push to keep Argo CD in sync with the configured domain and repo URLs."
fi

if [[ -z "$O11Y_DEPLOY" ]]; then
  read -r -p "Deploy observability stack (o11y)? [y/N]: " O11Y_DEPLOY
fi

case "$O11Y_DEPLOY" in
  y|Y|yes|YES)
    kubectl apply -k "$REPO_ROOT/deploy/gitops/overlays/o11y"
    ;;
  *)
    echo "Skipping observability stack."
    ;;
esac

if ! kubectl -n argocd get secret argocd-basic-auth >/dev/null 2>&1; then
  if [[ -n "$ARGOCD_BASIC_AUTH" ]]; then
    kubectl -n argocd create secret generic argocd-basic-auth \
      --from-literal=auth="$ARGOCD_BASIC_AUTH"
  else
    echo "WARNING: argocd-basic-auth secret not found in namespace argocd."
    echo "Set ARGOCD_BASIC_AUTH with htpasswd format (ex.: admin:$$(openssl passwd -apr1 'SENHA'))."
  fi
fi

if ! kubectl -n argocd get secret argocd-tls >/dev/null 2>&1; then
  if [[ -n "$ARGOCD_TLS_CERT_FILE" && -n "$ARGOCD_TLS_KEY_FILE" ]]; then
    kubectl -n argocd create secret tls argocd-tls \
      --cert="$ARGOCD_TLS_CERT_FILE" --key="$ARGOCD_TLS_KEY_FILE"
  else
    echo "WARNING: argocd-tls secret not found in namespace argocd."
    echo "Set ARGOCD_TLS_CERT_FILE and ARGOCD_TLS_KEY_FILE to create the TLS secret automatically."
  fi
fi

echo "== Ingress external address =="
LB_PUBLIC_IP=$(terraform -chdir="$REPO_ROOT/infra/terraform" output -raw loadbalancer_public_ip 2>/dev/null || echo "$INGRESS_PUBLIC_IP")
echo ""
echo "✓ Load Balancer configured with Static IP: $LB_PUBLIC_IP"
echo ""
echo "Next steps:"
echo "1. Ensure DNS A record for '$ARGOCD_DOMAIN' points to: $LB_PUBLIC_IP"
echo "2. Access Argo CD at: https://$ARGOCD_DOMAIN"
echo ""
echo "To verify everything is working:"
echo "  kubectl -n ingress-nginx get svc ingress-nginx-controller -w"
echo ""

echo "Bootstrap complete."
