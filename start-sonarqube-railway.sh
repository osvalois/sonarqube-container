#!/bin/bash
set -e

echo "=== SonarQube Ultimate Railway Configuration ==="
echo "Port: ${PORT:-9000}"
echo "Database: ${SONAR_JDBC_URL}"

# Ensure we have the correct port
export SONAR_WEB_PORT=${PORT:-9000}

# Force Elasticsearch memory settings in environment
export ES_JAVA_OPTS="-Xms256m -Xmx512m -XX:MaxDirectMemorySize=256m"
export SONAR_SEARCH_JAVA_OPTS="-Xms256m -Xmx512m -XX:MaxDirectMemorySize=256m"
export SONAR_SEARCH_JAVA_ADDITIONAL_OPTS="-Des.enforce.bootstrap.checks=false -Des.node.store.allow_mmap=false"

# Create a wrapper for the java command to intercept ES startup
cat > /usr/local/bin/java-wrapper << 'EOF'
#!/bin/bash
# Check if this is an Elasticsearch process
if echo "$@" | grep -q "elasticsearch"; then
    echo "[Java Wrapper] Detected Elasticsearch startup"
    # Filter out the low memory settings and inject our own
    NEW_ARGS=""
    skip_next=false
    for arg in "$@"; do
        if [[ "$arg" =~ ^-Xms4m$ ]] || [[ "$arg" =~ ^-Xmx64m$ ]]; then
            continue
        fi
        NEW_ARGS="$NEW_ARGS $arg"
    done
    echo "[Java Wrapper] Starting ES with: java -Xms256m -Xmx512m $NEW_ARGS"
    exec /opt/java/openjdk/bin/java -Xms256m -Xmx512m $NEW_ARGS
else
    # Not ES, run normally
    exec /opt/java/openjdk/bin/java "$@"
fi
EOF

chmod +x /usr/local/bin/java-wrapper

# Temporarily replace java in PATH
export PATH="/usr/local/bin:$PATH"

# Update sonar.properties with our settings
cat >> /opt/sonarqube/conf/sonar.properties << EOF

# Railway-specific settings
sonar.web.port=${PORT:-9000}
sonar.search.javaOpts=-Xms256m -Xmx512m -XX:MaxDirectMemorySize=256m
sonar.search.javaAdditionalOpts=-Des.enforce.bootstrap.checks=false -Des.node.store.allow_mmap=false
sonar.web.javaOpts=-Xmx384m -Xms128m
sonar.ce.javaOpts=-Xmx384m -Xms128m
EOF

echo "Starting SonarQube with forced memory configuration..."

# Start SonarQube
exec java -jar /opt/sonarqube/lib/sonar-application-*.jar \
    -Dsonar.log.console=true