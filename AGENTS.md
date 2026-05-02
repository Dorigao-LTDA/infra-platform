# AGENTS.md — Dorigao-LTDA / infra-platform

Terraform + Argo CD + AKS.

## Repo structure

| Directory | Purpose |
|---|---|
| `infra/terraform/` | Azure IaC: modular — cluster, argocd, ingress, external-secrets |
| `infra/terraform/modules/cluster/` | RG, VNet, Subnet, ACR, AKS, AcrPull role |
| `deploy/helm/service-chart/` | Generic Helm chart for microservices with OTLP env injection |
| `deploy/gitops/` | Argo CD Application/ApplicationSet manifests (managed in `Dorigao-LTDA/central-gitops`) |
| `.github/workflows/` | `pipeline.yml` (bootstrap), `destroy.yml` (manual teardown) |

## Core facts

- **No language package managers** — no npm, pip, cargo, go.mod. Pure infra/ops repo.
- **Terraform** is the only IaC tool (required `>= 1.6.0`, providers pinned). Working dir: `infra/terraform/`.
- **Backend**: Azure Storage (`azurerm`). Backend config comes from GitHub secrets.
- **Argo CD** is installed via `module.argocd.helm_release.argocd`, always `ClusterIP` by default. Access via:
  ```
  kubectl -n argocd port-forward svc/argocd-server 8080:443
  curl -k https://localhost:8080/healthz
  ```
- **Pipeline** runs on `push` to `main` or `workflow_dispatch`. Uses Azure OIDC (no service principal secrets).
- **Teardown**: only via manual `destroy.yml` workflow.

## Drift recovery patterns

The pipeline handles known Terraform state drifts:

1. **Stale `module.argocd.helm_release.argocd` in state while cluster unreachable**: `terraform state rm module.argocd.helm_release.argocd` then retry plan
2. **Existing Azure RG outside Terraform state**: `terraform import module.cluster.azurerm_resource_group.main ...` then retry
3. **Existing Helm release `argocd` outside Terraform state**: `terraform import module.argocd.helm_release.argocd argocd/argocd` then retry

## GitOps / microservices

- Argo CD ApplicationSet supports both directory-based and SCM provider generators.
- Service Helm chart injects OTel env vars by default (OTLP endpoint: `alloy.observability.svc.cluster.local:4318`).
- Helm values use placeholder `REPLACE_WITH_ACR` — replace with actual ACR login server before deploying.

## Terraform variables to know

| Variable | Default | Note |
|---|---|---|
| `enable_argocd_public_access` | `false` | `true` requires `manage_networking_rg`/`manage_ingress_public_ip` |
| `manage_networking_rg` | `false` | Set to `true` if Terraform should create the networking RG |
| `manage_ingress_public_ip` | `false` | Set to `true` if Terraform should create the public IP |
| `enable_external_secrets` | `false` | Set up Key Vault + External Secrets Operator |
| `argocd_chart_version` | `6.7.11` | Pinned in variables |
| `key_vault_name` | `""` | Required if `enable_external_secrets = true` |
