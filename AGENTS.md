# AGENTS.md — Continuous Testing Framework (TCC)

Terraform + Argo CD + AKS + k6 + Chaos.

## Repo structure

| Directory | Purpose |
|---|---|
| `infra/terraform/` | Azure IaC: modular — cluster, argocd, ingress, external-secrets |
| `infra/terraform/modules/cluster/` | RG, VNet, Subnet, ACR, AKS, AcrPull role |
| `scripts/` | Local bootstrap, teardown, perf/chaos runners, gate evaluation |
| `deploy/helm/service-chart/` | Generic Helm chart for microservices with OTLP env injection |
| `deploy/helm/values/` | Per-service values (catalogo, pagamento, pedido) |
| `deploy/helm/observability/` | Reference values for Grafana stack (Mimir, Loki, Tempo, Pyroscope, Alloy) |
| `deploy/gitops/` | Argo CD Application/ApplicationSet manifests |
| `tests/perf/` | k6 scripts (predeploy-infra.js, postdeploy-app.js) |
| `tests/chaos/` | Chaos Mesh PodChaos manifest (example only) |
| `.github/workflows/` | `pipeline.yml` (bootstrap), `destroy.yml` (manual teardown) |
| `docs/` | Quickstart, architecture, deploy, pipeline, testing, operations, GitOps, observability |

## Core facts

- **No language package managers** — no npm, pip, cargo, go.mod. Pure infra/ops repo.
- **Terraform** is the only IaC tool (required `>= 1.6.0`, providers pinned). Working dir: `infra/terraform/`.
- **Backend**: Azure Storage (`azurerm`). Backend config comes from GitHub secrets (see `quickstart.md`).
- **Argo CD** is installed via `module.argocd.helm_release.argocd`, always `ClusterIP` by default. Access via:
  ```
  kubectl -n argocd port-forward svc/argocd-server 8080:443
  curl -k https://localhost:8080/healthz
  ```
- **Pipeline** runs on `push` to `main` or `workflow_dispatch`. Uses Azure OIDC (no service principal secrets).
- **Teardown**: only via manual `destroy.yml` workflow or `SUBSCRIPTION_ID=<id> ./scripts/remove.sh`.
- **Observability stack** is optional (values in `deploy/helm/observability/`, not deployed by default).

## Drift recovery patterns

The pipeline and `scripts/bootstrap.sh` both handle known Terraform state drifts:

1. **Stale `module.argocd.helm_release.argocd` in state while cluster unreachable**: `terraform state rm module.argocd.helm_release.argocd` then retry plan
2. **Existing Azure RG outside Terraform state**: `terraform import module.cluster.azurerm_resource_group.main ...` then retry
3. **Existing Helm release `argocd` outside Terraform state**: `terraform import module.argocd.helm_release.argocd argocd/argocd` then retry

## Testing

- **Performance** (k6): `TARGET_URL=<url> ./scripts/run-perf.sh predeploy` or `postdeploy`
  - Falls back to Docker if `k6` CLI not installed (`grafana/k6` image)
  - Thresholds: `http_req_failed < 1%`, `http_req_duration p(95) < 300ms`
  - Optional: `K6_VUS`, `K6_DURATION`, `SUMMARY_EXPORT=<path>` for JSON summary
- **Resilience** (built-in, no external tool): `NAMESPACE=argocd DEPLOYMENT=argocd-server ./scripts/run-resilience.sh`
  - Kills a pod, waits for rollout recovery (default timeout: 180s)
- **Gate evaluation**: `./scripts/evaluate-gates.sh` reads summary JSONs + resilience status → `reports/report.md` + `reports/status.env`

## GitOps / microservices

- Three microservices: catalogo, pagamento, pedido (in `deploy/helm/values/`).
- Each service has OTel env vars configured via the Helm chart (OTLP endpoint defaults to `alloy.observability.svc.cluster.local:4318`).
- Helm values use placeholder `REPLACE_WITH_ACR` — replace with actual ACR login server before deploying.
- Argo CD ApplicationSet supports both directory-based and SCM provider generators.

## Terraform variables to know

| Variable | Default | Note |
|---|---|---|
| `enable_argocd_public_access` | `false` | `true` requires `manage_networking_rg`/`manage_ingress_public_ip` |
| `manage_networking_rg` | `false` | Set to `true` if Terraform should create the networking RG |
| `manage_ingress_public_ip` | `false` | Set to `true` if Terraform should create the public IP |
| `enable_external_secrets` | `false` | Set up Key Vault + External Secrets Operator |
| `argocd_chart_version` | `6.7.11` | Pinned in variables |
| `key_vault_name` | `""` | Required if `enable_external_secrets = true` |
