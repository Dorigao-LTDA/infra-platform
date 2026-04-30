output "resource_group_name" {
  value       = var.resource_group_name
  description = "Resource group name"
}

output "aks_name" {
  value       = var.aks_name
  description = "AKS name"
}

output "acr_name" {
  value       = var.acr_name
  description = "ACR name"
}

output "acr_login_server" {
  value       = module.cluster.acr_login_server
  description = "ACR login server"
}

output "aks_node_resource_group" {
  value       = module.cluster.aks_node_resource_group
  description = "AKS node resource group name"
}

output "kube_config_raw" {
  value       = module.cluster.kube_config_raw
  description = "Kubeconfig"
  sensitive   = true
}

output "tenant_id" {
  value       = data.azurerm_client_config.current.tenant_id
  description = "Azure tenant ID"
}

output "key_vault_uri" {
  value       = try(module.external_secrets[0].key_vault_uri, "")
  description = "Key Vault URI for GitOps secrets"
}

output "external_secrets_identity_client_id" {
  value       = try(module.external_secrets[0].external_secrets_identity_client_id, "")
  description = "Client ID for External Secrets workload identity"
}

output "argocd_public_ip" {
  value       = module.ingress.public_ip_address
  description = "Public IP expected for Argo CD endpoint when public access is enabled"
}

output "argocd_url" {
  value       = "https://localhost:8080"
  description = "Argo CD URL via kubectl port-forward"
}

output "argocd_port_forward_command" {
  value       = "kubectl -n ${var.argocd_namespace} port-forward svc/argocd-server 8080:443"
  description = "Command to access Argo CD using local tunnel"
}
