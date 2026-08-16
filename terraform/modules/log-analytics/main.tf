resource "azurerm_log_analytics_workspace" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku                        = var.sku
  retention_in_days          = var.retention_in_days
  daily_quota_gb             = var.daily_quota_gb
  internet_ingestion_enabled = var.internet_ingestion_enabled
  internet_query_enabled     = var.internet_query_enabled

  tags = var.tags
}

# Saved searches give operators a curated starting point in the Logs blade.
# The query text itself is maintained in the kql/ library and passed in here.
resource "azurerm_log_analytics_saved_search" "this" {
  for_each = var.saved_searches

  name                       = each.key
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  category                   = each.value.category
  display_name               = each.value.display_name
  query                      = each.value.query
}
