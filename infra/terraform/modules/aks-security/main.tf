# =============================================================================
# AKS Security Hardening Module
# =============================================================================
# This module applies security controls to an AKS cluster:
# - Log Analytics workspace + Container Insights
# - Azure Policy assignment (Kubernetes pod security baseline)
# =============================================================================

locals {
  law_name = "${var.name_prefix}-law"
}

# -----------------------------------------------------------------------------
# Log Analytics Workspace
# -----------------------------------------------------------------------------
resource "azurerm_log_analytics_workspace" "aks" {
  name                = local.law_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Log Analytics Solution: Container Insights
# -----------------------------------------------------------------------------
resource "azurerm_log_analytics_solution" "container_insights" {
  solution_name         = "ContainerInsights"
  location              = var.location
  resource_group_name   = var.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.aks.id
  workspace_name        = azurerm_log_analytics_workspace.aks.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Azure Policy Assignment: Kubernetes cluster pod security baseline
# -----------------------------------------------------------------------------
# Built-in initiative: "Kubernetes cluster pod security baseline standards for Linux-based workloads"
# Definition ID: /providers/Microsoft.Authorization/policySetDefinitions/a8640138-9b0a-4a28-b8cb-1666c838647d

resource "azurerm_resource_group_policy_assignment" "aks_baseline_policy" {
  count = var.enable_azure_policy ? 1 : 0

  name                 = "${var.name_prefix}-aks-baseline"
  display_name         = "Kubernetes pod security baseline - ${var.name_prefix}"
  resource_group_id    = var.resource_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/a8640138-9b0a-4a28-b8cb-1666c838647d"

  # Effect: Audit or Deny (Audit for visibility, Deny for enforcement)
  parameters = jsonencode({
    effect = {
      value = var.azure_policy_effect
    }
    excludedNamespaces = {
      value = var.azure_policy_excluded_namespaces
    }
  })

  metadata = jsonencode({
    description = "Enforces pod security baseline on AKS cluster"
  })
}

# -----------------------------------------------------------------------------
# Azure Policy Assignment: Kubernetes cluster pod security restricted
# -----------------------------------------------------------------------------
# Built-in initiative: "Kubernetes cluster pod security restricted standards for Linux-based workloads"
# Definition ID: /providers/Microsoft.Authorization/policySetDefinitions/42b8ef37-b724-4e24-bbc8-7a7708edfe00

resource "azurerm_resource_group_policy_assignment" "aks_restricted_policy" {
  count = var.enable_azure_policy && var.azure_policy_level == "restricted" ? 1 : 0

  name                 = "${var.name_prefix}-aks-restricted"
  display_name         = "Kubernetes pod security restricted - ${var.name_prefix}"
  resource_group_id    = var.resource_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/42b8ef37-b724-4e24-bbc8-7a7708edfe00"

  parameters = jsonencode({
    effect = {
      value = var.azure_policy_effect
    }
    excludedNamespaces = {
      value = var.azure_policy_excluded_namespaces
    }
  })

  metadata = jsonencode({
    description = "Enforces pod security restricted standards on AKS cluster"
  })
}

# -----------------------------------------------------------------------------
# Diagnostic Settings for AKS
# -----------------------------------------------------------------------------
resource "azurerm_monitor_diagnostic_setting" "aks" {
  name                       = "${var.name_prefix}-aks-diag"
  target_resource_id         = var.aks_cluster_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.aks.id

  # Control plane logs
  enabled_log {
    category = "kube-apiserver"
  }

  enabled_log {
    category = "kube-audit"
  }

  enabled_log {
    category = "kube-audit-admin"
  }

  enabled_log {
    category = "kube-controller-manager"
  }

  enabled_log {
    category = "kube-scheduler"
  }

  enabled_log {
    category = "cluster-autoscaler"
  }

  enabled_log {
    category = "guard"
  }

  enabled_log {
    category = "cloud-controller-manager"
  }

  # Metrics
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
