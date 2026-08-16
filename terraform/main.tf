locals {
  # e.g. "amop-prod" — prefix for every resource this stack owns
  prefix = "${var.project}-${var.environment}"

  common_tags = merge(var.tags, {
    project     = var.project
    environment = var.environment
    managed_by  = "terraform"
    repository  = "azure-monitoring-observability-platform"
  })
}

resource "azurerm_resource_group" "monitoring" {
  name     = "rg-${local.prefix}-monitoring"
  location = var.location
  tags     = local.common_tags
}

# ---------------------------------------------------------------------------
# Core telemetry backends
# ---------------------------------------------------------------------------

module "log_analytics" {
  source = "./modules/log-analytics"

  name                = "log-${local.prefix}"
  location            = azurerm_resource_group.monitoring.location
  resource_group_name = azurerm_resource_group.monitoring.name

  retention_in_days = var.log_retention_in_days
  daily_quota_gb    = var.log_daily_quota_gb

  tags = local.common_tags
}

module "application_insights" {
  source = "./modules/application-insights"

  name                       = "appi-${local.prefix}"
  location                   = azurerm_resource_group.monitoring.location
  resource_group_name        = azurerm_resource_group.monitoring.name
  log_analytics_workspace_id = module.log_analytics.id

  availability_tests              = var.availability_tests
  smart_detection_action_group_id = module.action_groups.ids["ag-${local.prefix}-platform"]

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# Notification routing
# ---------------------------------------------------------------------------
# Three-tier routing model:
#   critical — pages the on-call engineer (SMS + email), Sev0/Sev1 alerts
#   platform — infrastructure team email, Sev2/Sev3 alerts
#   info     — ticket/webhook sink for informational signals, Sev4
# Alert rules reference these tiers by name; receivers vary per environment.

module "action_groups" {
  source = "./modules/action-groups"

  resource_group_name = azurerm_resource_group.monitoring.name

  action_groups = {
    "ag-${local.prefix}-critical" = {
      short_name      = "amop-crit"
      email_receivers = var.critical_email_receivers
      sms_receivers   = var.critical_sms_receivers
    }
    "ag-${local.prefix}-platform" = {
      short_name      = "amop-plat"
      email_receivers = var.platform_email_receivers
    }
    "ag-${local.prefix}-info" = {
      short_name        = "amop-info"
      email_receivers   = var.info_email_receivers
      webhook_receivers = var.info_webhook_receivers
    }
  }

  tags = local.common_tags
}
