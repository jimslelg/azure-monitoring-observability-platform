variable "monitored_aks_clusters" {
  description = "AKS clusters to onboard to Container Insights and managed Prometheus."
  type = map(object({
    id = string
  }))
  default = {}
}

variable "grafana_enabled" {
  description = "Provision Azure Managed Grafana. Disable in environments that reuse a shared instance."
  type        = bool
  default     = true
}

variable "grafana_admin_object_ids" {
  description = "Entra object IDs granted Grafana Admin on the instance."
  type        = list(string)
  default     = []
}
