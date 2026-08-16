# Workload resources to onboard, passed by resource ID. The platform never
# creates workload resources — it observes what already exists.

variable "monitored_virtual_machines" {
  description = "VMs to monitor, keyed by logical name."
  type = map(object({
    id      = string
    os_type = string
  }))
  default = {}
}

variable "monitored_app_services" {
  description = "App Services to monitor, keyed by logical name."
  type = map(object({
    id = string
  }))
  default = {}
}

variable "monitored_app_service_plans" {
  description = "App Service plans to monitor, keyed by logical name."
  type = map(object({
    id = string
  }))
  default = {}
}

variable "monitored_sql_databases" {
  description = "Azure SQL databases to monitor, keyed by logical name."
  type = map(object({
    id = string
  }))
  default = {}
}

variable "sql_dtu_alerts_enabled" {
  description = "Enable DTU alerts (DTU-based SQL tiers only)."
  type        = bool
  default     = false
}

variable "monitored_storage_accounts" {
  description = "Storage accounts to monitor, keyed by logical name."
  type = map(object({
    id = string
  }))
  default = {}
}

variable "monitored_network_security_groups" {
  description = "NSGs to enable flow logs + Traffic Analytics on."
  type = map(object({
    id = string
  }))
  default = {}
}

variable "monitored_network_resources" {
  description = "Network resources (firewalls, gateways, LBs) to attach diagnostic settings to."
  type = map(object({
    id = string
  }))
  default = {}
}

variable "monitored_application_gateways" {
  description = "Application Gateways to alert on."
  type = map(object({
    id = string
  }))
  default = {}
}

variable "network_watcher_name" {
  description = "Regional Network Watcher name."
  type        = string
  default     = "NetworkWatcher_canadacentral"
}

variable "network_watcher_resource_group_name" {
  description = "Network Watcher resource group."
  type        = string
  default     = "NetworkWatcherRG"
}

variable "flow_log_storage_account_id" {
  description = "Storage account receiving raw NSG flow logs (null disables flow logs)."
  type        = string
  default     = null
}
