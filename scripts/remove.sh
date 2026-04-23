#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-03f3b99e-3f4f-4159-afa3-c1dd44374397}"
RG_NAME="${RG_NAME:-rg-ct-framework}"
AKS_NAME="${AKS_NAME:-aks-ct-framework}"

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

echo "== Azure login =="
if ! az account show --only-show-errors >/dev/null 2>&1; then
  az login --use-device-code --only-show-errors
fi
az account set --subscription "$SUBSCRIPTION_ID"

echo "== AKS credentials =="
az aks get-credentials --resource-group "$RG_NAME" --name "$AKS_NAME" --overwrite-existing || true

# Remove Argo CD and related namespaces
for ns in argocd observability app chaos-testing; do
  kubectl delete namespace "$ns" --ignore-not-found
 done

echo "== Terraform destroy =="
pushd "$REPO_ROOT/infra/terraform" >/dev/null
  terraform init
  terraform destroy -auto-approve
popd >/dev/null

echo "Removal complete."
