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
