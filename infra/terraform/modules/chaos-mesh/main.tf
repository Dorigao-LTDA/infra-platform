terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
  }
}

resource "helm_release" "chaos_mesh" {
  name             = "chaos-mesh"
  repository       = var.chaos_mesh_chart_repo
  chart            = var.chaos_mesh_chart_name
  version          = var.chaos_mesh_chart_version
  namespace        = var.chaos_mesh_namespace
  create_namespace = true

  set {
    name  = "createCustomResource"
    value = "true"
  }
}
