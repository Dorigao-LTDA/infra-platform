resource_group_name             = "rg-ct-framework"
aks_name                        = "aks-ct-framework"
acr_name            = "acrctframework"
location            = "brazilsouth"
node_count          = 2
node_vm_size        = "Standard_D2s_v6"
enable_argocd_public_access = false

# Corporate defaults (set true after import if resources already exist)
manage_networking_rg     = false
manage_ingress_public_ip = false
