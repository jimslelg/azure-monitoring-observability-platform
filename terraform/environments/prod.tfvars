environment = "prod"
location    = "canadacentral"

# Production keeps 6 months interactive and never caps ingestion — dropping
# telemetry during an incident is worse than the overage.
log_retention_in_days = 180
log_daily_quota_gb    = -1

critical_email_receivers = [
  { name = "oncall", email_address = "oncall@example.com" }
]

critical_sms_receivers = [
  { name = "oncall-phone", country_code = "1", phone_number = "5555550100" }
]

platform_email_receivers = [
  { name = "platform-team", email_address = "platform-team@example.com" }
]

info_email_receivers = [
  { name = "platform-team", email_address = "platform-team@example.com" }
]

info_webhook_receivers = [
  { name = "itsm-intake", service_uri = "https://itsm.example.com/api/azure-alerts" }
]

availability_tests = {
  "webtest-inventory-api" = {
    url               = "https://inventory-api.example.com/health"
    geo_locations     = ["us-ca-sjc-azr", "us-va-ash-azr", "emea-nl-ams-azr"]
    frequency_seconds = 300
  }
}
