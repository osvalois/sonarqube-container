#!/bin/bash

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "🔧 Construyendo imagen Docker..."

# Limpiar contenedores anteriores si existen
docker stop sonarqube-test 2>/dev/null
docker rm sonarqube-test 2>/dev/null

# Construir imagen
docker build -t sonarqube-container:latest .

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Build exitoso${NC}"
    
    echo ""
    echo "🚀 Iniciando contenedor de prueba..."
    
    # Ejecutar contenedor con configuración de Railway
    docker run -d \
        --name sonarqube-test \
        -p 9000:9000 \
        -e SONAR_JDBC_URL="jdbc:postgresql://centerbeam.proxy.rlwy.net:10795/railway" \
        -e SONAR_JDBC_USERNAME="postgres" \
        -e SONAR_JDBC_PASSWORD="YdrHocBwDVCjlrkFsqEgSfQclOZYDYLc" \
        -e SONAR_WEB_CONTEXT="/" \
        -e SONAR_WEB_HOST="0.0.0.0" \
        -e SONAR_WEB_PORT="9000" \
        sonarqube-container:latest
    
    echo ""
    echo "⏳ Esperando 30 segundos para que SonarQube inicie..."
    sleep 30
    
    echo ""
    echo "📋 Logs del contenedor:"
    echo "----------------------------------------"
    docker logs sonarqube-test --tail 50
    echo "----------------------------------------"
    
    # Verificar si el contenedor está corriendo
    if [ $(docker ps -q -f name=sonarqube-test) ]; then
        echo -e "${GREEN}✅ Contenedor ejecutándose correctamente${NC}"
        echo ""
        echo "🌐 SonarQube disponible en: http://localhost:9000"
        echo "📌 Usuario por defecto: admin"
        echo "🔑 Contraseña por defecto: admin"
        echo ""
        echo "Para ver logs en tiempo real: docker logs -f sonarqube-test"
        echo "Para detener: docker stop sonarqube-test && docker rm sonarqube-test"
    else
        echo -e "${RED}❌ El contenedor no está ejecutándose${NC}"
        echo "Verificando estado..."
        docker ps -a | grep sonarqube-test
    fi
else
    echo -e "${RED}❌ Error en el build${NC}"
    exit 1
fi