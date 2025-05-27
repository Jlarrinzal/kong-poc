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
  --data url=https://obx-greenguard.aaaida.com/dashboards?kiosk
  #--data url=http://host.docker.internal:3000

curl -s -i -X POST http://localhost:8001/routes \
  --data service.name=grafana3000-service \
  --data name=grafana3000-route \
  --data "hosts[]=grafana-poc.test"

echo "🛠️ Registrando ruta guardar-token con lógica Lua..."

# Servicio dummy (solo para asociar la ruta /guardar-token)
curl -s -i -X POST http://localhost:8001/services \
  --data name=guardar-token-service \
  --data url=http://does-not-matter.local

# Ruta: local.grafana-poc.test/guardar-token
curl -s -i -X POST http://localhost:8001/services/guardar-token-service/routes \
  --data name=guardar-token \
  --data "hosts[]=local.grafana-poc.test" \
  --data "paths[]=/guardar-token" \
  --data strip_path=false

# Plugin pre-function: guarda cookie y redirige
curl -s -i -X POST http://localhost:8001/routes/guardar-token/plugins \
  --data name=pre-function \
  --data-urlencode "config.access[1]=local a=kong.request.get_query_arg('token')if a=='123456'then kong.response.set_header('Set-Cookie','token='..a..'; Domain=grafana-poc; Path=/; HttpOnly')return kong.response.exit(302,'',{['Location']='http://grafana-poc.test:8000'})end;return kong.response.exit(401,'Token invalido')"
  # --data-urlencode "config.access[1]=$(< kong-plugins/config-redirect-obx-upcxels.lua)" \

echo "✅ Listo. Visita en tu navegador:"
echo "➡️ http://local.grafana-poc.test:8000/guardar-token?token=123456"
