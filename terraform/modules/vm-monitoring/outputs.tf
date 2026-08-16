output "linux_dcr_id" {
  description = "Data collection rule ID for Linux VMs."
  value       = azurerm_monitor_data_collection_rule.linux.id
}

output "windows_dcr_id" {
  description = "Data collection rule ID for Windows VMs."
  value       = azurerm_monitor_data_collection_rule.windows.id
}
