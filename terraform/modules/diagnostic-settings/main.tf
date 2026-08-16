# Generic diagnostic-settings fan-out: one setting per target resource, all
# routed to the central Log Analytics workspace. Category groups ("allLogs",
# "audit") are preferred over explicit categories so new categories added by
# Azure are picked up without code changes; explicit categories remain
# available for resources where category groups are not supported.
resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each = var.targets

  name                       = var.setting_name
  target_resource_id         = each.value.resource_id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = each.value.log_category_groups
    content {
      category_group = enabled_log.value
    }
  }

  dynamic "enabled_log" {
    for_each = each.value.log_categories
    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = each.value.metrics_enabled ? ["AllMetrics"] : []
    content {
      category = metric.value
      enabled  = true
    }
  }
}
