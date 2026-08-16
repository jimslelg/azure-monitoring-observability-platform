variable "resource_group_name" {
  description = "Resource group the alert rules are created in."
  type        = string
}

variable "location" {
  description = "Azure region for scheduled query rules (metric alerts are global)."
  type        = string
}

variable "metric_alerts" {
  description = "Metric alert rules keyed by rule name."
  type = map(object({
    scopes           = list(string)
    description      = string
    severity         = number
    metric_namespace = string
    metric_name      = string
    aggregation      = string
    operator         = string
    threshold        = number
    frequency        = optional(string, "PT5M")
    window_size      = optional(string, "PT15M")
    enabled          = optional(bool, true)
    dimensions = optional(list(object({
      name     = string
      operator = string
      values   = list(string)
    })), [])
    action_group_ids = list(string)
  }))
  default = {}
}

variable "query_alerts" {
  description = "Log (KQL) alert rules keyed by rule name."
  type = map(object({
    scopes                  = list(string)
    description             = string
    severity                = number
    query                   = string
    time_aggregation_method = string
    operator                = string
    threshold               = number
    metric_measure_column   = optional(string)
    resource_id_column      = optional(string)
    evaluation_frequency    = optional(string, "PT5M")
    window_duration         = optional(string, "PT15M")
    minimum_failing_periods = optional(number, 1)
    evaluation_periods      = optional(number, 1)
    enabled                 = optional(bool, true)
    action_group_ids        = list(string)
  }))
  default = {}
}

variable "tags" {
  description = "Tags applied to all alert rules."
  type        = map(string)
  default     = {}
}
