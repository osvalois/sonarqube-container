# SonarQube Plugins Instalados

Este contenedor incluye los siguientes plugins para proporcionar una experiencia similar a SonarCloud:

## 🎯 Plugins de Funcionalidad Core

### 1. **Community Branch Plugin** (v10.11.0)
**Propósito**: Análisis de ramas y Pull Requests en Community Edition  
**Características**:
- ✅ Análisis de múltiples ramas
- ✅ Decoración de Pull Requests (GitHub, GitLab, Bitbucket)
- ✅ Métricas separadas por rama
- ⚠️ **Importante**: Requiere configuración con `-javaagent` (ya configurado)

### 2. **CNES Report Plugin** (v5.0.2)
**Propósito**: Generación de reportes en múltiples formatos  
**Formatos soportados**:
- ✅ DOCX (Word)
- ✅ XLSX (Excel)
- ✅ CSV
- ✅ Markdown
- ✅ TXT

## 🌐 Plugins de Lenguajes

### Lenguajes Nativos en Community Edition:
- ✅ **Java** - Soporte completo nativo
- ✅ **JavaScript/TypeScript** - Soporte completo nativo
- ✅ **Python** - Soporte completo nativo
- ✅ **Go** - Soporte completo nativo
- ✅ **PHP** - Soporte básico nativo
- ✅ **HTML/CSS/XML** - Soporte completo nativo
- ❌ **C#** - Requiere Developer Edition (no disponible en Community)
- ❌ **C/C++** - Requiere Developer Edition (no disponible en Community)

### Lenguajes Adicionales Instalados:

#### 3. **Rust Plugin** (v0.2.6)
**Características**:
- ✅ Análisis basado en Clippy
- ✅ Soporte para cobertura LCOV/Cobertura
- ✅ Métricas de calidad de código

#### 4. **Dart/Flutter Plugin** (v4.0.1)
**Características**:
- ✅ Análisis de código Dart
- ✅ Soporte para proyectos Flutter
- ✅ Detección de code smells

#### 5. **YAML Plugin** (v1.9.1)
**Características**:
- ✅ Validación de sintaxis YAML
- ✅ Análisis de archivos de configuración
- ✅ Soporte para Kubernetes, Docker Compose, etc.

#### 6. **ShellCheck Plugin** (v2.5.0)
**Características**:
- ✅ Análisis de scripts Bash/Shell
- ✅ Detección de errores comunes
- ✅ Mejores prácticas de scripting

## 🔧 Plugins de Integración

### 7. **GitLab Plugin** (v4.1.0-SNAPSHOT)
**Características**:
- ✅ Integración mejorada con GitLab
- ✅ Comentarios en Merge Requests
- ✅ Análisis de pipelines

## 📊 Cobertura de Lenguajes

| Lenguaje | Soporte | Tipo | Plugin |
|----------|---------|------|--------|
| Java | ✅ Completo | Nativo | - |
| JavaScript | ✅ Completo | Nativo | - |
| TypeScript | ✅ Completo | Nativo | - |
| Python | ✅ Completo | Nativo | - |
| Go | ✅ Completo | Nativo | - |
| Rust | ✅ Básico | Plugin | community-rust |
| Dart/Flutter | ✅ Básico | Plugin | sonar-dart |
| PHP | ✅ Básico | Nativo | - |
| HTML/CSS | ✅ Completo | Nativo | - |
| XML | ✅ Completo | Nativo | - |
| YAML | ✅ Completo | Plugin | sonar-yaml |
| Shell/Bash | ✅ Completo | Plugin | sonar-shellcheck |
| C# | ❌ No disponible | Requiere Developer Edition | - |
| C/C++ | ❌ No disponible | Requiere Developer Edition | - |

## 🚀 Configuración de Ramas y PRs

Para habilitar el análisis de ramas y Pull Requests:

### GitHub:
```bash
sonar-scanner \
  -Dsonar.pullrequest.provider=github \
  -Dsonar.pullrequest.github.repository=owner/repo \
  -Dsonar.pullrequest.key=123 \
  -Dsonar.pullrequest.branch=feature/branch \
  -Dsonar.pullrequest.base=main
```

### GitLab:
```bash
sonar-scanner \
  -Dsonar.pullrequest.provider=gitlab \
  -Dsonar.pullrequest.gitlab.repositorySlug=owner/repo \
  -Dsonar.pullrequest.key=123 \
  -Dsonar.pullrequest.branch=feature/branch \
  -Dsonar.pullrequest.base=main
```

## 📝 Notas Importantes

1. **Branch Plugin**: Ya está configurado con `-javaagent` en las variables de entorno
2. **Limitaciones**: Algunos plugins comunitarios pueden tener menos características que las versiones comerciales
3. **Actualizaciones**: Verificar periódicamente nuevas versiones de plugins en sus repositorios
4. **Compatibilidad**: Todos los plugins están probados con SonarQube 10.x+

## 🔄 Actualización de Plugins

Para actualizar un plugin:
1. Descargar la nueva versión del repositorio oficial
2. Reemplazar el archivo JAR en `/opt/sonarqube/extensions/plugins/`
3. Reiniciar SonarQube

## ⚠️ Advertencias

- El plugin de ramas comunitario no tiene ruta de actualización oficial a ediciones comerciales
- Algunos plugins pueden requerir configuración adicional en `sonar.properties`
- Para C# y C/C++, considerar actualizar a Developer Edition o Enterprise Edition