variable "location" {
  type        = string
  description = "Azure region"
  default     = "eastus"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "aks_name" {
  type        = string
  description = "AKS cluster name"
}

variable "acr_name" {
  type        = string
  description = "Azure Container Registry name"
}

variable "acr_sku" {
  type        = string
  description = "ACR SKU"
  default     = "Basic"
}

variable "kubernetes_version" {
  type        = string
  description = "AKS Kubernetes version"
  default     = ""
}

variable "node_count" {
  type        = number
  description = "AKS node count"
  default     = 2
}

variable "node_vm_size" {
  type        = string
  description = "AKS node VM size"
  default     = "Standard_B2s"
}

variable "network_address_space" {
  type        = list(string)
  description = "VNet address space"
  default     = ["10.0.0.0/16"]
}

variable "subnet_address_prefix" {
  type        = list(string)
  description = "Subnet address prefix"
  default     = ["10.0.1.0/24"]
}

variable "networking_resource_group_name" {
  type        = string
  description = "Networking resource group for the ingress public IP"
  default     = "rg-ct-framework-networking"
}

variable "manage_networking_rg" {
  type        = bool
  description = "Whether Terraform should create/manage the networking resource group"
  default     = false
}

variable "ingress_public_ip_name" {
  type        = string
  description = "Name of the ingress public IP"
  default     = "ingress-ct-framework"
}

variable "manage_ingress_public_ip" {
  type        = bool
  description = "Whether Terraform should create/manage the ingress public IP"
  default     = false
}

variable "ingress_public_ip_sku" {
  type        = string
  description = "Ingress public IP SKU"
  default     = "Standard"
}

variable "ingress_public_ip_allocation_method" {
  type        = string
  description = "Ingress public IP allocation method"
  default     = "Static"
}

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

variable "manage_nodeport_nsg_rule" {
  type        = bool
  description = "Whether Terraform should manage a NodePort NSG rule in the AKS node RG"
  default     = false
}

variable "aks_node_nsg_name" {
  type        = string
  description = "AKS node pool NSG name (in the node resource group)"
  default     = ""
}

variable "enable_external_secrets" {
  type        = bool
  description = "Whether to install External Secrets and Key Vault integration"
  default     = false
}

variable "key_vault_name" {
  type        = string
  description = "Azure Key Vault name for GitOps secrets"
  default     = ""
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
