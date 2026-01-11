variable "prefix" {
  description = "Resource naming prefix (lowercase, numbers, hyphens)."
  type        = string
  default     = "aks-demo01"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "westeurope"
}

variable "environment" {
  description = "Environment name (dev, test, prod)."
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Tags applied to resources."
  type        = map(string)
  default = {
    project     = "aks-demo01-project"
    managed_by  = "terraform"
    environment = "dev"
  }
}

variable "jumpbox_ssh_public_key" {
  description = "SSH public key for the jumpbox VM (e.g., contents of ~/.ssh/id_ed25519.pub)."
  type        = string
  default     = ""
}

variable "jumpbox_assign_public_ip" {
  description = "Whether to assign a public IP to the jumpbox (enables SSH from allowed CIDRs)."
  type        = bool
  default     = false
}

variable "jumpbox_allowed_ssh_cidrs" {
  description = "CIDRs allowed to reach SSH on the jumpbox when a public IP is enabled (e.g., [\"203.0.113.10/32\"])."
  type        = list(string)
  default     = []
}

variable "jumpbox_bootstrap_tools" {
  description = "Whether the jumpbox should bootstrap AKS admin tooling (az, kubectl, kubelogin) via cloud-init. Enabling this will recreate the VM."
  type        = bool
  default     = false
}

variable "jumpbox_kubectl_version" {
  description = "Kubectl version to install on the jumpbox. If null, the version will follow aks_kubernetes_version (when set) or use the latest kubectl. Use the format 'v1.29.15'."
  type        = string
  default     = null
}

variable "jumpbox_kubelogin_version" {
  description = "Kubelogin version to install on the jumpbox. If null, the latest kubelogin will be installed. Use the format '0.2.14'."
  type        = string
  default     = null
}

variable "jumpbox_vm_size" {
  description = "Azure VM size for the jumpbox (must be available in the chosen region)."
  type        = string
  default     = "Standard_D2s_v6"
}

variable "jumpbox_image_publisher" {
  description = "Jumpbox OS image publisher."
  type        = string
  default     = "Canonical"
}

variable "jumpbox_image_offer" {
  description = "Jumpbox OS image offer."
  type        = string
  default     = "0001-com-ubuntu-server-jammy"
}

variable "jumpbox_image_sku" {
  description = "Jumpbox OS image SKU."
  type        = string
  default     = "22_04-lts-gen2"
}

variable "jumpbox_image_version" {
  description = "Jumpbox OS image version."
  type        = string
  default     = "latest"
}

variable "vnet_address_space" {
  description = "VNet address space."
  type        = list(string)
  default     = ["10.10.0.0/16"]
}

variable "snet_aks_address_prefixes" {
  description = "AKS subnet address prefixes."
  type        = list(string)
  default     = ["10.10.0.0/22"]
}

variable "snet_private_endpoints_address_prefixes" {
  description = "Private endpoints subnet address prefixes."
  type        = list(string)
  default     = ["10.10.4.0/24"]
}

variable "snet_jumpbox_address_prefixes" {
  description = "Jumpbox subnet address prefixes."
  type        = list(string)
  default     = ["10.10.5.0/27"]
}

variable "aks_admin_group_object_ids" {
  description = "Entra ID group object IDs that should have AKS admin rights (used for Azure RBAC for Kubernetes)."
  type        = list(string)
  default     = []
}

variable "aks_kubernetes_version" {
  description = "AKS Kubernetes version (pin for repeatability). If null, Azure selects a default."
  type        = string
  default     = null
}

# Azure CNI Overlay
variable "aks_pod_cidr" {
  description = "Pod CIDR for Azure CNI Overlay. Must not overlap with VNet address space."
  type        = string
  default     = "192.168.0.0/16"
}

variable "aks_service_cidr" {
  description = "Service CIDR. Must not overlap with VNet address space."
  type        = string
  default     = "10.20.0.0/16"
}

