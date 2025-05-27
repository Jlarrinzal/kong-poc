#!/bin/bash

echo "🧹 Eliminando configuración previa..."

# Eliminar rutas y servicios existentes
curl -s -X DELETE http://localhost:8001/routes/guardar-token
curl -s -X DELETE http://localhost:8001/services/guardar-token-service
curl -s -X DELETE http://localhost:8001/routes/grafana3000-route
curl -s -X DELETE http://localhost:8001/services/grafana3000-service

echo "🛠️ Creando nueva ruta /guardar-token en local.grafana-poc..."

# Servicio dummy para ejecutar el plugin
curl -s -i -X POST http://localhost:8001/services \
  --data name=guardar-token-service \
  --data url=http://example.com

# Ruta para el subdominio local.grafana-poc con path /guardar-token
curl -s -i -X POST http://localhost:8001/services/guardar-token-service/routes \
  --data name=guardar-token \
  --data "hosts[]=local.grafana-poc.test" \
  --data "paths[]=/guardar-token" \
  --data strip_path=false

# Plugin Lua para leer el token y redirigir
curl -s -i -X POST http://localhost:8001/routes/guardar-token/plugins \
  --data name=pre-function \
  --data-urlencode "config.access[1]=$(< kong-plugins/set-cookie-redirect.lua)"

echo "🖥️ Registrando grafana-poc → localhost:3000..."

# Servicio que apunta al grafana local real
curl -s -i -X POST http://localhost:8001/services \
  --data name=grafana3000-service \
  --data url=http://host.docker.internal:4848

# Ruta para acceder vía grafana-poc
curl -s -i -X POST http://localhost:8001/routes \
  --data service.name=grafana3000-service \
  --data name=grafana3000-route \
  --data "hosts[]=grafana-poc.test"

echo "✅ Todo listo. Accede en el navegador a: http://local.grafana-poc:8000/guardar-token?token=123456"
