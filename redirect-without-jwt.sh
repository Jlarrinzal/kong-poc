#!/bin/bash

echo "🧹 Eliminando configuración previa (modo redirección sin plugin)..."

# Eliminar rutas y servicios previos
for route in local-redirect grafana3000-route; do
  curl -s -X DELETE http://localhost:9001/routes/$route
done

for service in local-grafana-redirect-service grafana3000-service; do
  curl -s -X DELETE http://localhost:9001/services/$service
done

echo "🛠️ Registrando servicio grafana3000-service → host.docker.internal:4848..."

# Servicio real que sirve contenido
curl -s -i -X POST http://localhost:9001/services \
  --data name=grafana3000-service \
  --data url=http://host.docker.internal:4848

curl -s -i -X POST http://localhost:9001/services/grafana3000-service/routes \
  --data name=grafana3000-route \
  --data "hosts[]=grafana-poc.test" \
  --data "paths[]=/" \
  --data strip_path=false

echo "🛠️ Registrando redirección: local.grafana-poc.test → grafana-poc.test"

# Servicio dummy que redirige
curl -s -i -X POST http://localhost:9001/services \
  --data name=local-grafana-redirect-service \
  --data url=http://example.com  # dummy

# Ruta en local.*
curl -s -i -X POST http://localhost:9001/services/local-grafana-redirect-service/routes \
  --data name=local-redirect \
  --data "hosts[]=local.grafana-poc.test" \
  --data "paths[]=/" \
  --data strip_path=false

# Plugin pre-function que hace el redirect manual
curl -s -i -X POST http://localhost:9001/routes/local-redirect/plugins \
  --data name=pre-function \
  --data-urlencode "config.access[1]=
    return kong.response.exit(302, nil, {
      ['Location'] = 'http://grafana-poc.test:9000'
    })"

echo "✅ Listo. Prueba en tu navegador:"
echo "➡️ http://local.grafana-poc.test:9000 → redirige a → http://grafana-poc.test:9000 (contenido servido desde :4848)"
