
# Informacion del entorno desplegado.

# Nombre del entorno.
output "environment" {
  description = "Entorno de despliegue"
  value       = var.environment
}

# Numero de replicas Flask configuradas.
output "web_replicas_configured" {
  description = "Cantidad de replicas web"
  value       = var.web_replicas
}

# Nombre de la red Docker.
output "docker_network_name" {
  description = "Red interna del entorno"
  value       = module.network.network_name
}

# Contenedor MySQL.
output "mysql_container_name" {
  description = "Nombre del contenedor MySQL"
  value       = module.database.container_name
}

# Volumen persistente de MySQL.
output "mysql_volume_name" {
  description = "Volumen donde se almacenan los datos"
  value       = module.database.volume_name
}

# Contenedor Redis.
output "redis_container_name" {
  description = "Nombre del contenedor Redis"
  value       = module.cache.container_name
}

# Lista de instancias Flask.
output "flask_container_names" {
  description = "Instancias de la aplicacion web"
  value       = module.web.container_names
}
