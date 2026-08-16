# Storage account monitoring: transaction/audit logs from the blob service
# (the account-level resource only emits metrics, so logs are attached to the
# blobServices sub-resource) plus availability, latency, and capacity alerts.

module "diagnostics" {
  source = "../diagnostic-settings"

  log_analytics_workspace_id = var.log_analytics_workspace_id
  targets = merge(
    {
      for k, v in var.storage_accounts : "st-${k}" => {
        resource_id         = v.id
        log_category_groups = []
        log_categories      = []
        metrics_enabled     = true
      }
    },
    {
      for k, v in var.storage_accounts : "st-${k}-blob" => {
        resource_id         = "${v.id}/blobServices/default"
        log_category_groups = ["allLogs"]
        metrics_enabled     = true
      }
    }
  )
}

module "alerts" {
  source = "../alerts"

  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  metric_alerts = length(var.storage_accounts) == 0 ? {} : {
    "alert-${var.prefix}-storage-availability" = {
      scopes           = [for v in var.storage_accounts : v.id]
      description      = "Storage account availability below 99.9% over 15 minutes."
      severity         = 1
      metric_namespace = "Microsoft.Storage/storageAccounts"
      metric_name      = "Availability"
      aggregation      = "Average"
      operator         = "LessThan"
      threshold        = 99.9
      action_group_ids = [var.critical_action_group_id]
    }
    "alert-${var.prefix}-storage-latency" = {
      scopes           = [for v in var.storage_accounts : v.id]
      description      = "End-to-end request latency above 1000 ms on average for 15 minutes."
      severity         = 2
      metric_namespace = "Microsoft.Storage/storageAccounts"
      metric_name      = "SuccessE2ELatency"
      aggregation      = "Average"
      operator         = "GreaterThan"
      threshold        = 1000
      action_group_ids = [var.platform_action_group_id]
    }
    "alert-${var.prefix}-storage-capacity" = {
      scopes           = [for v in var.storage_accounts : v.id]
      description      = "Used capacity above the configured threshold (default 4.5 TB)."
      severity         = 3
      metric_namespace = "Microsoft.Storage/storageAccounts"
      metric_name      = "UsedCapacity"
      aggregation      = "Average"
      operator         = "GreaterThan"
      threshold        = var.capacity_threshold_bytes
      window_size      = "PT1H"
      frequency        = "PT30M"
      action_group_ids = [var.platform_action_group_id]
    }
    "alert-${var.prefix}-storage-throttling" = {
      scopes           = [for v in var.storage_accounts : v.id]
      description      = "Requests are being throttled (success rate with throttling errors)."
      severity         = 2
      metric_namespace = "Microsoft.Storage/storageAccounts"
      metric_name      = "Transactions"
      aggregation      = "Total"
      operator         = "GreaterThan"
      threshold        = 0
      dimensions = [{
        name     = "ResponseType"
        operator = "Include"
        values   = ["ServerBusyError", "ClientThrottlingError"]
      }]
      action_group_ids = [var.platform_action_group_id]
    }
  }
}
