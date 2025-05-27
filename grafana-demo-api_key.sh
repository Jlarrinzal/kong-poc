#!/bin/bash

echo "🧹 Eliminando configuración previa..."

# Borrar rutas y servicios
for route in guardar-apikey grafana3000-apikey-route; do
  curl -s -X DELETE http://localhost:8001/routes/$route
done

for service in guardar-apikey-service grafana3000-apikey-service; do
  curl -s -X DELETE http://localhost:8001/services/$service
done

# Borrar plugins anteriores
curl -s http://localhost:8001/plugins | jq -r '.data[] | select(.name == "key-auth" or .name == "pre-function") | .id' | while read id; do
  curl -s -X DELETE http://localhost:8001/plugins/$id
done

# Borrar consumidor (si ya existía)
curl -s -X DELETE http://localhost:8001/consumers/apikey-demo

echo "👤 Creando consumidor y clave..."

# Crear consumidor
curl -s -i -X POST http://localhost:8001/consumers \
  --data username=apikey-demo

# Crear API key real (la misma que se usará en la URL)
curl -s -i -X POST http://localhost:8001/consumers/apikey-demo/key-auth \
  --data key=abcdef123

echo "🔐 Registrando servicio Grafana protegido con key-auth..."

# Crear servicio apuntando a Grafana real
curl -s -i -X POST http://localhost:8001/services \
  --data name=grafana3000-apikey-service \
  --data url=http://host.docker.internal:3000

# Crear ruta grafana-poc2.test
curl -s -i -X POST http://localhost:8001/routes \
  --data service.name=grafana3000-apikey-service \
  --data name=grafana3000-apikey-route \
  --data "hosts[]=grafana-poc2.test"

# Activar key-auth para ese servicio
curl -i -X POST http://localhost:8001/services/grafana3000-apikey-service/plugins \
  --data name=key-auth \
  --data config.key_names[]=apikey \
  --data config.key_in_query=true \
  --data config.key_in_header=true

echo "📦 Registrando lógica de redirección con cookie..."

# Servicio dummy para redirección
curl -s -i -X POST http://localhost:8001/services \
  --data name=guardar-apikey-service \
  --data url=https://example.com

# Ruta de redirección
curl -s -i -X POST http://localhost:8001/services/guardar-apikey-service/routes \
  --data name=guardar-apikey \
  --data "hosts[]=local.grafana-poc2.test" \
  --data "paths[]=/guardar-apikey" \
  --data strip_path=false

# Plugin Lua que guarda cookie y redirige
curl -s -i -X POST http://localhost:8001/routes/guardar-apikey/plugins \
  --data name=pre-function \
  # --data-urlencode "config.access[1]=local k=kong.request.get_query_arg('apikey')if k then kong.response.set_header('Set-Cookie','apikey_token='..k..'; Domain=grafana-poc2.test; Path=/; HttpOnly') return kong.response.exit(302,'',{['Location']='http://grafana-poc2.test:8000'}) end return"
  --data-urlencode "config.access[1]=local k=kong.request.get_query_arg('apikey')if k then kong.response.set_header('Set-Cookie','apikey_token='..k..'; Domain=grafana-poc2.test; Path=/; HttpOnly') return kong.response.exit(302,'',{['Location']='http://grafana-poc2.test:8000?apikey='..k}) end return"

echo "✅ Todo listo. Prueba esto:"
echo "➡️ http://local.grafana-poc2.test:8000/guardar-apikey?apikey=abcdef123"
