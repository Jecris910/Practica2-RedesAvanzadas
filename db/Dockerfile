
# MySQL independiente de la Practica 2.
# La imagen incluye los datos iniciales de Inazuma Eleven.
FROM mysql:8.4

# Se ejecuta al crear una base de datos nueva.
COPY init.sql /docker-entrypoint-initdb.d/01-init.sql
