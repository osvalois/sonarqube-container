#!/bin/bash
set -e

# Sync port configuration with Railway
if [ -n "$PORT" ]; then
    export SONAR_WEB_PORT="$PORT"
fi

# Try to increase vm.max_map_count if running with appropriate privileges
if [ "$(id -u)" = "0" ]; then
    echo "Checking vm.max_map_count setting..."
    CURRENT_MAP_COUNT=$(sysctl -n vm.max_map_count 2>/dev/null || echo "unknown")

    if [ "$CURRENT_MAP_COUNT" = "unknown" ]; then
        echo "WARNING: Could not check vm.max_map_count value."
    elif [ "$CURRENT_MAP_COUNT" -lt 262144 ]; then
        echo "Current vm.max_map_count is $CURRENT_MAP_COUNT (too low for Elasticsearch)"
        echo "Attempting to set vm.max_map_count to 262144..."

        if sysctl -w vm.max_map_count=262144 2>/dev/null; then
            echo "Successfully set vm.max_map_count to 262144"
        else
            echo "WARNING: Could not set vm.max_map_count. Elasticsearch bootstrap may fail."
        fi
    else
        echo "vm.max_map_count is already set to $CURRENT_MAP_COUNT (sufficient for Elasticsearch)"
    fi
fi

# Change ownership of required directories to sonarqube user
if [ "$(id -u)" = "0" ] && [ "${RUN_AS_ROOT}" != "true" ]; then
    echo "Setting directory permissions for sonarqube user..."
    chown -R sonarqube:sonarqube "$SQ_DATA_DIR" "$SQ_EXTENSIONS_DIR" "$SQ_LOGS_DIR" "$SQ_TEMP_DIR"
else
    echo "Running with current user permissions..."
fi

# Configurar el plugin Community Branch
echo "Configurando Community Branch Plugin..."
if [ -x "/usr/local/bin/bootstrap-branch-plugin.sh" ]; then
    /usr/local/bin/bootstrap-branch-plugin.sh
else
    echo "ADVERTENCIA: Script de configuración del plugin no encontrado"
fi

# Find the sonar-application JAR dynamically
# Look for any available JAR file with the right pattern
SONAR_APP_JAR=$(find /opt/sonarqube/lib -name "sonar-application-*.jar" -type f | head -1)

if [ -z "$SONAR_APP_JAR" ]; then
    echo "ERROR: Could not find sonar-application JAR file"
    exit 1
fi

echo "Found SonarQube application JAR: $SONAR_APP_JAR"

# Ensure JAVA_OPTS includes the JavaAgent for server
if [[ "$JAVA_OPTS" != *"-javaagent:/opt/sonarqube/extensions/plugins/sonarqube-community-branch-plugin-25.5.0.jar=server"* ]]; then
    export JAVA_OPTS="$JAVA_OPTS -javaagent:/opt/sonarqube/extensions/plugins/sonarqube-community-branch-plugin-25.5.0.jar=server"
    echo "Added JavaAgent to JAVA_OPTS: $JAVA_OPTS"
fi

# Check which privilege downgrade tool is available (su-exec or gosu)
if command -v su-exec >/dev/null 2>&1; then
    echo "Using su-exec for privilege downgrade"
    DEFAULT_CMD=('su-exec' 'sonarqube' '/opt/java/openjdk/bin/java' '-javaagent:/opt/sonarqube/extensions/plugins/sonarqube-community-branch-plugin-25.5.0.jar' '-jar' "$SONAR_APP_JAR" '-Dsonar.log.console=true' '-Des.discovery.type=single-node' '-Dsonar.search.bootstrap.checks.disable=true')
elif command -v gosu >/dev/null 2>&1; then
    echo "Using gosu for privilege downgrade"
    DEFAULT_CMD=('gosu' 'sonarqube' '/opt/java/openjdk/bin/java' '-javaagent:/opt/sonarqube/extensions/plugins/sonarqube-community-branch-plugin-25.5.0.jar' '-jar' "$SONAR_APP_JAR" '-Dsonar.log.console=true' '-Des.discovery.type=single-node' '-Dsonar.search.bootstrap.checks.disable=true')
else
    # Fallback to direct execution when neither su-exec nor gosu is available
    echo "Neither su-exec nor gosu found, falling back to direct execution with current user"
    DEFAULT_CMD=('/opt/java/openjdk/bin/java' '-javaagent:/opt/sonarqube/extensions/plugins/sonarqube-community-branch-plugin-25.5.0.jar' '-jar' "$SONAR_APP_JAR" '-Dsonar.log.console=true' '-Des.discovery.type=single-node' '-Dsonar.search.bootstrap.checks.disable=true')
fi

# this if will check if the first argument is a flag
# but only works if all arguments require a hyphenated flag
# -v; -SL; -f arg; etc will work, but not arg1 arg2
if [ "$#" -eq 0 ] || [ "${1#-}" != "$1" ]; then
    set -- "${DEFAULT_CMD[@]}" "$@"
fi

exec "$@"