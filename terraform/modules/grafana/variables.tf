variable "prefix" {
  description = "Naming prefix (e.g. amop-prod)."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for the Grafana instance."
  type        = string
}

variable "monitor_workspace_id" {
  description = "Azure Monitor workspace to integrate as the Prometheus datasource."
  type        = string
}

variable "monitoring_reader_scope" {
  description = "Scope for the Monitoring Reader role (usually the subscription)."
  type        = string
}

variable "grafana_major_version" {
  description = "Grafana major version."
  type        = string
  default     = "10"
}

variable "zone_redundancy_enabled" {
  description = "Zone redundancy for the Grafana instance (production)."
  type        = bool
  default     = false
}

variable "grafana_admin_object_ids" {
  description = "Entra object IDs granted Grafana Admin."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
