resource "azurerm_application_insights" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  application_type = var.application_type
  workspace_id     = var.log_analytics_workspace_id

  retention_in_days   = var.retention_in_days
  sampling_percentage = var.sampling_percentage
  disable_ip_masking  = false

  tags = var.tags
}

# Synthetic availability checks against public endpoints. Standard web tests
# replace the classic (deprecated) multi-step web tests.
resource "azurerm_application_insights_standard_web_test" "this" {
  for_each = var.availability_tests

  name                    = each.key
  resource_group_name     = var.resource_group_name
  location                = var.location
  application_insights_id = azurerm_application_insights.this.id

  geo_locations = each.value.geo_locations
  frequency     = each.value.frequency_seconds
  timeout       = each.value.timeout_seconds
  enabled       = true
  retry_enabled = true

  request {
    url = each.value.url
  }

  validation_rules {
    expected_status_code = each.value.expected_status_code
    ssl_check_enabled    = each.value.ssl_check_enabled
  }

  tags = var.tags
}

# Failure Anomalies smart detection, wired to a real action group instead of
# the default "email everyone with access" behaviour.
resource "azurerm_monitor_smart_detector_alert_rule" "failure_anomalies" {
  count = var.smart_detection_action_group_id == null ? 0 : 1

  name                = "${var.name}-failure-anomalies"
  resource_group_name = var.resource_group_name
  severity            = "Sev3"
  scope_resource_ids  = [azurerm_application_insights.this.id]
  frequency           = "PT1M"
  detector_type       = "FailureAnomaliesDetector"

  action_group {
    ids = [var.smart_detection_action_group_id]
  }

  tags = var.tags
}
