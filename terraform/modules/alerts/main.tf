# Generic alert factory used by every workload module. Two rule kinds:
#   - metric alerts: near-real-time, evaluated on platform metrics
#   - scheduled query alerts (v2): KQL against the Log Analytics workspace
# Severity convention (matches action-group tiers in the root stack):
#   0-1 -> critical, 2-3 -> platform, 4 -> info

resource "azurerm_monitor_metric_alert" "this" {
  for_each = var.metric_alerts

  name                = each.key
  resource_group_name = var.resource_group_name
  scopes              = each.value.scopes
  description         = each.value.description
  severity            = each.value.severity
  frequency           = each.value.frequency
  window_size         = each.value.window_size
  auto_mitigate       = true
  enabled             = each.value.enabled

  criteria {
    metric_namespace = each.value.metric_namespace
    metric_name      = each.value.metric_name
    aggregation      = each.value.aggregation
    operator         = each.value.operator
    threshold        = each.value.threshold

    dynamic "dimension" {
      for_each = each.value.dimensions
      content {
        name     = dimension.value.name
        operator = dimension.value.operator
        values   = dimension.value.values
      }
    }
  }

  dynamic "action" {
    for_each = each.value.action_group_ids
    content {
      action_group_id = action.value
    }
  }

  tags = var.tags
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "this" {
  for_each = var.query_alerts

  name                = each.key
  resource_group_name = var.resource_group_name
  location            = var.location
  description         = each.value.description
  display_name        = each.key
  severity            = each.value.severity
  enabled             = each.value.enabled

  scopes               = each.value.scopes
  evaluation_frequency = each.value.evaluation_frequency
  window_duration      = each.value.window_duration

  auto_mitigation_enabled = true

  criteria {
    query                   = each.value.query
    time_aggregation_method = each.value.time_aggregation_method
    metric_measure_column   = each.value.metric_measure_column
    resource_id_column      = each.value.resource_id_column
    operator                = each.value.operator
    threshold               = each.value.threshold

    failing_periods {
      minimum_failing_periods_to_trigger_alert = each.value.minimum_failing_periods
      number_of_evaluation_periods             = each.value.evaluation_periods
    }
  }

  action {
    action_groups = each.value.action_group_ids
  }

  tags = var.tags
}
