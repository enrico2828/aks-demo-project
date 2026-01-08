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
  description = "Subnet ID where the jumpbox NIC will be placed."
}

variable "assign_public_ip" {
  type        = bool
  description = "Whether to assign a public IP to the VM."
  default     = false
}

variable "allowed_ssh_cidrs" {
  type        = list(string)
  description = "List of CIDRs allowed to access SSH on the jumpbox. Effective only if assign_public_ip=true."
  default     = []
}

variable "admin_username" {
  type        = string
  description = "Admin username for the VM."
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key contents (e.g., ~/.ssh/id_ed25519.pub). Required when use_ssh_key_auth=true."
  default     = null
}

variable "vm_size" {
  type        = string
  description = "Azure VM size for the jumpbox."
}

variable "image_publisher" {
  type        = string
  description = "OS image publisher."
}

variable "image_offer" {
  type        = string
  description = "OS image offer."
}

variable "image_sku" {
  type        = string
  description = "OS image SKU."
}

variable "image_version" {
  type        = string
  description = "OS image version."
}

variable "cloud_init" {
  type        = string
  description = "Optional cloud-init user data to bootstrap the VM. If null/empty, no custom data is applied."
  default     = null
}
