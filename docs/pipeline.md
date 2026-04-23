# Pipeline de Bootstrap de Infra

Arquivo: `.github/workflows/pipeline.yml`

## Gatilhos
- `push` na branch `main`
- `workflow_dispatch`

## Objetivo
- Aplicar infraestrutura base de forma idempotente.
- Evitar conflito quando o release Helm do Argo CD já existir fora do state.
- Validar acesso ao Argo CD por túnel local (`kubectl port-forward`).

## Estágios
1. `deploy-base-infra`: `terraform init/plan/apply`.
2. Auto-recovery para drift (`terraform import helm_release.argocd argocd/argocd`) quando necessário.
3. Validação do rollout do `argocd-server`.
4. Validação de serviço interno (`ClusterIP`).
5. Validação de health (`/healthz`) por `kubectl port-forward`.
