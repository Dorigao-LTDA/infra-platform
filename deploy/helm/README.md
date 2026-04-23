# Helm Charts

Este diretório contém:
- chart base para microserviços (`service-chart`);
- values por serviço (`values/`);
- values de referência para observabilidade (`observability/`).

## Uso rápido
1. Ajustar `repository` e `tag` em `deploy/helm/values/*.yaml`.
2. Publicar chart/values no fluxo GitOps do ambiente.
