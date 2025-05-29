#!/bin/bash

echo "🧹 Eliminando todas las rutas..."

ROUTES=$(curl -s http://localhost:9001/routes)

IFS='}' # delimitador para separar por objeto JSON
for chunk in $ROUTES; do
  case "$chunk" in
    *\"id\"*) 
      ID=$(echo "$chunk" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')
      if [ -n "$ID" ]; then
        echo "🗑️ Eliminando $ID"
        curl -s -X DELETE http://localhost:9001/routes/$ID
      fi
      ;;
  esac
done

echo "✅ Rutas eliminadas."

# curl -s http://localhost:9001/routes