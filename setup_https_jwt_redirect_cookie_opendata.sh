#!/bin/bash

# Nombre del subdominio para este servicio (sin .proxy.upcxels.upc.edu)
SERVICE_NAME="open-data-gg"

# Dominios a usar
DOMAIN_PUBLIC="${SERVICE_NAME}.proxy.upcxels.upc.edu"
DOMAIN_LOCAL="local.${SERVICE_NAME}.proxy.upcxels.upc.edu"

echo "🧹 Eliminando configuración previa..."

# Eliminamos rutas antiguas si existen (por nombre)
for route in launch-jwt-${SERVICE_NAME} proxy-${SERVICE_NAME}; do
  curl -s -X DELETE http://localhost:9001/routes/$route
done

# Eliminamos servicios antiguos si existen (por nombre)
for service in launch-jwt-service-${SERVICE_NAME} proxy-service-${SERVICE_NAME}; do
  curl -s -X DELETE http://localhost:9001/services/$service
done

echo "🛠️ Registrando servicio real: $DOMAIN_PUBLIC → https://open-data-greenguard.aaaida.com"

# Registramos el servicio real que será proxyado
curl -s -i -X POST http://localhost:9001/services \
  --data name=proxy-service-${SERVICE_NAME} \
  --data url=https://open-data-greenguard.aaaida.com

# Creamos la ruta pública que accederá directamente al servicio real
curl -s -i -X POST http://localhost:9001/services/proxy-service-${SERVICE_NAME}/routes \
  --data name=proxy-${SERVICE_NAME} \
  --data "hosts[]=${DOMAIN_PUBLIC}" \
  --data "paths[]=/" \
  --data strip_path=false

# Añadimos el plugin jwt_cookie_validator para verificar cookie auth_token
curl -s -i -X POST http://localhost:9001/routes/proxy-${SERVICE_NAME}/plugins \
  --data "name=jwt_cookie_validator" \
  --data "config.secret=clave-super-secreta" \
  --data "config.failure_url=https://${DOMAIN_LOCAL}/__LAUNCH__"

echo "🛠️ Registrando ruta JWT: https://${DOMAIN_LOCAL}/__LAUNCH__"

# Creamos un servicio dummy que será usado como "trampolín" para lanzar al verdadero si el token JWT es válido
curl -s -i -X POST http://localhost:9001/services \
  --data name=launch-jwt-service-${SERVICE_NAME} \
  --data url=https://example.com  # dummy service

# Creamos una ruta dedicada a validar el token JWT
curl -s -i -X POST http://localhost:9001/services/launch-jwt-service-${SERVICE_NAME}/routes \
  --data name=launch-jwt-${SERVICE_NAME} \
  --data "hosts[]=${DOMAIN_LOCAL}" \
  --data "paths[]=/__LAUNCH__" \
  --data strip_path=false

# Añadimos el plugin personalizado `jwt_validator` para que gestione la lógica JWT en esa ruta
curl -s -i -X POST http://localhost:9001/routes/launch-jwt-${SERVICE_NAME}/plugins \
  --data "name=jwt_validator" \
  --data "config.secret=clave-super-secreta" \
  --data "config.success_url=https://${DOMAIN_PUBLIC}" \
  --data "config.failure_url=https://example.com"

echo "✅ Listo. Puedes probar con:"
echo "➡️ https://${DOMAIN_LOCAL}/__LAUNCH__?token=<JWT>"
echo "🔁 Si es válido, redirige a: https://${DOMAIN_PUBLIC} (contenido de open-data-greenguard)"
