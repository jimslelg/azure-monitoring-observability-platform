variable "project" {
  description = "Short project code used in resource names."
  type        = string
  default     = "amop"
}

variable "environment" {
  description = "Deployment environment (dev, prod)."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "location" {
  description = "Azure region for all monitoring resources."
  type        = string
  default     = "canadacentral"
}

variable "log_retention_in_days" {
  description = "Interactive retention for the central Log Analytics workspace."
  type        = number
  default     = 90
}

variable "log_daily_quota_gb" {
  description = "Daily ingestion cap for the workspace (-1 = uncapped)."
  type        = number
  default     = -1
}

variable "availability_tests" {
  description = "Application Insights standard web tests keyed by name."
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

variable "critical_email_receivers" {
  description = "Email receivers for the critical (on-call) action group."
  type = list(object({
    name          = string
    email_address = string
  }))
  default = []
}

variable "critical_sms_receivers" {
  description = "SMS receivers for the critical (on-call) action group."
  type = list(object({
    name         = string
    country_code = string
    phone_number = string
  }))
  default = []
}

variable "platform_email_receivers" {
  description = "Email receivers for the platform-team action group."
  type = list(object({
    name          = string
    email_address = string
  }))
  default = []
}

variable "info_email_receivers" {
  description = "Email receivers for the informational action group."
  type = list(object({
    name          = string
    email_address = string
  }))
  default = []
}

variable "info_webhook_receivers" {
  description = "Webhook receivers (e.g. ITSM/ticketing) for the informational action group."
  type = list(object({
    name        = string
    service_uri = string
  }))
  default = []
}

variable "tags" {
  description = "Extra tags merged onto every resource."
  type        = map(string)
  default     = {}
}
