
# ============================================================
# PRACTICA 2 - REDES AVANZADAS
# INFRAESTRUCTURA COMO CODIGO CON TERRAFORM Y DOCKER
# ============================================================
#
# Automatizacion de despliegue, validacion, pruebas y defensa.
#
# Entornos:
#   DEV  -> Nginx puerto 8100 -> 2 instancias Flask
#   PROD -> Nginx puerto 8200 -> 3 instancias Flask
#
# IMPORTANTE:
# - Ejecutar desde la raiz del proyecto.
# - Las recetas de Makefile deben usar TABULACIONES.
# - No usar Docker Swarm.
# - Los volumenes MySQL estan protegidos con prevent_destroy.
#
# ============================================================

SHELL := /bin/bash
.DEFAULT_GOAL := help

DEV_URL  := http://localhost:8100
PROD_URL := http://localhost:8200

.PHONY: help fmt init-dev init-prod init-all
.PHONY: validate-dev validate-prod validate-all
.PHONY: plan-dev plan-prod plan-all
.PHONY: up-dev up-prod up-all
.PHONY: status status-dev status-prod
.PHONY: check check-dev check-prod
.PHONY: balance-dev balance-prod
.PHONY: nginx-test logs-dev logs-prod
.PHONY: demo demo-ha
.PHONY: down-dev down-prod

# ============================================================
# 1. MENU DE AYUDA
# ============================================================

help:
	@echo ""
	@echo "=================================================="
	@echo " PRACTICA 2 - TERRAFORM Y DOCKER"
	@echo "=================================================="
	@echo ""
	@echo "CONFIGURACION:"
	@echo "  make fmt             Formatear Terraform"
	@echo "  make init-dev        Inicializar DEV"
	@echo "  make init-prod       Inicializar PROD"
	@echo "  make init-all        Inicializar ambos"
	@echo ""
	@echo "VALIDACION:"
	@echo "  make validate-dev    Validar DEV"
	@echo "  make validate-prod   Validar PROD"
	@echo "  make validate-all    Validar ambos"
	@echo "  make plan-dev        Ver plan DEV"
	@echo "  make plan-prod       Ver plan PROD"
	@echo "  make plan-all        Ver ambos planes"
	@echo ""
	@echo "DESPLIEGUE:"
	@echo "  make up-dev          Desplegar DEV"
	@echo "  make up-prod         Desplegar PROD"
	@echo "  make up-all          Desplegar ambos"
	@echo ""
	@echo "COMPROBACIONES:"
	@echo "  make status          Ver todos los contenedores"
	@echo "  make status-dev      Ver contenedores DEV"
	@echo "  make status-prod     Ver contenedores PROD"
	@echo "  make check           Comprobar DEV y PROD"
	@echo "  make check-dev       Comprobar DEV"
	@echo "  make check-prod      Comprobar PROD"
	@echo "  make balance-dev     Round Robin DEV"
	@echo "  make balance-prod    Round Robin PROD"
	@echo "  make nginx-test      Validar Nginx"
	@echo ""
	@echo "LOGS:"
	@echo "  make logs-dev        Logs de Nginx DEV"
	@echo "  make logs-prod       Logs de Nginx PROD"
	@echo ""
	@echo "DEFENSA:"
	@echo "  make demo            Demostracion interactiva"
	@echo "  make demo-ha         Prueba de alta disponibilidad"
	@echo ""
	@echo "MANTENIMIENTO:"
	@echo "  make down-dev        Destruir DEV (protegido)"
	@echo "  make down-prod       Destruir PROD (protegido)"
	@echo ""
	@echo "WEB DEV:  $(DEV_URL)"
	@echo "WEB PROD: $(PROD_URL)"
	@echo "=================================================="

# ============================================================
# 2. INICIALIZACION Y FORMATO
# ============================================================

fmt:
	terraform fmt -recursive

init-dev:
	terraform -chdir=environments/dev init

init-prod:
	terraform -chdir=environments/prod init

init-all: init-dev init-prod

# ============================================================
# 3. VALIDACIONES
# ============================================================

validate-dev:
	terraform -chdir=environments/dev validate

validate-prod:
	terraform -chdir=environments/prod validate

validate-all: validate-dev validate-prod

# ============================================================
# 4. PLANIFICACION
# ============================================================

plan-dev:
	terraform -chdir=environments/dev plan

