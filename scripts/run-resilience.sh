#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-argocd}"
DEPLOYMENT="${DEPLOYMENT:-argocd-server}"
RECOVERY_TIMEOUT_SECONDS="${RECOVERY_TIMEOUT_SECONDS:-180}"

pod="$(kubectl -n "$NAMESPACE" get pods -l app.kubernetes.io/name=argocd-server -o jsonpath='{.items[0].metadata.name}')"
if [[ -z "$pod" ]]; then
  echo "No pod found for $NAMESPACE/$DEPLOYMENT" >&2
  exit 1
fi

kubectl -n "$NAMESPACE" delete pod "$pod" --wait=false
kubectl -n "$NAMESPACE" rollout status deployment/"$DEPLOYMENT" --timeout="${RECOVERY_TIMEOUT_SECONDS}s"

echo "Resilience test passed for $NAMESPACE/$DEPLOYMENT"
