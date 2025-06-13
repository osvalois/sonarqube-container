# Nombre de la imagen y versión
IMAGE_NAME = osvalois/sonarqube-container
IMAGE_VERSION = 2025.1.3
DOCKER_USERNAME = osvalois
SONARQUBE_VERSION = 2025.1.0.77975

# Construir la imagen de Docker
build:
	docker build -t $(IMAGE_NAME):$(IMAGE_VERSION) .

# Construir con versión específica de SonarQube
build-version:
	docker build --build-arg SONARQUBE_VERSION=$(SONARQUBE_VERSION) -t $(IMAGE_NAME):$(IMAGE_VERSION) .

# Publicar la imagen en Docker Hub
publish: build
	docker tag $(IMAGE_NAME):$(IMAGE_VERSION) $(DOCKER_USERNAME)/$(IMAGE_NAME):$(IMAGE_VERSION)
	docker push $(DOCKER_USERNAME)/$(IMAGE_NAME):$(IMAGE_VERSION)

# Ejecutar con docker-compose (recomendado)
run:
	docker-compose up -d

# Ejecutar el contenedor standalone
run-standalone:
	docker run -d -p 9000:9000 \
		-v /opt/sonarqube/data:/opt/sonarqube/data \
		-v /opt/sonarqube/extensions:/opt/sonarqube/extensions \
		-v /opt/sonarqube/logs:/opt/sonarqube/logs \
		-v /opt/sonarqube/temp:/opt/sonarqube/temp \
		--name sonarqube $(IMAGE_NAME):$(IMAGE_VERSION)

# Limpiar las imágenes locales
clean:
	docker rmi $(IMAGE_NAME):$(IMAGE_VERSION)
	docker rmi $(DOCKER_USERNAME)/$(IMAGE_NAME):$(IMAGE_VERSION)

# Detener servicios
stop:
	docker-compose down

# Ver logs
logs:
	docker-compose logs -f sonarqube

# Verificar estado
status:
	docker-compose ps

# Ejecutar análisis de seguridad
security-scan:
	@echo "Ejecutando análisis de seguridad..."
	docker run --rm -v $(PWD):/workspace -w /workspace \
		aquasec/trivy fs --security-checks vuln,secret,config .

# Ayuda
help:
	@echo "Comandos disponibles:"
	@echo "  build         - Construir la imagen de Docker"
	@echo "  build-version - Construir con versión específica de SonarQube"
	@echo "  publish       - Publicar la imagen en Docker Hub"
	@echo "  run           - Ejecutar con docker-compose (recomendado)"
	@echo "  run-standalone- Ejecutar contenedor standalone"
	@echo "  stop          - Detener servicios"
	@echo "  logs          - Ver logs del servicio"
	@echo "  status        - Verificar estado de servicios"
	@echo "  security-scan - Ejecutar análisis de seguridad con Trivy"
	@echo "  clean         - Eliminar las imágenes locales"
	@echo "  help          - Mostrar esta ayuda"

.PHONY: build build-version publish run run-standalone stop logs status security-scan clean help