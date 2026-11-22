
# Valores de configuracion del entorno.
# Todavia no representan contenedores desplegados.

output "environment" {
  description = "Entorno configurado"
  value       = var.environment
}

output "web_replicas_configured" {
  description = "Numero de replicas web solicitadas"
  value       = var.web_replicas
}

# Muestra el nombre de la red creada.
output "docker_network_name" {
  description = "Red Docker utilizada por este entorno"
  value       = module.network.network_name
}