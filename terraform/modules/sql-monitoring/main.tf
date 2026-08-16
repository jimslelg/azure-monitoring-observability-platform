# Azure SQL monitoring: Query Store / errors / deadlock diagnostics to the
# central workspace plus a baseline alert pack. SQL databases do not support
# the "allLogs" category group with all pricing tiers, so key categories are
# listed explicitly.

module "diagnostics" {
  source = "../diagnostic-settings"

  log_analytics_workspace_id = var.log_analytics_workspace_id
  targets = {
    for k, v in var.sql_databases : "sqldb-${k}" => {
      resource_id         = v.id
      log_category_groups = []
      log_categories = [
        "SQLInsights",
        "QueryStoreRuntimeStatistics",
        "QueryStoreWaitStatistics",
        "Errors",
        "Blocks",
        "Deadlocks",
        "Timeouts",
      ]
    }
  }
}

module "alerts" {
  source = "../alerts"

  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  metric_alerts = length(var.sql_databases) == 0 ? {} : {
    "alert-${var.prefix}-sql-cpu-high" = {
      scopes           = [for v in var.sql_databases : v.id]
      description      = "SQL database CPU above 90% for 15 minutes."
      severity         = 2
      metric_namespace = "Microsoft.Sql/servers/databases"
      metric_name      = "cpu_percent"
      aggregation      = "Average"
      operator         = "GreaterThan"
      threshold        = 90
      action_group_ids = [var.platform_action_group_id]
    }
    "alert-${var.prefix}-sql-storage-high" = {
      scopes           = [for v in var.sql_databases : v.id]
      description      = "SQL database storage above 85% of the configured maximum."
      severity         = 2
      metric_namespace = "Microsoft.Sql/servers/databases"
      metric_name      = "storage_percent"
      aggregation      = "Maximum"
      operator         = "GreaterThan"
      threshold        = 85
      window_size      = "PT30M"
      frequency        = "PT15M"
      action_group_ids = [var.platform_action_group_id]
    }
    "alert-${var.prefix}-sql-deadlocks" = {
      scopes           = [for v in var.sql_databases : v.id]
      description      = "Deadlocks detected in the last 15 minutes."
      severity         = 1
      metric_namespace = "Microsoft.Sql/servers/databases"
      metric_name      = "deadlock"
      aggregation      = "Total"
      operator         = "GreaterThan"
      threshold        = 0
      action_group_ids = [var.critical_action_group_id]
    }
    "alert-${var.prefix}-sql-dtu-high" = {
      scopes           = [for v in var.sql_databases : v.id]
      description      = "DTU consumption above 90% for 15 minutes (DTU-based tiers only)."
      severity         = 2
      metric_namespace = "Microsoft.Sql/servers/databases"
      metric_name      = "dtu_consumption_percent"
      aggregation      = "Average"
      operator         = "GreaterThan"
      threshold        = 90
      enabled          = var.dtu_alerts_enabled
      action_group_ids = [var.platform_action_group_id]
    }
  }
}
