
# PRACTICA 2 - AUTOMATIZACION CON TERRAFORM
# Todos los comandos se ejecutan desde la raiz del proyecto.

.PHONY: help fmt init-dev init-prod validate-dev validate-prod
.PHONY: plan-dev plan-prod up-dev up-prod status-dev status-prod
.PHONY: check-dev check-prod down-dev down-prod

# Menu de ayuda.
help:
	@echo "======================================"
	@echo " PRACTICA 2 - TERRAFORM Y DOCKER"
	@echo "======================================"
	@echo "make fmt           Formatear Terraform"
	@echo "make init-dev      Inicializar DEV"
	@echo "make init-prod     Inicializar PROD"
	@echo "make validate-dev  Validar DEV"
	@echo "make validate-prod Validar PROD"
	@echo "make plan-dev      Comprobar plan DEV"
	@echo "make plan-prod     Comprobar plan PROD"
	@echo "make up-dev        Desplegar DEV"
	@echo "make up-prod       Desplegar PROD"
	@echo "make status-dev    Estado de DEV"
	@echo "make status-prod   Estado de PROD"
	@echo "make check-dev     Comprobar Flask DEV"
	@echo "make check-prod    Comprobar Flask PROD"
	@echo "make down-dev      Destruir DEV"
	@echo "make down-prod     Destruir PROD"

# Formatea los archivos Terraform.
fmt:
	terraform fmt -recursive

# Inicializa los proveedores y modulos.
init-dev:
	terraform -chdir=environments/dev init

init-prod:
	terraform -chdir=environments/prod init

# Valida cada entorno.
validate-dev:
	terraform -chdir=environments/dev validate

validate-prod:
	terraform -chdir=environments/prod validate

# Muestra los cambios antes de aplicarlos.
plan-dev:
	terraform -chdir=environments/dev plan

plan-prod:
	terraform -chdir=environments/prod plan

# Despliega los recursos con Terraform.
up-dev:
	terraform -chdir=environments/dev apply

up-prod:
	terraform -chdir=environments/prod apply

# Consulta las salidas y los contenedores Docker.
status-dev:
	terraform -chdir=environments/dev output
	docker ps -a --filter name=practica2-dev

status-prod:
	terraform -chdir=environments/prod output
	docker ps -a --filter name=practica2-prod

# Comprueba las instancias web de desarrollo.
check-dev:
	curl -fsS http://localhost:5101/status
	@echo ""
	curl -fsS http://localhost:5102/status
	@echo ""

# Comprueba las instancias web de produccion.
check-prod:
	curl -fsS http://localhost:5201/status
	@echo ""
	curl -fsS http://localhost:5202/status
	@echo ""
	curl -fsS http://localhost:5203/status
	@echo ""

# Destruccion controlada.
# El volumen de MySQL esta protegido con prevent_destroy,
# por lo que un destroy completo no se ejecutara sin
# revisar primero esa proteccion y los datos guardados.
down-dev:
	terraform -chdir=environments/dev destroy

down-prod:
	terraform -chdir=environments/prod destroy
