variable "name" {
  description = "Name of the Application Insights component."
  type        = string
}

variable "location" {
  description = "Azure region for the component."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group the component is created in."
  type        = string
}

variable "application_type" {
  description = "Application type ('web' for most workloads)."
  type        = string
  default     = "web"
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics workspace backing this component (workspace-based mode)."
  type        = string
}

variable "retention_in_days" {
  description = "Retention for classic tables; workspace-based data follows the workspace retention."
  type        = number
  default     = 90
}

variable "sampling_percentage" {
  description = "Ingestion sampling percentage. 100 = keep everything; lower in high-volume apps to bound cost."
  type        = number
  default     = 100
}

variable "availability_tests" {
  description = "Standard web tests keyed by test name."
  type = map(object({
    url                  = string
    geo_locations        = list(string)
    frequency_seconds    = optional(number, 300)
    timeout_seconds      = optional(number, 30)
    expected_status_code = optional(number, 200)
    ssl_check_enabled    = optional(bool, true)
  }))
  default = {}
}

variable "smart_detection_action_group_id" {
  description = "Action group ID for the Failure Anomalies smart detector. Null skips the rule."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
