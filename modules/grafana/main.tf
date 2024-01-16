terraform {
  required_providers {
    grafana = { source = "grafana/grafana", version = "2.8.1" }
    shell   = { source = "scottwinkler/shell", version = "1.7.10" }
  }
}

provider "grafana" {
  url  = "http://localhost:${local.grafana_exposed_port}"
  auth = "${var.admin_user}:${var.admin_password}"
}

locals {
  grafana_exposed_port = 3000
}

resource "grafana_organization" "org" {
  name = var.org_name
}

module "grafana" {
  source = "../apps/scroach"
  image  = "grafana/grafana:9.4.3"
  name   = "grafana"

  networks = [local.grafana_network]
  ports    = [{ host_port : local.grafana_exposed_port, container_port : 3000 }]
  environment = {
    GF_SECURITY_ADMIN_USER     = var.admin_user
    GF_SECURITY_ADMIN_PASSWORD = var.admin_password
  }
}