#!/bin/bash
set -e

# Try to increase vm.max_map_count if running with appropriate privileges
if [ "$(id -u)" = "0" ]; then
    echo "Attempting to set vm.max_map_count to 262144..."
    if sysctl -w vm.max_map_count=262144 2>/dev/null; then
        echo "Successfully set vm.max_map_count to 262144"
    else
        echo "WARNING: Could not set vm.max_map_count. If you encounter Elasticsearch bootstrap errors,"
        echo "         please ensure vm.max_map_count=262144 is set on the Docker host."
        echo "         See DOCKER_HOST_REQUIREMENTS.md for more information."
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