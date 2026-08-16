variable "prefix" {
  description = "Naming prefix (e.g. amop-prod)."
  type        = string
}

variable "location" {
  description = "Azure region for DCRs and query alert rules."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for DCRs and alert rules."
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of the central Log Analytics workspace."
  type        = string
}

variable "virtual_machines" {
  description = "VMs to monitor, keyed by logical name. os_type is 'linux' or 'windows'."
  type = map(object({
    id      = string
    os_type = string
  }))
  default = {}

  validation {
    condition     = alltrue([for v in var.virtual_machines : contains(["linux", "windows"], lower(v.os_type))])
    error_message = "os_type must be 'linux' or 'windows'."
  }
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
