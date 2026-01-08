output "resource_group_name" {
  description = "Resource group created for the demo."
  value       = azurerm_resource_group.rg.name
}

output "vnet_name" {
  description = "VNet name."
  value       = module.network.vnet_name
}

output "subnet_ids" {
  description = "Subnet IDs by purpose."
  value       = module.network.subnet_ids
}

output "jumpbox_private_ip" {
  description = "Jumpbox private IP address."
  value       = module.jumpbox.private_ip
}

output "jumpbox_public_ip" {
  description = "Jumpbox public IP address (if enabled)."
  value       = module.jumpbox.public_ip
}
