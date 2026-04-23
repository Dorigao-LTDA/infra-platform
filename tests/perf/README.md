# Testes de Performance (k6)

## Scripts
- `tests/perf/predeploy-infra.js`
- `tests/perf/postdeploy-app.js`

## Thresholds
- `http_req_failed < 1%`
- `http_req_duration p95 < 300ms`

## Execução
```bash
TARGET_URL=https://localhost:8080/healthz ./scripts/run-perf.sh predeploy
TARGET_URL=https://localhost:8080/healthz ./scripts/run-perf.sh postdeploy
```

## Ajuste de carga
Variáveis opcionais:
- `K6_VUS`
- `K6_DURATION`
- `SUMMARY_EXPORT` (gera arquivo JSON de resumo)
