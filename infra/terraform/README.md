# Terraform

Este diretório provisiona a infraestrutura principal no Azure usando módulos reutilizáveis:

## Estrutura

```
infra/terraform/
├── main.tf              # Orchestrator — chama os módulos
├── variables.tf         # Variáveis de entrada (todas)
├── outputs.tf           # Outputs do root module
├── providers.tf         # Provider azurerm
├── data.tf              # Data sources globais
├── versions.tf          # Versões do Terraform e providers
├── terraform.tfvars     # Valores padrão
└── modules/
    ├── cluster/         # RG, VNet, Subnet, ACR, AKS, role assignment
    ├── argocd/          # Providers kubernetes/helm + Helm release Argo CD
    ├── ingress/         # Public IP e RG de networking (opcional)
    └── external-secrets/# Key Vault, UAI, Federated Identity, External Secrets
```

## Módulos

### cluster
Recursos base do Azure: Resource Group, VNet, Subnet, Container Registry, AKS e role assignment AcrPull.

### argocd
Configura os providers `kubernetes` e `helm` via credenciais do AKS e instala o Argo CD via Helm release. Serviço exposto como `ClusterIP` por padrão.

### ingress
Gerencia o Public IP estático e o Resource Group de networking para exposição pública do Argo CD (desabilitado por padrão). Suporta recursos gerenciados pelo Terraform ou existentes (importados).

### external-secrets
Cria Key Vault, User Assigned Identity, Federated Identity Credential e instala o External Secrets Operator via Helm (desabilitado por padrão).

## Acesso do Argo CD

O serviço `argocd-server` é criado como `ClusterIP`.
O acesso recomendado é via túnel local:

```bash
kubectl -n argocd port-forward svc/argocd-server 8080:443
```

Variáveis relevantes:
- `argocd_namespace`
- `enable_argocd_public_access`

## Backend remoto (Azure Storage)

O state do Terraform usa backend `azurerm`.
Crie os recursos de state uma vez:

```bash
az group create --name rg-ctf-tfstate --location brazilsouth
az storage account create --name stctframeworktfstate --resource-group rg-ctf-tfstate --location brazilsouth --sku Standard_LRS --allow-blob-public-access false
az storage container create --name tfstate --account-name stctframeworktfstate --auth-mode login
```

Para bootstrap local, exporte:
- `TF_BACKEND_RESOURCE_GROUP`
- `TF_BACKEND_STORAGE_ACCOUNT`
- `TF_BACKEND_CONTAINER`
- `TF_BACKEND_KEY` (opcional, default: `terraform.tfstate`)

## Opcoes de IP estatico (corporativo)

Por padrao, o Argo CD nao usa IP publico.
Para habilitar exposicao publica explicitamente:
- `enable_argocd_public_access = true`
- `manage_networking_rg = true` para criar o RG de networking.
- `manage_ingress_public_ip = true` para criar o Public IP.

Se o RG/IP ja existem, importe antes de ativar as flags:

```bash
terraform import module.ingress.azurerm_resource_group.networking /subscriptions/<SUB_ID>/resourceGroups/rg-ct-framework-networking
terraform import module.ingress.azurerm_public_ip.ingress /subscriptions/<SUB_ID>/resourceGroups/rg-ct-framework-networking/providers/Microsoft.Network/publicIPAddresses/ingress-ct-framework
```

Variaveis relevantes:
- `networking_resource_group_name`
- `ingress_public_ip_name`
- `ingress_public_ip_sku`
- `ingress_public_ip_allocation_method`

## External Secrets + Key Vault (repo privado)

Para GitOps corporativo com repo privado:
- `enable_external_secrets = true`
- `key_vault_name = "<nome-do-keyvault>"`

Depois do `terraform apply`, crie os secrets no Key Vault:

```bash
az keyvault secret set --vault-name <KV_NAME> --name argocd-repo-token --value "<GITHUB_PAT>"
az keyvault secret set --vault-name <KV_NAME> --name argocd-basic-auth --value "admin:$(openssl passwd -apr1 'SENHA')"
```

Depois do `terraform apply`, use os outputs `tenant_id` e `key_vault_uri` para
configurar seu `SecretStore`/`ExternalSecret` no fluxo GitOps do ambiente.
