#!/bin/bash

SERVICE_NAME="odoo"
DOMAIN="market.proxy.upcxels.upc.edu"

echo "🧹 Eliminando configuración previa (si existe)..."
curl -s -X DELETE http://localhost:9001/routes/proxy-${SERVICE_NAME}
curl -s -X DELETE http://localhost:9001/services/proxy-service-${SERVICE_NAME}

echo "🛠️ Registrando servicio local: http://localhost:8000"
curl -s -i -X POST http://localhost:9001/services \
  --data name=proxy-service-${SERVICE_NAME} \
  --data url=http://host.docker.internal:8000

echo "🌐 Creando ruta pública en dominio HTTPS ${DOMAIN}"
curl -s -i -X POST http://localhost:9001/services/proxy-service-${SERVICE_NAME}/routes \
  --data name=proxy-${SERVICE_NAME} \
  --data "hosts[]=${DOMAIN}" \
  --data "paths[]=/" \
  --data strip_path=false \
  --data https_redirect_status_code=426

echo "✅ Odoo debería ser accesible desde: https://${DOMAIN}"
