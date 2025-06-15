#!/bin/bash
# Railway-specific startup script for SonarQube

set -euo pipefail

echo "🚀 Starting SonarQube for Railway deployment - divine-intuition"
echo "📍 Instance: divine-intuition (8 vCPU, 8GB RAM)"
echo "🌐 Domain: sonarqube-container-production-a7e6.up.railway.app"
echo "🔌 Port: ${PORT:-9000}"

# Critical directories for SonarQube
mkdir -p /opt/sonarqube/data /opt/sonarqube/extensions /opt/sonarqube/logs /opt/sonarqube/temp /opt/sonarqube/temp/conf/es
chmod -R 777 /opt/sonarqube/data /opt/sonarqube/extensions /opt/sonarqube/logs /opt/sonarqube/temp

# Create custom Elasticsearch config if it doesn't exist
if [ ! -f "/opt/sonarqube/temp/conf/es/elasticsearch.yml" ]; then
  echo "📝 Creating Elasticsearch configuration..."
  cat > /opt/sonarqube/temp/conf/es/elasticsearch.yml << EOF
# Railway-specific Elasticsearch configuration
node.name: sonarqube
cluster.name: sonarqube
discovery.type: single-node
cluster.routing.allocation.disk.threshold_enabled: false
bootstrap.system_call_filter: false
discovery.seed_hosts: 127.0.0.1
network.host: 127.0.0.1
transport.host: 127.0.0.1
http.host: 127.0.0.1
xpack.security.enabled: false
action.auto_create_index: false
EOF
  chmod 777 /opt/sonarqube/temp/conf/es/elasticsearch.yml
fi

# Export critical variables for Elasticsearch
export ES_JAVA_OPTS="-Xms512m -Xmx1g -XX:+UseSerialGC -XX:MaxDirectMemorySize=512m -Des.enforce.bootstrap.checks=false -Des.bootstrap.system_call_filter=false -Des.bootstrap.checks=false"
# Prevent GC conflicts
export JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75.0"

# Database connection check
if [ -n "${SONAR_JDBC_URL:-}" ]; then
    echo "✅ Database URL configured: ${SONAR_JDBC_URL}"
else
    echo "⚠️  No database URL configured. Using embedded H2 database (not recommended for production)"
fi

# Find the sonar-application JAR dynamically
SONAR_APP_JAR=$(find /opt/sonarqube/lib -name "sonar-application-*.jar" -type f | head -1)

if [ -z "$SONAR_APP_JAR" ]; then
    echo "❌ ERROR: Could not find sonar-application JAR file"
    exit 1
fi

echo "📦 Found SonarQube JAR: $SONAR_APP_JAR"

# Plugin verification
echo "🔌 Verifying plugins..."
ls -la /opt/sonarqube/extensions/plugins/

# Memory settings display
echo "🧠 Memory settings:"
echo "JAVA_OPTS: ${JAVA_OPTS:-Not set}"
echo "SONAR_WEB_JAVAOPTS: ${SONAR_WEB_JAVAOPTS:-Not set}"
echo "SONAR_CE_JAVAOPTS: ${SONAR_CE_JAVAOPTS:-Not set}"
echo "SONAR_SEARCH_JAVAOPTS: ${SONAR_SEARCH_JAVAOPTS:-Not set}"
echo "ES_JAVA_OPTS: ${ES_JAVA_OPTS:-Not set}"

# Elasticsearch settings
echo "🔍 Elasticsearch configuration:"
cat /opt/sonarqube/temp/conf/es/elasticsearch.yml

# Add explicit paths to the JAVA_OPTS
export JAVA_OPTS="${JAVA_OPTS} -Dsonar.path.data=/opt/sonarqube/data -Dsonar.path.logs=/opt/sonarqube/logs -Dsonar.path.temp=/opt/sonarqube/temp"

# Start SonarQube with Railway-specific settings
echo "🚀 Launching SonarQube with Railway-specific settings..."
exec java \
    -Djava.security.egd=file:/dev/./urandom \
    -Dfile.encoding=UTF-8 \
    ${JAVA_OPTS} \
    -Dsonar.web.port=${PORT:-9000} \
    -Dsonar.web.host=${SONAR_WEB_HOST:-0.0.0.0} \
    -Dsonar.search.javaOpts="${SONAR_SEARCH_JAVAOPTS:-'-Xms512m -Xmx1g -XX:+UseSerialGC -XX:MaxDirectMemorySize=512m -Des.enforce.bootstrap.checks=false -Des.bootstrap.system_call_filter=false -Des.bootstrap.checks=false'}" \
    -Dsonar.search.javaAdditionalOpts="-Des.enforce.bootstrap.checks=false -Des.bootstrap.system_call_filter=false -Des.bootstrap.checks=false" \
    -Dsonar.web.javaOpts="${SONAR_WEB_JAVAOPTS:-'-Xmx1g -Xms512m -XX:+UseSerialGC'}" \
    -Dsonar.ce.javaOpts="${SONAR_CE_JAVAOPTS:-'-Xmx1g -Xms512m -XX:+UseSerialGC'}" \
    -Dsonar.telemetry.enable=${SONAR_TELEMETRY_ENABLE:-false} \
    -Dsonar.updatecenter.activate=${SONAR_UPDATECENTER_ACTIVATE:-false} \
    -Dsonar.log.level=INFO \
    -Dsonar.ce.workerCount=4 \
    -Dsonar.cluster.enabled=false \
    -Dsonar.es.bootstrap.checks.disable=${SONAR_ES_BOOTSTRAP_CHECKS_DISABLE:-true} \
    -jar "$SONAR_APP_JAR"