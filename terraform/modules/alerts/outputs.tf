output "metric_alert_ids" {
  description = "Map of metric alert name to resource ID."
  value       = { for k, v in azurerm_monitor_metric_alert.this : k => v.id }
}

output "query_alert_ids" {
  description = "Map of query alert name to resource ID."
  value       = { for k, v in azurerm_monitor_scheduled_query_rules_alert_v2.this : k => v.id }
}
