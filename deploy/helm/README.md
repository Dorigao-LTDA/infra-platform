# Helm Charts

Chart generico para microsservicos (`service-chart`).

## O que faz

O chart cria Deployment, Service (ClusterIP:8080) e Ingress (opcional) para cada microsservico. Injeta automaticamente as variaveis de ambiente OpenTelemetry:

- `OTEL_EXPORTER_OTLP_ENDPOINT`: `http://alloy.observability.svc.cluster.local:4318`
- `OTEL_SERVICE_NAME`: derivado do nome do release
- `OTEL_RESOURCE_ATTRIBUTES`: configuravel via values

## Uso

Cada servico tem seu proprio arquivo de values em `central-gitops/deploy/helm/values/{servico}.yaml`. O placeholder `REPLACE_WITH_ACR` no campo `image.repository` deve ser substituido pelo login server do ACR antes do deploy.

## Templates

- `deployment.yaml`: Deployment com probes, env vars OTel, init containers, volumes
- `service.yaml`: Service ClusterIP na porta 8080
- `ingress.yaml`: Ingress NGINX (habilitado via values)
