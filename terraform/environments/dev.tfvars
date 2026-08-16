environment = "dev"
location    = "canadacentral"

# Cheap and short-lived in dev: minimum retention, hard ingestion cap.
log_retention_in_days = 30
log_daily_quota_gb    = 5

platform_email_receivers = [
  { name = "platform-team", email_address = "platform-team@example.com" }
]

info_email_receivers = [
  { name = "platform-team", email_address = "platform-team@example.com" }
]

# No paging from dev — critical alerts land in the same mailbox.
critical_email_receivers = [
  { name = "platform-team", email_address = "platform-team@example.com" }
]

availability_tests = {
  "webtest-inventory-api-dev" = {
    url           = "https://inventory-api-dev.example.com/health"
    geo_locations = ["us-ca-sjc-azr", "us-va-ash-azr"]
  }
}

# Workload IDs are populated once workloads exist in the subscription, e.g.:
# monitored_virtual_machines = {
#   web01 = { id = "/subscriptions/.../virtualMachines/vm-web01", os_type = "linux" }
# }
