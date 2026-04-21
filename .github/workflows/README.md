# Workflows

Este diretorio contera workflows do GitHub Actions para CI/CD e IaC.

## Pipeline base
Ver [pipeline.yml](pipeline.yml). O fluxo contempla:
- IaC (Terraform)
- Teste pre-deploy de infraestrutura
- Build e testes
- Build de imagem
- Deploy via Argo CD
- Testes de performance e resiliencia
- Gates e relatorio
