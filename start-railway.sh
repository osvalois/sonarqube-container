#!/bin/bash
set -euo pipefail

# Railway start script for SonarQube
echo "Starting SonarQube 25.5 for Railway deployment..."
echo "Port: ${PORT:-9000}"
echo "Database: ${SONAR_JDBC_URL:-Not configured}"

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

# Configure JVM options for Railway
export SONAR_WEB_JAVAADDITIONALOPTS="${SONAR_WEB_JAVAADDITIONALOPTS:-} -Dsonar.web.port=${PORT:-9000}"
export SONAR_CE_JAVAADDITIONALOPTS="${SONAR_CE_JAVAADDITIONALOPTS:-} -XX:+UseContainerSupport"
export SONAR_SEARCH_JAVAADDITIONALOPTS="${SONAR_SEARCH_JAVAADDITIONALOPTS:-} -Des.enforce.bootstrap.checks=false"

# Execute SonarQube
exec java \
    -Djava.security.egd=file:/dev/./urandom \
    -Dfile.encoding=UTF-8 \
    -Dsonar.web.port=${PORT:-9000} \
    ${SONAR_WEB_JAVAADDITIONALOPTS} \
    ${SONAR_CE_JAVAADDITIONALOPTS} \
    -jar "$SONAR_APP_JAR" \
    "$@"