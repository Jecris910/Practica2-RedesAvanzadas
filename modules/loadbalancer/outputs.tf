
# Nombre del contenedor Nginx.
output "container_name" {
  description = "Contenedor balanceador del entorno"
  value       = docker_container.nginx.name
}

# Puerto del balanceador.
output "external_port" {
  description = "Puerto HTTP publicado"
  value       = var.external_port
}
