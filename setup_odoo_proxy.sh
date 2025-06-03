#!/bin/bash

SERVICE_NAME="odoo"
DOMAIN="market.proxy.upcxels.upc.edu"
ODOO_INTERNAL_URL="http://172.20.0.1:8000"

echo "🧹 Eliminando configuración previa (si existe)..."
curl -s -X DELETE http://localhost:9001/routes/proxy-${SERVICE_NAME}
curl -s -X DELETE http://localhost:9001/services/proxy-service-${SERVICE_NAME}

echo "🛠️ Registrando servicio real en Kong → $ODOO_INTERNAL_URL"
curl -s -i -X POST http://localhost:9001/services \
  --data name=proxy-service-${SERVICE_NAME} \
  --data url=$ODOO_INTERNAL_URL

echo "🌐 Creando ruta pública: https://${DOMAIN}"
curl -s -i -X POST http://localhost:9001/services/proxy-service-${SERVICE_NAME}/routes \
  --data name=proxy-${SERVICE_NAME} \
  --data "hosts[]=${DOMAIN}" \
  --data "paths[]=/" \
  --data strip_path=false \
  --data https_redirect_status_code=426

echo "✅ Ya puedes acceder a: https://${DOMAIN}"
