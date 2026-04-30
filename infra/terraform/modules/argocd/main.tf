terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = var.argocd_chart_repo
  chart            = var.argocd_chart_name
  version          = var.argocd_chart_version
  namespace        = var.argocd_namespace
  create_namespace = true

  values = [<<-YAML
    server:
      service:
        type: ClusterIP
      ingress:
        enabled: false
    configs:
      cm:
        url: https://localhost:8080
  YAML
  ]
}
