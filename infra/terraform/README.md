# Terraform

Este diretorio contem o esqueleto de IaC para provisionar a infraestrutura (AKS, ACR, rede, observabilidade).

## Componentes alvo
- Resource Group
- AKS
- ACR
- Rede (VNet/Subnets)
- Observabilidade Grafana Stack (Mimir, Loki, Tempo, Pyroscope, Alloy)

## Proximos passos
- Implementar recursos base no [main.tf](main.tf).
- Ajustar variaveis e outputs para uso em CI/CD.
- Adicionar ambientes (dev/stage/prod) conforme necessario.

## Opcoes de IP estatico (corporativo)
Por padrao, o IP publico do ingress pode ser externo. Para gerenciar tudo via Terraform:
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

## NodePort NSG rule (opcional)
Para permitir o acesso externo direto aos NodePorts do ingress:
- `manage_nodeport_nsg_rule = true`
- `aks_node_nsg_name = "<nome do NSG do agent pool>"`

Para descobrir o NSG do agent pool:
```bash
terraform output -raw aks_node_resource_group
az network nsg list -g <NODE_RG> -o table
```

O NSG fica no node resource group do AKS (ex.: `MC_rg-ct-framework_aks-ct-framework_brazilsouth`).

## External Secrets + Key Vault (repo privado)
Para GitOps corporativo com repo privado:
- `enable_external_secrets = true`
- `key_vault_name = "<nome-do-keyvault>"`

Depois do `terraform apply`, crie os secrets no Key Vault:
```bash
az keyvault secret set --vault-name <KV_NAME> --name argocd-repo-token --value "<GITHUB_PAT>"
az keyvault secret set --vault-name <KV_NAME> --name argocd-basic-auth --value "admin:$(openssl passwd -apr1 'SENHA')"
```

Atualize `deploy/gitops/overlays/corporate/values.env` com `tenantId` e `keyVaultUrl`
antes de executar o bootstrap para aplicar o manifest de External Secrets.
