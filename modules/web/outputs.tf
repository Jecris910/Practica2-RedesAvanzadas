
output "container_names" {
  description = "Nombres de las instancias Flask"
  value       = docker_container.flask[*].name
}
