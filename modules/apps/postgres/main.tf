variable "init_password" {
  type        = string
  description = "Initial password for the postgres user"
}

locals {
  image = "postgres:14.1-alpine"

  command    = var.command
  configs    = var.configs
  entrypoint = var.entrypoint
  environment = merge(
    var.environment,
    { POSTGRES_PASSWORD = var.init_password }
  )
  healthcheck       = var.healthcheck
  name              = var.name
  networks          = var.networks
  ports             = var.ports
  restart           = var.restart
  stop_grace_period = var.stop_grace_period
  volumes           = var.volumes
  working_dir       = var.working_dir
}