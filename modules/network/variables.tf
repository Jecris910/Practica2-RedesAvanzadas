# Nombre de la red que creara Docker.
# Lo recibimos desde DEV o PROD para reutilizar
# el mismo modulo sin duplicar codigo.

variable "network_name" {
  description = "Nombre de la red Docker del entorno"
  type        = string
}