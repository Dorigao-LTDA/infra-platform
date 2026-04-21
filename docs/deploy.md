# Deploy guide

## Goal
Provide a repeatable, Terraform-first deployment flow with GitOps and optional corporate controls (static IP, External Secrets + Key Vault, and overlays).

## Recent changes and motivation
- Terraform-first GitOps: Argo CD and External Secrets are installed via Terraform to reduce manual steps.
- Kustomize overlays: Bootstrap now applies overlays instead of editing files in place, keeping manifests declarative.
- External Secrets + Key Vault: Private repo credentials can be centralized in Key Vault and synced to Argo CD.

## Preconditions
- Azure subscription and permissions to create RG/AKS/ACR.
- Azure CLI, Terraform, kubectl, helm.
- DNS zone for Argo CD domain.

## New deploy checklist
1) Static IP is created (or managed by Terraform).
2) Terraform variables updated in infra/terraform/terraform.tfvars.
3) If using External Secrets: Key Vault created and secrets set.
4) Overlay values updated in deploy/gitops/overlays/corporate/values.env.
5) Bootstrap executed and Argo CD is reachable.

## Step-by-step

### 1) Networking RG and static IP
If you want the IP to persist across re-deploys:

```bash
az group create --name rg-ct-framework-networking --location brazilsouth
az network public-ip create \
  -g rg-ct-framework-networking \
  -n ingress-ct-framework \
  --sku Standard \
  --allocation-method Static
```

Get the IP:

```bash
INGRESS_IP=$(az network public-ip show \
  -g rg-ct-framework-networking \
  -n ingress-ct-framework \
  --query ipAddress -o tsv)
```

### 2) Terraform
Update infra/terraform/terraform.tfvars with your defaults and optional corporate flags:

```bash
manage_networking_rg     = false
manage_ingress_public_ip = false
manage_nodeport_nsg_rule = false
aks_node_nsg_name        = ""

# Optional: External Secrets + Key Vault
enable_external_secrets = true
key_vault_name           = "<key-vault-name>"
```

Apply:

```bash
cd infra/terraform
terraform init
terraform plan -out tfplan
terraform apply -auto-approve tfplan
```

### 3) External Secrets (optional)
If enabled, store secrets in Key Vault:

```bash
az keyvault secret set --vault-name <KV_NAME> --name argocd-repo-token --value "<GITHUB_PAT>"
az keyvault secret set --vault-name <KV_NAME> --name argocd-basic-auth --value "admin:$(openssl passwd -apr1 'SENHA')"
```

Update overlay values in deploy/gitops/overlays/corporate/values.env:
- tenantId
- keyVaultUrl

### 4) Bootstrap

```bash
cd scripts
SUBSCRIPTION_ID=<your-subscription-id> \
INGRESS_PUBLIC_IP=<static-ip> \
REPO_URL=https://github.com/Dorigao-LTDA/central-gitops.git \
SERVICES_REPO_URL=https://github.com/Dorigao-LTDA/continuous-testing-framework.git \
ARGOCD_DOMAIN=argocd.dorigao.dev.br \
SKIP_BOOTSTRAP_REPO_SECRET=1 \
./bootstrap.sh
```

Set SKIP_BOOTSTRAP_REPO_SECRET=1 when External Secrets is enabled.

### 5) DNS
Create an A record for the Argo CD domain:
- argocd.dorigao.dev.br -> <static-ip>

### 6) Validate
- Argo CD UI: https://argocd.dorigao.dev.br
- Ingress:

```bash
kubectl -n ingress-nginx get svc ingress-nginx-controller
```

## Post-deploy
- Argo CD should sync applications automatically.
- Use scripts/run-perf.sh for pre/post deploy tests.

## Troubleshooting
- Repo auth failure: confirm Key Vault secrets or fallback repo secret.
- Argo CD URL incorrect: update overlay values and re-apply.
- Ingress not reachable: check LB backend pool registration and NSG rule.
