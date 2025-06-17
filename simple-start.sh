#!/bin/bash
set -e

echo "=== Iniciando SonarQube con Community Branch Plugin ==="

# Definir el JAR del plugin
PLUGIN_JAR="/opt/sonarqube/extensions/plugins/sonarqube-community-branch-plugin-25.5.0.jar"

# Verificar existencia del JAR
if [ ! -f "$PLUGIN_JAR" ]; then
    echo "ERROR: Plugin JAR no encontrado en $PLUGIN_JAR"
    exit 1
fi

# Establecer permisos
chmod 644 "$PLUGIN_JAR"
chown 1000:0 "$PLUGIN_JAR"

# Configurar las variables de entorno - SOLO UNA VEZ
export JAVA_OPTS="-XX:MaxRAMPercentage=75.0"
export JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75.0"
export SONAR_WEB_JAVAOPTS="-Xmx512m -Xms256m"
export SONAR_CE_JAVAOPTS="-Xmx512m -Xms256m" 
export SONAR_SEARCH_JAVAOPTS="-Xms256m -Xmx512m -XX:MaxDirectMemorySize=256m -Des.enforce.bootstrap.checks=false -Des.bootstrap.system_call_filter=false -Des.bootstrap.checks=false -Des.node.store.allow_mmap=false"

# Crear la configuración para el plugin
mkdir -p /opt/sonarqube/conf
cat > /opt/sonarqube/conf/branch-plugin.properties << EOF
# Community Branch Plugin Configuration
sonar.community.branch.enabled=true
sonar.community.branch.autoMerge=true
sonar.branch.longLivedBranches.regex=(master|main|develop|release/.+|hotfix/.+)
sonar.branch.name.defaultForShortLivedBranches=true
sonar.branch.name.strategy=default
sonar.branch.target=main
EOF

# Encontrar el JAR de la aplicación
SONAR_APP_JAR=$(find /opt/sonarqube/lib -name "sonar-application-*.jar" -type f | head -1)
if [ -z "$SONAR_APP_JAR" ]; then
    echo "ERROR: No se encontró el JAR de la aplicación SonarQube"
    exit 1
fi

echo "Encontrado JAR de SonarQube: $SONAR_APP_JAR"

# Ejecutar SonarQube con un único JavaAgent
if command -v gosu >/dev/null 2>&1; then
    echo "Usando gosu para ejecución"
    exec gosu sonarqube java -javaagent:$PLUGIN_JAR -jar "$SONAR_APP_JAR" -Dsonar.log.console=true
else
    echo "Ejecución directa"
    exec java -javaagent:$PLUGIN_JAR -jar "$SONAR_APP_JAR" -Dsonar.log.console=true
fi