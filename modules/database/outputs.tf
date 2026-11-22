
output "container_name" {
  description = "Nombre del contenedor MySQL"
  value       = docker_container.mysql.name
}

output "volume_name" {
  description = "Volumen persistente de MySQL"
  value       = docker_volume.data.name
}

output "app_password" {
  description = "Credencial para Flask"
  value       = random_password.app.result
  sensitive   = true
}
