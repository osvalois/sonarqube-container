#!/bin/bash
set -e

echo "=== Patching SonarQube for Railway ==="

# Function to patch JAR files
patch_memory_settings() {
    echo "Searching for SonarQube configuration files..."
    
    # Find and patch any properties files
    find /opt/sonarqube -name "*.properties" -type f | while read -r file; do
        if grep -q "sonar.search.javaOpts" "$file" 2>/dev/null; then
            echo "Patching: $file"
            sed -i 's/sonar.search.javaOpts=.*/sonar.search.javaOpts=-Xms512m -Xmx512m -XX:MaxDirectMemorySize=256m/g' "$file"
        fi
    done
    
    # Patch wrapper.conf files
    find /opt/sonarqube -name "wrapper.conf" -type f | while read -r file; do
        echo "Patching wrapper config: $file"
        sed -i 's/wrapper.java.initmemory=.*/wrapper.java.initmemory=512/g' "$file" 2>/dev/null || true
        sed -i 's/wrapper.java.maxmemory=.*/wrapper.java.maxmemory=512/g' "$file" 2>/dev/null || true
    done
}

# Patch class files in JARs (aggressive approach)
patch_jar_files() {
    echo "Looking for sonar-application JAR..."
    
    # Find the main application JAR
    APP_JAR=$(find /opt/sonarqube/lib -name "sonar-application-*.jar" | head -1)
    
    if [ -n "$APP_JAR" ]; then
        echo "Found: $APP_JAR"
        # Create temp directory
        TEMP_DIR="/tmp/sonar-patch"
        mkdir -p "$TEMP_DIR"
        cd "$TEMP_DIR"
        
        # Extract JAR
        jar -xf "$APP_JAR" 2>/dev/null || unzip -q "$APP_JAR" || true
        
        # Look for ES launcher configurations
        find . -name "*.class" -o -name "*.properties" | while read -r file; do
            # Try to patch any ES memory references
            if file "$file" | grep -q "text"; then
                sed -i 's/-Xms4m/-Xms512m/g' "$file" 2>/dev/null || true
                sed -i 's/-Xmx64m/-Xmx512m/g' "$file" 2>/dev/null || true
            fi
        done
        
        # Repackage if we made changes
        if [ -f "META-INF/MANIFEST.MF" ]; then
            echo "Repackaging JAR..."
            jar -cfm "$APP_JAR.new" META-INF/MANIFEST.MF . 2>/dev/null || true
            if [ -f "$APP_JAR.new" ]; then
                mv "$APP_JAR.new" "$APP_JAR"
            fi
        fi
        
        cd /
        rm -rf "$TEMP_DIR"
    fi
}

# Override CommandFactoryImpl behavior
create_command_override() {
    cat > /opt/sonarqube/bin/sonar.sh << 'EOF'
#!/bin/bash
# Override script to force ES memory settings

if [[ "$@" == *"elasticsearch"* ]]; then
    echo "[Override] Detected Elasticsearch launch, forcing memory settings"
    # Replace the command with proper memory
    CMD="$@"
    CMD="${CMD//-Xms4m/-Xms512m}"
    CMD="${CMD//-Xmx64m/-Xmx512m}"
    echo "[Override] Running: $CMD"
    exec $CMD
else
    exec "$@"
fi
EOF
    chmod +x /opt/sonarqube/bin/sonar.sh
}

# Main execution
echo "Step 1: Patching configuration files..."
patch_memory_settings

echo "Step 2: Creating command override..."
create_command_override

echo "Step 3: Patching JAR files..."
patch_jar_files

# Set port from Railway
export SONAR_WEB_PORT=${PORT:-9000}

# Add database configuration if provided
if [ -n "$DATABASE_URL" ] || [ -n "$SONAR_JDBC_URL" ]; then
    echo "Configuring database..."
    cat >> /opt/sonarqube/conf/sonar.properties << EOF

# Database configuration
sonar.jdbc.url=${SONAR_JDBC_URL:-$DATABASE_URL}
sonar.jdbc.username=${SONAR_JDBC_USERNAME:-}
sonar.jdbc.password=${SONAR_JDBC_PASSWORD:-}
EOF
fi

echo "Starting patched SonarQube..."

# Try to find java in multiple locations
JAVA_CMD="/opt/java/openjdk/bin/java"
if [ ! -f "$JAVA_CMD" ]; then
    JAVA_CMD="java"
fi

# Force environment variables
export ES_JAVA_OPTS="-Xms512m -Xmx512m"
export SONAR_SEARCH_JAVA_OPTS="-Xms512m -Xmx512m"

# Start SonarQube with forced settings
exec $JAVA_CMD \
    -Dsonar.search.javaOpts="-Xms512m -Xmx512m -XX:MaxDirectMemorySize=256m" \
    -Dsonar.search.javaAdditionalOpts="-Des.enforce.bootstrap.checks=false" \
    -Dsonar.web.port=${PORT:-9000} \
    -jar /opt/sonarqube/lib/sonar-application-*.jar