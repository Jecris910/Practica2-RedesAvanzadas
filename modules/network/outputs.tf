# Devuelve el nombre de la red creada.
# Otros modulos podran utilizarlo para conectar
# los contenedores Flask, MySQL y Redis.

output "network_name" {
  description = "Nombre de la red Docker creada"
  value       = docker_network.network.name
}