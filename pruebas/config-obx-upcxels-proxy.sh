# #!/bin/bash

# echo "🧹 Eliminando configuración previa..."

# # Eliminar rutas y servicios previos
# for route in guardar-token grafana3000-route; do
#   curl -s -X DELETE http://localhost:8001/routes/$route
# done

# for service in guardar-token-service grafana3000-service; do
#   curl -s -X DELETE http://localhost:8001/services/$service
# done

# echo "🛠️ Registrando grafana-poc.test → obx-greenguard.aaaida.com como proxy..."

# # Registrar servicio real de obx-greenguard
# curl -s -i -X POST http://localhost:8001/services \
#   --data name=grafana3000-service \
#   --data url=http://localhost:3000

# # Registrar ruta en host grafana-poc.test
# curl -s -i -X POST http://localhost:8001/routes \
#   --data service.name=grafana3000-service \
#   --data name=grafana3000-route \
#   --data "hosts[]=grafana-poc.test" \
#   --data strip_path=true

# echo "🛠️ Registrando ruta guardar-token con lógica Lua..."

# # Servicio dummy para usar el plugin Lua
# curl -s -i -X POST http://localhost:8001/services \
#   --data name=guardar-token-service \
#   --data url=http://does-not-matter.local

# # Ruta para /guardar-token en local.grafana-poc.test
# curl -s -i -X POST http://localhost:8001/services/guardar-token-service/routes \
#   --data name=guardar-token \
#   --data "hosts[]=local.grafana-poc.test" \
#   --data "paths[]=/guardar-token" \
#   --data strip_path=false

# # Plugin Lua: guarda cookie y redirige si token válido
# curl -s -i -X POST http://localhost:8001/routes/guardar-token/plugins \
#   --data name=pre-function \
#   --data-urlencode "config.access[1]=local a=kong.request.get_query_arg('token')if a=='123456'then kong.response.set_header('Set-Cookie','token='..a..'; Domain=grafana-poc.test; Path=/; HttpOnly')return kong.response.exit(302,'',{['Location']='http://grafana-poc.test:8000'})end;return kong.response.exit(401,'Token invalido')"

# echo "✅ Configuración completada"
# echo "➡️ Visita: http://local.grafana-poc.test:8000/guardar-token?token=123456"
