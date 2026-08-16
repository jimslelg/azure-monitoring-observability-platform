# Azure Managed Grafana wired to the Azure Monitor workspace (PromQL) and
# granted read access to Azure Monitor at subscription scope so dashboards
# can mix Prometheus and platform-metric panels.

resource "azurerm_dashboard_grafana" "this" {
  name                = "graf-${var.prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location

  grafana_major_version             = var.grafana_major_version
  sku                               = "Standard"
  zone_redundancy_enabled           = var.zone_redundancy_enabled
  api_key_enabled                   = false
  deterministic_outbound_ip_enabled = true
  public_network_access_enabled     = true

  identity {
    type = "SystemAssigned"
  }

  azure_monitor_workspace_integrations {
    resource_id = var.monitor_workspace_id
  }

  tags = var.tags
}

# PromQL access to the Monitor workspace
resource "azurerm_role_assignment" "monitoring_data_reader" {
  scope                = var.monitor_workspace_id
  role_definition_name = "Monitoring Data Reader"
  principal_id         = azurerm_dashboard_grafana.this.identity[0].principal_id
}

# Azure Monitor datasource access (metrics, logs, resource graph)
resource "azurerm_role_assignment" "monitoring_reader" {
  scope                = var.monitoring_reader_scope
  role_definition_name = "Monitoring Reader"
  principal_id         = azurerm_dashboard_grafana.this.identity[0].principal_id
}

# Human admins — everyone else gets Viewer via their directory membership
resource "azurerm_role_assignment" "grafana_admin" {
  for_each = toset(var.grafana_admin_object_ids)

  scope                = azurerm_dashboard_grafana.this.id
  role_definition_name = "Grafana Admin"
  principal_id         = each.value
}
