module "aks" {
  source = "./modules/aks"

  name_prefix         = local.name_prefix
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  tags                = local.common_tags

  subnet_id = module.network.subnet_ids["aks"]

  # Restrict API server access to the jumpbox subnet CIDR(s).
  api_server_authorized_ip_ranges = var.snet_jumpbox_address_prefixes

  # Entra ID group object IDs that should have admin rights.
  admin_group_object_ids = var.aks_admin_group_object_ids

  kubernetes_version = var.aks_kubernetes_version

  # Azure CNI Overlay
  pod_cidr       = var.aks_pod_cidr
  service_cidr   = var.aks_service_cidr
  dns_service_ip = var.aks_dns_service_ip

  private_cluster_enabled = true

  default_node_pool = {
    name                 = "system"
    vm_size              = var.aks_system_node_vm_size
    node_count           = var.aks_system_node_count
    enable_auto_scaling  = false
    min_count            = null
    max_count            = null
    os_disk_size_gb      = var.aks_system_node_os_disk_size_gb
    vnet_subnet_id       = module.network.subnet_ids["aks"]
    max_pods             = var.aks_system_node_max_pods
    zones                = var.aks_system_node_zones
    only_critical_addons = true
  }

  # -------------------------------------------------------------------------
  # Security hardening
  # -------------------------------------------------------------------------

  # Azure Policy add-on (Gatekeeper)
  azure_policy_addon_enabled = var.enable_azure_policy

  # Log Analytics integration (Container Insights)
  oms_agent_log_analytics_workspace_id = module.aks_security.log_analytics_workspace_id

  # Key Vault Secrets Provider (CSI driver)
  key_vault_secrets_provider_enabled = var.key_vault_secrets_provider_enabled
  key_vault_secret_rotation_enabled  = var.key_vault_secret_rotation_enabled
  key_vault_secret_rotation_interval = var.key_vault_secret_rotation_interval

  # Image Cleaner (Eraser)
  image_cleaner_enabled        = var.image_cleaner_enabled
  image_cleaner_interval_hours = var.image_cleaner_interval_hours

  # Network policy (Azure NPM or Calico)
  network_policy = var.aks_network_policy
  # Run command (az aks command invoke)
  run_command_enabled = var.aks_run_command_enabled

  # Blob CSI driver
  blob_driver_enabled = var.aks_blob_driver_enabled
}
