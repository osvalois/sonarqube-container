# Variables de configuración
DOCKER_REGISTRY ?= docker.io
IMAGE_NAME = osvalois/sonarqube-container
DOCKER_USERNAME = osvalois
SONARQUBE_VERSION = lts-community

# Git information for versioning
GIT_SHA := $(shell git rev-parse HEAD)
GIT_SHA_SHORT := $(shell git rev-parse --short HEAD)
GIT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
GIT_TAG := $(shell git describe --tags --abbrev=0 2>/dev/null || echo "untagged")
BUILD_DATE := $(shell date -u +'%Y-%m-%dT%H:%M:%SZ')

# Version tags following best practices
VERSION_TAG := sha-$(GIT_SHA_SHORT)
BRANCH_TAG := $(GIT_BRANCH)
DATE_TAG := $(shell date -u +'%Y%m%d')-$(GIT_SHA_SHORT)
LATEST_TAG := latest

# Construir la imagen de Docker con SHA como versión
build:
	@echo "Building image with SHA: $(GIT_SHA_SHORT)"
	docker build \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg BUILD_VERSION=$(VERSION_TAG) \
		--build-arg VCS_REF=$(GIT_SHA) \
		-t $(IMAGE_NAME):$(VERSION_TAG) \
		-t $(IMAGE_NAME):$(BRANCH_TAG) \
		-t $(IMAGE_NAME):$(DATE_TAG) \
		-f Dockerfile .
	@if [ "$(GIT_BRANCH)" = "main" ]; then \
		docker tag $(IMAGE_NAME):$(VERSION_TAG) $(IMAGE_NAME):$(LATEST_TAG); \
		echo "Tagged as latest"; \
	fi

# Construir con versión específica de SonarQube
build-version:
	docker build --build-arg SONARQUBE_VERSION=$(SONARQUBE_VERSION) \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg BUILD_VERSION=$(VERSION_TAG) \
		--build-arg VCS_REF=$(GIT_SHA) \
		-t $(IMAGE_NAME):$(VERSION_TAG) .

# Publicar la imagen en Docker Hub con todas las tags
publish: build
	@echo "Publishing images with tags:"
	@echo "  - $(VERSION_TAG)"
	@echo "  - $(BRANCH_TAG)"
	@echo "  - $(DATE_TAG)"
	docker push $(DOCKER_USERNAME)/$(IMAGE_NAME):$(VERSION_TAG)
	docker push $(DOCKER_USERNAME)/$(IMAGE_NAME):$(BRANCH_TAG)
	docker push $(DOCKER_USERNAME)/$(IMAGE_NAME):$(DATE_TAG)
	@if [ "$(GIT_BRANCH)" = "main" ]; then \
		docker push $(DOCKER_USERNAME)/$(IMAGE_NAME):$(LATEST_TAG); \
		echo "  - $(LATEST_TAG)"; \
	fi

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

# Mostrar información de versionado
info:
	@echo "Build Information:"
	@echo "  Git SHA: $(GIT_SHA)"
	@echo "  Git SHA Short: $(GIT_SHA_SHORT)"
	@echo "  Git Branch: $(GIT_BRANCH)"
	@echo "  Git Tag: $(GIT_TAG)"
	@echo "  Build Date: $(BUILD_DATE)"
	@echo ""
	@echo "Docker tags that will be created:"
	@echo "  - $(VERSION_TAG) (primary)"
	@echo "  - $(BRANCH_TAG) (branch)"
	@echo "  - $(DATE_TAG) (date-based)"
	@if [ "$(GIT_BRANCH)" = "main" ]; then \
		echo "  - $(LATEST_TAG) (latest)"; \
	fi

# Host system requirements check
check-host-requirements:
	@echo "Checking host system requirements for SonarQube/Elasticsearch..."
	@echo "Current vm.max_map_count:"
	@sysctl vm.max_map_count || echo "Failed to check vm.max_map_count"
	@echo ""
	@echo "To fix vm.max_map_count issues, run:"
	@echo "  sudo bash scripts/check-elasticsearch-requirements.sh"
	@echo ""
	@echo "Or run the following command:"
	@echo "  sudo sysctl -w vm.max_map_count=262144"
	@echo "  echo vm.max_map_count=262144 | sudo tee -a /etc/sysctl.conf"

# Ayuda
help:
	@echo "Comandos disponibles:"
	@echo "  build         - Construir imagen con SHA como versión"
	@echo "  build-version - Construir con versión específica de SonarQube"
	@echo "  publish       - Publicar imagen con todas las tags"
	@echo "  run           - Ejecutar con docker-compose"
	@echo "  run-standalone- Ejecutar contenedor standalone"
	@echo "  stop          - Detener servicios"
	@echo "  logs          - Ver logs del servicio"
	@echo "  status        - Verificar estado de servicios"
	@echo "  security-scan - Ejecutar análisis de seguridad con Trivy"
	@echo "  clean         - Eliminar las imágenes locales"
	@echo "  info          - Mostrar información de build y versionado"
	@echo "  check-host-requirements - Verificar requisitos del host para Elasticsearch"
	@echo "  help          - Mostrar esta ayuda"
	@echo ""
	@echo "Ejemplo de uso:"
	@echo "  make build    # Construye con sha-$(GIT_SHA_SHORT)"
	@echo "  make publish  # Publica con todas las tags"

.PHONY: build build-version publish run run-standalone stop logs status security-scan clean check-host-requirements help