# ---------------------------------------------------------------------------
# Workbooks and the portal dashboard are authored as JSON in workbooks/ and
# dashboards/azure/ (reviewable, diffable) and deployed from here. Workbook
# resource names must be UUIDs; uuidv5 keeps them deterministic per env so
# re-plans never recreate them.
# ---------------------------------------------------------------------------

resource "azurerm_application_insights_workbook" "platform_health" {
  name                = uuidv5("url", "amop-${var.environment}-platform-health")
  resource_group_name = azurerm_resource_group.monitoring.name
  location            = azurerm_resource_group.monitoring.location
  display_name        = "Platform Health (${var.environment})"
  data_json           = file("${path.module}/../workbooks/platform-health.workbook.json")

  tags = local.common_tags
}

resource "azurerm_application_insights_workbook" "cost_and_ingestion" {
  name                = uuidv5("url", "amop-${var.environment}-cost-ingestion")
  resource_group_name = azurerm_resource_group.monitoring.name
  location            = azurerm_resource_group.monitoring.location
  display_name        = "Cost & Ingestion (${var.environment})"
  data_json           = file("${path.module}/../workbooks/cost-and-ingestion.workbook.json")

  tags = local.common_tags
}

resource "azurerm_portal_dashboard" "platform_overview" {
  name                = "dash-${local.prefix}-platform-overview"
  resource_group_name = azurerm_resource_group.monitoring.name
  location            = azurerm_resource_group.monitoring.location

  dashboard_properties = templatefile("${path.module}/../dashboards/azure/platform-overview.tpl.json", {
    environment    = var.environment
    workspace_id   = module.log_analytics.id
    workspace_name = module.log_analytics.name
  })

  tags = merge(local.common_tags, {
    hidden-title = "Platform Overview (${var.environment})"
  })
}
