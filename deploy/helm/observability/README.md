# Observability Helm

Este diretorio centraliza referencias da stack Grafana.

## Componentes
- Grafana
- Mimir
- Loki
- Tempo
- Pyroscope
- Grafana Alloy

## Diretriz
- Ingestao 100% OTLP
- Descoberta automatica via Alloy (K8s + Azure)

## Proximos passos
- Definir charts/values para cada componente
- Publicar tudo via Argo CD
