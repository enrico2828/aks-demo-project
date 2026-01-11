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

variable "vnet_address_space" {
  type        = list(string)
  description = "VNet address space."
}

variable "subnets" {
  description = "Map of subnet definitions."
  type = map(object({
    address_prefixes = list(string)
  }))
}
