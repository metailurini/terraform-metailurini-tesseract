variable "org_name" {
  type        = string
  default     = "grafana"
  description = "Name of the Grafana organization"
}

variable "admin_user" {
  type        = string
  default     = "admin"
  description = "Name of the Grafana admin user"
}

variable "admin_password" {
  type        = string
  default     = "admin"
  description = "Password of the Grafana admin user"
}

variable "enable_dashboard_node_exporter" {
  type        = bool
  default     = true
  description = "Enable the full node exporter dashboard"
}

