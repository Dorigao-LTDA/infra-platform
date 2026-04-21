data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "gitops" {
  count                       = var.enable_external_secrets ? 1 : 0
  name                        = var.key_vault_name
  location                    = azurerm_resource_group.main.location
  resource_group_name         = azurerm_resource_group.main.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = var.key_vault_sku_name
  purge_protection_enabled    = false
  soft_delete_retention_days  = 7

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete"
    ]
  }
}

resource "azurerm_user_assigned_identity" "external_secrets" {
  count               = var.enable_external_secrets ? 1 : 0
  name                = "uai-external-secrets"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_key_vault_access_policy" "external_secrets" {
  count        = var.enable_external_secrets ? 1 : 0
  key_vault_id = azurerm_key_vault.gitops[0].id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.external_secrets[0].principal_id

  secret_permissions = [
    "Get",
    "List"
  ]
}

resource "azurerm_federated_identity_credential" "external_secrets" {
  count               = var.enable_external_secrets ? 1 : 0
  name                = "external-secrets-fic"
  resource_group_name = azurerm_resource_group.main.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.main.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.external_secrets[0].id
  subject             = "system:serviceaccount:${var.external_secrets_namespace}:${var.external_secrets_service_account}"
}
