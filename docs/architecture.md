# Architecture

## Scope
The framework provides:
- GitOps control plane (Argo CD)
- Kubernetes runtime (AKS)
- Optional observability components
- Continuous testing gates (performance + resilience)

## High-level architecture
```mermaid
flowchart LR
  Dev[Developer] -->|push| Git[GitHub]
  Git --> CI[GitHub Actions]
  CI --> TF[Terraform]
  TF --> Azure[Azure RG + AKS + ACR]
  TF --> Argo[Argo CD via Helm]
  Argo --> AKS[Kubernetes]
  CI --> NFR[Testes Nao Funcionais]
  NFR --> Gates[Gate Final]
```

## Resource Groups
- **rg-ct-framework**: Main RG for AKS, VNet, ACR (deleted by `terraform destroy`)

## Network
- O serviço `argocd-server` é `ClusterIP`.
- O acesso administrativo é feito por túnel local com `kubectl port-forward`.
- URL de acesso local: `https://localhost:8080`.

## Identity and access
- Azure OIDC para pipeline (GitHub Actions).
- Identidade gerenciada opcional para External Secrets + Key Vault.

## Sequence (GitOps sync)
```mermaid
sequenceDiagram
  participant Dev as Developer
  participant Git as GitHub
  participant Argo as Argo CD
  participant AKS as AKS

  Dev->>Git: push config
  Git-->>Argo: webhook/poll
  Argo->>AKS: apply state
  AKS-->>Argo: sync/health
```
