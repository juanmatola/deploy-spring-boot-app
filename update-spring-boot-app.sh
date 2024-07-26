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
BACKUP_DIR="/opt/${APP_NAME}_backup"

# Verificar si el directorio de la aplicación existe
if [ ! -d "$APP_DIR" ]; then
    echo "Error: El directorio de la aplicación '$APP_NAME' no existe en '$UPLOADS_DIR'."
    exit 1
fi

# Verificar si existe el directorio de configuración
if [ ! -d "$CONFIG_DIR" ]; then
    echo "Error: El directorio de configuración '$CONFIG_DIR' no existe."
    exit 1
fi

# Verificar si el archivo mvnw tiene permisos de ejecución
if [ ! -x "$APP_DIR/mvnw" ]; then
    echo "Dando permisos de ejecución a mvnw..."
    sudo chmod +x "$APP_DIR/mvnw"
fi

# Compilar la aplicación
echo "Compilando la aplicación en $APP_DIR..."
(cd "$APP_DIR" && ./mvnw clean package)
if [ $? -ne 0 ]; then
    echo "Error: Fallo la compilación del proyecto."
    exit 1
fi

# Verificar si existe el directorio target
if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: El directorio de destino '$TARGET_DIR' no existe."
    exit 1
fi

if [ -d "$BACKUP_DIR" ]; then
    echo "Limpiando directorio de respaldo existente: $BACKUP_DIR"
    sudo rm -rf "$BACKUP_DIR"/*
else
    # Crear directorio de respaldo si no existe
    echo "Creando directorio de respaldo: $BACKUP_DIR"
    sudo mkdir -p "$BACKUP_DIR"
fi

# Hacer copia de seguridad de los archivos existentes
echo "Haciendo copia de seguridad de los archivos existentes en $DEPLOY_DIR"
sudo mv "$DEPLOY_DIR"/app.jar "$BACKUP_DIR"/app.jar.bak
sudo mv "$DEPLOY_DIR"/config "$BACKUP_DIR"/config.bak

# Copiar archivo JAR compilado a /opt/<nombre_de_la_aplicacion>/app.jar
echo "Copiando $TARGET_DIR/*.jar a $DEPLOY_DIR/app.jar"
sudo cp "$TARGET_DIR"/*.jar "$DEPLOY_DIR"/app.jar

# Copiar directorio de configuración a /opt/<nombre_de_la_aplicacion>
echo "Copiando $CONFIG_DIR a $DEPLOY_DIR"
sudo cp -r "$CONFIG_DIR" "$DEPLOY_DIR"

# Recargar y reiniciar el servicio
echo "Reiniciando servicio $APP_NAME."
sudo systemctl daemon-reload
sudo systemctl restart $APP_NAME.service

echo "Actualización completada para la aplicación $APP_NAME."

# Mostrar estado del servicio
echo "Estado del servicio $APP_NAME:"
sudo systemctl status $APP_NAME.service --no-pager

echo "Actualizacion completada para la aplicación $APP_NAME."

# Mostrar log en tiempo real
echo "LOG en tiempo real del servicio $APP_NAME:"
sudo journalctl -u $APP_NAME.service -f
