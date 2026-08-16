output "monitor_workspace_id" {
  description = "Resource ID of the Azure Monitor workspace."
  value       = azurerm_monitor_workspace.this.id
}

output "data_collection_endpoint_id" {
  description = "Resource ID of the Prometheus data collection endpoint."
  value       = azurerm_monitor_data_collection_endpoint.this.id
}

output "query_endpoint" {
  description = "PromQL query endpoint used by Grafana."
  value       = azurerm_monitor_workspace.this.query_endpoint
}
