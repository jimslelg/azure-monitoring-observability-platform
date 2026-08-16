# Azure Monitor workspace (managed Prometheus backend) plus the data
# collection endpoint metrics flow through, and platform-level Prometheus
# alert rule groups evaluated inside the managed service.

resource "azurerm_monitor_workspace" "this" {
  name                = "amw-${var.prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_monitor_data_collection_endpoint" "this" {
  name                = "dce-${var.prefix}-prometheus"
  resource_group_name = var.resource_group_name
  location            = var.location
  kind                = "Linux"
  tags                = var.tags
}

# Kubernetes alert rules evaluated by the managed Prometheus service. These
# fire on kube-state-metrics / node-exporter series that the AMA metrics
# add-on scrapes by default from every connected cluster.
resource "azurerm_monitor_alert_prometheus_rule_group" "kubernetes" {
  name                = "prg-${var.prefix}-kubernetes"
  resource_group_name = var.resource_group_name
  location            = var.location
  description         = "Baseline Kubernetes health alerts evaluated in managed Prometheus."
  rule_group_enabled  = true
  interval            = "PT1M"
  scopes              = [azurerm_monitor_workspace.this.id]

  rule {
    alert      = "KubeNodeNotReady"
    enabled    = true
    expression = "kube_node_status_condition{condition=\"Ready\",status=\"true\"} == 0"
    for        = "PT10M"
    severity   = 1

    labels = {
      team = "platform"
    }
    annotations = {
      summary = "Node {{ $labels.node }} has been NotReady for more than 10 minutes."
    }

    alert_resolution {
      auto_resolved   = true
      time_to_resolve = "PT10M"
    }

    action {
      action_group_id = var.critical_action_group_id
    }
  }

  rule {
    alert      = "KubePodCrashLooping"
    enabled    = true
    expression = "increase(kube_pod_container_status_restarts_total[15m]) > 3"
    for        = "PT5M"
    severity   = 2

    labels = {
      team = "platform"
    }
    annotations = {
      summary = "Pod {{ $labels.namespace }}/{{ $labels.pod }} restarted more than 3 times in 15 minutes."
    }

    alert_resolution {
      auto_resolved   = true
      time_to_resolve = "PT10M"
    }

    action {
      action_group_id = var.platform_action_group_id
    }
  }

  rule {
    alert      = "KubeContainerOOMKilled"
    enabled    = true
    expression = "increase(kube_pod_container_status_last_terminated_reason{reason=\"OOMKilled\"}[15m]) > 0"
    for        = "PT0M"
    severity   = 2

    labels = {
      team = "platform"
    }
    annotations = {
      summary = "Container {{ $labels.container }} in {{ $labels.namespace }}/{{ $labels.pod }} was OOMKilled."
    }

    alert_resolution {
      auto_resolved   = true
      time_to_resolve = "PT15M"
    }

    action {
      action_group_id = var.platform_action_group_id
    }
  }

  rule {
    alert      = "KubePersistentVolumeFillingUp"
    enabled    = true
    expression = "kubelet_volume_stats_available_bytes / kubelet_volume_stats_capacity_bytes < 0.10"
    for        = "PT15M"
    severity   = 2

    labels = {
      team = "platform"
    }
    annotations = {
      summary = "PersistentVolume for claim {{ $labels.persistentvolumeclaim }} in {{ $labels.namespace }} is below 10% free."
    }

    alert_resolution {
      auto_resolved   = true
      time_to_resolve = "PT15M"
    }

    action {
      action_group_id = var.platform_action_group_id
    }
  }
}

# Recording rules keep expensive aggregations pre-computed for dashboards.
resource "azurerm_monitor_alert_prometheus_rule_group" "recording" {
  name                = "prg-${var.prefix}-recording"
  resource_group_name = var.resource_group_name
  location            = var.location
  description         = "Recording rules backing the Grafana cluster dashboards."
  rule_group_enabled  = true
  interval            = "PT1M"
  scopes              = [azurerm_monitor_workspace.this.id]

  rule {
    record     = "node:cpu_utilisation:avg5m"
    enabled    = true
    expression = "1 - avg by (instance) (rate(node_cpu_seconds_total{mode=\"idle\"}[5m]))"
  }

  rule {
    record     = "node:memory_utilisation:ratio"
    enabled    = true
    expression = "1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)"
  }

  rule {
    record     = "namespace:container_cpu_usage:sum_rate5m"
    enabled    = true
    expression = "sum by (namespace) (rate(container_cpu_usage_seconds_total{container!=\"\"}[5m]))"
  }

  rule {
    record     = "namespace:container_memory_working_set:sum"
    enabled    = true
    expression = "sum by (namespace) (container_memory_working_set_bytes{container!=\"\"})"
  }
}
