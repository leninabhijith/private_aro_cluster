resource "azurerm_virtual_network_peering" "aro2jbox" {
  name                      = "aro2jbox"
  resource_group_name       = azurerm_resource_group.aro.name
 virtual_network_name      = module.arovnet.vnet_name
  remote_virtual_network_id = module.jbvnet.vnet_id
}

resource "azurerm_virtual_network_peering" "jbox2aro" {
  name                      = "jbox2aro"
  resource_group_name       = azurerm_resource_group.support_rg.name
  virtual_network_name      = module.jbvnet.vnet_name
  remote_virtual_network_id = module.arovnet.vnet_id
}