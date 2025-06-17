#!/bin/bash
set -e

PLUGIN_JAR="/opt/sonarqube/extensions/plugins/sonarqube-community-branch-plugin-25.5.0.jar"
WEBAPP_DIR="/opt/sonarqube/web"

# Verificar existencia del plugin
if [ ! -f "$PLUGIN_JAR" ]; then
    echo "ERROR: Plugin JAR no encontrado en $PLUGIN_JAR"
    exit 1
fi

# Verificar permisos
echo "Verificando permisos del plugin..."
chmod 644 "$PLUGIN_JAR"
chown 1000:0 "$PLUGIN_JAR"

# Verificar webapp
if [ ! -d "$WEBAPP_DIR" ]; then
    echo "ERROR: Directorio webapp no encontrado en $WEBAPP_DIR"
    exit 1
fi

# Establecer permisos correctos para webapp
echo "Estableciendo permisos para el directorio webapp..."
chmod -R 755 "$WEBAPP_DIR"
chown -R 1000:0 "$WEBAPP_DIR"

# Verificar configuración
if [ -f "/opt/sonarqube/conf/branch-plugin.properties" ]; then
    echo "Archivo de configuración del plugin encontrado"
else
    echo "ADVERTENCIA: Archivo de configuración del plugin no encontrado"
fi

# Verificar variables de entorno para JavaAgent
echo "Verificando configuración de JavaAgent..."

# Verificar JAVA_OPTS
if [[ "$JAVA_OPTS" != *"-javaagent:/opt/sonarqube/extensions/plugins/sonarqube-community-branch-plugin-25.5.0.jar"* ]]; then
    echo "ADVERTENCIA: JAVA_OPTS no contiene la configuración del JavaAgent"
    echo "Actual JAVA_OPTS: $JAVA_OPTS"
    export JAVA_OPTS="$JAVA_OPTS -javaagent:/opt/sonarqube/extensions/plugins/sonarqube-community-branch-plugin-25.5.0.jar"
    echo "Nuevo JAVA_OPTS: $JAVA_OPTS"
fi

# Verificar SONAR_WEB_JAVAOPTS
if [[ "$SONAR_WEB_JAVAOPTS" != *"-javaagent:/opt/sonarqube/extensions/plugins/sonarqube-community-branch-plugin-25.5.0.jar"* ]]; then
    echo "ADVERTENCIA: SONAR_WEB_JAVAOPTS no contiene la configuración del JavaAgent"
    echo "Actual SONAR_WEB_JAVAOPTS: $SONAR_WEB_JAVAOPTS"
    export SONAR_WEB_JAVAOPTS="$SONAR_WEB_JAVAOPTS -javaagent:/opt/sonarqube/extensions/plugins/sonarqube-community-branch-plugin-25.5.0.jar"
    echo "Nuevo SONAR_WEB_JAVAOPTS: $SONAR_WEB_JAVAOPTS"
fi

# Verificar SONAR_CE_JAVAOPTS
if [[ "$SONAR_CE_JAVAOPTS" != *"-javaagent:/opt/sonarqube/extensions/plugins/sonarqube-community-branch-plugin-25.5.0.jar"* ]]; then
    echo "ADVERTENCIA: SONAR_CE_JAVAOPTS no contiene la configuración del JavaAgent"
    echo "Actual SONAR_CE_JAVAOPTS: $SONAR_CE_JAVAOPTS"
    export SONAR_CE_JAVAOPTS="$SONAR_CE_JAVAOPTS -javaagent:/opt/sonarqube/extensions/plugins/sonarqube-community-branch-plugin-25.5.0.jar"
    echo "Nuevo SONAR_CE_JAVAOPTS: $SONAR_CE_JAVAOPTS"
fi

echo "Configuración del Community Branch Plugin completada correctamente"