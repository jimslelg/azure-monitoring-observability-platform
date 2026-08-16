# ---------------------------------------------------------------------------
# Container platform observability: managed Prometheus + Container Insights
# + Azure Managed Grafana
# ---------------------------------------------------------------------------

module "managed_prometheus" {
  source = "./modules/managed-prometheus"

  prefix              = local.prefix
  location            = azurerm_resource_group.monitoring.location
  resource_group_name = azurerm_resource_group.monitoring.name

  critical_action_group_id = local.critical_ag
  platform_action_group_id = local.platform_ag

  tags = local.common_tags
}

module "aks_monitoring" {
  source = "./modules/aks-monitoring"

  prefix                      = local.prefix
  location                    = azurerm_resource_group.monitoring.location
  resource_group_name         = azurerm_resource_group.monitoring.name
  log_analytics_workspace_id  = module.log_analytics.id
  monitor_workspace_id        = module.managed_prometheus.monitor_workspace_id
  data_collection_endpoint_id = module.managed_prometheus.data_collection_endpoint_id

  aks_clusters             = var.monitored_aks_clusters
  critical_action_group_id = local.critical_ag
  platform_action_group_id = local.platform_ag
  info_action_group_id     = module.action_groups.ids["ag-${local.prefix}-info"]

  tags = local.common_tags
}

module "grafana" {
  count  = var.grafana_enabled ? 1 : 0
  source = "./modules/grafana"

  prefix                  = local.prefix
  location                = azurerm_resource_group.monitoring.location
  resource_group_name     = azurerm_resource_group.monitoring.name
  monitor_workspace_id    = module.managed_prometheus.monitor_workspace_id
  monitoring_reader_scope = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"

  zone_redundancy_enabled  = var.environment == "prod"
  grafana_admin_object_ids = var.grafana_admin_object_ids

  tags = local.common_tags
}

output "grafana_endpoint" {
  description = "Grafana UI endpoint (null when Grafana is disabled)."
  value       = var.grafana_enabled ? module.grafana[0].endpoint : null
}

output "prometheus_query_endpoint" {
  description = "PromQL endpoint of the Azure Monitor workspace."
  value       = module.managed_prometheus.query_endpoint
}
