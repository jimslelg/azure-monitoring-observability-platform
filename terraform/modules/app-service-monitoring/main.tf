# App Service monitoring: full diagnostic logs to the central workspace plus a
# baseline alert pack. App-level metrics (5xx, latency) alert per app; plan
# metrics (CPU, memory) alert per App Service plan since compute is shared.

module "diagnostics" {
  source = "../diagnostic-settings"

  log_analytics_workspace_id = var.log_analytics_workspace_id
  targets = {
    for k, v in var.app_services : "app-${k}" => {
      resource_id = v.id
    }
  }
}

module "alerts" {
  source = "../alerts"

  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  metric_alerts = merge(
    length(var.app_services) == 0 ? {} : {
      "alert-${var.prefix}-app-http-5xx" = {
        scopes           = [for v in var.app_services : v.id]
        description      = "More than 10 HTTP 5xx responses in 5 minutes."
        severity         = 1
        metric_namespace = "Microsoft.Web/sites"
        metric_name      = "Http5xx"
        aggregation      = "Total"
        operator         = "GreaterThan"
        threshold        = 10
        frequency        = "PT1M"
        window_size      = "PT5M"
        action_group_ids = [var.critical_action_group_id]
      }
      "alert-${var.prefix}-app-response-time" = {
        scopes           = [for v in var.app_services : v.id]
        description      = "Average HTTP response time above 3 seconds for 15 minutes."
        severity         = 2
        metric_namespace = "Microsoft.Web/sites"
        metric_name      = "HttpResponseTime"
        aggregation      = "Average"
        operator         = "GreaterThan"
        threshold        = 3
        action_group_ids = [var.platform_action_group_id]
      }
    },
    length(var.app_service_plans) == 0 ? {} : {
      "alert-${var.prefix}-plan-cpu-high" = {
        scopes           = [for v in var.app_service_plans : v.id]
        description      = "App Service plan CPU above 85% for 15 minutes — consider scaling out."
        severity         = 2
        metric_namespace = "Microsoft.Web/serverfarms"
        metric_name      = "CpuPercentage"
        aggregation      = "Average"
        operator         = "GreaterThan"
        threshold        = 85
        action_group_ids = [var.platform_action_group_id]
      }
      "alert-${var.prefix}-plan-memory-high" = {
        scopes           = [for v in var.app_service_plans : v.id]
        description      = "App Service plan memory above 85% for 15 minutes."
        severity         = 2
        metric_namespace = "Microsoft.Web/serverfarms"
        metric_name      = "MemoryPercentage"
        aggregation      = "Average"
        operator         = "GreaterThan"
        threshold        = 85
        action_group_ids = [var.platform_action_group_id]
      }
    }
  )
}
