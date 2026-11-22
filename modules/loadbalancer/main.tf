
# MODULO LOADBALANCER
# Balanceador Nginx desplegado mediante Terraform.
# Round Robin y recuperacion ante fallo de una replica.

terraform {
  required_providers {
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
    "    server practica2-${var.environment}-flask-${i + 1}:5000 resolve max_fails=1 fail_timeout=5s;"
  ])

  # Configuracion Nginx a partir de una plantilla reutilizable.
  nginx_config = templatefile(
    "${path.module}/nginx.conf.tftpl",
    {
      upstream_servers = local.upstream_servers
    }
  )
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

  # Genera el archivo de configuracion dentro del contenedor.
  # No necesitamos Docker Compose ni archivos con contrasenas.
  command = [
    "/bin/sh",
    "-c",
    <<-EOT
      cat > /etc/nginx/conf.d/default.conf <<'NGINX_CONFIG'
      ${local.nginx_config}
      NGINX_CONFIG
      exec nginx -g 'daemon off;'
    EOT
  ]

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
