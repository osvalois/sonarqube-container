#!/bin/bash
# Script para configurar Elasticsearch para SonarQube

# Verificar si se está ejecutando como root
if [ "$(id -u)" -eq 0 ]; then
    echo "Configurando vm.max_map_count para Elasticsearch..."
    sysctl -w vm.max_map_count=262144 || echo "ADVERTENCIA: No se pudo configurar vm.max_map_count"
fi

# Crear archivo de configuración específico para Elasticsearch
mkdir -p /opt/sonarqube/conf
cat > /opt/sonarqube/conf/es-config.properties << EOF
# Elasticsearch Configuration
es.enforce.bootstrap.checks=true
es.bootstrap.system_call_filter=false
es.node.store.allow_mmap=false
es.discovery.type=single-node
EOF

# Exportar variables de entorno necesarias
export ES_JAVA_OPTS="-Xms512m -Xmx512m -XX:MaxDirectMemorySize=256m -Des.enforce.bootstrap.checks=true -Des.bootstrap.system_call_filter=false -Des.node.store.allow_mmap=false -Des.discovery.type=single-node"
export SONAR_SEARCH_JAVAOPTS="-Xms512m -Xmx512m -XX:MaxDirectMemorySize=256m -Des.enforce.bootstrap.checks=true -Des.bootstrap.system_call_filter=false -Des.node.store.allow_mmap=false -Des.discovery.type=single-node"
export SONAR_ES_BOOTSTRAP_CHECKS_DISABLE="true"
export SONAR_SEARCH_BOOTSTRAP_CHECKS_DISABLE="true"

echo "Configuración de Elasticsearch completada:"
echo "ES_JAVA_OPTS: $ES_JAVA_OPTS"
echo "SONAR_SEARCH_JAVAOPTS: $SONAR_SEARCH_JAVAOPTS"
echo "SONAR_ES_BOOTSTRAP_CHECKS_DISABLE: $SONAR_ES_BOOTSTRAP_CHECKS_DISABLE"
echo "SONAR_SEARCH_BOOTSTRAP_CHECKS_DISABLE: $SONAR_SEARCH_BOOTSTRAP_CHECKS_DISABLE"