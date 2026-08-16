output "resource_group_name" {
  description = "Monitoring resource group."
  value       = azurerm_resource_group.monitoring.name
}

output "log_analytics_workspace_id" {
  description = "Resource ID of the central Log Analytics workspace."
  value       = module.log_analytics.id
}

output "application_insights_connection_string" {
  description = "Connection string applications use to send telemetry."
  value       = module.application_insights.connection_string
  sensitive   = true
}

output "action_group_ids" {
  description = "Map of action group name to resource ID."
  value       = module.action_groups.ids
}
