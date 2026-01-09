module "network" {
  source = "./modules/network"

  name_prefix         = local.name_prefix
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  tags                = local.common_tags

  vnet_address_space = var.vnet_address_space

  # Keep subnets right-sized; we can always expand later.
  subnets = {
    aks = {
      address_prefixes = var.snet_aks_address_prefixes
    }

    private_endpoints = {
      address_prefixes = var.snet_private_endpoints_address_prefixes
    }

    jumpbox = {
      address_prefixes = var.snet_jumpbox_address_prefixes
    }
  }
}
