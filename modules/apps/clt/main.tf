variable "cluster_path" {
  type = string
}

locals {
  cluster_container_path = "/cluster"
  image                  = "docker:25.0.0-rc.1-cli"
  cluster_path           = abspath(var.cluster_path)

  command           = var.command
  configs           = var.configs
  environment       = var.environment
  name              = var.name
  networks          = var.networks
  ports             = var.ports
  restart           = var.restart
  stop_grace_period = "1s"
  volumes = [
    "${local.cluster_path}:${local.cluster_container_path}",
    "/var/run/docker.sock:/var/run/docker.sock"
  ]
  entrypoint  = ["tail", "-f", "/dev/null"]
  working_dir = local.cluster_container_path
  healthcheck = {
    test : ["CMD", "docker", "ps"]
    interval : "1s"
    timeout : "5s"
    retries : 5
  }

  docker_compose_version = "3.8"
  docker_compose_path    = "${local.cluster_path}/docker-compose.yml"
  docker_compose_content = yamlencode({
    version : local.docker_compose_version,
    services : {
      (local.name) : {
        for attr, value in local.data :
        attr => value if(attr != "name" && attr != "configs")
      }
    }
  })

  cmd_start     = "docker-compose up -d --remove-orphans"
  cmd_update    = "docker-compose up -d --remove-orphans"
  cmd_stop      = "docker compose down"
  cmd_deploy_fn = abspath("${local.cluster_path}/deploy.sh")
}

resource "local_file" "docker_compose" {
  filename = local.docker_compose_path
  content  = <<-EOT
    # Generated by "${path.module}" module; DO NOT EDIT.
    # Make changes to the template in "${path.module}" module
    # Make changes to the template in "${path.module}" module

    ${local.docker_compose_content}
  EOT
}

resource "local_file" "deployment_script" {
  content  = <<-EOT
    #!/usr/bin/env bash

    # Generated by "${path.module}" module; DO NOT EDIT.
    # Make changes to the template in "${path.module}" module

    set -euo pipefail

    docker_compose_path="${local.docker_compose_path}"
    cluster_id=""
    while [ -z "$cluster_id" ]; do
      sleep 1
      cluster_id=$(
        docker compose -f "$docker_compose_path" ps \
          | awk '{print($1)}' \
          | grep -v 'NAME'
      )
    done

    docker exec "$cluster_id" sh -c "$*"
  EOT
  filename = local.cmd_deploy_fn
}

output "path" {
  value = abspath(local.cluster_path)
}

output "cmd_start" {
  value = local.cmd_start
}

output "cmd_update" {
  value = local.cmd_update
}

output "cmd_stop" {
  value = local.cmd_stop
}

output "cmd_deploy_fn" {
  value = local.cmd_deploy_fn
}
