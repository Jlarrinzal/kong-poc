#!/bin/bash

echo "🧹 Eliminando todos los servicios registrados en Kong..."

SERVICES=$(curl -s http://localhost:8001/services)

IFS='}' # separamos por objetos JSON
for chunk in $SERVICES; do
  case "$chunk" in
    *\"id\"*) 
      ID=$(echo "$chunk" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')
      if [ -n "$ID" ]; then
        echo "🗑️ Eliminando servicio con ID: $ID"
        curl -s -X DELETE http://localhost:8001/services/$ID
      fi
      ;;
  esac
done

echo "✅ Todos los servicios han sido eliminados."

# curl -s http://localhost:8001/services

# curl -s http://localhost:8001/plugins/enabled