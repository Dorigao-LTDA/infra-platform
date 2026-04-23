# Quickstart (Azure + Argo CD interno)

## 1) Configurar secrets no GitHub
No repositório, configure os secrets usados pela workflow:
- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `AKS_RESOURCE_GROUP`
- `AKS_CLUSTER_NAME`

## 2) Executar bootstrap da infra
O bootstrap é feito por GitHub Actions em:
- `push` na branch `main`; ou
- execução manual (`workflow_dispatch`) da workflow `.github/workflows/pipeline.yml`.

## 3) Obter contexto do cluster
```bash
az aks get-credentials --resource-group <AKS_RESOURCE_GROUP> --name <AKS_CLUSTER_NAME> --overwrite-existing
```

## 4) Abrir túnel local para o Argo CD
```bash
kubectl -n argocd port-forward svc/argocd-server 8080:443
```

## 5) Confirmar acesso
- URL: `https://localhost:8080`
- Health endpoint:
```bash
curl -k https://localhost:8080/healthz
```
