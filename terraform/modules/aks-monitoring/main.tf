# AKS monitoring: Container Insights (logs/inventory to Log Analytics) and
# managed Prometheus (metrics to the Azure Monitor workspace), both delivered
# as data collection rules associated with each cluster, plus a baseline
# cluster alert pack. The clusters themselves are managed elsewhere; enabling
# the AMA/metrics add-ons on the cluster resource stays with the cluster's
# own Terraform, which references these DCR IDs.

resource "azurerm_monitor_data_collection_rule" "container_insights" {
  name                = "dcr-${var.prefix}-container-insights"
  location            = var.location
  resource_group_name = var.resource_group_name

  destinations {
    log_analytics {
      workspace_resource_id = var.log_analytics_workspace_id
      name                  = "central-law"
    }
  }

  data_flow {
    streams      = ["Microsoft-ContainerInsights-Group-Default"]
    destinations = ["central-law"]
  }

  data_sources {
    extension {
      name           = "ContainerInsightsExtension"
      extension_name = "ContainerInsights"
      streams        = ["Microsoft-ContainerInsights-Group-Default"]
      extension_json = jsonencode({
        dataCollectionSettings = {
          interval               = "1m"
          namespaceFilteringMode = "Off"
          enableContainerLogV2   = true
        }
      })
    }
  }

  tags = var.tags
}

resource "azurerm_monitor_data_collection_rule" "prometheus" {
  name                        = "dcr-${var.prefix}-prometheus"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  kind                        = "Linux"
  data_collection_endpoint_id = var.data_collection_endpoint_id

  destinations {
    monitor_account {
      monitor_account_id = var.monitor_workspace_id
      name               = "prometheus-amw"
    }
  }

  data_flow {
    streams      = ["Microsoft-PrometheusMetrics"]
    destinations = ["prometheus-amw"]
  }

  data_sources {
    prometheus_forwarder {
      name    = "prometheus-forwarder"
      streams = ["Microsoft-PrometheusMetrics"]
    }
  }

  tags = var.tags
}

resource "azurerm_monitor_data_collection_rule_association" "container_insights" {
  for_each = var.aks_clusters

  name                    = "dcra-${var.prefix}-ci"
  target_resource_id      = each.value.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.container_insights.id
}

resource "azurerm_monitor_data_collection_rule_association" "prometheus" {
  for_each = var.aks_clusters

  name                    = "dcra-${var.prefix}-prom"
  target_resource_id      = each.value.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.prometheus.id
}

# ---------------------------------------------------------------------------
# Baseline AKS alert pack (platform metrics + Container Insights logs)
# ---------------------------------------------------------------------------

module "alerts" {
  source = "../alerts"

  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  metric_alerts = length(var.aks_clusters) == 0 ? {} : {
    "alert-${var.prefix}-aks-node-cpu" = {
      scopes           = [for v in var.aks_clusters : v.id]
      description      = "AKS node CPU above 85% for 15 minutes."
      severity         = 2
      metric_namespace = "Microsoft.ContainerService/managedClusters"
      metric_name      = "node_cpu_usage_percentage"
      aggregation      = "Average"
      operator         = "GreaterThan"
      threshold        = 85
      action_group_ids = [var.platform_action_group_id]
    }
    "alert-${var.prefix}-aks-node-memory" = {
      scopes           = [for v in var.aks_clusters : v.id]
      description      = "AKS node working-set memory above 90% for 15 minutes."
      severity         = 2
      metric_namespace = "Microsoft.ContainerService/managedClusters"
      metric_name      = "node_memory_working_set_percentage"
      aggregation      = "Average"
      operator         = "GreaterThan"
      threshold        = 90
      action_group_ids = [var.platform_action_group_id]
    }
    "alert-${var.prefix}-aks-pods-failed" = {
      scopes           = [for v in var.aks_clusters : v.id]
      description      = "Pods stuck in Failed phase on the cluster."
      severity         = 2
      metric_namespace = "Microsoft.ContainerService/managedClusters"
      metric_name      = "kube_pod_status_phase"
      aggregation      = "Average"
      operator         = "GreaterThan"
      threshold        = 0
      dimensions = [{
        name     = "phase"
        operator = "Include"
        values   = ["Failed"]
      }]
      action_group_ids = [var.platform_action_group_id]
    }
  }

  query_alerts = length(var.aks_clusters) == 0 ? {} : {
    "alert-${var.prefix}-aks-container-errors" = {
      scopes                  = [var.log_analytics_workspace_id]
      description             = "Container stderr volume spiked above 100 error lines in 15 minutes for a single workload."
      severity                = 3
      query                   = <<-KQL
        ContainerLogV2
        | where LogSource == "stderr"
        | summarize ErrorLines = count() by PodNamespace, ContainerName
        | where ErrorLines > 100
      KQL
      time_aggregation_method = "Count"
      operator                = "GreaterThan"
      threshold               = 0
      evaluation_frequency    = "PT15M"
      window_duration         = "PT15M"
      action_group_ids        = [var.info_action_group_id]
    }
  }
}
