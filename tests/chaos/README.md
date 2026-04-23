# Testes de Resiliencia (Chaos)

O pipeline utiliza um teste de resiliência sem dependência externa:
- remoção de um pod do `argocd-server`;
- validação de recuperação do deployment.

Script:
- `scripts/run-resilience.sh`

O manifesto em `tests/chaos/pod-kill-catalogo.yaml` continua como exemplo para ambientes com Chaos Mesh.
