# Deploy guide

## Objetivo
Provisionar no Azure, de forma repetível, uma base de plataforma com Argo CD interno.

## Pré-requisitos
- Permissão para criar recursos no Azure.
- `az`, `terraform`, `kubectl`, `helm`, `curl`.
- Secrets do GitHub Actions configurados para OIDC + AKS context + backend remoto.

## Backend remoto (Azure Storage)
Crie os recursos uma vez para armazenar o state remoto:

```bash
az group create --name rg-ctf-tfstate --location brazilsouth
az storage account create --name stctframeworktfstate --resource-group rg-ctf-tfstate --location brazilsouth --sku Standard_LRS --allow-blob-public-access false
az storage container create --name tfstate --account-name stctframeworktfstate --auth-mode login
```

Se você já tem state local, migre uma vez para o backend remoto:

```bash
cd infra/terraform
terraform init -migrate-state \
	-backend-config="resource_group_name=rg-ctf-tfstate" \
	-backend-config="storage_account_name=stctframeworktfstate" \
	-backend-config="container_name=tfstate" \
	-backend-config="key=infra/terraform.tfstate"
```

## Passos
1. Confirmar secrets da workflow (`AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `AKS_RESOURCE_GROUP`, `AKS_CLUSTER_NAME`, `TF_BACKEND_RESOURCE_GROUP`, `TF_BACKEND_STORAGE_ACCOUNT`, `TF_BACKEND_CONTAINER`, `TF_BACKEND_KEY`).
2. Executar `.github/workflows/pipeline.yml` (push na `main` ou manual).
3. Obter credenciais AKS localmente.
4. Abrir túnel local com `kubectl port-forward`.
5. Validar acesso ao Argo CD.

## Secrets do backend remoto
- `TF_BACKEND_RESOURCE_GROUP`: nome do RG do storage de state (ex.: `rg-ctf-tfstate`)
- `TF_BACKEND_STORAGE_ACCOUNT`: nome da storage account (ex.: `stctframeworktfstate`)
- `TF_BACKEND_CONTAINER`: nome do container blob (ex.: `tfstate`)
- `TF_BACKEND_KEY`: caminho do state (ex.: `infra/terraform.tfstate`)

## Variáveis principais
- `resource_group_name` (Terraform)
- `aks_name` (Terraform)
- `acr_name` (Terraform)
- `enable_argocd_public_access` (default: `false`)

## Estrutura modular do Terraform
O diretório `infra/terraform/` é organizado em módulos filho:

```
infra/terraform/
├── main.tf              # Orchestrator — chama os módulos
├── variables.tf         # Variáveis de entrada
├── outputs.tf           # Outputs do root module
├── providers.tf         # Provider azurerm
├── data.tf              # Data sources globais
├── versions.tf          # Versões do Terraform e providers
├── terraform.tfvars     # Valores padrão
└── modules/
    ├── cluster/          # RG, VNet, Subnet, ACR, AKS, AcrPull
    ├── argocd/          # Helm release Argo CD (ClusterIP)
    ├── ingress/         # Public IP e RG de networking (opcional)
    └── external-secrets/# Key Vault, UAI, Federated Identity, External Secrets
```

Os providers `kubernetes` e `helm` são configurados no root module e repassados aos módulos `argocd` e `external-secrets` via `providers`.

## O que o bootstrap faz
- login no Azure via OIDC;
- `terraform init/plan/apply` em `infra/terraform`;
- se ocorrer drift de estado (`cannot re-use a name that is still in use`), importa `module.argocd.helm_release.argocd` e repete plan/apply;
- valida rollout do `argocd-server`;
- valida que o serviço está como `ClusterIP`;
- valida `/healthz` do Argo CD via `kubectl port-forward`.

## Resultado esperado
Mensagem final:
- `Argo CD is reachable at https://localhost:8080 via kubectl tunnel`
