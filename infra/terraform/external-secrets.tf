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
