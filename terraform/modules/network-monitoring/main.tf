# Network monitoring: NSG flow logs with Traffic Analytics, diagnostic logs
# from network resources (Application Gateway, Azure Firewall, VPN gateways,
# load balancers), and a baseline alert pack for Application Gateway health.

resource "azurerm_network_watcher_flow_log" "this" {
  for_each = var.network_security_groups

  name                 = "fl-${var.prefix}-${each.key}"
  network_watcher_name = var.network_watcher_name
  resource_group_name  = var.network_watcher_resource_group_name

  network_security_group_id = each.value.id
  storage_account_id        = var.flow_log_storage_account_id
  enabled                   = true
  version                   = 2

  retention_policy {
    enabled = true
    days    = var.flow_log_retention_days
  }

  traffic_analytics {
    enabled               = true
    workspace_id          = var.log_analytics_workspace_guid
    workspace_region      = var.location
    workspace_resource_id = var.log_analytics_workspace_id
    interval_in_minutes   = 10
  }

  tags = var.tags
}

# Any network resource that supports diagnostic settings (app gateways,
# firewalls, VPN/ER gateways, public load balancers) can be passed here.
module "diagnostics" {
  source = "../diagnostic-settings"

  log_analytics_workspace_id = var.log_analytics_workspace_id
  targets = {
    for k, v in var.diagnostic_targets : "net-${k}" => {
      resource_id = v.id
    }
  }
}

module "alerts" {
  source = "../alerts"

  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  metric_alerts = length(var.application_gateways) == 0 ? {} : {
    "alert-${var.prefix}-agw-unhealthy-hosts" = {
      scopes           = [for v in var.application_gateways : v.id]
      description      = "Application Gateway reports unhealthy backend hosts."
      severity         = 1
      metric_namespace = "Microsoft.Network/applicationGateways"
      metric_name      = "UnhealthyHostCount"
      aggregation      = "Average"
      operator         = "GreaterThan"
      threshold        = 0
      frequency        = "PT1M"
      window_size      = "PT5M"
      action_group_ids = [var.critical_action_group_id]
    }
    "alert-${var.prefix}-agw-failed-requests" = {
      scopes           = [for v in var.application_gateways : v.id]
      description      = "More than 25 failed requests through the Application Gateway in 5 minutes."
      severity         = 2
      metric_namespace = "Microsoft.Network/applicationGateways"
      metric_name      = "FailedRequests"
      aggregation      = "Total"
      operator         = "GreaterThan"
      threshold        = 25
      frequency        = "PT1M"
      window_size      = "PT5M"
      action_group_ids = [var.platform_action_group_id]
    }
  }

  query_alerts = length(var.network_security_groups) == 0 ? {} : {
    "alert-${var.prefix}-net-denied-spike" = {
      scopes                  = [var.log_analytics_workspace_id]
      description             = "Spike in denied flows recorded by Traffic Analytics — possible scanning or misconfigured rule."
      severity                = 3
      query                   = <<-KQL
        AzureNetworkAnalytics_CL
        | where SubType_s == "FlowLog" and FlowStatus_s == "D"
        | summarize DeniedFlows = count() by bin(TimeGenerated, 15m)
        | where DeniedFlows > 1000
      KQL
      time_aggregation_method = "Count"
      operator                = "GreaterThan"
      threshold               = 0
      evaluation_frequency    = "PT15M"
      window_duration         = "PT30M"
      action_group_ids        = [var.platform_action_group_id]
    }
  }
}
