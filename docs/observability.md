# Observability (OTLP + Grafana stack)

## Goal
Centralizar métricas, logs, traces e profiles.

## Components
- Grafana
- Mimir
- Loki
- Tempo
- Pyroscope
- Alloy

## Estado no repositório
- Values de referência em `deploy/helm/observability/`.
- A implantação da stack completa é opcional e pode ser adicionada ao fluxo GitOps do ambiente.

## OTLP conventions
- OTEL_EXPORTER_OTLP_ENDPOINT points to Alloy
- OTEL_SERVICE_NAME per microservice
- Standard attributes: service.namespace, service.instance.id, cloud.provider

## Discovery
- Kubernetes discovery in Alloy for pods/services
- Azure discovery for managed resources

## Data flow (sequence)
```mermaid
sequenceDiagram
  participant App as Microservice
  participant OTel as OTLP
  participant Alloy as Grafana Alloy
  participant Mimir as Mimir
  participant Loki as Loki
  participant Tempo as Tempo
  participant Pyro as Pyroscope
  participant Grafana as Grafana

  App->>OTel: emit metrics/logs/traces/profiles
  OTel->>Alloy: OTLP
  Alloy->>Mimir: metrics
  Alloy->>Loki: logs
  Alloy->>Tempo: traces
  Alloy->>Pyro: profiles
  Grafana->>Mimir: query
  Grafana->>Loki: query
  Grafana->>Tempo: query
  Grafana->>Pyro: query
```
