output "ids" {
  description = "Map of action group name to resource ID."
  value       = { for k, v in azurerm_monitor_action_group.this : k => v.id }
}
