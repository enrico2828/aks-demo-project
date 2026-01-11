output "id" {
  description = "AKS resource ID."
  value       = azurerm_kubernetes_cluster.aks.id
}

output "name" {
  description = "AKS name."
  value       = azurerm_kubernetes_cluster.aks.name
}

output "private_fqdn" {
  description = "Private FQDN for the API server (private cluster)."
  value       = azurerm_kubernetes_cluster.aks.private_fqdn
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL (used for Workload Identity)."
  value       = azurerm_kubernetes_cluster.aks.oidc_issuer_url
}

output "node_resource_group" {
  description = "The auto-generated resource group containing AKS node resources."
  value       = azurerm_kubernetes_cluster.aks.node_resource_group
}

output "kubelet_identity" {
  description = "The kubelet managed identity (used for ACR pull, etc.)."
  value = {
    client_id   = azurerm_kubernetes_cluster.aks.kubelet_identity[0].client_id
    object_id   = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
    resource_id = azurerm_kubernetes_cluster.aks.kubelet_identity[0].user_assigned_identity_id
  }
}

output "key_vault_secrets_provider_identity" {
  description = "The Key Vault Secrets Provider managed identity (if enabled)."
  value = length(azurerm_kubernetes_cluster.aks.key_vault_secrets_provider) > 0 ? {
    client_id = azurerm_kubernetes_cluster.aks.key_vault_secrets_provider[0].secret_identity[0].client_id
    object_id = azurerm_kubernetes_cluster.aks.key_vault_secrets_provider[0].secret_identity[0].object_id
  } : null
}
