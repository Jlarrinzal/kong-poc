#!/bin/bash

DOMAIN="prueba-obx.proxy.upcxels.upc.edu"

#### 🧹 Limpieza previa ####

echo "🧹 Eliminando configuración previa (si existe)..."

for SERVICE_NAME in odoo grafana; do
  curl -s -X DELETE http://localhost:9001/routes/proxy-${SERVICE_NAME} > /dev/null
  curl -s -X DELETE http://localhost:9001/services/proxy-service-${SERVICE_NAME} > /dev/null
done

# #### 🛠️ Odoo ####

# SERVICE_NAME="odoo"
# ODOO_INTERNAL_URL="http://localhost:8069"

# echo "🛠️ Registrando servicio de Odoo en Kong → $ODOO_INTERNAL_URL"
# curl -s -i -X POST http://localhost:9001/services \
#   --data name=proxy-service-${SERVICE_NAME} \
#   --data url=$ODOO_INTERNAL_URL

# echo "🌐 Creando ruta para Odoo en: https://${DOMAIN}/odoo/"
# curl -s -i -X POST http://localhost:9001/services/proxy-service-${SERVICE_NAME}/routes \
#   --data name=proxy-${SERVICE_NAME} \
#   --data "hosts[]=${DOMAIN}" \
#   --data "paths[]=/odoo" \
#   --data strip_path=false \
#   --data https_redirect_status_code=426

# #### 🛠️ Grafana ####

# SERVICE_NAME="grafana"
# GRAFANA_INTERNAL_URL="http://host.docker.internal:4848"

# echo "🛠️ Registrando servicio de Grafana en Kong → $GRAFANA_INTERNAL_URL"
# curl -s -i -X POST http://localhost:9001/services \
#   --data name=proxy-service-${SERVICE_NAME} \
#   --data url=$GRAFANA_INTERNAL_URL

# echo "🌐 Creando ruta para Grafana en: https://${DOMAIN}/grafana"
# curl -s -i -X POST http://localhost:9001/services/proxy-service-${SERVICE_NAME}/routes \
#   --data name=proxy-${SERVICE_NAME} \
#   --data "hosts[]=${DOMAIN}" \
#   --data "paths[]=/grafana" \
#   --data strip_path=true \
#   --data https_redirect_status_code=426

# #### ✅ Fin ####

# echo ""
# echo "✅ Configuración completada"
# echo "🔗 Puedes acceder a:"
# echo " - Odoo → http://${DOMAIN}/odoo"
# echo " - Grafana → http://${DOMAIN}/grafana"
