
output "container_name" {
  description = "Nombre del contenedor Redis"
  value       = docker_container.redis.name
}
