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

variable "enable_dashboard_postgres_exporter" {
  type = object({
    enabled = bool
    dsn     = string
  })
  default = {
    enabled = true
    dsn     = ""
  }
  description = "Enable the full postgres exporter dashboard"
  validation {
    condition     = var.enable_dashboard_postgres_exporter.enabled == true && length(var.enable_dashboard_postgres_exporter.dsn) > 0
    error_message = "Postgres exporter dashboard enabled but no DSN provided, please provide a DSN or disable the dashboard"
  }
}

