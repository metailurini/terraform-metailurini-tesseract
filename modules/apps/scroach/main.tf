variable "image" {
  type        = string
  description = "The image to use for the container"
}

locals {
  command           = var.command
  entrypoint        = var.entrypoint
  environment       = var.environment
  image             = var.image
  name              = var.name
  networks          = var.networks
  ports             = var.ports
  restart           = var.restart
  stop_grace_period = var.stop_grace_period
  volumes           = var.volumes
  working_dir       = var.working_dir
  healthcheck       = var.healthcheck

  configs = [
    for config in var.configs : {
      config_file = config.config_file
      destination = config.destination
      content = templatefile(
        "${path.module}/configurations/${config.config_file}.tftpl",
        config.args != null ? config.args : {},
      )
    }
  ]
}