#!/bin/bash

IP=${1:-"127.0.0.1"}

echo "🧹 Eliminando configuración previa..."

for route in launch-jwt ip-proxy; do
  curl -s -X DELETE http://localhost:9001/routes/$route
done

for service in launch-jwt-service ip-service; do
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

echo "🛠️ Registrando ruta con plugin: /__LAUNCH__"

curl -s -i -X POST http://localhost:9001/services \
  --data name=launch-jwt-service \
  --data url=https://example.com  # dummy, nunca se llega

curl -s -i -X POST http://localhost:9001/services/launch-jwt-service/routes \
  --data name=launch-jwt \
  --data "hosts[]=$IP" \
  --data "paths[]=/__LAUNCH__" \
  --data strip_path=false

curl -s -i -X POST http://localhost:9001/routes/launch-jwt/plugins \
  --data "name=jwt_validator" \
  --data "config.secret=clave-super-secreta" \
  --data "config.success_url=http://$IP:9000" \
  --data "config.failure_url=https://example.com"

echo "✅ Listo. Prueba en tu navegador:"
echo "➡️ http://$IP:9000/__LAUNCH__?token=<TU_JWT>"
