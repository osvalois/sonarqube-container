#!/bin/bash
# Elasticsearch wrapper to force memory settings

echo "[ES Wrapper] Intercepting Elasticsearch startup..."
echo "[ES Wrapper] Original command: $@"

# Force proper memory settings
export ES_JAVA_OPTS="-Xms256m -Xmx512m -XX:MaxDirectMemorySize=256m"

# Remove any -Xms/-Xmx from original arguments
FILTERED_ARGS=""
skip_next=false
for arg in "$@"; do
    if [[ "$arg" =~ ^-Xms || "$arg" =~ ^-Xmx ]]; then
        continue
    fi
    if [ "$skip_next" = true ]; then
        skip_next=false
        continue
    fi
    if [[ "$arg" == "-Xms"* ]] || [[ "$arg" == "-Xmx"* ]]; then
        skip_next=true
        continue
    fi
    FILTERED_ARGS="$FILTERED_ARGS $arg"
done

echo "[ES Wrapper] Starting with ES_JAVA_OPTS: $ES_JAVA_OPTS"
echo "[ES Wrapper] Filtered args: $FILTERED_ARGS"

# Call original elasticsearch with forced memory settings
exec /opt/sonarqube/elasticsearch/bin/elasticsearch.original $ES_JAVA_OPTS $FILTERED_ARGS