# ---------------------------------------------------------------------------
# Workload monitoring — each module attaches diagnostics and a baseline alert
# pack to existing workload resources passed in by ID. Empty maps mean the
# module provisions nothing for that workload in this environment.
# ---------------------------------------------------------------------------

locals {
  critical_ag = module.action_groups.ids["ag-${local.prefix}-critical"]
  platform_ag = module.action_groups.ids["ag-${local.prefix}-platform"]
}

module "vm_monitoring" {
  source = "./modules/vm-monitoring"

  prefix                     = local.prefix
  location                   = azurerm_resource_group.monitoring.location
  resource_group_name        = azurerm_resource_group.monitoring.name
  log_analytics_workspace_id = module.log_analytics.id

  virtual_machines         = var.monitored_virtual_machines
  critical_action_group_id = local.critical_ag
  platform_action_group_id = local.platform_ag

  tags = local.common_tags
}

module "app_service_monitoring" {
  source = "./modules/app-service-monitoring"

  prefix                     = local.prefix
  location                   = azurerm_resource_group.monitoring.location
  resource_group_name        = azurerm_resource_group.monitoring.name
  log_analytics_workspace_id = module.log_analytics.id

  app_services             = var.monitored_app_services
  app_service_plans        = var.monitored_app_service_plans
  critical_action_group_id = local.critical_ag
  platform_action_group_id = local.platform_ag

  tags = local.common_tags
}

module "sql_monitoring" {
  source = "./modules/sql-monitoring"

  prefix                     = local.prefix
  location                   = azurerm_resource_group.monitoring.location
  resource_group_name        = azurerm_resource_group.monitoring.name
  log_analytics_workspace_id = module.log_analytics.id

  sql_databases            = var.monitored_sql_databases
  dtu_alerts_enabled       = var.sql_dtu_alerts_enabled
  critical_action_group_id = local.critical_ag
  platform_action_group_id = local.platform_ag

  tags = local.common_tags
}

module "storage_monitoring" {
  source = "./modules/storage-monitoring"

  prefix                     = local.prefix
  location                   = azurerm_resource_group.monitoring.location
  resource_group_name        = azurerm_resource_group.monitoring.name
  log_analytics_workspace_id = module.log_analytics.id

  storage_accounts         = var.monitored_storage_accounts
  critical_action_group_id = local.critical_ag
  platform_action_group_id = local.platform_ag

  tags = local.common_tags
}

module "network_monitoring" {
  source = "./modules/network-monitoring"

  prefix                       = local.prefix
  location                     = azurerm_resource_group.monitoring.location
  resource_group_name          = azurerm_resource_group.monitoring.name
  log_analytics_workspace_id   = module.log_analytics.id
  log_analytics_workspace_guid = module.log_analytics.workspace_id

  network_watcher_name                = var.network_watcher_name
  network_watcher_resource_group_name = var.network_watcher_resource_group_name
  flow_log_storage_account_id         = var.flow_log_storage_account_id

  network_security_groups  = var.monitored_network_security_groups
  diagnostic_targets       = var.monitored_network_resources
  application_gateways     = var.monitored_application_gateways
  critical_action_group_id = local.critical_ag
  platform_action_group_id = local.platform_ag

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# Subscription-level signals
# ---------------------------------------------------------------------------

data "azurerm_client_config" "current" {}

resource "azurerm_monitor_activity_log_alert" "service_health" {
  name                = "alert-${local.prefix}-service-health"
  resource_group_name = azurerm_resource_group.monitoring.name
  location            = "global"
  scopes              = ["/subscriptions/${data.azurerm_client_config.current.subscription_id}"]
  description         = "Azure Service Health incidents and security advisories affecting this subscription's regions."

  criteria {
    category = "ServiceHealth"
    service_health {
      events    = ["Incident", "Security"]
      locations = [var.location, "Global"]
    }
  }

  action {
    action_group_id = local.platform_ag
  }

  tags = local.common_tags
}
