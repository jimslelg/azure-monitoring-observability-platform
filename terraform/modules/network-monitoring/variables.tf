variable "prefix" {
  description = "Naming prefix (e.g. amop-prod)."
  type        = string
}

variable "location" {
  description = "Azure region (also used as the Traffic Analytics workspace region)."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for alert rules."
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of the central Log Analytics workspace."
  type        = string
}

variable "log_analytics_workspace_guid" {
  description = "Workspace (customer) GUID of the central workspace, required by Traffic Analytics."
  type        = string
}

variable "network_watcher_name" {
  description = "Name of the regional Network Watcher (usually NetworkWatcher_<region>)."
  type        = string
}

variable "network_watcher_resource_group_name" {
  description = "Resource group of the Network Watcher (usually NetworkWatcherRG)."
  type        = string
}

variable "flow_log_storage_account_id" {
  description = "Storage account that receives raw NSG flow logs."
  type        = string
  default     = null
}

variable "flow_log_retention_days" {
  description = "Retention of raw flow logs in the storage account."
  type        = number
  default     = 30
}

variable "network_security_groups" {
  description = "NSGs to enable flow logs on, keyed by logical name."
  type = map(object({
    id = string
  }))
  default = {}
}

variable "diagnostic_targets" {
  description = "Network resources (app gateways, firewalls, gateways, LBs) to attach diagnostic settings to."
  type = map(object({
    id = string
  }))
  default = {}
}

variable "application_gateways" {
  description = "Application Gateways to alert on, keyed by logical name."
  type = map(object({
    id = string
  }))
  default = {}
}

variable "critical_action_group_id" {
  description = "Action group for Sev0/Sev1 alerts (on-call)."
  type        = string
}

variable "platform_action_group_id" {
  description = "Action group for Sev2/Sev3 alerts (platform team)."
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
