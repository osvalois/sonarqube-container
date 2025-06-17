#!/bin/bash
set -e

echo "===================================================="
echo "Iniciando SonarQube optimizado para Railway con Plugin de Branch"
echo "===================================================="

# Configurar el plugin Community Branch
export PLUGIN_JAR=/opt/sonarqube/extensions/plugins/sonarqube-community-branch-plugin-25.5.0.jar

# Verificar existencia del plugin
if [ ! -f "$PLUGIN_JAR" ]; then
    echo "ERROR: Plugin JAR no encontrado en $PLUGIN_JAR"
    exit 1
fi

# Asegurar que tenemos acceso directo al JavaAgent en el classpath de Java
echo "Configurando JavaAgent para todos los componentes..."

# Modificar variables de entorno para incluir el JavaAgent
export JAVA_OPTS="-javaagent:$PLUGIN_JAR $JAVA_OPTS"
export SONAR_WEB_JAVAOPTS="-javaagent:$PLUGIN_JAR $SONAR_WEB_JAVAOPTS"
export SONAR_CE_JAVAOPTS="-javaagent:$PLUGIN_JAR $SONAR_CE_JAVAOPTS"
export SONAR_SEARCH_JAVAOPTS="$SONAR_SEARCH_JAVAOPTS"

# Mostrar configuración para verificación
echo "JAVA_OPTS: $JAVA_OPTS"
echo "SONAR_WEB_JAVAOPTS: $SONAR_WEB_JAVAOPTS"
echo "SONAR_CE_JAVAOPTS: $SONAR_CE_JAVAOPTS"

# Ejecutar el script de inicio de Railway
echo "Iniciando SonarQube..."
exec /usr/local/bin/start-railway.sh