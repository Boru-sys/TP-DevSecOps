# Provider Docker
terraform {
  required_version = ">= 1.6"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# Network
resource "docker_network" "monitoring" {
  name   = "monitoring-network"
  driver = "bridge"

  ipam_config {
    subnet  = "172.20.0.0/16"
    gateway = "172.20.0.1"
  }
}

# Volume pour Prometheus
resource "docker_volume" "prometheus_data" {
  name = "prometheus-data"
}

# Volume pour Grafana
resource "docker_volume" "grafana_data" {
  name = "grafana-data"
}

# Container Prometheus (Chainguard)
resource "docker_container" "prometheus" {
  name  = "prometheus"
  image = "cgr.dev/chainguard/prometheus:latest"

  networks_advanced {
    name = docker_network.monitoring.name
  }

  ports {
    internal = 9090
    external = 9090
  }

  volumes {
    volume_name    = docker_volume.prometheus_data.name
    container_path = "/prometheus"
  }

  volumes {
    host_path      = "${path.cwd}/../../monitoring/prometheus/prometheus.yml"
    container_path = "/etc/prometheus/prometheus.yml"
    read_only      = true
  }

  command = [
    "--config.file=/etc/prometheus/prometheus.yml",
    "--storage.tsdb.path=/prometheus",
    "--web.console.libraries=/usr/share/prometheus/console_libraries",
    "--web.console.templates=/usr/share/prometheus/consoles"
  ]

  restart = "unless-stopped"

  labels {
    label = "monitoring"
    value = "prometheus"
  }
}

# Container Grafana
resource "docker_container" "grafana" {
  name  = "grafana"
  image = "grafana/grafana:latest"

  networks_advanced {
    name = docker_network.monitoring.name
  }

  ports {
    internal = 3000
    external = 3000
  }

  volumes {
    volume_name    = docker_volume.grafana_data.name
    container_path = "/var/lib/grafana"
  }

  env = [
    "GF_SECURITY_ADMIN_USER=admin",
    "GF_SECURITY_ADMIN_PASSWORD=gitops2024",
    "GF_INSTALL_PLUGINS=grafana-piechart-panel"
  ]

  restart = "unless-stopped"

  labels {
    label = "monitoring"
    value = "grafana"
  }

  depends_on = [docker_container.prometheus]
}

# Container Jenkins
resource "docker_container" "jenkins" {
  name  = "jenkins"
  image = "jenkins/jenkins:lts"

  networks_advanced {
    name = docker_network.monitoring.name
  }

  ports {
    internal = 8080
    external = 8080
  }

  ports {
    internal = 50000
    external = 50000
  }

  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
  }

  volumes {
    host_path      = "${path.cwd}/../../jenkins_home"
    container_path = "/var/jenkins_home"
  }

  restart = "unless-stopped"

  labels {
    label = "ci"
    value = "jenkins"
  }
}

# Outputs
output "network_id" {
  value = docker_network.monitoring.id
}

output "prometheus_url" {
  value = "http://localhost:9090"
}

output "grafana_url" {
  value = "http://localhost:3000"
}

output "jenkins_url" {
  value = "http://localhost:8080"
}
