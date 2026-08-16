output "id" {
  description = "Resource ID of the Grafana instance."
  value       = azurerm_dashboard_grafana.this.id
}

output "endpoint" {
  description = "Grafana UI endpoint."
  value       = azurerm_dashboard_grafana.this.endpoint
}
