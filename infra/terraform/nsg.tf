data "azurerm_network_security_group" "aks_node" {
  count               = var.manage_nodeport_nsg_rule ? 1 : 0
  name                = var.aks_node_nsg_name
  resource_group_name = azurerm_kubernetes_cluster.main.node_resource_group
}

resource "azurerm_network_security_rule" "allow_ingress_nodeports" {
  count                       = var.manage_nodeport_nsg_rule ? 1 : 0
  name                        = "allow-ingress-nodeports"
  priority                    = 300
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["32212", "31200"]
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_kubernetes_cluster.main.node_resource_group
  network_security_group_name = data.azurerm_network_security_group.aks_node[0].name
}
