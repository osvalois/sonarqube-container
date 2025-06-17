#!/bin/bash
set -e

# Script para generar reportes de SonarQube usando el plugin CNES Report
# Uso: ./generate-report.sh [project_key] [branch_name]

echo "==========================================="
echo "Generador de Reportes SonarQube CNES"
echo "==========================================="

# Obtener variables de railway.toml
if [ -f railway.toml ]; then
    # Extraer URL del servidor SonarQube
    SONAR_URL="http://localhost:9000"  # Valor predeterminado
    
    # Extraer puerto
    PORT=$(grep "PORT" railway.toml | cut -d '=' -f2 | tr -d ' "')
    if [ -n "$PORT" ]; then
        SONAR_URL="http://localhost:${PORT}"
    fi
    
    echo "URL de SonarQube: $SONAR_URL"
fi

# Parámetros del reporte
PROJECT_KEY=${1:-"all"}  # Usar "all" para todos los proyectos si no se especifica
BRANCH_NAME=${2:-"master"}  # Usar "master" por defecto

echo "Proyecto: $PROJECT_KEY"
echo "Rama: $BRANCH_NAME"

# Llamar a la API de CNES Report para generar el reporte
echo "Generando reporte..."

REPORT_URL="${SONAR_URL}/api/cnesreport/report"
REPORT_PARAMS="?project=${PROJECT_KEY}&branch=${BRANCH_NAME}&author=SonarQubeRailway&template=true"

curl -X GET "${REPORT_URL}${REPORT_PARAMS}" -o sonar-report.zip

if [ -f sonar-report.zip ]; then
    echo "Reporte descargado exitosamente como 'sonar-report.zip'"
    echo "Descomprimiendo reporte..."
    mkdir -p sonar-reports
    unzip -o sonar-report.zip -d sonar-reports
    echo "Reporte disponible en el directorio 'sonar-reports'"
else
    echo "Error al generar el reporte. Verifica que SonarQube esté en funcionamiento."
fi

echo "==========================================="
echo "Proceso completado"
echo "==========================================="