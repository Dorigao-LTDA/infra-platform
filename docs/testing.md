# Testing and gates

## Test types
- Pre-deploy infra performance (k6)
- Post-deploy performance (k6)
- Chaos tests (pod kill)

## Gates
- Latency p95 and error rate thresholds
- Availability during chaos events
- SLO compliance per service

## Sequence (pre-deploy)
```mermaid
sequenceDiagram
  participant CI as CI Pipeline
  participant Tests as k6
  participant AKS as AKS

  CI->>Tests: run infra tests
  Tests->>AKS: synthetic load
  AKS-->>Tests: metrics
  Tests-->>CI: pass/fail gate
```

## Sequence (chaos)
```mermaid
sequenceDiagram
  participant CI as CI Pipeline
  participant Chaos as Chaos Runner
  participant AKS as AKS
  participant Obs as Grafana

  CI->>Chaos: inject fault
  Chaos->>AKS: kill pods
  AKS-->>Obs: telemetry
  Obs-->>CI: SLO report
```
