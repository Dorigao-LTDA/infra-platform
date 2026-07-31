variable "chaos_mesh_namespace" {
  type        = string
  description = "Namespace for Chaos Mesh"
  default     = "chaos-mesh"
}

variable "chaos_mesh_chart_repo" {
  type        = string
  description = "Chaos Mesh Helm chart repository"
  default     = "https://charts.chaos-mesh.org"
}

variable "chaos_mesh_chart_name" {
  type        = string
  description = "Chaos Mesh Helm chart name"
  default     = "chaos-mesh"
}

variable "chaos_mesh_chart_version" {
  type        = string
  description = "Chaos Mesh Helm chart version"
  default     = "2.6.3"
}
