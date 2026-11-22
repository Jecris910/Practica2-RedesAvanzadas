
# Nombre del entorno.
variable "environment" {
  description = "Nombre del entorno de despliegue"
  type        = string
}

# Numero de instancias de Flask que se desplegaran.
variable "web_replicas" {
  description = "Cantidad de instancias de la aplicacion web"
  type        = number

  validation {
    condition     = var.web_replicas >= 1
    error_message = "Debe configurarse al menos una instancia web."
  }
}