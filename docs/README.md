# Documentação do projeto

## Ordem recomendada
1. [quickstart.md](./quickstart.md)
2. [deploy.md](./deploy.md)
3. [pipeline.md](./pipeline.md)
4. [testing.md](./testing.md)

## Referências
- [architecture.md](./architecture.md)
- [gitops.md](./gitops.md)
- [observability.md](./observability.md)
- [operations.md](./operations.md)

## Padrões definidos
- Argo CD interno via `ClusterIP`.
- Acesso ao Argo CD via `kubectl -n argocd port-forward svc/argocd-server 8080:443`.
- Bootstrap de infra base via GitHub Actions em push na `main` e execução manual.
- Terraform modular: cluster, argocd, ingress, external-secrets (ver `architecture.md` e `deploy.md`).
