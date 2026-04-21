# Testes de Performance (k6)

Scripts de carga e cenarios para validar SLOs de latencia e throughput.

## Proximos passos
- Criar cenarios por servico
- Definir thresholds por metrica
- Criar teste pre-deploy de infra (hello svc + k6)

## Scripts base
- [tests/perf/predeploy-infra.js](tests/perf/predeploy-infra.js)
- [tests/perf/postdeploy-app.js](tests/perf/postdeploy-app.js)

## Executar
Opcoes:
- Com k6 local:
	- `TARGET_URL=https://argocd.dorigao.dev.br/ ./scripts/run-perf.sh predeploy`
	- `TARGET_URL=https://argocd.dorigao.dev.br/ ./scripts/run-perf.sh postdeploy`
- Com Docker:
	- `TARGET_URL=https://argocd.dorigao.dev.br/ ./scripts/run-perf.sh predeploy`

Observacoes:
- Ajuste `TARGET_URL` para o endpoint que deseja medir (ex.: /health de um servico).
- Os thresholds ficam no propio arquivo .js de cada teste.
