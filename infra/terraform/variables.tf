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

variable "jumpbox_vm_size" {
  description = "Azure VM size for the jumpbox (must be available in the chosen region)."
  type        = string
  default     = "Standard_B1s"
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
