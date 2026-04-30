provider "kubernetes" {
  host                   = module.cluster.kube_config_host
  client_certificate     = base64decode(module.cluster.kube_config_client_certificate)
  client_key             = base64decode(module.cluster.kube_config_client_key)
  cluster_ca_certificate = base64decode(module.cluster.kube_config_cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = module.cluster.kube_config_host
    client_certificate     = base64decode(module.cluster.kube_config_client_certificate)
    client_key             = base64decode(module.cluster.kube_config_client_key)
    cluster_ca_certificate = base64decode(module.cluster.kube_config_cluster_ca_certificate)
  }
}

module "cluster" {
  source = "./modules/cluster"

  resource_group_name   = var.resource_group_name
  location              = var.location
  network_address_space = var.network_address_space
  subnet_address_prefix = var.subnet_address_prefix
  aks_name              = var.aks_name
  kubernetes_version    = var.kubernetes_version
  node_count            = var.node_count
  node_vm_size          = var.node_vm_size
  acr_name              = var.acr_name
  acr_sku               = var.acr_sku
}

module "argocd" {
  source = "./modules/argocd"

  argocd_namespace     = var.argocd_namespace
  argocd_chart_repo    = var.argocd_chart_repo
  argocd_chart_name    = var.argocd_chart_name
  argocd_chart_version = var.argocd_chart_version

  providers = {
    helm       = helm
    kubernetes = kubernetes
  }
}

module "ingress" {
  source = "./modules/ingress"

  enable_argocd_public_access         = var.enable_argocd_public_access
  manage_networking_rg                = var.manage_networking_rg
  manage_ingress_public_ip            = var.manage_ingress_public_ip
  networking_resource_group_name      = var.networking_resource_group_name
  location                            = var.location
  ingress_public_ip_name              = var.ingress_public_ip_name
  ingress_public_ip_sku               = var.ingress_public_ip_sku
  ingress_public_ip_allocation_method = var.ingress_public_ip_allocation_method
  argocd_public_ip                    = var.argocd_public_ip
}

module "external_secrets" {
  source = "./modules/external-secrets"
  count  = var.enable_external_secrets ? 1 : 0

  enable_external_secrets          = var.enable_external_secrets
  location                         = var.location
  resource_group_name              = var.resource_group_name
  key_vault_name                   = var.key_vault_name
  key_vault_sku_name               = var.key_vault_sku_name
  external_secrets_namespace       = var.external_secrets_namespace
  external_secrets_chart_repo      = var.external_secrets_chart_repo
  external_secrets_chart_name      = var.external_secrets_chart_name
  external_secrets_chart_version   = var.external_secrets_chart_version
  external_secrets_service_account = var.external_secrets_service_account
  aks_oidc_issuer_url              = module.cluster.aks_oidc_issuer_url
  tenant_id                        = data.azurerm_client_config.current.tenant_id
  tenant_object_id                 = data.azurerm_client_config.current.object_id

  providers = {
    helm = helm
  }
}
