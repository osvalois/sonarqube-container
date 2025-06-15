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

# Database connection check
echo "🔄 Checking database connection..."
if [ -n "${DATABASE_URL:-}" ]; then
    echo "✅ Database URL configured"
else
    echo "⚠️  Using default database configuration"
fi

# Memory optimization for Railway
echo "🧠 Optimizing memory settings..."
export SONAR_WEB_JAVAADDITIONALOPTS="${SONAR_WEB_JAVAADDITIONALOPTS} -XX:+ExitOnOutOfMemoryError"
export SONAR_CE_JAVAADDITIONALOPTS="${SONAR_CE_JAVAADDITIONALOPTS} -XX:+ExitOnOutOfMemoryError"
export SONAR_SEARCH_JAVAADDITIONALOPTS="${SONAR_SEARCH_JAVAADDITIONALOPTS} -XX:+ExitOnOutOfMemoryError"

# Plugin verification
echo "🔌 Verifying plugins..."
if [ -f "/opt/sonarqube/extensions/plugins/sonar-cnes-report-plugin.jar" ]; then
    echo "✅ CNES Report Plugin installed"
    ls -lh /opt/sonarqube/extensions/plugins/sonar-cnes-report-plugin.jar
else
    echo "❌ CNES Report Plugin not found!"
fi

# Start SonarQube
echo "🚀 Launching SonarQube..."
exec /opt/sonarqube/bin/linux-x86-64/sonar.sh console