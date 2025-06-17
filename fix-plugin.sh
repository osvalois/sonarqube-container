#!/bin/bash
# Script para corregir manualmente el plugin en un contenedor Docker existente

# Variables
CONTAINER_NAME="sonarqube-railway"
PLUGIN_JAR="/opt/sonarqube/extensions/plugins/sonarqube-community-branch-plugin-25.5.0.jar"

# Verificar si el contenedor existe
if ! docker ps -a | grep -q "$CONTAINER_NAME"; then
    echo "ERROR: El contenedor $CONTAINER_NAME no existe"
    exit 1
fi

# Reiniciar el contenedor si está ejecutándose
if docker ps | grep -q "$CONTAINER_NAME"; then
    echo "Deteniendo el contenedor $CONTAINER_NAME..."
    docker stop "$CONTAINER_NAME"
fi

echo "=== Corrigiendo configuración del plugin en $CONTAINER_NAME ==="

# Ejecutar un comando en el contenedor para verificar el plugin
docker start "$CONTAINER_NAME"
docker exec "$CONTAINER_NAME" bash -c "ls -la $PLUGIN_JAR && chmod 644 $PLUGIN_JAR && chown 1000:0 $PLUGIN_JAR"

# Configurar variables de entorno simplificadas
docker exec "$CONTAINER_NAME" bash -c "export JAVA_OPTS='-XX:MaxRAMPercentage=75.0' && \
    export JAVA_TOOL_OPTIONS='-XX:MaxRAMPercentage=75.0' && \
    export SONAR_WEB_JAVAOPTS='-Xmx512m -Xms256m' && \
    export SONAR_CE_JAVAOPTS='-Xmx512m -Xms256m'"

# Reiniciar el contenedor con el comando correcto
docker stop "$CONTAINER_NAME"
docker start "$CONTAINER_NAME"

echo "=== Mostrando logs del contenedor ==="
docker logs -f "$CONTAINER_NAME"