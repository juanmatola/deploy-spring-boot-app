#!/bin/bash

# Verificar que se ha proporcionado un nombre de aplicación como argumento
if [ $# -ne 1 ]; then
    echo "Usage: $0 <nombre_de_la_aplicacion>"
    exit 1
fi

# Nombre de la aplicación
APP_NAME=$1

# Directorios
DEPLOY_DIR="/opt/$APP_NAME"
BACKUP_DIR="/opt/${APP_NAME}_backup"

# Verificar si el directorio de respaldo existe
if [ ! -d "$BACKUP_DIR" ]; then
    echo "Error: El directorio de respaldo '$BACKUP_DIR' no existe."
    exit 1
fi

# Verificar si el archivo JAR de respaldo existe
if [ ! -f "$BACKUP_DIR/app.jar.bak" ]; then
    echo "Error: El archivo de respaldo 'app.jar.bak' no existe en '$BACKUP_DIR'."
    exit 1
fi

# Verificar si el directorio de configuración de respaldo existe
if [ ! -d "$BACKUP_DIR/config.bak" ]; then
    echo "Error: El directorio de configuración de respaldo 'config.bak' no existe en '$BACKUP_DIR'."
    exit 1
fi

# Parar el servicio antes de hacer el rollback
echo "Parando servicio $APP_NAME."
sudo systemctl stop $APP_NAME.service

# Eliminar los archivos desplegados
echo "Eliminando archivos desplegados en $DEPLOY_DIR"
sudo rm -f "$DEPLOY_DIR/app.jar"
sudo rm -rf "$DEPLOY_DIR/config"

# Restaurar el archivo JAR desde el respaldo
echo "Restaurando $BACKUP_DIR/app.jar.bak a $DEPLOY_DIR/app.jar"
sudo mv "$BACKUP_DIR/app.jar.bak" "$DEPLOY_DIR/app.jar"

# Restaurar el directorio de configuración desde el respaldo
echo "Restaurando $BACKUP_DIR/config.bak a $DEPLOY_DIR/config"
sudo mv "$BACKUP_DIR/config.bak" "$DEPLOY_DIR/config"

# Recargar y reiniciar el servicio
echo "Reiniciando servicio $APP_NAME."
sudo systemctl daemon-reload
sudo systemctl start $APP_NAME.service

# Verificar si el servicio se inició correctamente
if [ $? -ne 0 ]; then
    echo "Error: Fallo al reiniciar el servicio $APP_NAME."
    exit 1
fi

echo "Rollback completado para la aplicación $APP_NAME."

# Mostrar estado del servicio
echo "Estado del servicio $APP_NAME:"
sudo systemctl status $APP_NAME.service --no-pager

echo "Rollback completado para la aplicación $APP_NAME."

# Mostrar log en tiempo real
echo "LOG en tiempo real del servicio $APP_NAME:"
sudo journalctl -u $APP_NAME.service -f
