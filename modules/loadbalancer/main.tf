
# MODULO LOADBALANCER
# Balanceador Nginx desplegado mediante Terraform.
# Round Robin y recuperacion ante fallo de una replica.

terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "2.6.2"
    }

    docker = {
      source  = "kreuzwerker/docker"
      version = "4.6.0"
    }
  }
}

# Genera la lista de servidores Flask segun el entorno.
# DEV: 2 instancias. PROD: 3 instancias.
locals {
  upstream_servers = join("\n", [
    for i in range(var.replicas) :
    "    server practica2-${var.environment}-flask-${i + 1}:5000 resolve fail_timeout=5s;"
  ])

  # Configuracion Nginx a partir de una plantilla reutilizable.
  nginx_config = templatefile(
    "${path.module}/nginx.conf.tftpl",
    {
      upstream_servers = local.upstream_servers
    }
  )
}

# Genera un archivo independiente para cada entorno.
resource "local_file" "nginx_config" {
  content         = local.nginx_config
  filename        = abspath("${path.root}/generated/nginx.conf")
  file_permission = "0644"
}

# Imagen oficial de Nginx.
resource "docker_image" "nginx" {
  name         = "nginx:1.29-alpine"
  keep_locally = true
}

# Contenedor balanceador de carga.
resource "docker_container" "nginx" {
  name    = "practica2-${var.environment}-nginx"
  image   = docker_image.nginx.image_id
  restart = "unless-stopped"

  # Monta la configuracion generada por Terraform.
  volumes {
    host_path      = local_file.nginx_config.filename
    container_path = "/etc/nginx/conf.d/default.conf"
    read_only      = true
  }

  # Recrea Nginx cuando cambia su configuracion.
  lifecycle {
    replace_triggered_by = [local_file.nginx_config]
  }

  # Conexion con las instancias Flask de su entorno.
  networks_advanced {
    name = var.network_name
  }

  # Solo publicamos el puerto del balanceador.
  ports {
    internal = 80
    external = var.external_port
    ip       = "127.0.0.1"
  }

  # Verifica que Nginx puede servir /status.
  healthcheck {
    test = [
      "CMD-SHELL",
      "wget -q -O /dev/null http://127.0.0.1/status || exit 1"
    ]

    interval     = "30s"
    timeout      = "5s"
    retries      = 3
    start_period = "20s"
  }
}
