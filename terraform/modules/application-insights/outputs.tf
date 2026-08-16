output "id" {
  description = "Resource ID of the Application Insights component."
  value       = azurerm_application_insights.this.id
}

output "app_id" {
  description = "Application ID used by the API."
  value       = azurerm_application_insights.this.app_id
}

output "connection_string" {
  description = "Connection string for SDK/agent configuration. Prefer this over the instrumentation key."
  value       = azurerm_application_insights.this.connection_string
  sensitive   = true
}
