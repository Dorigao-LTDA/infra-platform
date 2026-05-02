# Workflows

Este diretório contém os workflows de CI/CD e IaC.

## Pipeline principal
Ver [pipeline.yml](pipeline.yml). O fluxo contempla:
- IaC (Terraform init, plan e apply com drift recovery)
- Validação do deployment do Argo CD (rollout status + verificação ClusterIP)
- Execução por `push` na `main` ou `workflow_dispatch`

## Destroy
Ver [destroy.yml](destroy.yml). Workflow manual para teardown completo da infraestrutura via `terraform destroy`.
