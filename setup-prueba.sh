#!/bin/bash

# Servicio 1: Grafana
SERVICE_NAME_1="grafana"
DOMAIN_1="${SERVICE_NAME_1}.proxy.upcxels.upc.edu"
UPSTREAM_URL_1="https://obx-greenguard.aaaida.com/dashboards"

# Servicio 2: Market
SERVICE_NAME_2="prueba"
DOMAIN_2="${SERVICE_NAME_2}.upcxels.upc.edu"
UPSTREAM_URL_2="https://upcxels-pre.widening.eu/"

echo "🧹 Eliminando configuraciones anteriores..."

for route in route-${SERVICE_NAME_1} route-${SERVICE_NAME_2}; do
  curl -s -X DELETE http://localhost:9001/routes/$route
done

for service in service-${SERVICE_NAME_1} service-${SERVICE_NAME_2}; do
  curl -s -X DELETE http://localhost:9001/services/$service
done

echo "🛠️ Registrando servicio para $DOMAIN_1 → $UPSTREAM_URL_1"
curl -s -i -X POST http://localhost:9001/services \
  --data name=service-${SERVICE_NAME_1} \
  --data url=$UPSTREAM_URL_1

curl -s -i -X POST http://localhost:9001/services/service-${SERVICE_NAME_1}/routes \
  --data name=route-${SERVICE_NAME_1} \
  --data "hosts[]=$DOMAIN_1" \
  --data "paths[]=/" \
  --data strip_path=true

echo "🛠️ Registrando servicio para $DOMAIN_2 → $UPSTREAM_URL_2"
curl -s -i -X POST http://localhost:9001/services \
  --data name=service-${SERVICE_NAME_2} \
  --data url=$UPSTREAM_URL_2

curl -s -i -X POST http://localhost:9001/services/service-${SERVICE_NAME_2}/routes \
  --data name=route-${SERVICE_NAME_2} \
  --data "hosts[]=$DOMAIN_2" \
  --data "paths[]=/" \
  --data strip_path=false

echo "✅ Configuración completada."
echo "🔗 Prueba accediendo a:"
echo "   ➤ https://${DOMAIN_1}"
echo "   ➤ https://${DOMAIN_2}"
