#!/bin/bash

SERVICE_NAME="co2_orchestrator"
DOMAIN="${SERVICE_NAME}.proxy.upcxels.upc.edu"
INTERNAL_URL="https://co2.services.upcxels.upc.edu"

echo "🧹 Eliminando configuración previa (si existe)..."
curl -s -X DELETE http://localhost:9001/routes/proxy-${SERVICE_NAME}
curl -s -X DELETE http://localhost:9001/services/proxy-service-${SERVICE_NAME}

echo "🛠️ Registrando servicio real en Kong → $INTERNAL_URL"
curl -s -i -X POST http://localhost:9001/services \
  --data name=proxy-service-${SERVICE_NAME} \
  --data url=$INTERNAL_URL

echo "🌐 Creando ruta pública: https://${DOMAIN}"
curl -s -i -X POST http://localhost:9001/services/proxy-service-${SERVICE_NAME}/routes \
  --data name=proxy-${SERVICE_NAME} \
  --data "hosts[]=${DOMAIN}" \
  --data "paths[]=/" \
  --data strip_path=false \
  --data https_redirect_status_code=426

echo "✅ Ya puedes acceder a: https://${DOMAIN}"
