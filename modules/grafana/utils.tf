locals {
  grafana_network = "grafana"

  mount_name = {
    loki_config       = "loki.yml"
    prometheus_config = "prometheus.yml"
    prometheus_data   = "prometheus/data"
    promtail_config   = "promtail.yml"
    promtail_log      = "promtail/log"
  }
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
  ports    = [{ host_port : 9100, container_port : 9100 }]
  restart  = "unless-stopped"
  volumes = [
    { abs_host_path : "/", container_path : "/rootfs:ro" },
    { abs_host_path : "/proc", container_path : "/host/proc:ro" },
    { abs_host_path : "/sys", container_path : "/host/sys:ro" },
  ]
}

locals {
  prometheus_internal_config_path = "/etc/prometheus/prometheus.yml"
  prometheus_internal_data_path   = "/prometheus"
  prometheus_exposed_port         = 9090
}

module "prometheus" {
  source = "../apps/scroach"
  image  = "prom/prometheus:v2.49.0-rc.2"
  name   = "prometheus"

  command = [
    "--config.file=${local.prometheus_internal_config_path}",
    "--storage.tsdb.path=${local.prometheus_internal_data_path}",
    "--web.console.libraries=/etc/prometheus/console_libraries",
    "--web.console.templates=/etc/prometheus/consoles",
    "--web.enable-lifecycle",
  ]
  configs = [
    {
      config_file = local.mount_name.prometheus_config
      destination = local.prometheus_internal_config_path
      args = {
        node_exporter_url  = module.node_exporter.name
        node_exporter_port = element(module.node_exporter.ports, 0).host_port
      }
    },
  ]
  networks = [local.grafana_network]
  ports    = [{ host_port : local.prometheus_exposed_port, container_port : 9090 }]
  volumes  = [{ mount_name : local.mount_name.prometheus_data, container_path : local.prometheus_internal_data_path }]
}

resource "grafana_data_source" "prometheus" {
  type   = "prometheus"
  name   = "prometheus"
  org_id = grafana_organization.org.id
  url    = "http://host.docker.internal:${local.prometheus_exposed_port}"
}

resource "grafana_folder" "system_metrics" {
  depends_on = [grafana_organization.org]
  title      = "System Metrics"
  org_id     = grafana_organization.org.id
}

resource "grafana_dashboard" "node_exporter_full" {
  count       = var.enable_dashboard_node_exporter ? 1 : 0
  depends_on  = [grafana_folder.system_metrics, grafana_data_source.prometheus]
  folder      = grafana_folder.system_metrics.id
  org_id      = grafana_folder.system_metrics.org_id
  config_json = file("${path.module}/dashboards/node-exporter-full.json")
}

locals {
  loki_internal_config_path = "/etc/loki/local-config.yaml"
}

module "loki" {
  source = "../apps/scroach"
  image  = "grafana/loki:2.3.0"
  name   = "loki"

  command = ["-config.file=${local.loki_internal_config_path}"]
  configs = [
    {
      config_file = local.mount_name.loki_config
      destination = local.loki_internal_config_path
    },
  ]
  networks = [local.grafana_network]
  ports    = [{ host_port : 3100, container_port : 3100 }]
}

locals {
  promtail_internal_config_path = "/etc/promtail/config.yml"
}

module "promtail" {
  source = "../apps/scroach"
  image  = "grafana/promtail:2.3.0"
  name   = "promtail"

  command = ["-config.file=${local.promtail_internal_config_path}"]
  configs = [
    {
      config_file = local.mount_name.promtail_config
      destination = local.promtail_internal_config_path
    },
  ]
  networks = [local.grafana_network]
  volumes  = [{ mount_name : local.mount_name.promtail_log, container_path : "/var/log" }]
}
