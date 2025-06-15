# SonarQube DevSecOps 2025

Contenedor de SonarQube optimizado para despliegues en Railway y Docker, con soporte para análisis de código mejorado.

## Características

- Basado en SonarQube Community Edition (última versión estable)
- Optimizado para entornos con recursos limitados
- Configurado para despliegue en Railway
- Incluye plugin CNES Report para generar informes avanzados
- Soporte para múltiples lenguajes (Java, JavaScript, Python, etc.)
- Configuración de seguridad y rendimiento optimizada

## Requisitos

- Docker y Docker Compose para desarrollo local
- Cuenta en Railway para despliegue en la nube
- Al menos 4GB de RAM disponible para ejecución local

## Uso Local

1. Clonar el repositorio:
   ```bash
   git clone https://github.com/osvalois/sonarqube-container.git
   cd sonarqube-container
   ```

2. Crear archivo `.env` con las variables de entorno necesarias:
   ```bash
   # Ejemplo de .env
   SONAR_JDBC_URL=jdbc:postgresql://localhost:5432/sonar
   SONAR_JDBC_USERNAME=sonar
   SONAR_JDBC_PASSWORD=sonar
   ```

3. Iniciar SonarQube con Docker Compose:
   ```bash
   docker-compose up -d
   ```

4. Acceder a SonarQube en http://localhost:9000 (usuario: admin, contraseña: admin)

## Despliegue en Railway

1. Asegúrate de tener una cuenta en Railway y el CLI instalado.

2. Conecta tu repositorio de GitHub a Railway.

3. Railway detectará automáticamente la configuración en `railway.toml`.

4. Configura las variables de entorno en Railway:
   - `SONAR_JDBC_URL`: URL de conexión a la base de datos PostgreSQL
   - `SONAR_JDBC_USERNAME`: Usuario de la base de datos
   - `SONAR_JDBC_PASSWORD`: Contraseña de la base de datos

5. Inicia el despliegue en Railway.

## Solución de Problemas

### Error de permisos "Permission denied"

Si encuentras errores de permisos al ejecutar SonarQube en Railway, verifica:

1. La variable `RUN_AS_ROOT` debe estar configurada como `true`.
2. No intentar modificar directamente archivos de configuración, en su lugar usar propiedades del sistema Java.

### Problemas con Elasticsearch

Para evitar problemas con Elasticsearch en entornos contenedorizados:

1. Configurar la variable `SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true`.
2. Asegurar que `vm.max_map_count` esté configurado correctamente en el host.

## Estructura del Proyecto

- `Dockerfile`: Configuración principal del contenedor
- `Dockerfile.railway`: Configuración específica para Railway
- `start-railway.sh`: Script de inicio para Railway
- `entrypoint.sh`: Punto de entrada del contenedor
- `install-plugins.sh`: Script para instalar plugins adicionales
- `railway.toml`: Configuración para Railway
- `docker-compose.yml`: Configuración para desarrollo local

## Licencia

MIT