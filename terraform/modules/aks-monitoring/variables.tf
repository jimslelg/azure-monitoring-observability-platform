variable "prefix" {
  description = "Naming prefix (e.g. amop-prod)."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for DCRs and alert rules."
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of the central Log Analytics workspace (Container Insights destination)."
  type        = string
}

variable "monitor_workspace_id" {
  description = "Resource ID of the Azure Monitor workspace (Prometheus destination)."
  type        = string
}

variable "data_collection_endpoint_id" {
  description = "Resource ID of the Prometheus data collection endpoint."
  type        = string
}

variable "aks_clusters" {
  description = "AKS clusters to monitor, keyed by logical name."
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

variable "info_action_group_id" {
  description = "Action group for informational (Sev4) signals."
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
