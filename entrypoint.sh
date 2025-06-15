#!/bin/bash
set -e

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
            echo "         To fix this issue:"
            echo "         1. Run 'sudo sysctl -w vm.max_map_count=262144' on the Docker host"
            echo "         2. Add 'vm.max_map_count=262144' to /etc/sysctl.conf for persistence"
            echo "         See DOCKER_HOST_REQUIREMENTS.md for detailed instructions"
        fi
    else
        echo "vm.max_map_count is already set to $CURRENT_MAP_COUNT (sufficient for Elasticsearch)"
    fi
fi

# Change ownership of required directories to sonarqube user
chown -R sonarqube:sonarqube "$SQ_DATA_DIR" "$SQ_EXTENSIONS_DIR" "$SQ_LOGS_DIR" "$SQ_TEMP_DIR"

DEFAULT_CMD=('su-exec' 'sonarqube' '/opt/java/openjdk/bin/java' '-jar' 'lib/sonar-application-2025.1.0.77975.jar' '-Dsonar.log.console=true')

# this if will check if the first argument is a flag
# but only works if all arguments require a hyphenated flag
# -v; -SL; -f arg; etc will work, but not arg1 arg2
if [ "$#" -eq 0 ] || [ "${1#-}" != "$1" ]; then
    set -- "${DEFAULT_CMD[@]}" "$@"
fi

exec "$@"