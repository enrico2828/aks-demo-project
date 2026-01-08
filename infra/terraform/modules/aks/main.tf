locals {
  aks_name = "${var.name_prefix}-aks"

  # Minimal validation to avoid obvious misconfig.
  service_cidr_prefix = cidrhost(var.service_cidr, 0) != null
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = local.aks_name
  location            = var.location
  resource_group_name = var.resource_group_name

  dns_prefix = replace(local.aks_name, "-", "")

  kubernetes_version = var.kubernetes_version

  private_cluster_enabled = var.private_cluster_enabled

  # Disable local accounts (--admin credential) for enterprise posture.
  # When true, only Entra ID authentication is allowed.
  local_account_disabled = var.local_account_disabled

  dynamic "api_server_access_profile" {
    # Azure API limitation: Authorized IP Ranges can't be used with private clusters.
    for_each = var.private_cluster_enabled ? [] : [1]

    content {
      authorized_ip_ranges = var.api_server_authorized_ip_ranges
    }
  }

  default_node_pool {
    name                         = var.default_node_pool.name
    vm_size                      = var.default_node_pool.vm_size
    node_count                   = var.default_node_pool.node_count
    enable_auto_scaling          = var.default_node_pool.enable_auto_scaling
    min_count                    = var.default_node_pool.enable_auto_scaling ? var.default_node_pool.min_count : null
    max_count                    = var.default_node_pool.enable_auto_scaling ? var.default_node_pool.max_count : null
    os_disk_size_gb              = var.default_node_pool.os_disk_size_gb
    vnet_subnet_id               = var.default_node_pool.vnet_subnet_id
    max_pods                     = var.default_node_pool.max_pods
    zones                        = length(var.default_node_pool.zones) > 0 ? var.default_node_pool.zones : null
    only_critical_addons_enabled = var.default_node_pool.only_critical_addons
    type                         = "VirtualMachineScaleSets"
  }

  identity {
    type = "SystemAssigned"
  }

  # Entra ID integration + Azure RBAC for Kubernetes authorization
  azure_active_directory_role_based_access_control {
    managed                = true
    azure_rbac_enabled     = true
    admin_group_object_ids = var.admin_group_object_ids
  }

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  # -----------------------------------------------------------------------------
  # Security hardening
  # -----------------------------------------------------------------------------

  # Azure Policy add-on for Gatekeeper-based policy enforcement
  azure_policy_enabled = var.azure_policy_addon_enabled

  # Microsoft Defender for Containers (AKS-level profile)
  dynamic "microsoft_defender" {
    for_each = var.defender_log_analytics_workspace_id != null ? [1] : []
    content {
      log_analytics_workspace_id = var.defender_log_analytics_workspace_id
    }
  }

  # Container Insights (OMS agent)
  dynamic "oms_agent" {
    for_each = var.oms_agent_log_analytics_workspace_id != null ? [1] : []
    content {
      log_analytics_workspace_id = var.oms_agent_log_analytics_workspace_id
    }
  }

  # Key Vault Secrets Provider (CSI driver)
  dynamic "key_vault_secrets_provider" {
    for_each = var.key_vault_secrets_provider_enabled ? [1] : []
    content {
      secret_rotation_enabled  = var.key_vault_secret_rotation_enabled
      secret_rotation_interval = var.key_vault_secret_rotation_interval
    }
  }

  # Image Cleaner (Eraser) - removes stale/vulnerable images from nodes
  image_cleaner_enabled        = var.image_cleaner_enabled
  image_cleaner_interval_hours = var.image_cleaner_interval_hours

  # HTTP application routing (disabled for security)
  http_application_routing_enabled = false

  # Run command disabled (prevents az aks command invoke)
  run_command_enabled = var.run_command_enabled

  network_profile {
    network_plugin = "azure"

    # Azure CNI Overlay
    network_plugin_mode = "overlay"
    pod_cidr            = var.pod_cidr

    # Azure Network Policy (Calico alternative: network_policy = "calico")
    network_policy = var.network_policy

    service_cidr      = var.service_cidr
    dns_service_ip    = var.dns_service_ip
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"
  }

  # Storage profile for host encryption
  storage_profile {
    blob_driver_enabled         = var.blob_driver_enabled
    disk_driver_enabled         = true
    file_driver_enabled         = true
    snapshot_controller_enabled = true
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition     = length(var.admin_group_object_ids) > 0
      error_message = "admin_group_object_ids must contain at least one Entra ID group object ID."
    }
  }
}

# Assign Azure RBAC Cluster Admin role on the AKS resource scope.
resource "azurerm_role_assignment" "aks_cluster_admin" {
  for_each = var.enable_rbac_cluster_admin_role_assignment ? toset(var.admin_group_object_ids) : toset([])

  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = each.value
}
