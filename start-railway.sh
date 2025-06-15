#!/bin/bash
# Railway-specific startup script for SonarQube

set -euo pipefail

echo "🚀 Starting SonarQube for Railway deployment..."
echo "📍 Instance: divine-intuition"
echo "🌐 Domain: sonarqube-container-production-a7e6.up.railway.app"
echo "🔌 Port: ${PORT:-8080}"
echo "💾 Memory: 8GB available"

# Set Railway-specific environment variables
export SONAR_WEB_PORT=${PORT:-8080}
export SONAR_WEB_HOST=0.0.0.0

# Fix Elasticsearch memory settings
export ES_JAVA_OPTS="-Xms512m -Xmx1g"
export SONAR_SEARCH_JAVA_OPTS="-Xms512m -Xmx1g -XX:MaxDirectMemorySize=256m"
export SONAR_SEARCH_JAVAADDITIONALOPTS="-Xms512m -Xmx1g -XX:MaxDirectMemorySize=256m"

# Override the default Elasticsearch settings
export SONARQUBE_SEARCH_JVM_OPTS="-Xmx1g -Xms512m"

# Database connection check
echo "🔄 Checking database connection..."
if [ -n "${DATABASE_URL:-}" ]; then
    echo "✅ Database URL configured"
    # Parse DATABASE_URL if it's in URL format
    if [[ $DATABASE_URL =~ postgres://([^:]+):([^@]+)@([^:]+):([^/]+)/(.+) ]]; then
        export SONAR_JDBC_URL="jdbc:postgresql://${BASH_REMATCH[3]}:${BASH_REMATCH[4]}/${BASH_REMATCH[5]}"
        export SONAR_JDBC_USERNAME="${BASH_REMATCH[1]}"
        export SONAR_JDBC_PASSWORD="${BASH_REMATCH[2]}"
    fi
elif [ -n "${SONAR_JDBC_URL:-}" ]; then
    echo "✅ SONAR_JDBC_URL configured: ${SONAR_JDBC_URL}"
else
    echo "⚠️  Using embedded H2 database (not recommended for production)"
fi

# Memory optimization for Railway
echo "🧠 Optimizing memory settings..."
export SONAR_WEB_JAVAADDITIONALOPTS="${SONAR_WEB_JAVAADDITIONALOPTS} -XX:+ExitOnOutOfMemoryError"
export SONAR_CE_JAVAADDITIONALOPTS="${SONAR_CE_JAVAADDITIONALOPTS} -XX:+ExitOnOutOfMemoryError"

# Find the sonar-application JAR dynamically
SONAR_APP_JAR=$(find /opt/sonarqube/lib -name "sonar-application-*.jar" -type f | head -1)

if [ -z "$SONAR_APP_JAR" ]; then
    echo "❌ ERROR: Could not find sonar-application JAR file"
    exit 1
fi

echo "📦 Found SonarQube JAR: $SONAR_APP_JAR"

# Plugin verification
echo "🔌 Verifying plugins..."
if [ -f "/opt/sonarqube/extensions/plugins/sonar-cnes-report-plugin.jar" ]; then
    echo "✅ CNES Report Plugin installed"
    ls -lh /opt/sonarqube/extensions/plugins/sonar-cnes-report-plugin.jar
else
    echo "❌ CNES Report Plugin not found!"
fi

# Configuration applied via system properties (no file modification needed)
echo "📝 Configuration will be applied via system properties..."

# Start SonarQube directly with JAR
echo "🚀 Launching SonarQube..."
exec java \
    -Djava.security.egd=file:/dev/./urandom \
    -Dfile.encoding=UTF-8 \
    -Dsonar.web.port=${PORT:-8080} \
    -Dsonar.web.host=0.0.0.0 \
    -Dsonar.search.javaOpts="-Xmx1g -Xms512m -XX:MaxDirectMemorySize=256m" \
    -Dsonar.search.javaAdditionalOpts="-XX:+UseG1GC" \
    $SONAR_WEB_JAVAADDITIONALOPTS \
    $SONAR_CE_JAVAADDITIONALOPTS \
    -jar "$SONAR_APP_JAR"