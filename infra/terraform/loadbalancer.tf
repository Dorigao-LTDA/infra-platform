# Azure Load Balancer with Static Public IP for persistent ingress
# Supports either Terraform-managed or externally managed public IP

resource "azurerm_resource_group" "networking" {
  count    = var.manage_networking_rg ? 1 : 0
  name     = var.networking_resource_group_name
  location = var.location
}

data "azurerm_resource_group" "networking" {
  count = var.manage_networking_rg ? 0 : 1
  name  = var.networking_resource_group_name
}

locals {
  networking_rg_name     = var.manage_networking_rg ? azurerm_resource_group.networking[0].name : data.azurerm_resource_group.networking[0].name
  networking_rg_location = var.manage_networking_rg ? azurerm_resource_group.networking[0].location : data.azurerm_resource_group.networking[0].location
}

resource "azurerm_public_ip" "ingress" {
  count               = var.manage_ingress_public_ip ? 1 : 0
  name                = var.ingress_public_ip_name
  resource_group_name = local.networking_rg_name
  location            = local.networking_rg_location
  sku                 = var.ingress_public_ip_sku
  allocation_method   = var.ingress_public_ip_allocation_method
}

data "azurerm_public_ip" "ingress" {
  count               = var.manage_ingress_public_ip ? 0 : 1
  name                = var.ingress_public_ip_name
  resource_group_name = local.networking_rg_name
}

locals {
  ingress_public_ip_id      = var.manage_ingress_public_ip ? azurerm_public_ip.ingress[0].id : data.azurerm_public_ip.ingress[0].id
  ingress_public_ip_address = var.manage_ingress_public_ip ? azurerm_public_ip.ingress[0].ip_address : data.azurerm_public_ip.ingress[0].ip_address
}

# Subnet for Load Balancer (will be in main VNet)
resource "azurerm_subnet" "loadbalancer" {
  name                 = "loadbalancer-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.3.0/24"]
}

# Load Balancer (Standard for better performance and features)
resource "azurerm_lb" "main" {
  name                = "lb-ct-framework"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"
  sku_tier            = "Regional"

  frontend_ip_configuration {
    name              = "lb-frontend-ip"
    public_ip_address_id = local.ingress_public_ip_id
  }
}

# Backend Address Pool (will contain AKS nodes)
resource "azurerm_lb_backend_address_pool" "main" {
  loadbalancer_id = azurerm_lb.main.id
  name            = "backend-aks-nodes"
}

# Health Probe for HTTP (port 80 / NodePort)
resource "azurerm_lb_probe" "http" {
  loadbalancer_id     = azurerm_lb.main.id
  name                = "probe-http-32212"
  protocol            = "Tcp"
  port                = 32212  # NGINX HTTP NodePort
  interval_in_seconds = 15
  number_of_probes    = 2
}

# Health Probe for HTTPS (port 443 / NodePort)
resource "azurerm_lb_probe" "https" {
  loadbalancer_id     = azurerm_lb.main.id
  name                = "probe-https-31200"
  protocol            = "Tcp"
  port                = 31200  # NGINX HTTPS NodePort
  interval_in_seconds = 15
  number_of_probes    = 2
}

# Load Balancing Rule - HTTP
resource "azurerm_lb_rule" "http" {
  loadbalancer_id                = azurerm_lb.main.id
  name                           = "lb-rule-http"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 32212  # NGINX HTTP NodePort
  frontend_ip_configuration_name = "lb-frontend-ip"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main.id]
  probe_id                       = azurerm_lb_probe.http.id
  load_distribution              = "SourceIP"
  floating_ip_enabled             = false
}

# Load Balancing Rule - HTTPS
resource "azurerm_lb_rule" "https" {
  loadbalancer_id                = azurerm_lb.main.id
  name                           = "lb-rule-https"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 31200  # NGINX HTTPS NodePort
  frontend_ip_configuration_name = "lb-frontend-ip"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main.id]
  probe_id                       = azurerm_lb_probe.https.id
  load_distribution              = "SourceIP"
  floating_ip_enabled             = false
}

# Association between AKS Nodes and Load Balancer Backend Pool
# TODO: Implement via VMSS association or Network Interface IP Config management

output "loadbalancer_id" {
  value       = azurerm_lb.main.id
  description = "Load Balancer resource ID"
}

output "loadbalancer_public_ip" {
  value       = local.ingress_public_ip_address
  description = "Load Balancer public IP address"
}

output "loadbalancer_backend_pool_id" {
  value       = azurerm_lb_backend_address_pool.main.id
  description = "Backend address pool ID for AKS nodes"
}

output "nginx_http_nodeport" {
  value       = 32212
  description = "NGINX HTTP NodePort (mapped to LB port 80)"
}

output "nginx_https_nodeport" {
  value       = 31200
  description = "NGINX HTTPS NodePort (mapped to LB port 443)"
}
