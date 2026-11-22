
# PRACTICA 2 - REDES AVANZADAS
# Automatizacion de despliegue, validacion y pruebas con Terraform.
# Ejecutar todos los comandos desde la raiz del proyecto.
#
# NOTA: Las recetas de Makefile deben comenzar con TABULACIONES.

.PHONY: help fmt init-dev init-prod validate-dev validate-prod
.PHONY: plan-dev plan-prod up-dev up-prod up-all
.PHONY: status status-dev status-prod
.PHONY: check check-dev check-prod
.PHONY: balance-dev balance-prod demo
.PHONY: logs-dev logs-prod down-dev down-prod

# MENU PRINCIPAL
help:
	@echo "=============================================="
	@echo " PRACTICA 2 - TERRAFORM + DOCKER"
	@echo "=============================================="
	@echo "make init-dev       Inicializar Terraform DEV"
	@echo "make init-prod      Inicializar Terraform PROD"
	@echo "make fmt            Formatear archivos Terraform"
	@echo "make validate-dev   Validar DEV"
	@echo "make validate-prod  Validar PROD"
	@echo "make plan-dev       Ver cambios de DEV"
	@echo "make plan-prod      Ver cambios de PROD"
	@echo "make up-dev         Desplegar DEV"
	@echo "make up-prod        Desplegar PROD"
	@echo "make up-all         Desplegar ambos entornos"
	@echo "make status         Mostrar todos los contenedores"
	@echo "make status-dev     Ver estado DEV"
	@echo "make status-prod    Ver estado PROD"
	@echo "make check          Verificar DEV y PROD"
	@echo "make check-dev      Verificar servicios de DEV"
	@echo "make check-prod     Verificar servicios de PROD"
	@echo "make balance-dev    Demostrar Round Robin DEV"
	@echo "make balance-prod   Demostrar Round Robin PROD"
	@echo "make demo           Ejecutar pruebas de demostracion"
	@echo "make logs-dev       Consultar logs Nginx DEV"
	@echo "make logs-prod      Consultar logs Nginx PROD"
	@echo "make down-dev       Destruir DEV (datos protegidos)"
	@echo "make down-prod      Destruir PROD (datos protegidos)"

# FORMATO E INICIALIZACION
fmt:
	terraform fmt -recursive

init-dev:
	terraform -chdir=environments/dev init

init-prod:
	terraform -chdir=environments/prod init

# VALIDACION
validate-dev:
	terraform -chdir=environments/dev validate

validate-prod:
	terraform -chdir=environments/prod validate

# PLANIFICACION
plan-dev:
	terraform -chdir=environments/dev plan

plan-prod:
	terraform -chdir=environments/prod plan

# DESPLIEGUE
up-dev:
	terraform -chdir=environments/dev apply

up-prod:
	terraform -chdir=environments/prod apply

up-all: up-dev up-prod

# ESTADO DE CONTENEDORES
status:
	docker ps -a --filter "name=practica2"

status-dev:
	terraform -chdir=environments/dev output
	docker ps -a --filter "name=practica2-dev"

status-prod:
	terraform -chdir=environments/prod output
	docker ps -a --filter "name=practica2-prod"

# COMPROBACIONES A TRAVES DE NGINX
check-dev:
	@echo "=== DEV - Nginx puerto 8100 ==="
	curl -fsS http://localhost:8100/status
	@echo ""

check-prod:
	@echo "=== PROD - Nginx puerto 8200 ==="
	curl -fsS http://localhost:8200/status
	@echo ""

check: check-dev check-prod

# PRUEBAS DE BALANCEO ROUND ROBIN
# Identifica la replica que ha respondido a cada solicitud.
balance-dev:
	@echo "=== ROUND ROBIN DEV - 10 PETICIONES ==="
	@for i in $$(seq 1 10); do \
		curl -fsS http://localhost:8100/status | \
		python3 -c 'import json,sys; print(json.load(sys.stdin)["instance"])' || exit 1; \
	done

balance-prod:
	@echo "=== ROUND ROBIN PROD - 12 PETICIONES ==="
	@for i in $$(seq 1 12); do \
		curl -fsS http://localhost:8200/status | \
		python3 -c 'import json,sys; print(json.load(sys.stdin)["instance"])' || exit 1; \
	done

# DEMOSTRACION SIN PARAR NINGUN CONTENEDOR
demo: status check balance-dev balance-prod
	@echo "=============================================="
	@echo " Demostracion automatica completada"
	@echo "=============================================="

# LOGS DE LOS BALANCEADORES
logs-dev:
	docker logs --tail 50 practica2-dev-nginx

logs-prod:
	docker logs --tail 50 practica2-prod-nginx

# DESTRUCCION CONTROLADA
# El volumen MySQL utiliza prevent_destroy.
# Terraform impedira destruirlo sin revisar esa proteccion.
# No utilizar estas opciones durante la demostracion.
down-dev:
	terraform -chdir=environments/dev destroy

down-prod:
	terraform -chdir=environments/prod destroy
