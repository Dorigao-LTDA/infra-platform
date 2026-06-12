# Workflows

Workflows de CI/CD do infra-platform.

## pipeline.yml

Bootstrap de infraestrutura. Dispara em push para `main` ou `workflow_dispatch`.

Etapas: login Azure via OIDC, Terraform init/plan/apply com recuperacao automatica de drift, validacao do Argo CD (rollout + ClusterIP), bootstrap dos root-apps do central-gitops.

Ver [pipeline.yml](pipeline.yml).

## destroy.yml

Teardown manual de todos os recursos. Dispara apenas via `workflow_dispatch`. Executa `terraform destroy -auto-approve`.

Ver [destroy.yml](destroy.yml).

## register-oidc.yml

Registra credenciais federadas OIDC no Azure AD para novos repositorios. Usado pelo script `scripts/setup-oidc.sh`.

Ver [register-oidc.yml](register-oidc.yml).
