#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-03f3b99e-3f4f-4159-afa3-c1dd44374397}"
RG_NAME="${RG_NAME:-rg-ct-framework}"
AKS_NAME="${AKS_NAME:-aks-ct-framework}"
TF_BACKEND_RESOURCE_GROUP="${TF_BACKEND_RESOURCE_GROUP:-}"
TF_BACKEND_STORAGE_ACCOUNT="${TF_BACKEND_STORAGE_ACCOUNT:-}"
TF_BACKEND_CONTAINER="${TF_BACKEND_CONTAINER:-}"
TF_BACKEND_KEY="${TF_BACKEND_KEY:-terraform.tfstate}"

if [[ -z "$SUBSCRIPTION_ID" ]]; then
  echo "SUBSCRIPTION_ID is required" >&2
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

terraform_init_with_backend() {
  local init_args

  init_args=("-backend-config=resource_group_name=${TF_BACKEND_RESOURCE_GROUP}" "-backend-config=storage_account_name=${TF_BACKEND_STORAGE_ACCOUNT}" "-backend-config=container_name=${TF_BACKEND_CONTAINER}" "-backend-config=key=${TF_BACKEND_KEY}")

  if [[ -n "${AZURE_TENANT_ID:-}" ]]; then
    init_args+=("-backend-config=tenant_id=${AZURE_TENANT_ID}")
  fi

  if [[ -n "$SUBSCRIPTION_ID" ]]; then
    init_args+=("-backend-config=subscription_id=${SUBSCRIPTION_ID}")
  fi

  if [[ -n "${AZURE_CLIENT_ID:-}" ]]; then
    init_args+=("-backend-config=client_id=${AZURE_CLIENT_ID}")
  fi

  if [[ -n "${ARM_USE_OIDC:-}" ]]; then
    init_args+=("-backend-config=use_oidc=${ARM_USE_OIDC}")
  fi

  if [[ -n "$TF_BACKEND_RESOURCE_GROUP" && -n "$TF_BACKEND_STORAGE_ACCOUNT" && -n "$TF_BACKEND_CONTAINER" ]]; then
    terraform init -upgrade "${init_args[@]}"
  else
    terraform init -upgrade
  fi
}

terraform_apply_with_argocd_recovery() {
  local first_apply_log
  local apply_exit

  first_apply_log="$(mktemp)"

  set +e
  terraform apply -auto-approve tfplan 2> >(tee "$first_apply_log" >&2)
  apply_exit=$?
  set -e

  if [[ $apply_exit -eq 0 ]]; then
    rm -f "$first_apply_log"
    return 0
  fi

  if grep -q "azurerm_resource_group.main" "$first_apply_log" && grep -q "already exists - to be managed via Terraform this resource needs to be imported into the State" "$first_apply_log"; then
    echo "Detected existing Azure Resource Group outside Terraform state. Importing and retrying..."
    terraform import azurerm_resource_group.main "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG_NAME}"
    terraform plan -out tfplan
    terraform apply -auto-approve tfplan
    rm -f "$first_apply_log"
    return 0
  fi

  # Recover from a common drift case: Helm release exists in cluster but not in Terraform state.
  if grep -q "cannot re-use a name that is still in use" "$first_apply_log"; then
    echo "Detected existing Helm release 'argocd' outside Terraform state. Importing and retrying..."
    terraform import helm_release.argocd argocd/argocd
    terraform plan -out tfplan
    terraform apply -auto-approve tfplan
    rm -f "$first_apply_log"
    return 0
  fi

  rm -f "$first_apply_log"
  return "$apply_exit"
}

terraform_plan_with_state_recovery() {
  local first_plan_log
  local plan_exit

  first_plan_log="$(mktemp)"

  set +e
  terraform plan -out tfplan 2> >(tee "$first_plan_log" >&2)
  plan_exit=$?
  set -e

  if [[ $plan_exit -eq 0 ]]; then
    rm -f "$first_plan_log"
    return 0
  fi

  if grep -q "Kubernetes cluster unreachable" "$first_plan_log" && terraform state list | grep -qx "helm_release.argocd"; then
    echo "Detected stale helm_release.argocd in state while cluster is unreachable. Removing from state and retrying plan..."
    terraform state rm helm_release.argocd
    terraform plan -out tfplan
    rm -f "$first_plan_log"
    return 0
  fi

  rm -f "$first_plan_log"
  return "$plan_exit"
}

echo "== Azure login =="
if ! az account show --only-show-errors >/dev/null 2>&1; then
  az login --use-device-code --only-show-errors
fi
az account set --subscription "$SUBSCRIPTION_ID"

pushd "$REPO_ROOT/infra/terraform" >/dev/null
  echo "== Terraform apply =="
  terraform_init_with_backend
  terraform_plan_with_state_recovery
  terraform_apply_with_argocd_recovery
popd >/dev/null

echo "== AKS credentials =="
az aks get-credentials --resource-group "$RG_NAME" --name "$AKS_NAME" --overwrite-existing

echo "== Waiting for Argo CD server deployment =="
kubectl rollout status deployment/argocd-server -n argocd --timeout=300s

echo "== Validate Argo CD service type =="
ARGOCD_SERVICE_TYPE="$(kubectl -n argocd get svc argocd-server -o jsonpath='{.spec.type}')"
if [[ "$ARGOCD_SERVICE_TYPE" != "ClusterIP" ]]; then
  echo "ERROR: Argo CD service type is '$ARGOCD_SERVICE_TYPE', expected 'ClusterIP'." >&2
  exit 1
fi

echo "== Argo CD health endpoint via kubectl tunnel =="
kubectl -n argocd port-forward svc/argocd-server 8080:443 >/tmp/argocd-port-forward.log 2>&1 &
pf_pid=$!
trap 'kill "$pf_pid" >/dev/null 2>&1 || true' EXIT

for _ in {1..30}; do
  if curl --fail --silent --show-error --insecure https://127.0.0.1:8080/healthz >/dev/null; then
    echo "✓ Argo CD is reachable at https://localhost:8080 via kubectl tunnel"
    echo "Bootstrap complete."
    exit 0
  fi
  sleep 2
done

echo "ERROR: Argo CD is not reachable on local tunnel https://localhost:8080." >&2
cat /tmp/argocd-port-forward.log >&2 || true
exit 1
