variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "location" {
  type        = string
  description = "Azure region"
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

variable "aks_name" {
  type        = string
  description = "AKS cluster name"
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

variable "enable_cluster_autoscaler" {
  type        = bool
  description = "Enable AKS cluster autoscaler"
  default     = false
}

variable "node_pool_max_count" {
  type        = number
  description = "Maximum node count for cluster autoscaler"
  default     = 3
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
