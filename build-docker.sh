#!/bin/bash
set -e

# Variables
VERSION="25.5.0.107428"
IMAGE_NAME="sonarqube-railway"
DOCKERFILE="Dockerfile.railway"

echo "==========================================="
echo "Building SonarQube Community Build $VERSION Docker image..."
echo "==========================================="

# Login to Docker Hub
echo "Logging in to Docker Hub..."
docker login

# Pull base image first to ensure it exists
echo "Pulling base SonarQube image..."
docker pull sonarqube:25.5.0.107428-community

# Build the custom image
echo "Building custom SonarQube image..."
docker build -t $IMAGE_NAME -f $DOCKERFILE .

echo "==========================================="
echo "Image build complete. You can run it with:"
echo "docker run -d -p 9000:9000 $IMAGE_NAME"
echo "==========================================="