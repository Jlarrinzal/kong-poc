#!/bin/bash

IP=${1:-"127.0.0.1"}

echo "🧹 Eliminando configuración previa..."

for route in launch-redirect ip-proxy; do
  curl -s -X DELETE http://localhost:9001/routes/$route
done

for service in launch-redirect-service ip-service; do
  curl -s -X DELETE http://localhost:9001/services/$service
done

echo "🛠️ Registrando servicio real: $IP → https://obx-greenguard.aaaida.com/dashboards"

curl -s -i -X POST http://localhost:9001/services \
  --data name=ip-service \
  --data url=https://obx-greenguard.aaaida.com/dashboards

curl -s -i -X POST http://localhost:9001/services/ip-service/routes \
  --data name=ip-proxy \
  --data "hosts[]=$IP" \
  --data "paths[]=/" \
  --data strip_path=false

echo "🛠️ Registrando servicio redireccionador: /__LAUNCH__ → raíz del host"

curl -s -i -X POST http://localhost:9001/services \
  --data name=launch-redirect-service \
  --data url=https://example.com

curl -s -i -X POST http://localhost:9001/services/launch-redirect-service/routes \
  --data name=launch-redirect \
  --data "hosts[]=$IP" \
  --data "paths[]=/__LAUNCH__" \
  --data strip_path=false

curl -s -i -X POST http://localhost:9001/routes/launch-redirect/plugins \
  --data name=pre-function \
  --data-urlencode "config.access[1]=
    return kong.response.exit(302, nil, {
      ['Location'] = 'http://$IP:9000'
    })"

echo "✅ Listo. Puedes probar en tu navegador:"
echo "➡️ http://$IP:9000/__LAUNCH__"
echo "🔁 Te redirigirá a http://$IP:9000 y mostrará el contenido de obx-greenguard"
