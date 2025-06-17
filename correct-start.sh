#!/bin/bash
set -e

echo "=== Iniciando SonarQube con Community Branch Plugin ==="

# Directorio de instalación de SonarQube
SQ_HOME="/opt/sonarqube"
PLUGIN_JAR="$SQ_HOME/extensions/plugins/sonarqube-community-branch-plugin-25.5.0.jar"

# Verificar existencia del plugin
if [ ! -f "$PLUGIN_JAR" ]; then
    echo "ERROR: Plugin JAR no encontrado en $PLUGIN_JAR"
    exit 1
fi

# Mostrar versión del plugin
echo "Plugin encontrado: $PLUGIN_JAR"
chmod 644 "$PLUGIN_JAR"
chown 1000:0 "$PLUGIN_JAR"

# Crear archivo de propiedades para el plugin
mkdir -p "$SQ_HOME/conf"
cat > "$SQ_HOME/conf/sonar.properties" << EOF
# Community Branch Plugin Configuration
sonar.web.javaAdditionalOpts=-javaagent:$PLUGIN_JAR=web
sonar.ce.javaAdditionalOpts=-javaagent:$PLUGIN_JAR=ce
sonar.community.branch.enabled=true
sonar.community.branch.autoMerge=true
sonar.branch.longLivedBranches.regex=(master|main|develop|release/.+|hotfix/.+)

# Elasticsearch Configuration
sonar.search.javaOpts=-Xms512m -Xmx512m -XX:MaxDirectMemorySize=256m -Des.enforce.bootstrap.checks=true -Des.bootstrap.system_call_filter=false -Des.node.store.allow_mmap=false
sonar.search.bootstrap.checks.disable=true
EOF

# Establecer variables de entorno correctas según documentación oficial
export SONAR_WEB_JAVAADDITIONALOPTS="-javaagent:$PLUGIN_JAR=web"
export SONAR_CE_JAVAADDITIONALOPTS="-javaagent:$PLUGIN_JAR=ce"

# Configurar vm.max_map_count para Elasticsearch
if [ "$(id -u)" = "0" ]; then
    echo "Configurando vm.max_map_count para Elasticsearch..."
    # Intentar aumentar el valor
    sysctl -w vm.max_map_count=262144 || echo "ADVERTENCIA: No se pudo configurar vm.max_map_count"
    # Verificar valor actual
    echo "Valor actual de vm.max_map_count: $(sysctl -n vm.max_map_count)"
fi

# Estas variables también pueden ser útiles
export SONAR_WEB_JAVAOPTS="-Xmx512m -Xms512m -javaagent:$PLUGIN_JAR=web"
export SONAR_CE_JAVAOPTS="-Xmx512m -Xms512m -javaagent:$PLUGIN_JAR=ce"

# Configurar variables adicionales para Elasticsearch
export SONAR_SEARCH_BOOTSTRAP_CHECKS_DISABLE="true"
export SONAR_ES_BOOTSTRAP_CHECKS_DISABLE="true"
export ES_JAVA_OPTS="-Xms512m -Xmx512m -XX:MaxDirectMemorySize=256m -Des.enforce.bootstrap.checks=true -Des.bootstrap.system_call_filter=false -Des.node.store.allow_mmap=false"

# Configuración para Elasticsearch
export SONAR_SEARCH_JAVAOPTS="-Xms512m -Xmx512m -XX:MaxDirectMemorySize=256m -Des.enforce.bootstrap.checks=true -Des.bootstrap.system_call_filter=false -Des.node.store.allow_mmap=false"

# Otras configuraciones generales
export SONAR_TELEMETRY_ENABLE="false"
export SONAR_UPDATECENTER_ACTIVATE="false"
export SONAR_WEB_HOST="0.0.0.0"
export SONAR_WEB_PORT="9000"

# Encontrar JAR de aplicación
SONAR_APP_JAR=$(find $SQ_HOME/lib -name "sonar-application-*.jar" -type f | head -1)
if [ -z "$SONAR_APP_JAR" ]; then
    echo "ERROR: No se encontró el JAR de la aplicación SonarQube"
    exit 1
fi

echo "Encontrado JAR de SonarQube: $SONAR_APP_JAR"
echo "Configuración de variables de entorno para JavaAgent:"
echo "SONAR_WEB_JAVAADDITIONALOPTS: $SONAR_WEB_JAVAADDITIONALOPTS"
echo "SONAR_CE_JAVAADDITIONALOPTS: $SONAR_CE_JAVAADDITIONALOPTS"

# Ejecutar script de configuración de Elasticsearch
if [ -x "/usr/local/bin/es-config.sh" ]; then
    echo "Ejecutando configuración de Elasticsearch..."
    source /usr/local/bin/es-config.sh
fi

# Iniciar SonarQube con la configuración correcta
if command -v gosu >/dev/null 2>&1; then
    echo "Iniciando SonarQube con gosu..."
    exec gosu sonarqube java -jar "$SONAR_APP_JAR" \
      -Dsonar.web.javaAdditionalOpts="$SONAR_WEB_JAVAADDITIONALOPTS" \
      -Dsonar.ce.javaAdditionalOpts="$SONAR_CE_JAVAADDITIONALOPTS" \
      -Dsonar.search.javaOpts="$SONAR_SEARCH_JAVAOPTS" \
      -Dsonar.search.bootstrap.checks.disable=true \
      -Des.enforce.bootstrap.checks=true \
      -Dsonar.log.console=true
else
    echo "Iniciando SonarQube directamente..."
    exec java -jar "$SONAR_APP_JAR" \
      -Dsonar.web.javaAdditionalOpts="$SONAR_WEB_JAVAADDITIONALOPTS" \
      -Dsonar.ce.javaAdditionalOpts="$SONAR_CE_JAVAADDITIONALOPTS" \
      -Dsonar.search.javaOpts="$SONAR_SEARCH_JAVAOPTS" \
      -Dsonar.search.bootstrap.checks.disable=true \
      -Des.enforce.bootstrap.checks=true \
      -Dsonar.log.console=true
fi