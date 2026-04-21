# CI/CD and pipeline

## Stages
1) Build and test
2) Container image publish
3) GitOps update (values/versions)
4) Continuous tests (pre-deploy)
5) Deploy via Argo CD
6) Post-deploy tests and gates

## Sequence (pipeline)
```mermaid
sequenceDiagram
  participant Dev as Developer
  participant CI as CI Pipeline
  participant Registry as ACR
  participant GitOps as GitOps Repo
  participant Argo as Argo CD
  participant AKS as AKS
  participant Tests as Tests

  Dev->>CI: push code
  CI->>CI: unit/integration tests
  CI->>Registry: push image
  CI->>GitOps: update values
  GitOps-->>Argo: sync
  Argo->>AKS: deploy
  Tests->>AKS: pre/post deploy tests
  Tests-->>CI: gate results
```
