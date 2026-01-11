output "vm_id" {
  description = "Jumpbox VM resource ID."
  value       = azurerm_linux_virtual_machine.vm.id
}

output "private_ip" {
  description = "Jumpbox private IP address."
  value       = azurerm_network_interface.nic.private_ip_address
}

output "public_ip" {
  description = "Jumpbox public IP address (if enabled)."
  value       = try(azurerm_public_ip.pip[0].ip_address, null)
}
