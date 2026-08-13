output "storage_account_name" {
  value = azurerm_storage_account.test_history.name
}

output "container_name" {
  value = azurerm_storage_container.gate_results.name
}
