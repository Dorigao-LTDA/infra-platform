variable "argocd_namespace" {
  type        = string
  description = "Namespace for Argo CD"
  default     = "argocd"
}

variable "argocd_chart_repo" {
  type        = string
  description = "Argo CD Helm chart repository"
  default     = "https://argoproj.github.io/argo-helm"
}

variable "argocd_chart_name" {
  type        = string
  description = "Argo CD Helm chart name"
  default     = "argo-cd"
}

variable "argocd_chart_version" {
  type        = string
  description = "Argo CD Helm chart version"
  default     = "6.7.11"
}
