#!/bin/bash

# Script para instalar plugins adicionales en SonarQube Community Edition
# Para proyectos Java, JavaScript, Dart, Python, Rust

SONARQUBE_URL="http://localhost:9000"
USERNAME="admin"
PASSWORD="admin"

echo "=== Instalando plugins adicionales para SonarQube ==="

# Plugins disponibles para Community Edition
PLUGINS=(
    "sonar-rust-plugin"
    "sonar-yaml-plugin" 
    "shellcheck"
    "groovy"
    "sonar-findbugs"
    "pmd"
    "checkstyle"
    "sonar-hadolint"
)

# Función para instalar plugin
install_plugin() {
    local plugin_key=$1
    echo "Instalando plugin: $plugin_key"
    
    curl -u "$USERNAME:$PASSWORD" -X POST \
        "$SONARQUBE_URL/api/plugins/install?key=$plugin_key" \
        -o /dev/null -s -w "HTTP Status: %{http_code}\n"
    
    if [ $? -eq 0 ]; then
        echo "✅ Plugin $plugin_key enviado para instalación"
    else
        echo "❌ Error instalando plugin $plugin_key"
    fi
}

# Verificar que SonarQube esté disponible
echo "Verificando conexión a SonarQube..."
if curl -f -s "$SONARQUBE_URL/api/system/status" > /dev/null; then
    echo "✅ SonarQube está disponible"
else
    echo "❌ SonarQube no está disponible en $SONARQUBE_URL"
    exit 1
fi

# Instalar plugins
for plugin in "${PLUGINS[@]}"; do
    install_plugin "$plugin"
    sleep 2
done

echo ""
echo "=== Resumen de soporte de lenguajes ==="
echo "✅ Java - Soporte nativo completo"
echo "✅ JavaScript/TypeScript - Soporte nativo completo"  
echo "✅ Python - Soporte nativo completo"
echo "✅ HTML/CSS - Soporte nativo completo"
echo "✅ XML - Soporte nativo completo"
echo "🔧 Rust - Plugin comunitario instalado"
echo "🔧 YAML - Plugin instalado"
echo "🔧 Shell Scripts - Plugin ShellCheck instalado"
echo "🔧 Groovy - Plugin instalado"
echo "❌ C# - Requiere Developer Edition+"
echo "❌ C/C++ - Requiere Developer Edition+"
echo "🔧 Dart/Flutter - Plugin comunitario disponible"

echo ""
echo "=== Instrucciones ==="
echo "1. Reinicia SonarQube para aplicar los plugins:"
echo "   docker-compose restart sonarqube"
echo ""
echo "2. Los plugins se activarán después del reinicio"
echo ""
echo "3. Para lenguajes comerciales (C#, C++), considera actualizar a:"
echo "   - Developer Edition (incluye C#, C++, taint analysis)"
echo "   - Enterprise Edition (incluye OWASP/CWE reports)"

echo ""
echo "=== Plugins comunitarios adicionales disponibles ==="
echo "- Flutter/Dart: Plugins comunitarios en marketplace"
echo "- PMD, Checkstyle, FindBugs: Análisis adicional para Java"
echo "- ESLint: Integración con análisis JavaScript"