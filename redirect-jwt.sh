#!/bin/bash

echo "🧹 Eliminando configuración previa..."

# Eliminar rutas y servicios
for route in guardar-token grafana3000-route; do
  curl -s -X DELETE http://localhost:8001/routes/$route
done

for service in guardar-token-service grafana3000-service; do
  curl -s -X DELETE http://localhost:8001/services/$service
done

echo "🛠️ Registrando grafana-poc.test → localhost:3000..."

# Crear servicio real de Grafana
curl -s -i -X POST http://localhost:8001/services \
  --data name=grafana3000-service \
  --data url=http://host.docker.internal:4848
#   --data url=https://obx-greenguard.aaaida.com/dashboards?kiosk




curl -s -i -X POST http://localhost:8001/routes \
  --data service.name=grafana3000-service \
  --data name=grafana3000-route \
  --data "hosts[]=grafana-poc.test"

echo "🛠️ Registrando ruta guardar-token con lógica Lua..."

# Servicio dummy (solo para asociar la ruta /guardar-token)
curl -s -i -X POST http://localhost:8001/services \
  --data name=guardar-token-service \
  --data url=https://example.com

# Ruta: local.grafana-poc.test/guardar-token
curl -s -i -X POST http://localhost:8001/services/guardar-token-service/routes \
  --data name=guardar-token \
  --data "hosts[]=local.grafana-poc.test" \
  --data "paths[]=/guardar-token" \
  --data strip_path=false

# Plugin pre-function: guarda cookie y redirige
# curl -s -i -X POST http://localhost:8001/routes/guardar-token/plugins \
#   --data name=pre-function \
#   --data-urlencode "config.access[1]=$(< kong-plugins/validar-jwt-HMAC-SHA256.lua)" \

curl -i -X POST http://localhost:8001/routes/guardar-token/plugins \
  --data "name=jwt_validator" \
  --data "config.secret=clave-super-secreta" \
  --data "config.success_url=http://grafana-poc.test:8000" \
  --data "config.failure_url=https://example.com"

echo "✅ Listo. Visita en tu navegador:"
echo "➡️ http://local.grafana-poc.test:8000/guardar-token?token=123456"
