#!/bin/bash

# Archivos a los que se les agregará permisos de ejecución
FILES=(
    "./update-spring-boot-app.sh"
    "./rollback.sh"
    "./deploy-spring-boot-app.sh"
    "./deploy-app.sh"
)

# Agregar permisos de ejecución a cada archivo
for FILE in "${FILES[@]}"; do
    if [ -f "$FILE" ]; then
        echo "Agregando permisos de ejecución a $FILE"
        chmod +x "$FILE"
    else
        echo "Error: El archivo $FILE no existe."
    fi
done

echo "Permisos de ejecución agregados."