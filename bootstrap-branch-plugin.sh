#!/bin/bash
# Este script se ejecuta en el entrypoint para configurar correctamente el Community Branch Plugin

# Directorio de instalación
PLUGIN_JAR="/opt/sonarqube/extensions/plugins/sonarqube-community-branch-plugin-25.5.0.jar"
CONF_FILE="/opt/sonarqube/conf/branch-plugin.properties"

# Verificar existencia del plugin
if [ ! -f "$PLUGIN_JAR" ]; then
    echo "ERROR: Plugin JAR no encontrado en $PLUGIN_JAR"
    exit 1
fi

# Mensaje informativo
echo "Configurando Community Branch Plugin para SonarQube..."

# Modificar la configuración de SonarQube para soporte de ramas
cat > "$CONF_FILE" << EOF
# Community Branch Plugin Configuration for SonarQube 25.5.0
sonar.community.branch.enabled=true
sonar.community.branch.autoMerge=true
sonar.branch.longLivedBranches.regex=(master|main|develop|release/.+|hotfix/.+)
sonar.branch.issue.tracker.patterns.FIX={KEY}
sonar.pullrequest.provider=github
sonar.branch.name.defaultForShortLivedBranches=true
sonar.branch.name.strategy=default
sonar.branch.target=main
sonar.community.branch.security.enabled=true
EOF

# Asegurar permisos del JAR
chmod 644 "$PLUGIN_JAR"
chown 1000:0 "$PLUGIN_JAR"

# Verificar variables JAVA_OPTS
if [[ "$JAVA_OPTS" != *"javaagent"* ]]; then
    echo "Agregando configuración JavaAgent a JAVA_OPTS..."
    export JAVA_OPTS="$JAVA_OPTS -javaagent:$PLUGIN_JAR"
    echo "JAVA_OPTS actualizado: $JAVA_OPTS"
fi

# Verificar variables JAVA_TOOL_OPTIONS
if [[ "$JAVA_TOOL_OPTIONS" != *"javaagent"* ]]; then
    echo "Agregando configuración JavaAgent a JAVA_TOOL_OPTIONS..."
    export JAVA_TOOL_OPTIONS="$JAVA_TOOL_OPTIONS -javaagent:$PLUGIN_JAR"
    echo "JAVA_TOOL_OPTIONS actualizado: $JAVA_TOOL_OPTIONS"
fi

# Verificar SONAR_WEB_JAVAOPTS
if [[ "$SONAR_WEB_JAVAOPTS" != *"javaagent"* ]]; then
    echo "Agregando configuración JavaAgent a SONAR_WEB_JAVAOPTS..."
    export SONAR_WEB_JAVAOPTS="$SONAR_WEB_JAVAOPTS -javaagent:$PLUGIN_JAR"
    echo "SONAR_WEB_JAVAOPTS actualizado: $SONAR_WEB_JAVAOPTS"
fi

# Verificar SONAR_CE_JAVAOPTS
if [[ "$SONAR_CE_JAVAOPTS" != *"javaagent"* ]]; then
    echo "Agregando configuración JavaAgent a SONAR_CE_JAVAOPTS..."
    export SONAR_CE_JAVAOPTS="$SONAR_CE_JAVAOPTS -javaagent:$PLUGIN_JAR"
    echo "SONAR_CE_JAVAOPTS actualizado: $SONAR_CE_JAVAOPTS"
fi

echo "Configuración de Community Branch Plugin completada"
echo "- JavaAgent configurado para server, web y ce"
echo "- Archivo de configuración creado en $CONF_FILE"