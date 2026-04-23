# Quickstart (Azure + Argo CD interno)

## 1) Configurar secrets no GitHub
No repositório, configure os secrets usados pela workflow:
- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `AKS_RESOURCE_GROUP`
- `AKS_CLUSTER_NAME`

## 2) Criar backend remoto do Terraform (uma vez)
```bash
az group create --name rg-ctf-tfstate --location brazilsouth
az storage account create --name stctframeworktfstate --resource-group rg-ctf-tfstate --location brazilsouth --sku Standard_LRS --allow-blob-public-access false
az storage container create --name tfstate --account-name stctframeworktfstate --auth-mode login
```

Adicionar também estes secrets no GitHub:
- `TF_BACKEND_RESOURCE_GROUP=rg-ctf-tfstate`
- `TF_BACKEND_STORAGE_ACCOUNT=stctframeworktfstate`
- `TF_BACKEND_CONTAINER=tfstate`
- `TF_BACKEND_KEY=infra/terraform.tfstate`

Se houver state local anterior, migre uma vez:
```bash
cd infra/terraform
terraform init -migrate-state \
	-backend-config="resource_group_name=rg-ctf-tfstate" \
	-backend-config="storage_account_name=stctframeworktfstate" \
	-backend-config="container_name=tfstate" \
	-backend-config="key=infra/terraform.tfstate"
```

## 3) Executar bootstrap da infra
O bootstrap é feito por GitHub Actions em:
- `push` na branch `main`; ou
- execução manual (`workflow_dispatch`) da workflow `.github/workflows/pipeline.yml`.

## 4) Obter contexto do cluster
```bash
az aks get-credentials --resource-group <AKS_RESOURCE_GROUP> --name <AKS_CLUSTER_NAME> --overwrite-existing
```

## 5) Abrir túnel local para o Argo CD
```bash
kubectl -n argocd port-forward svc/argocd-server 8080:443
```

## 6) Confirmar acesso
- URL: `https://localhost:8080`
- Health endpoint:
```bash
curl -k https://localhost:8080/healthz
```
