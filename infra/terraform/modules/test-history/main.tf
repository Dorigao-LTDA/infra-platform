resource "azurerm_storage_account" "test_history" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "gate_results" {
  name                  = "gate-results"
  storage_account_name  = azurerm_storage_account.test_history.name
  container_access_type = "private"
}

# Grant the CI/CD runner service principal (same OIDC principal as bootstrap)
# write access to store/read test history blobs.
resource "azurerm_role_assignment" "runner_blob_contributor" {
  scope                = azurerm_storage_account.test_history.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.runner_principal_object_id
}
