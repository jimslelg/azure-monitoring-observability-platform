variable "resource_group_name" {
  description = "Resource group the action groups are created in."
  type        = string
}

variable "action_groups" {
  description = <<-EOT
    Action groups keyed by name. Receivers all use the common alert schema so
    downstream integrations (webhooks, Logic Apps) parse one payload format
    regardless of which alert type fired.
  EOT
  type = map(object({
    short_name = string
    enabled    = optional(bool, true)
    email_receivers = optional(list(object({
      name          = string
      email_address = string
    })), [])
    sms_receivers = optional(list(object({
      name         = string
      country_code = string
      phone_number = string
    })), [])
    webhook_receivers = optional(list(object({
      name        = string
      service_uri = string
    })), [])
    logic_app_receivers = optional(list(object({
      name         = string
      resource_id  = string
      callback_url = string
    })), [])
  }))

  validation {
    condition     = alltrue([for k, v in var.action_groups : length(v.short_name) <= 12])
    error_message = "Action group short_name must be 12 characters or fewer (shown in SMS/email)."
  }
}

variable "tags" {
  description = "Tags applied to all action groups."
  type        = map(string)
  default     = {}
}
