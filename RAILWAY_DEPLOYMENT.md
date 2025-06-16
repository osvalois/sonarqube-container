# Desplegando SonarQube en Railway

Este documento proporciona información y recomendaciones para desplegar SonarQube en Railway.

## Requisitos de recursos

SonarQube tiene requisitos significativos de recursos, especialmente para:

- **Memoria**: Mínimo 2GB recomendado, aunque puede funcionar con configuraciones optimizadas en 1GB
- **CPU**: 2 vCPUs recomendado
- **Almacenamiento**: Mínimo 500MB para la instalación básica, más espacio dependiendo del número de proyectos

## Tiempos de inicio

- **Primera inicialización**: 5-10 minutos (creación de esquema de base de datos)
- **Inicios posteriores**: 2-5 minutos
- **Entornos con recursos limitados**: Hasta 15-20 minutos

## Solución de problemas comunes

### Error "su-exec not found"

Si ves este error, significa que la herramienta `su-exec` no está disponible en el contenedor. La solución implementada es:

1. Verificar si `su-exec` o `gosu` están disponibles
2. Usar el que esté disponible para cambiar al usuario sonarqube
3. Si ninguno está disponible, ejecutar directamente como el usuario actual

### Error "Insufficient memory"

Si ves errores de memoria insuficiente:

1. Reduce los requisitos de memoria en `railway.toml`
2. Asegúrate de que tu proyecto en Railway tenga al menos 1GB de RAM asignada
3. Configura correctamente `-Xms` (memoria inicial) y `-Xmx` (memoria máxima)

### Error "The version of SonarQube you are trying to upgrade is too old"

Este error ocurre cuando intentas actualizar desde una versión muy antigua a una nueva. Las opciones son:

1. Realizar actualizaciones graduales (primero a una versión intermedia)
2. Reiniciar la base de datos (perderás toda la configuración y proyectos)

## Proceso de actualización

SonarQube tiene un proceso estricto de actualización:
1. No se puede saltar versiones LTS
2. Se debe actualizar primero a la última versión de la serie actual, luego a la siguiente LTS

## Scripts disponibles

- `build-docker.sh`: Construye la imagen Docker
- `run-local.sh`: Ejecuta SonarQube localmente
- `deploy-railway.sh`: Despliega SonarQube en Railway
- `create-railway-project.sh`: Crea un nuevo proyecto en Railway
- `reset-database.sh`: Limpia la base de datos para empezar desde cero

## Recursos adicionales

- [Documentación oficial de SonarQube](https://docs.sonarsource.com/sonarqube-server/10.6/setup-and-upgrade/install-the-server/)
- [Guía de actualización de SonarQube](https://docs.sonarsource.com/sonarqube-server/10.6/setup-and-upgrade/upgrade-guide/)
- [Documentación de Railway](https://docs.railway.app/)