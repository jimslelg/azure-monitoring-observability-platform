variable "prefix" {
  description = "Naming prefix (e.g. amop-prod)."
  type        = string
}

variable "location" {
  description = "Azure region for query alert rules."
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

variable "app_services" {
  description = "App Services (web apps / function apps) to monitor, keyed by logical name."
  type = map(object({
    id = string
  }))
  default = {}
}

variable "app_service_plans" {
  description = "App Service plans to monitor, keyed by logical name."
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
