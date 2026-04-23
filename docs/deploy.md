# Deploy guide

## Objetivo
Provisionar no Azure, de forma repetível, uma base de plataforma com Argo CD interno.

## Pré-requisitos
- Permissão para criar recursos no Azure.
- `az`, `terraform`, `kubectl`, `helm`, `curl`.
- Secrets do GitHub Actions configurados para OIDC + AKS context.

## Passos
1. Confirmar secrets da workflow (`AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `AKS_RESOURCE_GROUP`, `AKS_CLUSTER_NAME`).
2. Executar `.github/workflows/pipeline.yml` (push na `main` ou manual).
3. Obter credenciais AKS localmente.
4. Abrir túnel local com `kubectl port-forward`.
5. Validar acesso ao Argo CD.

## Variáveis principais
- `resource_group_name` (Terraform)
- `aks_name` (Terraform)
- `acr_name` (Terraform)
- `enable_argocd_public_access` (default: `false`)

## O que o bootstrap faz
- login no Azure via OIDC;
- `terraform init/plan/apply` em `infra/terraform`;
- se ocorrer drift de estado (`cannot re-use a name that is still in use`), importa `helm_release.argocd` e repete plan/apply;
- valida rollout do `argocd-server`;
- valida que o serviço está como `ClusterIP`;
- valida `/healthz` do Argo CD via `kubectl port-forward`.

## Resultado esperado
Mensagem final:
- `Argo CD is reachable at https://localhost:8080 via kubectl tunnel`
