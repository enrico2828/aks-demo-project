variable "name_prefix" {
  type        = string
  description = "Naming prefix for resources."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name."
}

variable "resource_group_id" {
  type        = string
  description = "Resource group ID (for policy assignments)."
}

variable "aks_cluster_id" {
  type        = string
  description = "AKS cluster resource ID."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to resources."
  default     = {}
}

# -----------------------------------------------------------------------------
# Log Analytics
# -----------------------------------------------------------------------------
variable "log_retention_days" {
  type        = number
  description = "Log Analytics workspace retention in days."
  default     = 30
}

# -----------------------------------------------------------------------------
# Microsoft Defender
# -----------------------------------------------------------------------------
variable "enable_defender_for_containers" {
  type        = bool
  description = "Enable Microsoft Defender for Containers at subscription level."
  default     = true
}

# -----------------------------------------------------------------------------
# Azure Policy
# -----------------------------------------------------------------------------
variable "enable_azure_policy" {
  type        = bool
  description = "Enable Azure Policy for Kubernetes."
  default     = true
}

variable "azure_policy_level" {
  type        = string
  description = "Policy level: 'baseline' (PSS baseline) or 'restricted' (PSS restricted)."
  default     = "baseline"

  validation {
    condition     = contains(["baseline", "restricted"], var.azure_policy_level)
    error_message = "azure_policy_level must be 'baseline' or 'restricted'."
  }
}

variable "azure_policy_effect" {
  type        = string
  description = "Policy effect: 'audit' for visibility or 'deny' for enforcement."
  default     = "audit"

  validation {
    condition     = contains(["audit", "Audit", "deny", "Deny"], var.azure_policy_effect)
    error_message = "azure_policy_effect must be 'audit' or 'deny'."
  }
}

variable "azure_policy_excluded_namespaces" {
  type        = list(string)
  description = "Namespaces excluded from Azure Policy enforcement."
  default     = ["kube-system", "gatekeeper-system", "azure-arc"]
}
