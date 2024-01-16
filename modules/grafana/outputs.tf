output "utils_services" {
  value = {
    loki     = module.loki.data,
    promtail = module.promtail.data,
  }
}

output "grafana_services" {
  value = {
    grafana       = module.grafana.data,
    prometheus    = module.prometheus.data,
    node_exporter = module.node_exporter.data,
  }
}
