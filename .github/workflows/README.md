# Workflows

Este diretório contém os workflows de CI/CD e IaC.

## Pipeline principal
Ver [pipeline.yml](pipeline.yml). O fluxo contempla:
- IaC (Terraform)
- Testes não funcionais pre e post deploy
- Teste de resiliência
- Gate final com relatório
- Execução por build e execução periódica (cron)
