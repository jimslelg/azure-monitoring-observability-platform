output "id" {
  description = "Resource ID of the workspace."
  value       = azurerm_log_analytics_workspace.this.id
}

output "name" {
  description = "Name of the workspace."
  value       = azurerm_log_analytics_workspace.this.name
}

output "workspace_id" {
  description = "Workspace (customer) GUID used by agents and the Data Collector API."
  value       = azurerm_log_analytics_workspace.this.workspace_id
}

output "primary_shared_key" {
  description = "Primary shared key. Only needed by legacy agents; prefer AMA with managed identity."
  value       = azurerm_log_analytics_workspace.this.primary_shared_key
  sensitive   = true
}
