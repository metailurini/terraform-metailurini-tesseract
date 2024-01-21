locals {
  postgres_password = "secret"
}

module "postgres" {
  source = "../modules/apps/postgres"

  name          = "postgres"
  init_password = local.postgres_password
  ports = [
    {
      host_port : 5432,
      container_port : 5432
    }
  ]
}

module "cluster" {
  source = "../modules/apps/clt"

  name         = "clt"
  cluster_path = "./cluster"
}

module "grafana" {
  source = "../modules/grafana"
  enable_dashboard_postgres_exporter = {
    enabled = true
    dsn     = "postgresql://postgres:${local.postgres_password}@host.docker.internal:5432/postgres"
  }
}

module "build" {
  source = "../modules/apps/builder"

  namespace = "mycloud"
  cluster   = module.cluster
  services = concat(
    [module.postgres.data],
    values(module.grafana.grafana_services),
    values(module.grafana.utils_services),
  )
}