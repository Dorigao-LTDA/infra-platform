resource "azurerm_resource_group" "networking" {
  count    = var.enable_argocd_public_access && var.manage_networking_rg ? 1 : 0
  name     = var.networking_resource_group_name
  location = var.location
}

data "azurerm_resource_group" "networking" {
  count = var.enable_argocd_public_access && !var.manage_networking_rg ? 1 : 0
  name  = var.networking_resource_group_name
}

locals {
  networking_rg_name = var.enable_argocd_public_access ? (
    var.manage_networking_rg ? azurerm_resource_group.networking[0].name : data.azurerm_resource_group.networking[0].name
  ) : null

  networking_rg_location = var.enable_argocd_public_access ? (
    var.manage_networking_rg ? azurerm_resource_group.networking[0].location : data.azurerm_resource_group.networking[0].location
  ) : null
}

resource "azurerm_public_ip" "ingress" {
  count               = var.enable_argocd_public_access && var.manage_ingress_public_ip ? 1 : 0
  name                = var.ingress_public_ip_name
  resource_group_name = local.networking_rg_name
  location            = local.networking_rg_location
  sku                 = var.ingress_public_ip_sku
  allocation_method   = var.ingress_public_ip_allocation_method
}

data "azurerm_public_ip" "ingress" {
  count               = var.enable_argocd_public_access && !var.manage_ingress_public_ip ? 1 : 0
  name                = var.ingress_public_ip_name
  resource_group_name = local.networking_rg_name
}

locals {
  ingress_public_ip_address = var.enable_argocd_public_access ? (
    var.manage_ingress_public_ip ? azurerm_public_ip.ingress[0].ip_address : data.azurerm_public_ip.ingress[0].ip_address
  ) : null
}

check "argocd_static_ip_match" {
  assert {
    condition     = !var.enable_argocd_public_access || local.ingress_public_ip_address == var.argocd_public_ip
    error_message = "Configured argocd_public_ip differs from ingress public IP."
  }
}
