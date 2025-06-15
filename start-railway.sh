#!/bin/bash
# Railway-specific startup script for SonarQube (8 vCPU, 8GB RAM)

set -euo pipefail

echo "🚀 Starting SonarQube for Railway deployment - divine-intuition"
echo "📍 Instance: divine-intuition (8 vCPU, 8GB RAM)"
echo "🌐 Domain: sonarqube-container-production-a7e6.up.railway.app"
echo "🔌 Port: ${PORT:-8080}"

# Environment variables for SonarQube components
# These will be passed to the JVM automatically through the Dockerfile

# Create required directories with correct permissions
mkdir -p /opt/sonarqube/data /opt/sonarqube/extensions /opt/sonarqube/logs /opt/sonarqube/temp
chmod -R 777 /opt/sonarqube/data /opt/sonarqube/extensions /opt/sonarqube/logs /opt/sonarqube/temp

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
echo "SONAR_WEB_JAVAADDITIONALOPTS: ${SONAR_WEB_JAVAADDITIONALOPTS:-Not set}"
echo "SONAR_CE_JAVAOPTS: ${SONAR_CE_JAVAOPTS:-Not set}"
echo "SONAR_CE_JAVAADDITIONALOPTS: ${SONAR_CE_JAVAADDITIONALOPTS:-Not set}"
echo "SONAR_SEARCH_JAVAOPTS: ${SONAR_SEARCH_JAVAOPTS:-Not set}"

# Start SonarQube directly with JAR
echo "🚀 Launching SonarQube with Railway-specific settings..."
exec java \
    -Djava.security.egd=file:/dev/./urandom \
    -Dfile.encoding=UTF-8 \
    ${JAVA_OPTS:+-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0} \
    -Dsonar.web.port=${SONAR_WEB_PORT:-8080} \
    -Dsonar.web.host=${SONAR_WEB_HOST:-0.0.0.0} \
    -Dsonar.search.javaOpts="${SONAR_SEARCH_JAVAOPTS:-'-Xmx1g -Xms512m -XX:MaxDirectMemorySize=256m'}" \
    -Dsonar.web.javaOpts="${SONAR_WEB_JAVAOPTS:-'-Xmx2g -Xms1g -XX:+UseG1GC -XX:MaxGCPauseMillis=200'}" \
    -Dsonar.web.javaAdditionalOpts="${SONAR_WEB_JAVAADDITIONALOPTS:-'-XX:+UseContainerSupport -XX:InitialRAMPercentage=50.0 -XX:MaxRAMPercentage=80.0 -XX:+ExitOnOutOfMemoryError'}" \
    -Dsonar.ce.javaOpts="${SONAR_CE_JAVAOPTS:-'-Xmx2g -Xms512m -XX:+UseG1GC'}" \
    -Dsonar.ce.javaAdditionalOpts="${SONAR_CE_JAVAADDITIONALOPTS:-'-XX:+UseContainerSupport -XX:InitialRAMPercentage=50.0 -XX:MaxRAMPercentage=80.0 -XX:+ExitOnOutOfMemoryError'}" \
    -Dsonar.telemetry.enable=${SONAR_TELEMETRY_ENABLE:-false} \
    -Dsonar.updatecenter.activate=${SONAR_UPDATECENTER_ACTIVATE:-false} \
    -Dsonar.log.level=INFO \
    -Dsonar.ce.workerCount=4 \
    -Dsonar.cluster.enabled=false \
    -Dsonar.es.bootstrap.checks.disable=${SONAR_ES_BOOTSTRAP_CHECKS_DISABLE:-true} \
    -jar "$SONAR_APP_JAR"