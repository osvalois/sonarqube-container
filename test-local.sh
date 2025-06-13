#!/bin/bash

# Start Docker Desktop if not running
echo "Starting Docker Desktop..."
open -a Docker

# Wait for Docker to start
echo "Waiting for Docker daemon to start..."
while ! docker info > /dev/null 2>&1; do
    sleep 2
done

echo "Docker is running. Building image..."

# Build the image
docker build -t sonarqube-container-sonarqube:latest .

if [ $? -eq 0 ]; then
    echo "Build successful. Starting SonarQube with Railway PostgreSQL..."
    
    # Run SonarQube with your database configuration
    docker run -d \
        --name sonarqube-test \
        -p 9000:9000 \
        -e SONAR_JDBC_URL="jdbc:postgresql://centerbeam.proxy.rlwy.net:10795/railway" \
        -e SONAR_JDBC_USERNAME="postgres" \
        -e SONAR_JDBC_PASSWORD="YdrHocBwDVCjlrkFsqEgSfQclOZYDYLc" \
        -e SONARQUBE_VERSION="2025.1.0.77975" \
        -e SONAR_WEB_CONTEXT="/" \
        -e SONAR_WEB_HOST="0.0.0.0" \
        -e SONAR_WEB_PORT="9000" \
        -e SONAR_SECURITY_REALM="" \
        -e SONAR_AUTHENTICATOR_DOWNCASE="false" \
        sonarqube-container-sonarqube:latest

    echo "SonarQube started. Check logs with: docker logs sonarqube-test"
    echo "Access SonarQube at: http://localhost:9000"
    echo "To stop: docker stop sonarqube-test && docker rm sonarqube-test"
else
    echo "Build failed!"
    exit 1
fi