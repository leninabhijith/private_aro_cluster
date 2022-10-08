
resource "random_string" "support_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "random_string" "admin_suffix" {
  length  = 5
  special = false
  upper   = false
}

resource "random_password" "win_password" {
  length = 16
}

resource "azurerm_resource_group" "support_rg" {
  name     = var.support_rg
  location = var.location
}

#this block created a standard keyvault
resource "azurerm_key_vault" "kv" {
  #name                       = "kv-${local.support_suffix}"
  name                       = "kv-${random_string.support_suffix.result}"
  location                   = azurerm_resource_group.support_rg.location
  resource_group_name        = azurerm_resource_group.support_rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard" #"premium"
  soft_delete_retention_days = 7
  purge_protection_enabled    = false #true
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    key_permissions = [
      "Create",
      "Get",
    ]
    secret_permissions = [
      "Set",
      "Get",
      "Delete",
      "Purge",
      "Recover",
      "List",
    ]
    certificate_permissions = [
      "create",
      "delete",
      "deleteissuers",
      "get",
      "getissuers",
      "import",
      "list",
      "listissuers",
      "managecontacts",
      "manageissuers",
      "purge",
      "setissuers",
      "update",
    ]
  }
}

resource "azurerm_key_vault_secret" "wpassword" {
  name         = "wpassword"
  value        = random_password.win_password.result
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "username" {
  name         = "username"
  #value        = "admin${local.admin_suffix}"
  value        = "admin${random_string.admin_suffix.result}"
  key_vault_id = azurerm_key_vault.kv.id
}


# this block creates a vnet.
module "jbvnet" {
  source              = "Azure/vnet/azurerm"
  depends_on          = [azurerm_resource_group.support_rg]
  resource_group_name = azurerm_resource_group.support_rg.name
  vnet_name           = "vnet-${random_string.support_suffix.result}"
  address_space       = ["192.168.1.0/24"]
  subnet_prefixes     = ["192.168.1.0/27"]
  subnet_names        = ["jbox_sub"]
  tags                = {}
}

# this block creates a jump box vm in the jbox-sub.
module "jbox_vm" {
  source                  = "Azure/compute/azurerm"
  depends_on              = [azurerm_resource_group.support_rg]
  resource_group_name     = azurerm_resource_group.support_rg.name
  is_windows_image        = true
  license_type            = "Windows_Client"
  #vm_hostname             = "vm-${local.support_suffix}" // line can be removed if only one VM module per resource group
  vm_hostname             = "vm-${random_string.support_suffix.result}"
  admin_username          = azurerm_key_vault_secret.username.value
  admin_password          = azurerm_key_vault_secret.wpassword.value
  vm_os_publisher         = "MicrosoftWindowsDesktop"
  vm_os_offer             = "Windows-10"
  vm_os_sku               = "rs5-pro"
  public_ip_dns           = ["vm-${random_string.support_suffix.result}"] // change to a unique name per datacenter region
  vnet_subnet_id          = module.jbvnet.vnet_subnets[0]
  vm_size                 = "Standard_B2s"
  remote_port             = "3389"
  #source_address_prefixes = ["*"]
}