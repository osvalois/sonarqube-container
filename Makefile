# Nombre de la imagen y versión
IMAGE_NAME = osvalois/sonarqube-container
IMAGE_VERSION = 1.0.2
DOCKER_USERNAME = osvalois

# Construir la imagen de Docker
build:
	docker build -t $(IMAGE_NAME):$(IMAGE_VERSION) .

# Publicar la imagen en Docker Hub
publish: build
	docker tag $(IMAGE_NAME):$(IMAGE_VERSION) $(DOCKER_USERNAME)/$(IMAGE_NAME):$(IMAGE_VERSION)
	docker push $(DOCKER_USERNAME)/$(IMAGE_NAME):$(IMAGE_VERSION)

# Ejecutar el contenedor de SonarQube
run:
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

# Ayuda
help:
	@echo "Comandos disponibles:"
	@echo "  build    - Construir la imagen de Docker"
	@echo "  publish  - Publicar la imagen en Docker Hub"
	@echo "  run      - Ejecutar el contenedor de SonarQube"
	@echo "  clean    - Eliminar las imágenes locales"
	@echo "  help     - Mostrar esta ayuda"

.PHONY: build publish run clean help