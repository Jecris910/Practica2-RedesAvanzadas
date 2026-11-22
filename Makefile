
# PRACTICA 2 - AUTOMATIZACION TERRAFORM
# Ejecutar desde la raiz del proyecto.

.PHONY: help init-dev init-prod fmt validate-dev validate-prod plan-dev plan-prod

help:
	@echo "====================================="
	@echo " PRACTICA 2 - COMANDOS"
	@echo "====================================="
	@echo "make init-dev       Inicializar DEV"
	@echo "make init-prod      Inicializar PROD"
	@echo "make fmt            Formatear Terraform"
	@echo "make validate-dev   Validar DEV"
	@echo "make validate-prod  Validar PROD"
	@echo "make plan-dev       Ver plan de DEV"
	@echo "make plan-prod      Ver plan de PROD"

# Inicializa cada entorno de forma independiente.
init-dev:
	terraform -chdir=environments/dev init

init-prod:
	terraform -chdir=environments/prod init

# Aplica formato a todos los archivos Terraform.
fmt:
	terraform fmt -recursive

# Comprueba la validez de las configuraciones.
validate-dev:
	terraform -chdir=environments/dev validate

validate-prod:
	terraform -chdir=environments/prod validate

# Muestra los cambios previstos sin aplicarlos.
plan-dev:
	terraform -chdir=environments/dev plan

plan-prod:
	terraform -chdir=environments/prod plan