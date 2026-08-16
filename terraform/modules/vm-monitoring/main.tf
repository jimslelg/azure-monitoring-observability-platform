locals {
  linux_vms   = { for k, v in var.virtual_machines : k => v if lower(v.os_type) == "linux" }
  windows_vms = { for k, v in var.virtual_machines : k => v if lower(v.os_type) == "windows" }

  perf_counter_sampling_seconds = 60
}

# ---------------------------------------------------------------------------
# Data collection rules for the Azure Monitor Agent
# ---------------------------------------------------------------------------

resource "azurerm_monitor_data_collection_rule" "linux" {
  name                = "dcr-${var.prefix}-linux"
  location            = var.location
  resource_group_name = var.resource_group_name
  kind                = "Linux"

  destinations {
    log_analytics {
      workspace_resource_id = var.log_analytics_workspace_id
      name                  = "central-law"
    }
  }

  data_flow {
    streams      = ["Microsoft-Perf", "Microsoft-Syslog"]
    destinations = ["central-law"]
  }

  data_sources {
    performance_counter {
      name                          = "linux-perf"
      streams                       = ["Microsoft-Perf"]
      sampling_frequency_in_seconds = local.perf_counter_sampling_seconds
      counter_specifiers = [
        "Processor(*)\\% Processor Time",
        "Memory(*)\\% Used Memory",
        "Memory(*)\\Available MBytes Memory",
        "Logical Disk(*)\\% Used Space",
        "Logical Disk(*)\\Disk Read Bytes/sec",
        "Logical Disk(*)\\Disk Write Bytes/sec",
        "Network(*)\\Total Bytes Transmitted",
        "Network(*)\\Total Bytes Received",
      ]
    }

    syslog {
      name           = "linux-syslog"
      streams        = ["Microsoft-Syslog"]
      facility_names = ["auth", "authpriv", "cron", "daemon", "kern", "syslog"]
      log_levels     = ["Warning", "Error", "Critical", "Alert", "Emergency"]
    }
  }

  tags = var.tags
}

resource "azurerm_monitor_data_collection_rule" "windows" {
  name                = "dcr-${var.prefix}-windows"
  location            = var.location
  resource_group_name = var.resource_group_name
  kind                = "Windows"

  destinations {
    log_analytics {
      workspace_resource_id = var.log_analytics_workspace_id
      name                  = "central-law"
    }
  }

  data_flow {
    streams      = ["Microsoft-Perf", "Microsoft-Event"]
    destinations = ["central-law"]
  }

  data_sources {
    performance_counter {
      name                          = "windows-perf"
      streams                       = ["Microsoft-Perf"]
      sampling_frequency_in_seconds = local.perf_counter_sampling_seconds
      counter_specifiers = [
        "\\Processor Information(_Total)\\% Processor Time",
        "\\Memory\\Available MBytes",
        "\\Memory\\% Committed Bytes In Use",
        "\\LogicalDisk(*)\\% Free Space",
        "\\LogicalDisk(*)\\Avg. Disk sec/Read",
        "\\LogicalDisk(*)\\Avg. Disk sec/Write",
        "\\Network Interface(*)\\Bytes Total/sec",
      ]
    }

    windows_event_log {
      name    = "windows-events"
      streams = ["Microsoft-Event"]
      x_path_queries = [
        "System!*[System[(Level=1 or Level=2 or Level=3)]]",
        "Application!*[System[(Level=1 or Level=2 or Level=3)]]",
        "Security!*[System[(EventID=4624 or EventID=4625 or EventID=4672)]]",
      ]
    }
  }

  tags = var.tags
}

resource "azurerm_monitor_data_collection_rule_association" "linux" {
  for_each = local.linux_vms

  name                    = "dcra-${var.prefix}-linux"
  target_resource_id      = each.value.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.linux.id
}

resource "azurerm_monitor_data_collection_rule_association" "windows" {
  for_each = local.windows_vms

  name                    = "dcra-${var.prefix}-windows"
  target_resource_id      = each.value.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.windows.id
}

# ---------------------------------------------------------------------------
# Baseline VM alert pack
# ---------------------------------------------------------------------------

module "alerts" {
  source = "../alerts"

  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  metric_alerts = length(var.virtual_machines) == 0 ? {} : {
    "alert-${var.prefix}-vm-cpu-high" = {
      scopes           = [for v in var.virtual_machines : v.id]
      description      = "VM CPU above 90% for 15 minutes."
      severity         = 2
      metric_namespace = "Microsoft.Compute/virtualMachines"
      metric_name      = "Percentage CPU"
      aggregation      = "Average"
      operator         = "GreaterThan"
      threshold        = 90
      action_group_ids = [var.platform_action_group_id]
    }
    "alert-${var.prefix}-vm-memory-low" = {
      scopes           = [for v in var.virtual_machines : v.id]
      description      = "VM available memory below 512 MB for 15 minutes."
      severity         = 2
      metric_namespace = "Microsoft.Compute/virtualMachines"
      metric_name      = "Available Memory Bytes"
      aggregation      = "Average"
      operator         = "LessThan"
      threshold        = 536870912
      action_group_ids = [var.platform_action_group_id]
    }
  }

  query_alerts = length(var.virtual_machines) == 0 ? {} : {
    "alert-${var.prefix}-vm-heartbeat-missing" = {
      scopes                  = [var.log_analytics_workspace_id]
      description             = "No heartbeat received from a monitored VM in the last 10 minutes — host is down or the agent stopped."
      severity                = 1
      query                   = <<-KQL
        Heartbeat
        | summarize LastHeartbeat = max(TimeGenerated) by Computer, _ResourceId
        | where LastHeartbeat < ago(10m)
      KQL
      time_aggregation_method = "Count"
      operator                = "GreaterThan"
      threshold               = 0
      resource_id_column      = "_ResourceId"
      evaluation_frequency    = "PT5M"
      window_duration         = "PT15M"
      action_group_ids        = [var.critical_action_group_id]
    }
    "alert-${var.prefix}-vm-disk-space-low" = {
      scopes                  = [var.log_analytics_workspace_id]
      description             = "Logical disk free space below 10% on a monitored VM."
      severity                = 2
      query                   = <<-KQL
        Perf
        | where ObjectName == "LogicalDisk" or ObjectName == "Logical Disk"
        | where CounterName == "% Free Space" or CounterName == "% Used Space"
        | extend FreePct = iff(CounterName == "% Free Space", CounterValue, 100 - CounterValue)
        | summarize AvgFreePct = avg(FreePct) by Computer, InstanceName, _ResourceId
        | where AvgFreePct < 10
      KQL
      time_aggregation_method = "Count"
      operator                = "GreaterThan"
      threshold               = 0
      resource_id_column      = "_ResourceId"
      evaluation_frequency    = "PT15M"
      window_duration         = "PT30M"
      action_group_ids        = [var.platform_action_group_id]
    }
  }
}
