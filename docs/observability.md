# Observability (OTLP + Grafana stack)

## Goal
Centralize metrics, logs, traces, and profiles using only OTLP and Grafana stack components.

## Components
- Grafana (dashboards)
- Mimir (metrics)
- Loki (logs)
- Tempo (traces)
- Pyroscope (profiles)
- Alloy (OTLP ingest + discovery)

## Enable
- Deploy root-app-o11y.yaml (GitOps repo)
- Ensure namespaces: observability

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
