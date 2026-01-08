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

output "aks_name" {
  description = "AKS cluster name."
  value       = module.aks.name
}

output "aks_private_fqdn" {
  description = "AKS API server private FQDN."
  value       = module.aks.private_fqdn
}

output "aks_oidc_issuer_url" {
  description = "AKS OIDC issuer URL."
  value       = module.aks.oidc_issuer_url
}

output "aks_access_commands" {
  description = "Ready-to-copy commands to authenticate and fetch kubeconfig (run from the jumpbox)."
  value = join("\n", [
    "# --- AKS access (run on the jumpbox) ---",
    "az login",
    "az aks get-credentials --resource-group ${azurerm_resource_group.rg.name} --name ${module.aks.name} --overwrite-existing",
    "kubectl get nodes",
  ])
}
