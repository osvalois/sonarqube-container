#!/bin/bash
set -e

echo "=== SonarQube Railway Deployment ==="
echo "Port: ${PORT:-9000}"
echo "Database URL: ${DATABASE_URL:-Not set}"

# Convert Railway DATABASE_URL to JDBC format if needed
if [ -n "$DATABASE_URL" ]; then
    # Extract components from DATABASE_URL
    if [[ "$DATABASE_URL" =~ postgres://([^:]+):([^@]+)@([^:]+):([^/]+)/(.+) ]]; then
        DB_USER="${BASH_REMATCH[1]}"
        DB_PASS="${BASH_REMATCH[2]}"
        DB_HOST="${BASH_REMATCH[3]}"
        DB_PORT="${BASH_REMATCH[4]}"
        DB_NAME="${BASH_REMATCH[5]}"
        
        # Remove query parameters if any
        DB_NAME="${DB_NAME%%\?*}"
        
        export SONAR_JDBC_URL="jdbc:postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME}"
        export SONAR_JDBC_USERNAME="${DB_USER}"
        export SONAR_JDBC_PASSWORD="${DB_PASS}"
        
        echo "Converted to JDBC URL: ${SONAR_JDBC_URL}"
    fi
fi

# Create sonar.properties from template
cp /opt/sonarqube/conf/sonar.properties.template /opt/sonarqube/conf/sonar.properties

# Update sonar.properties with environment variables
cat >> /opt/sonarqube/conf/sonar.properties << EOF

# Database configuration
sonar.jdbc.url=${SONAR_JDBC_URL}
sonar.jdbc.username=${SONAR_JDBC_USERNAME}
sonar.jdbc.password=${SONAR_JDBC_PASSWORD}

# Web server configuration
sonar.web.port=${PORT:-9000}
sonar.web.host=0.0.0.0

# Memory settings - Ultra low for Railway
sonar.web.javaOpts=-Xmx384m -Xms128m -XX:+HeapDumpOnOutOfMemoryError
sonar.ce.javaOpts=-Xmx384m -Xms128m -XX:+HeapDumpOnOutOfMemoryError
sonar.search.javaOpts=-Xmx512m -Xms512m -XX:MaxDirectMemorySize=256m -XX:+HeapDumpOnOutOfMemoryError

# Disable Elasticsearch bootstrap checks
sonar.search.javaAdditionalOpts=-Des.enforce.bootstrap.checks=false

# Path configurations
sonar.path.data=/opt/sonarqube/data
sonar.path.temp=/opt/sonarqube/temp

# Disable telemetry
sonar.telemetry.enable=false
EOF

# Ensure directories exist and have correct permissions
mkdir -p /opt/sonarqube/data /opt/sonarqube/temp /opt/sonarqube/logs
chmod -R 777 /opt/sonarqube/data /opt/sonarqube/temp /opt/sonarqube/logs

# Clear any existing Elasticsearch data
rm -rf /opt/sonarqube/data/es*

echo "Starting SonarQube..."

# Start SonarQube directly
exec java -jar /opt/sonarqube/lib/sonar-application-*.jar \
    -Dsonar.log.console=true \
    -Dsonar.log.level=INFO \
    -Dsonar.web.port=${PORT:-9000}