# infra-platform

Repositorio de infraestrutura como codigo para o Continuous Testing Framework. Contem modulos Terraform para provisionamento de AKS, ACR, Argo CD e recursos de rede na Azure, alem do Helm chart generico usado por todos os microsservicos.

## Estrutura do repositorio

```
infra-platform/
  .github/workflows/
    pipeline.yml          # Bootstrap: terraform apply + GitOps root-apps
    destroy.yml           # Teardown manual: terraform destroy
  deploy/
    helm/service-chart/   # Helm chart generico para microsservicos
    gitops/               # Manifests GitOps (gerenciados em central-gitops)
  infra/terraform/
    main.tf
    variables.tf
    versions.tf
    providers.tf
    outputs.tf
    data.tf
    terraform.tfvars
    modules/
      cluster/            # RG, VNet, Subnet, ACR, AKS, AcrPull
      argocd/             # Helm release Argo CD (ClusterIP)
      ingress/            # Public IP + networking RG (opcional)
      external-secrets/   # Key Vault + ESO (opcional)
```

## Pre-requisitos

- Azure CLI (`az`)
- Terraform >= 1.6.0
- kubectl
- GitHub CLI (`gh`) para disparar workflows manualmente

## Modulos Terraform

| Modulo | Descricao | Obrigatorio |
|---|---|---|
| `cluster` | Resource Group, VNet 10.0.0.0/16, Subnet 10.0.1.0/24, ACR (Basic SKU), AKS (kubenet, Standard_B2s), role AcrPull | Sim |
| `argocd` | Namespace `argocd`, Helm release argo-cd 6.7.11, servico ClusterIP | Sim |
| `ingress` | Resource Group de networking, Public IP estatica (Standard SKU) para ingress | Nao |
| `external-secrets` | Key Vault, Helm release external-secrets 0.10.5, ServiceAccount | Nao |

## Variaveis

| Variavel | Tipo | Default | Descricao |
|---|---|---|---|
| `location` | string | `eastus` | Regiao Azure |
| `resource_group_name` | string | (obrigatorio) | Nome do resource group principal |
| `aks_name` | string | (obrigatorio) | Nome do cluster AKS |
| `acr_name` | string | (obrigatorio) | Nome do Azure Container Registry |
| `acr_sku` | string | `Basic` | SKU do ACR |
| `kubernetes_version` | string | `""` | Versao do Kubernetes (vazio = ultima estavel) |
| `node_count` | number | `2` | Numero de nodes no pool padrao |
| `node_vm_size` | string | `Standard_B2s` | Tamanho da VM dos nodes |
| `enable_cluster_autoscaler` | bool | `false` | Habilitar autoscaler de nodes |
| `node_pool_max_count` | number | `3` | Maximo de nodes com autoscaler |
| `network_address_space` | list | `["10.0.0.0/16"]` | CIDR da VNet |
| `subnet_address_prefix` | list | `["10.0.1.0/24"]` | CIDR da Subnet |
| `enable_argocd_public_access` | bool | `false` | Expor Argo CD via IP publico |
| `manage_networking_rg` | bool | `false` | Terraform cria o RG de networking |
| `manage_ingress_public_ip` | bool | `false` | Terraform cria a Public IP de ingress |
| `ingress_public_ip_name` | string | `ingress-ct-framework` | Nome da Public IP |
| `ingress_public_ip_sku` | string | `Standard` | SKU da Public IP |
| `argocd_namespace` | string | `argocd` | Namespace do Argo CD |
| `argocd_chart_version` | string | `6.7.11` | Versao do chart Argo CD |
| `argocd_domain` | string | `argocd.dorigao.dev.br` | Dominio do Argo CD |
| `enable_external_secrets` | bool | `false` | Instalar External Secrets + Key Vault |
| `key_vault_name` | string | `""` | Nome do Key Vault (obrigatorio se external-secrets ativo) |
| `external_secrets_chart_version` | string | `0.10.5` | Versao do chart External Secrets |

## Pipeline CI/CD

**pipeline.yml** (`infra-bootstrap`): dispara em push para `main` ou `workflow_dispatch`.

Etapas:
1. Login Azure via OIDC (sem service principal)
2. Obtencao de token OIDC para Terraform
3. `terraform init` com backend config via GitHub secrets
4. `terraform plan` + `terraform apply` com recuperacao automatica de drift
5. Validacao do rollout do Argo CD (`kubectl rollout status`)
6. Validacao do tipo de servico ClusterIP
7. Bootstrap dos root-apps do GitOps (`root-app.yaml` + `root-app-o11y.yaml`)

**destroy.yml**: dispara apenas via `workflow_dispatch`. Executa `terraform destroy -auto-approve` para remover todos os recursos.

## Drift recovery

A pipeline detecta e corrige automaticamente 3 cenarios de drift no state do Terraform:

| Cenario | Deteccao | Acao |
|---|---|---|
| `helm_release.argocd` stale com cluster inacessivel | `Kubernetes cluster unreachable` no plan | `terraform state rm module.argocd.helm_release.argocd` + retry |
| Resource Group existente fora do state | `already exists - to be managed via Terraform this resource needs to be imported` no apply | `terraform import module.cluster.azurerm_resource_group.main` + retry |
| Helm release `argocd` existente fora do state | `cannot re-use a name that is still in use` no apply | `terraform import module.argocd.helm_release.argocd argocd/argocd` + retry |

## Backend remoto

O state do Terraform fica em Azure Storage. Criacao manual dos recursos de backend:

```bash
az group create --name rg-tf-backend --location eastus

az storage account create \
  --name <STORAGE_ACCOUNT> \
  --resource-group rg-tf-backend \
  --location eastus \
  --sku Standard_LRS

az storage container create \
  --name tfstate \
  --account-name <STORAGE_ACCOUNT>
```

Os valores sao passados via GitHub secrets: `TF_BACKEND_RESOURCE_GROUP`, `TF_BACKEND_STORAGE_ACCOUNT`, `TF_BACKEND_CONTAINER`, `TF_BACKEND_KEY`.

## Helm chart generico

O chart em `deploy/helm/service-chart/` e usado por todos os microsservicos. Ele injeta automaticamente as variaveis de ambiente do OpenTelemetry:

- `OTEL_EXPORTER_OTLP_ENDPOINT`: `http://alloy.observability.svc.cluster.local:4318`
- `OTEL_SERVICE_NAME`: derivado do nome do release
- `OTEL_TRACES_EXPORTER`: `otlp`
- `OTEL_METRICS_EXPORTER`: `otlp`
- `OTEL_LOGS_EXPORTER`: `otlp`

Os values usam o placeholder `REPLACE_WITH_ACR` para o registro de imagens. Substitua pelo login server do ACR antes do deploy.

## Acesso ao Argo CD

O Argo CD roda como ClusterIP. Acesso via port-forward:

```bash
kubectl -n argocd port-forward svc/argocd-server 8080:443
```

Senha inicial do admin:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

Health check:

```bash
curl -k https://localhost:8080/healthz
```
