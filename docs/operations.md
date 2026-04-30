# Operations

## Remove everything

```
cd scripts
SUBSCRIPTION_ID=<your-subscription-id> ./remove.sh
```

**Note**: This removes AKS, VNet, and ACR from `rg-ct-framework`.

## Drift recovery
Os scripts de bootstrap e a pipeline recuperam automaticamente os seguintes padrões de drift:

1. **Stale `module.argocd.helm_release.argocd` no state com cluster inacessível**: `terraform state rm module.argocd.helm_release.argocd` e retry.
2. **RG existente fora do state**: `terraform import module.cluster.azurerm_resource_group.main /subscriptions/<SUB_ID>/resourceGroups/<RG_NAME>` e retry.
3. **Helm release `argocd` existente fora do state**: `terraform import module.argocd.helm_release.argocd argocd/argocd` e retry.

## Runbooks
- Argo CD não responde: `kubectl -n argocd get svc argocd-server -o wide`.
- Tipo de serviço incorreto: validar `kubectl -n argocd get svc argocd-server -o jsonpath='{.spec.type}'` (esperado: `ClusterIP`).
- Health endpoint falhando: validar túnel local com `kubectl -n argocd port-forward svc/argocd-server 8080:443` e `curl -k https://localhost:8080/healthz`.
- Erro `cannot re-use a name that is still in use` no bootstrap: o script tenta recuperar automaticamente com `terraform import module.argocd.helm_release.argocd argocd/argocd` e reaplica o plano.

## Remove sequence
```mermaid
sequenceDiagram
  participant Dev as Developer
  participant Remove as remove.sh
  participant AKS as AKS
  participant TF as Terraform
  participant MainRG as rg-ct-framework

  Dev->>Remove: run
  Remove->>AKS: delete namespaces
  Remove->>TF: destroy
  TF->>MainRG: delete AKS/VNet/ACR
  TF-->>Remove: removed
```
