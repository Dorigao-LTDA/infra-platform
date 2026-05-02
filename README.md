# Dorigao-LTDA / infra-platform

Base de infraestrutura para a organização **Dorigao-LTDA**. Provisiona recursos base no Azure via Terraform (AKS, ACR, VNet, Argo CD) e gerencia o fluxo GitOps.

## Estado atual
- Infraestrutura provisionada por Terraform em Azure (RG, VNet/Subnet, AKS, ACR).
- Argo CD instalado via Helm/Terraform.
- Argo CD exposto internamente (`ClusterIP`) e acessível por `kubectl port-forward`.
- Pipeline GitHub Actions para bootstrap de infra base em `push` na `main` e `workflow_dispatch`.

## Estrutura
- [`infra/terraform/`](infra/terraform/) — Código Terraform modular (cluster, argocd, ingress, external-secrets).
- [`deploy/helm/service-chart/`](deploy/helm/service-chart/) — Helm chart genérico para microserviços com injeção OTLP.
- [`deploy/gitops/`](deploy/gitops/) — Manifestos Argo CD (Application/ApplicationSet).
- [`.github/workflows/`](.github/workflows/) — Workflows de CI/CD (bootstrap e destroy).
