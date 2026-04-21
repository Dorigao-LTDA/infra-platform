resource_group_name             = "rg-ct-framework"
aks_name                        = "aks-ct-framework"
acr_name            = "acrctframework"
location            = "brazilsouth"
node_count          = 2
node_vm_size        = "Standard_D2s_v6"

# Corporate defaults (set true after import if resources already exist)
manage_networking_rg     = false
manage_ingress_public_ip = false

# Optional: manage NodePort NSG rule via Terraform
manage_nodeport_nsg_rule = false
aks_node_nsg_name        = ""