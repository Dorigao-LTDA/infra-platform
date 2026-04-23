# Terraform

Este diretório provisiona a infraestrutura principal no Azure:
- Resource Group
- VNet/Subnet
- AKS
- ACR
- Argo CD (Helm)
- Exposição pública opcional do Argo CD (desabilitada por padrão)

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
terraform import azurerm_resource_group.networking /subscriptions/<SUB_ID>/resourceGroups/rg-ct-framework-networking
terraform import azurerm_public_ip.ingress /subscriptions/<SUB_ID>/resourceGroups/rg-ct-framework-networking/providers/Microsoft.Network/publicIPAddresses/ingress-ct-framework
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
