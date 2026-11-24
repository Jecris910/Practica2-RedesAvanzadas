# ENTORNO DE MONITORIZACION
# Independiente de DEV y PROD.

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "4.6.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
}

provider "docker" {}

module "monitoring" {
  source = "../../modules/monitoring"
}
# ============================================================
# PROMETHEUS
# Recoge las metricas de cAdvisor cada 15 segundos.
# ============================================================

resource "docker_image" "prometheus" {
  name         = "prom/prometheus:v3.16.0"
  keep_locally = true
}

resource "docker_volume" "prometheus_data" {
  name = "practica2-prometheus-data"
}

resource "docker_container" "prometheus" {
  name    = "practica2-prometheus"
  image   = docker_image.prometheus.image_id
  restart = "unless-stopped"

  network_mode = "host"

  command = [
    "--config.file=/etc/prometheus/prometheus.yml",
    "--storage.tsdb.path=/prometheus",
    "--storage.tsdb.retention.time=2d",
    "--storage.tsdb.retention.size=300MB",
    "--web.listen-address=127.0.0.1:8400"
  ]


  healthcheck {
    test         = ["CMD", "wget", "-q", "-O", "/dev/null", "http://127.0.0.1:8400/-/ready"]
    interval     = "30s"
    timeout      = "5s"
    retries      = 3
    start_period = "1m0s"
  }

  volumes {
    host_path      = abspath("${path.module}/prometheus.yml")
    container_path = "/etc/prometheus/prometheus.yml"
    read_only      = true
  }

  volumes {
    volume_name    = docker_volume.prometheus_data.name
    container_path = "/prometheus"
  }
}

# ============================================================
# GRAFANA
# Visualizacion de metricas de DEV y PROD.
# ============================================================

resource "docker_image" "grafana" {
  name         = "grafana/grafana:13.3.0"
  keep_locally = true
}

# Volumen persistente para dashboards y configuraciones.
resource "docker_volume" "grafana_data" {
  name = "practica2-grafana-data"
}

resource "docker_container" "grafana" {
  name    = "practica2-grafana"
  image   = docker_image.grafana.image_id
  restart = "unless-stopped"

  # Comparte la red del anfitrion para acceder
  # a Prometheus mediante localhost:8400.
  network_mode = "host"

  # Solo accesible desde la maquina Ubuntu.
  env = [
    "GF_SMTP_ENABLED=true",
    "GF_SMTP_HOST=127.0.0.1:1025",
    "GF_SMTP_FROM_ADDRESS=alertas@practica2.local",
    "GF_SMTP_FROM_NAME=Monitorizacion Practica2",
    "GF_SMTP_STARTTLS_POLICY=NoStartTLS",
    "GF_SERVER_HTTP_ADDR=127.0.0.1",
    "GF_SERVER_HTTP_PORT=8500",
    "GF_AUTH_ANONYMOUS_ENABLED=false"
  ]

  # Conserva dashboards, usuarios y configuraciones.

  healthcheck {
    test         = ["CMD", "curl", "-fsS", "http://127.0.0.1:8500/api/health"]
    interval     = "30s"
    timeout      = "5s"
    retries      = 3
    start_period = "1m0s"
  }

  volumes {
    volume_name    = docker_volume.grafana_data.name
    container_path = "/var/lib/grafana"
  }

}