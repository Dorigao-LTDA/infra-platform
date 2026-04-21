# Continuous Testing Framework (TCC)

Documentation for a TCC project focused on continuous testing, GitOps, and observability in Kubernetes.

## Read this first
- Quickstart: ./quickstart.md
- Deploy guide: ./deploy.md
- Architecture: ./architecture.md
- GitOps model: ./gitops.md
- CI/CD and pipeline: ./pipeline.md
- Observability: ./observability.md
- Testing and gates: ./testing.md
- Operations and teardown: ./operations.md

## Defaults (override via env vars)
- Argo CD domain: argocd.dorigao.dev.br (ARGOCD_DOMAIN)
- GitOps repo: https://github.com/Dorigao-LTDA/central-gitops.git (REPO_URL)
- Services repo: https://github.com/Dorigao-LTDA/continuous-testing-framework.git (SERVICES_REPO_URL)
- Kustomize values: deploy/gitops/overlays/corporate/values.env

## Diagrams
- Excalidraw: ./diagrams/architecture.excalidraw, ./diagrams/pipeline.excalidraw, ./diagrams/testing.excalidraw, ./diagrams/gitops.excalidraw
