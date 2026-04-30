output "key_vault_uri" {
  value       = try(azurerm_key_vault.gitops[0].vault_uri, "")
  description = "Key Vault URI for GitOps secrets"
}

output "key_vault_name" {
  value       = try(azurerm_key_vault.gitops[0].name, "")
  description = "Key Vault name"
}

output "external_secrets_identity_client_id" {
  value       = try(azurerm_user_assigned_identity.external_secrets[0].client_id, "")
  description = "Client ID for External Secrets workload identity"
}