variable "aks_dns_service_ip" {
  description = "DNS service IP (must be within aks_service_cidr)."
  type        = string
  default     = "10.20.0.10"
}

variable "aks_system_node_vm_size" {
  description = "VM size for the system node pool."
  type        = string
  default     = "Standard_D2s_v6"
}

variable "aks_system_node_count" {
  description = "Node count for the system node pool."
  type        = number
  default     = 2
}

variable "aks_system_node_os_disk_size_gb" {
  description = "OS disk size for system nodes."
  type        = number
  default     = 64
}

variable "aks_system_node_max_pods" {
  description = "Max pods per node."
  type        = number
  default     = 30
}

variable "aks_system_node_zones" {
  description = "Availability zones for system pool (empty for no zoning)."
  type        = list(string)
  # NOTE: Zone support can vary by subscription/SKU even within the same region.
  # Default to no-zoning for portability; set explicitly (e.g., ["1"]) when supported.
  default = []
}

# =============================================================================
# Security Hardening Variables
# =============================================================================

# -----------------------------------------------------------------------------
# Log Analytics & Monitoring
# -----------------------------------------------------------------------------
variable "log_analytics_retention_days" {
  description = "Log Analytics workspace retention in days."
  type        = number
  default     = 30 # Minimum allowed for Log Analytics
}

# -----------------------------------------------------------------------------
# Azure Policy
# -----------------------------------------------------------------------------
variable "enable_azure_policy" {
  description = "Enable Azure Policy for Kubernetes (both add-on and policy assignments)."
  type        = bool
  default     = true
}

variable "azure_policy_level" {
  description = "Policy level: 'baseline' (PSS baseline) or 'restricted' (PSS restricted)."
  type        = string
  default     = "baseline"
}

variable "azure_policy_effect" {
  description = "Policy effect: 'audit' for visibility or 'deny' for enforcement."
  type        = string
  default     = "deny"
}

variable "azure_policy_excluded_namespaces" {
  description = "Namespaces excluded from Azure Policy enforcement."
  type        = list(string)
  default     = ["kube-system", "gatekeeper-system", "azure-arc"]
}

# -----------------------------------------------------------------------------
# Key Vault Secrets Provider
# -----------------------------------------------------------------------------
variable "key_vault_secrets_provider_enabled" {
  description = "Enable Key Vault Secrets Provider (CSI driver) for secrets from Azure Key Vault."
  type        = bool
  default     = false
}

variable "key_vault_secret_rotation_enabled" {
  description = "Enable automatic secret rotation for Key Vault Secrets Provider."
  type        = bool
  default     = true
}

variable "key_vault_secret_rotation_interval" {
  description = "Rotation poll interval for Key Vault secrets (e.g., '2m')."
  type        = string
  default     = "2m"
}

# -----------------------------------------------------------------------------
# Image Cleaner
# -----------------------------------------------------------------------------
variable "image_cleaner_enabled" {
  description = "Enable Image Cleaner (Eraser) to remove stale/vulnerable images from nodes."
  type        = bool
  default     = true
}

variable "image_cleaner_interval_hours" {
  description = "Interval in hours for Image Cleaner to scan and remove images."
  type        = number
  default     = 48
}

# -----------------------------------------------------------------------------
# Network Policy
# -----------------------------------------------------------------------------
variable "aks_network_policy" {
  description = "Network policy to use: 'azure' (Azure NPM), 'calico', or null (disabled)."
  type        = string
  default     = "azure"
}

# -----------------------------------------------------------------------------
# Other Security Settings
# -----------------------------------------------------------------------------
variable "aks_run_command_enabled" {
  description = "Enable 'az aks command invoke' (run command). Disable for tighter security."
  type        = bool
  default     = false
}

variable "aks_blob_driver_enabled" {
  description = "Enable Azure Blob CSI driver for blob storage volumes."
  type        = bool
  default     = false
}
