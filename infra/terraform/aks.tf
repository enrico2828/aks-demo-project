module "aks" {
  source = "./modules/aks"

  name_prefix         = local.name_prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
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

  # Grant Azure RBAC Cluster Admin at the AKS resource scope to the admin group.
  enable_rbac_cluster_admin_role_assignment = true
}
