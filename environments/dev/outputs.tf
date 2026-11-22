
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