locals {
  grafana_network = "grafana"

  mount_name = {
    loki_config       = "loki.yml"
    prometheus_config = "prometheus.yml"
    prometheus_data   = "prometheus/data"
    promtail_config   = "promtail.yml"
    promtail_log      = "promtail/log"
  }

  config_path = {
    loki_config       = "/etc/loki/local-config.yaml"
    prometheus_config = "/etc/prometheus/prometheus.yml"
    promtail_config   = "/etc/promtail/config.yml"
  }

  exposed_port = {
    loki              = 3100
    node_exporter     = 9100
    postgres_exporter = 9187
    prometheus        = 9090
    promtail          = 9080
  }

  prometheus_internal_data_path = "/prometheus"
}

module "node_exporter" {
  source = "../apps/scroach"
  image  = "prom/node-exporter:v1.7.0"
  name   = "node-exporter"

  command = [
    "--path.procfs=/host/proc",
    "--path.rootfs=/rootfs",
    "--path.sysfs=/host/sys",
    "--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)",
  ]
  networks = [local.grafana_network]
  ports    = [{ host_port : local.exposed_port.node_exporter, container_port : 9100 }]
  restart  = "unless-stopped"
  volumes = [
    { abs_host_path : "/", container_path : "/rootfs:ro" },
    { abs_host_path : "/proc", container_path : "/host/proc:ro" },
    { abs_host_path : "/sys", container_path : "/host/sys:ro" },
  ]
}

module "postgres_exporter" {
  source = "../apps/scroach"
  image  = "prometheuscommunity/postgres-exporter:v0.14.0"
  name   = "postgres-exporter"

  environment = { DATA_SOURCE_NAME = var.enable_dashboard_postgres_exporter.dsn }
  networks    = [local.grafana_network]
  ports       = [{ host_port : local.exposed_port.postgres_exporter, container_port : 9187 }]
  restart     = "unless-stopped"
}

module "prometheus" {
  source = "../apps/scroach"
  image  = "prom/prometheus:v2.49.0-rc.2"
  name   = "prometheus"

  command = [
    "--config.file=${local.config_path.prometheus_config}",
    "--storage.tsdb.path=${local.prometheus_internal_data_path}",
    "--web.console.libraries=/etc/prometheus/console_libraries",
    "--web.console.templates=/etc/prometheus/consoles",
    "--web.enable-lifecycle",
  ]
  configs = [
    {
      config_file = local.mount_name.prometheus_config
      destination = local.config_path.prometheus_config
      args = {
        node_exporter_url  = module.node_exporter.name
        node_exporter_port = local.exposed_port.node_exporter

        postgres_exporter_url  = module.postgres_exporter.name
        postgres_exporter_port = local.exposed_port.postgres_exporter
      }
    },
  ]
  networks = [local.grafana_network]
  ports    = [{ host_port : local.exposed_port.prometheus, container_port : 9090 }]
  volumes  = [{ mount_name : local.mount_name.prometheus_data, container_path : local.prometheus_internal_data_path }]
}

resource "grafana_data_source" "prometheus" {
  type = "prometheus"
  name = "prometheus"
  url  = "http://host.docker.internal:${local.exposed_port.prometheus}"
}

resource "grafana_folder" "system_metrics" {
  title = "System Metrics"
}

resource "grafana_dashboard" "node_exporter_full" {
  count       = var.enable_dashboard_node_exporter ? 1 : 0
  depends_on  = [grafana_folder.system_metrics, grafana_data_source.prometheus]
  folder      = grafana_folder.system_metrics.id
  config_json = file("${path.module}/dashboards/node-exporter-full.json")
}

resource "grafana_dashboard" "postgres_exporter_full" {
  count       = var.enable_dashboard_postgres_exporter.enabled ? 1 : 0
  depends_on  = [grafana_folder.system_metrics, grafana_data_source.prometheus]
  folder      = grafana_folder.system_metrics.id
  config_json = file("${path.module}/dashboards/postgres-overview.json")
}

module "loki" {
  source = "../apps/scroach"
  image  = "grafana/loki:2.3.0"
  name   = "loki"

  command = ["-config.file=${local.config_path.loki_config}"]
  configs = [
    {
      config_file = local.mount_name.loki_config
      destination = local.config_path.loki_config
    },
  ]
  networks = [local.grafana_network]
  ports    = [{ host_port : local.exposed_port.loki, container_port : 3100 }]
}

module "promtail" {
  source = "../apps/scroach"
  image  = "grafana/promtail:2.3.0"
  name   = "promtail"

  command = ["-config.file=${local.config_path.promtail_config}"]
  configs = [
    {
      config_file = local.mount_name.promtail_config
      destination = local.config_path.promtail_config
    },
  ]
  networks = [local.grafana_network]
  volumes  = [{ mount_name : local.mount_name.promtail_log, container_path : "/var/log" }]
}
