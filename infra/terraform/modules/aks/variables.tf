variable "name_prefix" {
  type        = string
  description = "Naming prefix used for resources."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to resources."
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID for AKS nodes."
}

variable "api_server_authorized_ip_ranges" {
  type        = list(string)
  description = "Authorized IP ranges for AKS API server. For private clusters, this can be used with private CIDRs (e.g., jumpbox subnet)."
  default     = []
}

variable "admin_group_object_ids" {
  type        = list(string)
  description = "Entra ID group object IDs for AKS admins."
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version (pin for repeatability)."
  default     = null
}

variable "private_cluster_enabled" {
  type        = bool
  description = "Whether to create a private AKS cluster."
  default     = true
}

variable "pod_cidr" {
  type        = string
  description = "Pod CIDR for Azure CNI Overlay."
}

variable "service_cidr" {
  type        = string
  description = "Service CIDR."
}

variable "dns_service_ip" {
  type        = string
  description = "DNS service IP (must be within service_cidr)."
}

variable "default_node_pool" {
  description = "Default/system node pool configuration."
  type = object({
    name                 = string
    vm_size              = string
    node_count           = number
    enable_auto_scaling  = bool
    min_count            = number
    max_count            = number
    os_disk_size_gb      = number
    vnet_subnet_id       = string
    max_pods             = number
    zones                = list(string)
    only_critical_addons = bool
  })
}

variable "enable_rbac_cluster_admin_role_assignment" {
  type        = bool
  description = "If true, assigns 'Azure Kubernetes Service RBAC Cluster Admin' at the AKS resource scope to the admin_group_object_ids."
  default     = true
}

variable "local_account_disabled" {
  type        = bool
  description = "If true, disables local accounts (the --admin credential). Only Entra ID authentication will be allowed."
  default     = true
}
