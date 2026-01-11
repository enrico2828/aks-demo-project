output "resource_group_name" {
  description = "Resource group created for the demo."
  value       = data.azurerm_resource_group.rg.name
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
    "az aks get-credentials --resource-group ${data.azurerm_resource_group.rg.name} --name ${module.aks.name} --overwrite-existing",
    "kubectl get nodes",
  ])
}

# =============================================================================
# Security Outputs
# =============================================================================

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace resource ID."
  value       = module.aks_security.log_analytics_workspace_id
}

output "log_analytics_workspace_name" {
  description = "Log Analytics workspace name."
  value       = module.aks_security.log_analytics_workspace_name
}

output "aks_node_resource_group" {
  description = "The auto-generated resource group containing AKS node resources."
  value       = module.aks.node_resource_group
}

output "aks_kubelet_identity" {
  description = "The kubelet managed identity (client_id, object_id, resource_id)."
  value       = module.aks.kubelet_identity
}

output "security_features_enabled" {
  description = "Summary of security features enabled on the cluster."
  value = {
    private_cluster            = true
    local_accounts_disabled    = true
    azure_policy               = var.enable_azure_policy
    azure_policy_level         = var.azure_policy_level
    azure_policy_effect        = var.azure_policy_effect
    container_insights         = true
    network_policy             = var.aks_network_policy
    image_cleaner              = var.image_cleaner_enabled
    key_vault_secrets_provider = var.key_vault_secrets_provider_enabled
    run_command_disabled       = !var.aks_run_command_enabled
  }
}
