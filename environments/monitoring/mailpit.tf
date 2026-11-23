resource "docker_image" "mailpit" {
  name         = "axllent/mailpit:v1.30.4"
  keep_locally = true
}

resource "docker_container" "mailpit" {
  name         = "practica2-mailpit"
  image        = docker_image.mailpit.image_id
  restart      = "unless-stopped"
  network_mode = "host"

  command = [
    "--smtp", "127.0.0.1:1025",
    "--listen", "127.0.0.1:8025"
  ]
}
