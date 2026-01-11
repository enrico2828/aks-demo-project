output "log_analytics_workspace_id" {
  description = "Log Analytics workspace resource ID."
  value       = azurerm_log_analytics_workspace.aks.id
}

output "log_analytics_workspace_name" {
  description = "Log Analytics workspace name."
  value       = azurerm_log_analytics_workspace.aks.name
}

output "log_analytics_workspace_primary_key" {
  description = "Log Analytics workspace primary key."
  value       = azurerm_log_analytics_workspace.aks.primary_shared_key
  sensitive   = true
}

output "azure_policy_enabled" {
  description = "Whether Azure Policy is enabled."
  value       = var.enable_azure_policy
}

output "azure_policy_level" {
  description = "Azure Policy level (baseline or restricted)."
  value       = var.azure_policy_level
}
