#!/bin/bash

# Verificar que se ha proporcionado un nombre de aplicación como argumento
if [ $# -ne 1 ]; then
    echo "Usage: $0 <nombre_de_la_aplicacion>"
    exit 1
fi

# Nombre de la aplicación
APP_NAME=$1

# Archivo de configuración
CONFIG_FILE="./deploy.conf"

# Verificar si el archivo de configuración existe
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: El archivo de configuración '$CONFIG_FILE' no existe."
    exit 1
fi

# Cargar la configuración
source "$CONFIG_FILE"

# Validar JAVA_HOME
if [ -z "$JAVA_HOME" ]; then
    echo "Error: La variable JAVA_HOME no está definida en '$CONFIG_FILE'."
    exit 1
fi

# Verificar si JAVA_HOME está correctamente configurado
if [ ! -d "$JAVA_HOME" ]; then
    echo "Error: La ruta JAVA_HOME '$JAVA_HOME' no existe."
    exit 1
fi

# Verificar que se puede ejecutar Java desde la ruta especificada
if [ ! -x "$JAVA_HOME/bin/java" ]; then
    echo "Error: No se puede ejecutar Java desde '$JAVA_HOME'."
    exit 1
fi

# Directorios
UPLOADS_DIR="${HOME}/uploads"
APP_DIR="$UPLOADS_DIR/$APP_NAME"
TARGET_DIR="$APP_DIR/target"
CONFIG_DIR="$APP_DIR/config"
DEPLOY_DIR="/opt/$APP_NAME"
SERVICE_FILE="/etc/systemd/system/$APP_NAME.service"

# Verificar si el directorio de despliegue ya existe
if [ -d "$DEPLOY_DIR" ]; then
    echo "La aplicación '$APP_NAME' ya está desplegada en '$DEPLOY_DIR'."
    
    # Verificar si el archivo de servicio ya existe
    if [ -f "$SERVICE_FILE" ]; then
        echo "El archivo de servicio '$SERVICE_FILE' ya existe."

        # Consultar al usuario si quiere hacer un update o abortar
        read -p "¿Desea hacer un update? (s/n): " respuesta
        if [[ "$respuesta" == "s" || "$respuesta" == "S" ]]; then
            # Ejecutar el script de actualización
            echo "Ejecutando actualización..."
            bash ./update_script.sh "$APP_NAME"
        else
            echo "Actualización abortada."
            exit 0
        fi
    else
        echo "El archivo de servicio '$SERVICE_FILE' no existe."

        # Consultar al usuario si quiere desplegar de nuevo
        read -p "¿Desea desplegar de nuevo? (s/n): " respuesta
        if [[ "$respuesta" == "s" || "$respuesta" == "S" ]]; then
            # Ejecutar el script de despliegue
            echo "Ejecutando despliegue..."
            bash ./deploy_script.sh "$APP_NAME"
        else
            echo "Despliegue abortado."
            exit 0
        fi
    fi
else
    echo "La aplicación '$APP_NAME' no está desplegada."

    # Ejecutar el script de despliegue
    echo "Ejecutando despliegue..."
    bash ./deploy_script.sh "$APP_NAME"
fi