plan-prod:
	terraform -chdir=environments/prod plan

plan-all: plan-dev plan-prod

# ============================================================
# 5. DESPLIEGUE
# ============================================================

up-dev:
	terraform -chdir=environments/dev apply

up-prod:
	terraform -chdir=environments/prod apply

up-all: up-dev up-prod

# ============================================================
# 6. ESTADO DE CONTENEDORES
# ============================================================

status:
	@echo ""
	@echo "===== CONTENEDORES DE LA PRACTICA 2 ====="
	docker ps -a --filter "name=practica2"

status-dev:
	@echo ""
	@echo "===== CONTENEDORES DEV ====="
	docker ps -a --filter "name=practica2-dev"

status-prod:
	@echo ""
	@echo "===== CONTENEDORES PROD ====="
	docker ps -a --filter "name=practica2-prod"

# ============================================================
# 7. COMPROBACION DE SERVICIOS
# ============================================================
#
# Accedemos a Flask a traves de Nginx.
# Los puertos individuales de Flask NO estan publicados.
#

check-dev:
	@echo ""
	@echo "===== COMPROBANDO DEV ====="
	curl -fsS $(DEV_URL)/status
	@echo ""

check-prod:
	@echo ""
	@echo "===== COMPROBANDO PROD ====="
	curl -fsS $(PROD_URL)/status
	@echo ""

check: check-dev check-prod

# ============================================================
# 8. PRUEBAS ROUND ROBIN
# ============================================================
#
# Muestra la instancia que responde a cada peticion.
# DEV: 10 peticiones entre 2 replicas.
# PROD: 12 peticiones entre 3 replicas.
#

balance-dev:
	@echo ""
	@echo "===== ROUND ROBIN DEV - 10 PETICIONES ====="
	@for i in $$(seq 1 10); do \
		curl -fsS $(DEV_URL)/status | \
		python3 -c 'import json,sys; print(json.load(sys.stdin)["instance"])' || exit 1; \
	done

balance-prod:
	@echo ""
	@echo "===== ROUND ROBIN PROD - 12 PETICIONES ====="
	@for i in $$(seq 1 12); do \
		curl -fsS $(PROD_URL)/status | \
		python3 -c 'import json,sys; print(json.load(sys.stdin)["instance"])' || exit 1; \
	done

# ============================================================
# 9. VALIDACION DE NGINX
# ============================================================

nginx-test:
	@echo ""
	@echo "===== VALIDANDO NGINX DEV ====="
	docker exec practica2-dev-nginx nginx -t
	@echo ""
	@echo "===== VALIDANDO NGINX PROD ====="
	docker exec practica2-prod-nginx nginx -t

# ============================================================
# 10. LOGS DE NGINX
# ============================================================

logs-dev:
	docker logs --tail 50 practica2-dev-nginx

logs-prod:
	docker logs --tail 50 practica2-prod-nginx

# ============================================================
# 11. DEMOSTRACION INTERACTIVA
# ============================================================
#
# El profesor puede ver cada prueba por separado.
# Solo se avanza cuando el alumno pulsa ENTER.
#
# Esta parte NO modifica la infraestructura.
#

demo:
	bash scripts/demo.sh

# ============================================================
# 12. DEMOSTRACION DE ALTA DISPONIBILIDAD
# ============================================================
#
# Detiene temporalmente Flask 2 de PROD.
# Comprueba que Nginx sigue sirviendo peticiones.
# Recupera Flask 2 aunque falle la prueba o se pulse Ctrl+C.
#
# No debe ejecutarse simultaneamente con terraform apply.
#

