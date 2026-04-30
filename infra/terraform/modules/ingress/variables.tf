variable "enable_argocd_public_access" {
  type        = bool
  description = "Expose Argo CD using Azure public IP/load balancer"
  default     = false
}

variable "manage_networking_rg" {
  type        = bool
  description = "Whether Terraform should create/manage the networking resource group"
  default     = false
}

variable "manage_ingress_public_ip" {
  type        = bool
  description = "Whether Terraform should create/manage the ingress public IP"
  default     = false
}

variable "networking_resource_group_name" {
  type        = string
  description = "Networking resource group for the ingress public IP"
  default     = "rg-ct-framework-networking"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "ingress_public_ip_name" {
  type        = string
  description = "Name of the ingress public IP"
  default     = "ingress-ct-framework"
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

variable "argocd_public_ip" {
  type        = string
  description = "Static public IP that Argo CD service must use"
  default     = "20.197.180.231"
}
