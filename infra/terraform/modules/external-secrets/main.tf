terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
  }
}

resource "azurerm_key_vault" "gitops" {
  count                      = var.enable_external_secrets ? 1 : 0
  name                       = var.key_vault_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = var.tenant_id
  sku_name                   = var.key_vault_sku_name
  purge_protection_enabled   = false
  soft_delete_retention_days = 7

  access_policy {
    tenant_id = var.tenant_id
    object_id = var.tenant_object_id

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
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_key_vault_access_policy" "external_secrets" {
  count        = var.enable_external_secrets ? 1 : 0
  key_vault_id = azurerm_key_vault.gitops[0].id
  tenant_id    = var.tenant_id
  object_id    = azurerm_user_assigned_identity.external_secrets[0].principal_id

  secret_permissions = [
    "Get",
    "List"
  ]
}

resource "azurerm_federated_identity_credential" "external_secrets" {
  count               = var.enable_external_secrets ? 1 : 0
  name                = "external-secrets-fic"
  resource_group_name = var.resource_group_name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = var.aks_oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.external_secrets[0].id
  subject             = "system:serviceaccount:${var.external_secrets_namespace}:${var.external_secrets_service_account}"
}

resource "helm_release" "external_secrets" {
  count            = var.enable_external_secrets ? 1 : 0
  name             = "external-secrets"
  repository       = var.external_secrets_chart_repo
  chart            = var.external_secrets_chart_name
  version          = var.external_secrets_chart_version
  namespace        = var.external_secrets_namespace
  create_namespace = true

  values = [<<-YAML
    installCRDs: true
    serviceAccount:
      create: true
      name: ${var.external_secrets_service_account}
      annotations:
        azure.workload.identity/client-id: ${azurerm_user_assigned_identity.external_secrets[0].client_id}
      labels:
        azure.workload.identity/use: "true"
    podLabels:
      azure.workload.identity/use: "true"
  YAML
  ]

  depends_on = [
    azurerm_federated_identity_credential.external_secrets,
    azurerm_key_vault_access_policy.external_secrets
  ]
}
