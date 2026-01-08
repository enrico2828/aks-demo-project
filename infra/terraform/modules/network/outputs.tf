output "vnet_id" {
  description = "VNet resource ID."
  value       = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  description = "VNet name."
  value       = azurerm_virtual_network.vnet.name
}

output "subnet_ids" {
  description = "Subnet IDs by key."
  value       = { for k, s in azurerm_subnet.subnet : k => s.id }
}

output "subnet_names" {
  description = "Subnet names by key."
  value       = { for k, s in azurerm_subnet.subnet : k => s.name }
}
