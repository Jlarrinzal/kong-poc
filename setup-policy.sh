#!/bin/bash

SERVICE_NAME="prueba-obx"
DOMAIN="${SERVICE_NAME}.proxy.upcxels.upc.edu"
INTERNAL_URL="https://obx-greenguard.aaaida.com"

echo "🧹 Eliminando configuración previa (si existe)..."
curl -s -X DELETE http://localhost:9001/routes/proxy-${SERVICE_NAME}
curl -s -X DELETE http://localhost:9001/routes/launch-jwt-${SERVICE_NAME}
curl -s -X DELETE http://localhost:9001/services/proxy-service-${SERVICE_NAME}
curl -s -X DELETE http://localhost:9001/services/launch-jwt-service-${SERVICE_NAME}
curl -s -X DELETE http://localhost:9001/plugins/${SERVICE_NAME}-jwt-validator
curl -s -X DELETE http://localhost:9001/plugins/${SERVICE_NAME}-jwt-policy
curl -s -X DELETE http://localhost:9001/plugins/${SERVICE_NAME}-forwarded-headers
curl -s -X DELETE http://localhost:9001/plugins/${SERVICE_NAME}-redirect-root

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

echo "🧩 Añadiendo plugin 'jwt_policy_cookie_validator' para validar la cookie y políticas"
curl -s -i -X POST http://localhost:9001/services/proxy-service-${SERVICE_NAME}/plugins \
  --data name=jwt_policy_cookie_validator \
  --data "config.secret=mi_clave_secreta" \
  --data "config.failure_url=https://${DOMAIN}/__LAUNCH__" \
  --data "config.required_permissions[1].action=READ" \
  --data "config.required_permissions[1].leftOperand=location" \
  --data "config.required_permissions[1].operator=eq" \
  --data "config.required_permissions[1].rightOperand=EU" \
  --data-urlencode "config.prohibited_targets[1].action=not_show" \
  --data-urlencode "config.prohibited_targets[1].target=https://obx-gg.proxy.upcxels.upc.edu/alerting" \
  --data "tags[]=proxy-${SERVICE_NAME}"

echo "🔁 Añadiendo redirección condicional a /dashboards?kiosk"
curl -s -i -X POST http://localhost:9001/services/proxy-service-${SERVICE_NAME}/plugins \
  --data name=pre-function \
  --data "config.access[1]=if kong.request.get_path() == '/' then kong.response.set_header('Location', '/dashboards?kiosk'); return kong.response.exit(302) end" \
  --data "tags[]=proxy-${SERVICE_NAME}"

echo "🚀 Registrando servicio dummy JWT para __LAUNCH__"
curl -s -i -X POST http://localhost:9001/services \
  --data name=launch-jwt-service-${SERVICE_NAME} \
  --data url=https://example.com

echo "🚪 Registrando ruta JWT: https://${DOMAIN}/__LAUNCH__"
curl -s -i -X POST http://localhost:9001/services/launch-jwt-service-${SERVICE_NAME}/routes \
  --data name=launch-jwt-${SERVICE_NAME} \
  --data "hosts[]=${DOMAIN}" \
  --data "paths[]=/__LAUNCH__" \
  --data strip_path=false

echo "🧩 Añadiendo plugin 'jwt_validator' para aceptar el token y poner la cookie"
curl -s -i -X POST http://localhost:9001/routes/launch-jwt-${SERVICE_NAME}/plugins \
  --data name=jwt_validator \
  --data "config.secret=mi_clave_secreta" \
  --data "config.success_url=https://${DOMAIN}" \
  --data "config.failure_url=https://example.com" \
  --data "config.domain=${DOMAIN}"

echo "✅ Ya puedes probar el flujo con:"
echo "➡️ https://${DOMAIN}/__LAUNCH__?token=<JWT>"
echo "🍪 Si es válido, redirige con cookie a https://${DOMAIN}/"
