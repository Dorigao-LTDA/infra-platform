# Continuous Testing Framework (TCC)

Projeto acadêmico focado em **esteira de deployment com Argo CD no Azure (AKS)** e execução contínua de testes não funcionais de **performance** e **resiliência**.

## Estado atual do projeto
- Infraestrutura provisionada por Terraform em Azure (RG, VNet/Subnet, AKS, ACR).
- Argo CD instalado via Helm/Terraform.
- Argo CD exposto internamente (`ClusterIP`) e acessível por `kubectl port-forward`.
- Pipeline GitHub Actions para bootstrap de infra base em `push` na `main` e `workflow_dispatch`.

## Documentação
- [Visão geral](docs/README.md)
- [Quickstart](docs/quickstart.md)
- [Deploy](docs/deploy.md)
- [Arquitetura](docs/architecture.md)
- [Pipeline](docs/pipeline.md)
- [Testes e gates](docs/testing.md)
- [Operação e remoção](docs/operations.md)
- [GitOps](docs/gitops.md)
- [Observabilidade](docs/observability.md)
