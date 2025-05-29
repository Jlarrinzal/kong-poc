# Proyecto Kong

---

## Iniciar el proyecto

1. **Construir los contenedores**:
   ```bash
   docker compose build
   ```

2. **Levantar los servicios en segundo plano**:
   ```bash
   docker compose up -d
   ```

---

## Activar redirección con JWT

1. **Modificar el archivo `/etc/hosts`**:

   Abre el archivo con permisos de superusuario:
   ```bash
   sudo nano /etc/hosts
   ```

   Añade las siguientes líneas al final del archivo:

   ```
   127.0.0.1 grafana-poc.test
   127.0.0.1 local.grafana-poc.test
   ```

2. **Ejecutar el script de redirección**:
   ```bash
   ./redirect-jwt.sh
   ```

---

## Comprobar funcionamiento del JWT

1. **Generar un token válido usando el script**:
   ```bash
   python3 generate-token-jwt.py
   ```

   Este script imprimirá un JWT que puedes usar para autenticarte con los endpoints protegidos por Kong.

---

## Notas

- El plugin `jwt_validator` está implementado directamente en Lua y se carga como plugin personalizado en Kong.
- No se utilizan librerías externas para validar los JWT.
- La clave secreta está hardcodeada en el plugin para pruebas locales.

---

## Comprobar funcionamiento sin JWT

1. **Borrar las rutas y servicios**:
   ```bash
   ./eliminar-rutas.sh
   ./eliminar-servicios.sh
   ```

2. **Ejecutar el script de redirección**:
   ```bash
   ./redirect-without-jwt.sh
   ```
---

## Limpieza

Para detener y eliminar los contenedores:
```bash
docker compose down
```
Para eliminar todas las rutas y servicios:

   ```bash
   ./eliminar-rutas.sh
   ./eliminar-servicios.sh
   ```