output "ids" {
  description = "Map of target key to diagnostic setting ID."
  value       = { for k, v in azurerm_monitor_diagnostic_setting.this : k => v.id }
}
