#!/bin/bash

# Nombre del subdominio para este servicio (sin .proxy.upcxels.upc.edu)
SERVICE_NAME="opendata-gg"

# Dominio público único
DOMAIN="${SERVICE_NAME}.proxy.upcxels.upc.edu"

echo "🧹 Eliminando configuración previa..."

# Eliminamos rutas y servicios antiguos si existen (por nombre)
for route in launch-jwt-${SERVICE_NAME} proxy-${SERVICE_NAME}; do
  curl -s -X DELETE http://localhost:9001/routes/$route
done

for service in launch-jwt-service-${SERVICE_NAME} proxy-service-${SERVICE_NAME}; do
  curl -s -X DELETE http://localhost:9001/services/$service
done

echo "🛠️ Registrando servicio real: $DOMAIN → https://open-data-greenguard.aaaida.com"

# Registramos el servicio real que será proxyado
curl -s -i -X POST http://localhost:9001/services \
  --data name=proxy-service-${SERVICE_NAME} \
  --data url=https://open-data-greenguard.aaaida.com

# Ruta protegida por cookie (después de validación)
curl -s -i -X POST http://localhost:9001/services/proxy-service-${SERVICE_NAME}/routes \
  --data name=proxy-${SERVICE_NAME} \
  --data "hosts[]=${DOMAIN}" \
  --data "paths[]=/" \
  --data strip_path=false

# Plugin para verificar cookie en esa ruta
curl -s -i -X POST http://localhost:9001/routes/proxy-${SERVICE_NAME}/plugins \
  --data "name=jwt_cookie_validator" \
  --data "config.secret=clave-super-secreta" \
  --data "config.failure_url=https://${DOMAIN}/__LAUNCH__"

echo "🛠️ Registrando ruta JWT: https://${DOMAIN}/__LAUNCH__"

# Servicio dummy solo para validar token
curl -s -i -X POST http://localhost:9001/services \
  --data name=launch-jwt-service-${SERVICE_NAME} \
  --data url=https://example.com  # dummy service

# Ruta para validar el token JWT
curl -s -i -X POST http://localhost:9001/services/launch-jwt-service-${SERVICE_NAME}/routes \
  --data name=launch-jwt-${SERVICE_NAME} \
  --data "hosts[]=${DOMAIN}" \
  --data "paths[]=/__LAUNCH__" \
  --data strip_path=false

# Plugin para validar el token JWT y poner la cookie
curl -s -i -X POST http://localhost:9001/routes/launch-jwt-${SERVICE_NAME}/plugins \
  --data "name=jwt_validator" \
  --data "config.secret=clave-super-secreta" \
  --data "config.success_url=https://${DOMAIN}" \
  --data "config.failure_url=https://example.com" \
  --data "config.domain=${DOMAIN}"

echo "✅ Puedes probar directamente con:"
echo "➡️ https://${DOMAIN}/__LAUNCH__?token=<JWT>"
echo "🔁 Si es válido, redirige a: https://${DOMAIN} (con la cookie ya puesta)"
