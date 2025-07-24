#!/bin/bash
set -euo pipefail

# Railway start script for SonarQube
echo "Starting SonarQube 25.5 for Railway deployment..."
echo "Port: ${PORT:-8080}"
echo "Database: ${SONAR_JDBC_URL:-Not configured}"
echo "Memory Limit: ${RAILWAY_MEMORY_LIMIT:-512MB}"

# Signal handlers for graceful shutdown
trap 'echo "Received SIGTERM, shutting down gracefully..."; exit 0' SIGTERM
trap 'echo "Received SIGINT, shutting down gracefully..."; exit 0' SIGINT

# Find the sonar-application JAR dynamically
SONAR_APP_JAR=$(find /opt/sonarqube/lib -name "sonar-application-*.jar" -type f | head -1)

if [ -z "$SONAR_APP_JAR" ]; then
    echo "ERROR: Could not find sonar-application JAR file"
    exit 1
fi

echo "Using JAR: $SONAR_APP_JAR"

# Configure JVM options for Railway with ultra-low memory
export SONAR_WEB_JAVAADDITIONALOPTS="${SONAR_WEB_JAVAADDITIONALOPTS:-} -Dsonar.web.port=${PORT:-8080} -XX:+UseContainerSupport -XX:MaxRAMPercentage=30.0"
export SONAR_CE_JAVAADDITIONALOPTS="${SONAR_CE_JAVAADDITIONALOPTS:-} -XX:+UseContainerSupport -XX:MaxRAMPercentage=30.0"
export SONAR_SEARCH_JAVAADDITIONALOPTS="${SONAR_SEARCH_JAVAADDITIONALOPTS:-} -Des.enforce.bootstrap.checks=false -XX:MaxRAMPercentage=40.0 -Des.node.store.allow_mmap=false"

# Create sonar.properties override if database URL is provided
if [ -n "${SONAR_JDBC_URL}" ]; then
    echo "Configuring database connection..."
    mkdir -p /opt/sonarqube/conf
    cat > /opt/sonarqube/conf/sonar.properties << EOF
sonar.jdbc.url=${SONAR_JDBC_URL}
sonar.jdbc.username=${SONAR_JDBC_USERNAME:-}
sonar.jdbc.password=${SONAR_JDBC_PASSWORD:-}
sonar.web.port=${PORT:-8080}
sonar.web.host=0.0.0.0
sonar.search.javaOpts=${SONAR_SEARCH_JAVAOPTS}
sonar.ce.javaOpts=${SONAR_CE_JAVAOPTS}
sonar.web.javaOpts=${SONAR_WEB_JAVAOPTS}
EOF
fi

# Execute SonarQube
exec java \
    -Djava.security.egd=file:/dev/./urandom \
    -Dfile.encoding=UTF-8 \
    -Dsonar.web.port=${PORT:-8080} \
    -XX:+UseContainerSupport \
    -XX:MaxRAMPercentage=75.0 \
    -jar "$SONAR_APP_JAR" \
    "$@"