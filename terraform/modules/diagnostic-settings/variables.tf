variable "targets" {
  description = "Resources to attach diagnostic settings to, keyed by a stable logical name."
  type = map(object({
    resource_id         = string
    log_category_groups = optional(list(string), ["allLogs"])
    log_categories      = optional(list(string), [])
    metrics_enabled     = optional(bool, true)
  }))
  default = {}
}

variable "log_analytics_workspace_id" {
  description = "Central Log Analytics workspace all diagnostics route to."
  type        = string
}

variable "setting_name" {
  description = "Name of the diagnostic setting on each resource. Keep constant so re-runs are idempotent."
  type        = string
  default     = "diag-to-central-law"
}
