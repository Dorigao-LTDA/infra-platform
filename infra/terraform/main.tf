provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

# Note: rg-ct-framework-networking is managed externally (not by Terraform)
# This RG holds the static Public IP for Ingress and persists across terraform destroy

resource "azurerm_virtual_network" "main" {
  name                = "${var.resource_group_name}-vnet"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = var.network_address_space
}

resource "azurerm_subnet" "aks" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.subnet_address_prefix
}

resource "azurerm_container_registry" "main" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = var.acr_sku
  admin_enabled       = false
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = var.aks_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = var.aks_name

  network_profile {
    network_plugin = "kubenet"
    service_cidr     = "10.1.0.0/16"
    dns_service_ip   = "10.1.0.10"
  }

  default_node_pool {
    name                = "default"
    node_count          = var.node_count
    vm_size             = var.node_vm_size
    vnet_subnet_id      = azurerm_subnet.aks.id
    orchestrator_version = var.kubernetes_version != "" ? var.kubernetes_version : null
  }

  identity {
    type = "SystemAssigned"
  }

  oidc_issuer_enabled = true
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}

# TODO: Grafana Stack (Mimir, Loki, Tempo, Pyroscope, Alloy) via Helm/Argo CD
