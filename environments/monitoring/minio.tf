# ==================================================
# MINIO - Almacenamiento de objetos compatible con S3
# ==================================================

resource "random_password" "minio_root" {
  length  = 24
  special = false
}

resource "docker_image" "minio" {
  name         = "cgr.dev/chainguard/minio:latest"
  keep_locally = true
}

resource "docker_volume" "minio_data" {
  name = "practica2-minio-data"

  lifecycle {
    prevent_destroy = true
  }
}

resource "docker_container" "minio" {
  name    = "practica2-minio"
  image   = docker_image.minio.image_id
  restart = "unless-stopped"

  # Acceso interno desde ambos entornos.
  networks_advanced {
    name = "practica2-dev-network"
  }

  networks_advanced {
    name = "practica2-prod-network"
  }

  # Acceso desde Ubuntu, sin exposicion exterior.
  ports {
    internal = 8800
    external = 8800
    ip       = "127.0.0.1"
  }

  ports {
    internal = 8801
    external = 8801
    ip       = "127.0.0.1"
  }


  command = [
    "server",
    "/data",
    "--address", ":8800",
    "--console-address", ":8801"
  ]

  env = [
    "MINIO_ROOT_USER=practica2admin",
    "MINIO_ROOT_PASSWORD=${random_password.minio_root.result}"
  ]

  volumes {
    volume_name    = docker_volume.minio_data.name
    container_path = "/data"
  }
}

output "minio_console_url" {
  value = "http://127.0.0.1:8801"
}

output "minio_username" {
  value = "practica2admin"
}

output "minio_password" {
  value     = random_password.minio_root.result
  sensitive = true
}
