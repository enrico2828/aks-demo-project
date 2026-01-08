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
