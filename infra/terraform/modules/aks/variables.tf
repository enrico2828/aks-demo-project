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

variable "local_account_disabled" {
  type        = bool
  description = "If true, disables local accounts (the --admin credential). Only Entra ID authentication will be allowed."
  default     = true
}

# -----------------------------------------------------------------------------
# Security Hardening Variables
# -----------------------------------------------------------------------------

variable "azure_policy_addon_enabled" {
  type        = bool
  description = "Enable Azure Policy add-on for Kubernetes (Gatekeeper-based policy enforcement)."
  default     = true
}

variable "oms_agent_log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics workspace ID for Container Insights (OMS agent). Set to null to disable."
  default     = null
}

variable "key_vault_secrets_provider_enabled" {
  type        = bool
  description = "Enable Key Vault Secrets Provider (CSI driver) for secrets from Azure Key Vault."
  default     = false
}

variable "key_vault_secret_rotation_enabled" {
  type        = bool
  description = "Enable automatic secret rotation for Key Vault Secrets Provider."
  default     = true
}

variable "key_vault_secret_rotation_interval" {
  type        = string
  description = "Rotation poll interval for Key Vault secrets (e.g., '2m')."
  default     = "2m"
}

variable "image_cleaner_enabled" {
  type        = bool
  description = "Enable Image Cleaner (Eraser) to remove stale/vulnerable images from nodes."
  default     = true
}

variable "image_cleaner_interval_hours" {
  type        = number
  description = "Interval in hours for Image Cleaner to scan and remove images."
  default     = 48
}

variable "run_command_enabled" {
  type        = bool
  description = "Enable 'az aks command invoke' (run command). Disable for tighter security."
  default     = false
}

variable "network_policy" {
  type        = string
  description = "Network policy to use: 'azure' (Azure NPM), 'calico', or null (disabled)."
  default     = "azure"

  validation {
    condition     = var.network_policy == null || contains(["azure", "calico"], var.network_policy)
    error_message = "network_policy must be 'azure', 'calico', or null."
  }
}

variable "blob_driver_enabled" {
  type        = bool
  description = "Enable Azure Blob CSI driver for blob storage volumes."
  default     = false
}
