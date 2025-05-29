# #!/bin/bash

# echo "🧹 Eliminando configuraciones anteriores en Kong (si existen)..."

# # Eliminar rutas
# curl -s -X DELETE http://localhost:8001/routes/actividades-route
# curl -s -X DELETE http://localhost:8001/routes/actividades-docs
# curl -s -X DELETE http://localhost:8001/routes/videos-route
# curl -s -X DELETE http://localhost:8001/routes/grafana-route

# # Eliminar servicios
# curl -s -X DELETE http://localhost:8001/services/actividades-service
# curl -s -X DELETE http://localhost:8001/services/videos-service
# curl -s -X DELETE http://localhost:8001/services/grafana-service

# echo "🔧 Registrando microservicios en Kong..."

# # Servicio Actividades
# curl -i -X POST http://localhost:8001/services \
#   --data name=actividades-service \
#   --data url=http://host.docker.internal:5001

# curl -i -X POST http://localhost:8001/routes \
#   --data service.name=actividades-service \
#   --data name=actividades-route \
#   --data hosts[]=actividades.marketplace.test

# # Ruta para Swagger UI (redirige /docs a /apidocs)
# curl -i -X POST http://localhost:8001/routes \
#   --data service.name=actividades-service \
#   --data name=actividades-docs \
#   --data hosts[]=actividades.marketplace.test \
#   --data paths[]=/docs \
#   --data strip_path=false

# # Servicio Videos
# curl -i -X POST http://localhost:8001/services \
#   --data name=videos-service \
#   --data url=http://host.docker.internal:5002

# curl -i -X POST http://localhost:8001/routes \
#   --data service.name=videos-service \
#   --data name=videos-route \
#   --data hosts[]=videos.marketplace.test

# # Crear servicio Grafana
# curl -i -X POST http://localhost:8001/services \
#   --data name=grafana-service \
#   --data url=http://host.docker.internal:4848

# curl -i -X POST http://localhost:8001/routes \
#   --data service.name=grafana-service \
#   --data name=grafana-route \
#   --data hosts[]=grafana.marketplace.test

# # Servicio Grafana Api Key
# curl -i -X POST http://localhost:8001/services \
#   --data name=grafana_api_key-service \
#   --data url=http://host.docker.internal:4848

# curl -i -X POST http://localhost:8001/routes \
#   --data service.name=grafana_api_key-service \
#   --data name=grafana_api_key-route \
#   --data hosts[]=grafana_api_key.marketplace.test

# echo "✅ Microservicios registrados correctamente, incluyendo Swagger UI para actividades."
