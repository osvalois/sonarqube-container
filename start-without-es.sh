#!/bin/bash
set -e

echo "=== SonarQube No-Elasticsearch Mode ==="
echo "Port: ${PORT:-9000}"

# Configure database
if [ -n "$DATABASE_URL" ]; then
    echo "sonar.jdbc.url=$DATABASE_URL" >> /opt/sonarqube/conf/sonar.properties
elif [ -n "$SONAR_JDBC_URL" ]; then
    echo "sonar.jdbc.url=$SONAR_JDBC_URL" >> /opt/sonarqube/conf/sonar.properties
    echo "sonar.jdbc.username=$SONAR_JDBC_USERNAME" >> /opt/sonarqube/conf/sonar.properties
    echo "sonar.jdbc.password=$SONAR_JDBC_PASSWORD" >> /opt/sonarqube/conf/sonar.properties
fi

# Update port
sed -i "s/sonar.web.port=.*/sonar.web.port=${PORT:-9000}/" /opt/sonarqube/conf/sonar.properties

# Try to start without ES
echo "Starting SonarQube without Elasticsearch..."

# Direct start bypassing ES check
exec java \
    -Dsonar.log.console=true \
    -Dsonar.web.port=${PORT:-9000} \
    -Dsonar.search.host=disabled \
    -jar /opt/sonarqube/lib/sonar-application-*.jar \
    --no-search