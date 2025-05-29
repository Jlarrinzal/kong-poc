#!/bin/bash

echo "🧹 Eliminando configuración previa..."

# Eliminar rutas
for route in guardar-token grafana3000-route; do
  curl -s -X DELETE http://localhost:8001/routes/$route
done

# Eliminar servicios
for service in guardar-token-service grafana3000-service; do
  curl -s -X DELETE http://localhost:8001/services/$service
done

# Eliminar plugins (por nombre no se puede directamente, se eliminarán con las rutas)

echo "🛠️ Registrando servicio de redirección final grafana.proxy.upcxels.upc.edu → obx-greenguard..."

# Crear servicio que apunta a la URL real
curl -s -i -X POST http://localhost:8001/services \
  --data name=grafana3000-service \
  --data url=https://obx-greenguard.aaaida.com/dashboards

# Crear ruta pública para el usuario final
curl -s -i -X POST http://localhost:8001/services/grafana3000-service/routes \
  --data name=grafana3000-route \
  --data "hosts[]=grafana.proxy.upcxels.upc.edu" \
  --data "paths[]=/" \
  --data strip_path=false

echo "🛠️ Registrando ruta de validación guardar-token con plugin..."

# Crear servicio dummy para asociar la ruta /guardar-token
curl -s -i -X POST http://localhost:8001/services \
  --data name=guardar-token-service \
  --data url=https://example.com

# Crear ruta para recibir el token
curl -s -i -X POST http://localhost:8001/services/guardar-token-service/routes \
  --data name=guardar-token \
  --data "hosts[]=local.grafana.proxy.upcxels.upc.edu" \
  --data "paths[]=/guardar-token" \
  --data strip_path=false

# Añadir plugin jwt_validator
curl -s -i -X POST http://localhost:8001/routes/guardar-token/plugins \
  --data "name=jwt_validator" \
  --data "config.secret=clave-super-secreta" \
  --data "config.success_url=https://grafana.proxy.upcxels.upc.edu" \
  --data "config.failure_url=https://grafana.proxy.upcxels.upc.edu/error"

echo "✅ Configuración completada correctamente."
echo "➡️ Puedes probar con:"
echo "   http://local.grafana.proxy.upcxels.upc.edu:8000/guardar-token?token=<TU_JWT>"
