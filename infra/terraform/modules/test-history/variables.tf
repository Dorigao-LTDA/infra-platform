variable "storage_account_name" {
  type        = string
  description = "Storage account name for test history"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "runner_principal_object_id" {
  type        = string
  description = "Object ID of the CI/CD runner service principal (for Blob role assignment)"
}
