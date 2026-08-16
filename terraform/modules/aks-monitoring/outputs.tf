output "container_insights_dcr_id" {
  description = "Container Insights data collection rule ID."
  value       = azurerm_monitor_data_collection_rule.container_insights.id
}

output "prometheus_dcr_id" {
  description = "Managed Prometheus data collection rule ID."
  value       = azurerm_monitor_data_collection_rule.prometheus.id
}
