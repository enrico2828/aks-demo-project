# =============================================================================
# AKS Security Hardening
# =============================================================================
# This file configures security controls for the AKS cluster:
# - Log Analytics workspace + Container Insights
# - Microsoft Defender for Containers
# - Azure Policy (pod security baseline/restricted)
# - Diagnostic settings
# =============================================================================

module "aks_security" {
  source = "./modules/aks-security"

  name_prefix         = local.name_prefix
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  resource_group_id   = data.azurerm_resource_group.rg.id
  tags                = local.common_tags

  aks_cluster_id = module.aks.id

  # Log Analytics
  log_retention_days = var.log_analytics_retention_days

  # Microsoft Defender for Containers (subscription-level)
  enable_defender_for_containers = var.enable_defender_for_containers

  # Azure Policy
  enable_azure_policy              = var.enable_azure_policy
  azure_policy_level               = var.azure_policy_level
  azure_policy_effect              = var.azure_policy_effect
  azure_policy_excluded_namespaces = var.azure_policy_excluded_namespaces
}
