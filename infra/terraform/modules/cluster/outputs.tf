output "resource_group_name" {
  value       = azurerm_resource_group.main.name
  description = "Resource group name"
}

output "resource_group_id" {
  value       = azurerm_resource_group.main.id
  description = "Resource group ID"
}

output "location" {
  value       = azurerm_resource_group.main.location
  description = "Azure region"
}

output "aks_name" {
  value       = azurerm_kubernetes_cluster.main.name
  description = "AKS cluster name"
}

output "aks_id" {
  value       = azurerm_kubernetes_cluster.main.id
  description = "AKS cluster ID"
}

output "kube_config_host" {
  value       = azurerm_kubernetes_cluster.main.kube_config[0].host
  description = "Kubernetes API server host"
  sensitive   = true
}

output "kube_config_client_certificate" {
  value       = azurerm_kubernetes_cluster.main.kube_config[0].client_certificate
  description = "Base64-encoded client certificate"
  sensitive   = true
}

output "kube_config_client_key" {
  value       = azurerm_kubernetes_cluster.main.kube_config[0].client_key
  description = "Base64-encoded client key"
  sensitive   = true
}

output "kube_config_cluster_ca_certificate" {
  value       = azurerm_kubernetes_cluster.main.kube_config[0].cluster_ca_certificate
  description = "Base64-encoded cluster CA certificate"
  sensitive   = true
}

output "kube_config_raw" {
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  description = "Raw kubeconfig"
  sensitive   = true
}

output "aks_node_resource_group" {
  value       = azurerm_kubernetes_cluster.main.node_resource_group
  description = "AKS node resource group name"
}

output "aks_oidc_issuer_url" {
  value       = azurerm_kubernetes_cluster.main.oidc_issuer_url
  description = "AKS OIDC issuer URL"
}

output "acr_login_server" {
  value       = azurerm_container_registry.main.login_server
  description = "ACR login server"
}

output "acr_name" {
  value       = azurerm_container_registry.main.name
  description = "ACR name"
}

output "acr_id" {
  value       = azurerm_container_registry.main.id
  description = "ACR ID"
}

output "kubelet_object_id" {
  value       = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  description = "AKS kubelet identity object ID"
}
