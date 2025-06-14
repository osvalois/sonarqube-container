# DevSecOps en SonarQube Container

Este documento describe la configuración DevSecOps implementada en este proyecto.

## Herramientas de Análisis de Seguridad

### Análisis Estático (SAST)
- **SonarCloud**: Análisis de calidad de código y seguridad
- **Checkov**: Análisis de configuración de infraestructura como código (IaC)
- **KICS**: Detección de problemas de seguridad en archivos de configuración
- **Hadolint**: Linting específico para Dockerfiles
- **ShellCheck**: Análisis de scripts de shell
- **YAMLint**: Validación de archivos YAML

### Análisis de Vulnerabilidades
- **Trivy**: Escaneo de vulnerabilidades en el código y en la imagen de contenedor
- **Docker Scout**: Análisis de vulnerabilidades específico para Docker
- **Grype**: Análisis de vulnerabilidades en imágenes de contenedor
- **OWASP Dependency Check**: Análisis de dependencias vulnerables

### Otros Análisis de Seguridad
- **Gitleaks**: Detección de secretos y credenciales expuestas
- **Dependency Review**: Revisión de seguridad en dependencias

## Estándares de Seguridad Implementados

- **CWE Top 25 2024**: Vulnerabilidades críticas más comunes
- **OWASP Top 10 2021**: Riesgos de seguridad en aplicaciones web
- **OWASP Mobile Top 10 2024**: Riesgos de seguridad en aplicaciones móviles

## Procesos de CI/CD

### Flujo de Trabajo Principal (ci.yml)
1. **Análisis de Calidad de Código**:
   - Linting de Dockerfile
   - Verificación de scripts de shell
   - Detección de secretos
   - Análisis YAML

2. **Análisis de Seguridad**:
   - Escaneo del repositorio con Trivy
   - Análisis IaC con Checkov
   - Análisis IaC con KICS

3. **Análisis SonarCloud**:
   - Análisis de calidad de código
   - Verificación de reglas de seguridad

4. **Construcción y Publicación de Imágenes**:
   - Construcción multi-arquitectura (amd64, arm64)
   - Generación de SBOM (Software Bill of Materials)
   - Firma de imágenes con Cosign

5. **Escaneo de Contenedores**:
   - Análisis de la imagen con Trivy
   - Análisis de la imagen con Docker Scout
   - Generación de informes de seguridad

### Escaneo de Seguridad Programado (security.yml)
1. **Verificación de Dependencias**:
   - OWASP Dependency Check
   - Generación de reportes SARIF

2. **Escaneo de Contenedores**:
   - Escaneo de múltiples tags de imágenes
   - Trivy, Grype y Docker Scout
   - Generación de reportes SARIF

3. **Actualizaciones Automáticas**:
   - Verificación de nuevas versiones de imagen base
   - Creación automática de PR para actualizaciones

## Quality Gates

El proyecto implementa tres quality gates configurables:

1. **DevSecOps Quality Gate 2025**:
   - Calificación de confiabilidad, seguridad y mantenibilidad
   - Cobertura de código
   - Revisión de hotspots de seguridad
   - Cero vulnerabilidades

2. **Security-First Quality Gate**:
   - Enfocado exclusivamente en seguridad
   - Cero vulnerabilidades
   - 100% de revisión de hotspots

3. **Compliance Quality Gate**:
   - Específico para cumplimiento de estándares
   - Enfoque en nuevas vulnerabilidades
   - Alta cobertura de código (90%)

## Configuración Avanzada de Seguridad

El archivo `security-config/advanced-security.properties` configura:

- Detección avanzada de secretos
- Integración con OWASP Dependency Check
- Configuración para cumplimiento de CWE, OWASP
- Reglas de seguridad por lenguaje

## Herramientas Eliminadas

- **CodeQL**: Eliminado porque el proyecto no contiene código fuente en los lenguajes soportados por CodeQL (JavaScript, Python, etc.)
- **Snyk**: Eliminado por redundancia con otras herramientas de análisis

## Mejoras Realizadas

1. **Optimización de herramientas**: Enfoque en las herramientas más relevantes para un proyecto de contenedor Docker
2. **Mejora de la integración con GitHub Security**: Generación y carga de reportes SARIF
3. **Adición de análisis IaC**: Checkov y KICS para analizar archivos de infraestructura
4. **Verificación de condiciones de archivo**: Prevención de errores cuando los archivos SARIF no existen