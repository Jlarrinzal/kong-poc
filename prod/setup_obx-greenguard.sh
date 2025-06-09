#!/bin/bash

SERVICE_NAME="obx-gg"
DOMAIN="${SERVICE_NAME}.proxy.upcxels.upc.edu"
INTERNAL_URL="https://obx-greenguard.aaaida.com"

echo "🧹 Eliminando configuración previa (si existe)..."
curl -s -X DELETE http://localhost:9001/routes/proxy-${SERVICE_NAME}
curl -s -X DELETE http://localhost:9001/services/proxy-service-${SERVICE_NAME}
curl -s -X DELETE http://localhost:9001/plugins/${SERVICE_NAME}-forwarded-headers

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

echo "🧩 Añadiendo plugin 'request-transformer' con cabeceras X-Forwarded-*"
curl -s -i -X POST http://localhost:9001/services/proxy-service-${SERVICE_NAME}/plugins \
  --data name=request-transformer \
  --data "config.add.headers=X-Forwarded-Host:https://obx-greenguard.aaaida.com,X-Forwarded-Proto:https" \
  --data "tags[]=proxy-${SERVICE_NAME}"

echo "🔁 Añadiendo redirección condicional a /dashboards?kiosk"
curl -s -i -X POST http://localhost:9001/services/proxy-service-${SERVICE_NAME}/plugins \
  --data name=pre-function \
  --data "config.access[1]=if kong.request.get_path() == '/' then kong.response.set_header('Location', '/dashboards?kiosk'); return kong.response.exit(302) end" \
  --data "tags[]=proxy-${SERVICE_NAME}"

echo "✅ Ya puedes acceder a: https://${DOMAIN}"