demo-ha:
	@set -euo pipefail; \
	container="practica2-prod-flask-2"; \
	stopped=0; \
	cleanup() { \
		if [ "$$stopped" -eq 1 ]; then \
			echo ""; \
			echo "Recuperando $$container..."; \
			docker start "$$container" >/dev/null || true; \
		fi; \
	}; \
	trap cleanup EXIT; \
	trap 'exit 130' INT; \
	trap 'exit 143' TERM; \
	echo ""; \
	echo "=================================================="; \
	echo " PRUEBA DE ALTA DISPONIBILIDAD - PROD"; \
	echo "=================================================="; \
	echo ""; \
	docker inspect -f '{{.State.Running}}' "$$container" | grep -qx true || { \
		echo "ERROR: Flask 2 no esta en ejecucion."; \
		exit 1; \
	}; \
	read -r -p 'Pulsa ENTER para detener Flask 2...' dummy; \
	docker stop "$$container"; \
	stopped=1; \
	echo ""; \
	echo "Flask 2 detenido. Nginx debe continuar respondiendo."; \
	read -r -p 'Pulsa ENTER para probar las replicas restantes...' dummy; \
	$(MAKE) --no-print-directory balance-prod; \
	echo ""; \
	echo "La aplicacion ha respondido sin Flask 2."; \
	read -r -p 'Pulsa ENTER para recuperar Flask 2...' dummy; \
	docker start "$$container"; \
	stopped=0; \
	echo ""; \
	docker ps -a --filter "name=practica2-prod"; \
	echo ""; \
	echo "=================================================="; \
	echo " PRUEBA DE ALTA DISPONIBILIDAD FINALIZADA"; \
	echo "=================================================="

# ============================================================
# 13. DESTRUCCION CONTROLADA
# ============================================================
#
# IMPORTANTE:
# Los volumenes MySQL estan protegidos con prevent_destroy.
# Estas reglas NO estan pensadas para la demostracion.
# Nunca eliminar los volumenes sin una copia de seguridad.
#

down-dev:
	terraform -chdir=environments/dev destroy

down-prod:
	terraform -chdir=environments/prod destroy

# ============================================================
# 14. MONITORIZACION Y ALMACENAMIENTO COMPARTIDO
# ============================================================

.PHONY: init-monitoring validate-monitoring plan-monitoring
.PHONY: up-monitoring init-minio check-minio reload-nginx
.PHONY: deploy-full check-full

init-monitoring:
	terraform -chdir=environments/monitoring init

validate-monitoring:
	terraform -chdir=environments/monitoring validate

plan-monitoring:
	terraform -chdir=environments/monitoring plan

up-monitoring:
	terraform -chdir=environments/monitoring apply

init-minio:
	bash scripts/init-minio.sh

reload-nginx:
	docker exec practica2-dev-nginx nginx -t
	docker exec practica2-prod-nginx nginx -t
	docker exec practica2-dev-nginx nginx -s reload
	docker exec practica2-prod-nginx nginx -s reload

check-minio:
	@echo "===== ALMACENAMIENTO DEV ====="
	curl -fsS $(DEV_URL)/storage/prueba.txt
	@echo ""
	@echo "===== ALMACENAMIENTO PROD ====="
	curl -fsS $(PROD_URL)/storage/prueba.txt
	@echo ""

deploy-full:
	$(MAKE) init-all
	$(MAKE) init-monitoring
	$(MAKE) validate-all
	$(MAKE) validate-monitoring
	$(MAKE) up-all
	$(MAKE) up-monitoring
	$(MAKE) init-minio
	$(MAKE) reload-nginx
	$(MAKE) check-full

check-full:
	$(MAKE) check
	$(MAKE) check-minio
	$(MAKE) nginx-test

# ============================================================
# 15. CONFIGURACION REPRODUCIBLE DE GRAFANA
# ============================================================

.PHONY: export-grafana restore-grafana

export-grafana:
	python3 scripts/export-grafana.py

restore-grafana:
	python3 scripts/restore-grafana.py --policies


# ============================================================
# 16. PRUEBAS CONTROLADAS DE ALERTAS
# ============================================================

.PHONY: alert-flask-dev alert-flask-prod
.PHONY: alert-nginx alert-mysql alert-redis

alert-flask-dev:
	bash scripts/demo-alertas.sh flask-dev

alert-flask-prod:
	bash scripts/demo-alertas.sh flask-prod

alert-nginx:
	bash scripts/demo-alertas.sh nginx

alert-mysql:
	bash scripts/demo-alertas.sh mysql

alert-redis:
	bash scripts/demo-alertas.sh redis

.PHONY: test-cache
test-cache:
	bash scripts/test-cache.sh

.PHONY: test-persistencia
test-persistencia:
	bash scripts/test-persistencia.sh

.PHONY: test-minio
test-minio:
	bash scripts/test-minio.sh

.PHONY: test-monitoring
test-monitoring:
	bash scripts/test-monitoring.sh

# Prueba de registros centralizados.
.PHONY: test-logs

test-logs:
	bash scripts/test-logs.sh
