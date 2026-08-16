variable "name" {
  description = "Name of the Log Analytics workspace."
  type        = string
}

variable "location" {
  description = "Azure region for the workspace."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group the workspace is created in."
  type        = string
}

variable "sku" {
  description = "Workspace SKU. PerGB2018 is the only SKU available to new workspaces."
  type        = string
  default     = "PerGB2018"
}

variable "retention_in_days" {
  description = "Interactive retention in days (30-730)."
  type        = number
  default     = 90

  validation {
    condition     = var.retention_in_days >= 30 && var.retention_in_days <= 730
    error_message = "retention_in_days must be between 30 and 730."
  }
}

variable "daily_quota_gb" {
  description = "Daily ingestion cap in GB. -1 disables the cap; keep a cap in non-production to bound cost."
  type        = number
  default     = -1
}

variable "internet_ingestion_enabled" {
  description = "Whether ingestion over the public internet is allowed. Disable when using AMPLS."
  type        = bool
  default     = true
}

variable "internet_query_enabled" {
  description = "Whether queries over the public internet are allowed. Disable when using AMPLS."
  type        = bool
  default     = true
}

variable "saved_searches" {
  description = "Saved searches to provision, keyed by search name."
  type = map(object({
    category     = string
    display_name = string
    query        = string
  }))
  default = {}
}

variable "tags" {
  description = "Tags applied to the workspace."
  type        = map(string)
  default     = {}
}
