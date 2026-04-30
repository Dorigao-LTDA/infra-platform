variable "enable_external_secrets" {
  type        = bool
  description = "Whether to install External Secrets and Key Vault integration"
  default     = false
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "key_vault_name" {
  type        = string
  description = "Azure Key Vault name for GitOps secrets"
}

variable "key_vault_sku_name" {
  type        = string
  description = "Key Vault SKU name"
  default     = "standard"
}

variable "external_secrets_namespace" {
  type        = string
  description = "Namespace for External Secrets Operator"
  default     = "external-secrets"
}

variable "external_secrets_chart_repo" {
  type        = string
  description = "External Secrets Helm chart repository"
  default     = "https://charts.external-secrets.io"
}

variable "external_secrets_chart_name" {
  type        = string
  description = "External Secrets Helm chart name"
  default     = "external-secrets"
}

variable "external_secrets_chart_version" {
  type        = string
  description = "External Secrets Helm chart version"
  default     = "0.10.5"
}

variable "external_secrets_service_account" {
  type        = string
  description = "Service account name for External Secrets"
  default     = "external-secrets"
}

variable "key_vault_secret_repo_token_name" {
  type        = string
  description = "Key Vault secret name for Argo CD repo token"
  default     = "argocd-repo-token"
}

variable "key_vault_secret_basic_auth_name" {
  type        = string
  description = "Key Vault secret name for Argo CD basic auth"
  default     = "argocd-basic-auth"
}

variable "tenant_id" {
  type        = string
  description = "Azure tenant ID"
}

variable "tenant_object_id" {
  type        = string
  description = "Azure tenant object ID (current user/SP)"
}

variable "aks_oidc_issuer_url" {
  type        = string
  description = "AKS OIDC issuer URL"
}
