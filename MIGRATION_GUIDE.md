# Guía de Migración SonarQube

Esta guía explica cómo actualizar SonarQube preservando todos los datos, configuraciones y plugins utilizando el script de migración automatizado.

## 🎯 Características Principales

- ✅ **Backup automático** antes de cada actualización
- ✅ **Preservación de datos** completa (base de datos, plugins, configuraciones)
- ✅ **Validación de compatibilidad** entre versiones
- ✅ **Rollback automático** en caso de fallos
- ✅ **Soporte para PostgreSQL** y H2
- ✅ **Verificación post-actualización** automática

## 📋 Requisitos Previos

### Dependencias
```bash
# Verificar que tienes instalado:
docker --version          # Docker 20.0+
docker-compose --version  # Docker Compose 2.0+
curl --version           # Para verificaciones de estado
```

### Estructura del Proyecto
```
sonarqube-container/
├── docker-compose.yml          # Configuración principal
├── .env                       # Variables de entorno
├── plugins/                   # Plugins personalizados
├── migrate-sonarqube.sh      # Script de migración
└── backups/                  # Directorio de backups (se crea automáticamente)
```

## 🚀 Uso del Script de Migración

### Sintaxis Básica
```bash
./migrate-sonarqube.sh [OPCIONES] NUEVA_VERSION
```

### Ejemplos de Uso

#### 1. Actualización Estándar
```bash
# Actualizar a una nueva versión
./migrate-sonarqube.sh 25.6.0.108429-community
```

#### 2. Solo Crear Backup
```bash
# Crear backup sin actualizar
./migrate-sonarqube.sh --backup-only
```

#### 3. Listar Backups Disponibles
```bash
# Ver todos los backups existentes
./migrate-sonarqube.sh --list-backups
```

#### 4. Restaurar desde Backup
```bash
# Restaurar backup específico
./migrate-sonarqube.sh --restore 20250722_143022
```

#### 5. Actualización Forzada
```bash
# Omitir validaciones de compatibilidad
./migrate-sonarqube.sh --force 26.0.0.123456-community
```

## 📚 Opciones del Script

| Opción | Descripción |
|--------|-------------|
| `-h, --help` | Mostrar ayuda |
| `-c, --compose FILE` | Especificar archivo docker-compose |
| `-b, --backup-only` | Solo crear backup |
| `-r, --restore BACKUP` | Restaurar desde backup |
| `-l, --list-backups` | Listar backups disponibles |
| `--skip-backup` | Omitir backup (NO RECOMENDADO) |
| `--force` | Forzar actualización sin validaciones |

## 🔄 Proceso de Migración Detallado

### Fase 1: Validación Inicial
1. **Verificación de dependencias** (Docker, docker-compose, curl)
2. **Detección de versión actual** (API o imagen Docker)
3. **Validación de compatibilidad** entre versiones
4. **Confirmación del usuario** para cambios de versión mayor

### Fase 2: Backup Automático
```bash
backups/sonarqube_backup_YYYYMMDD_HHMMSS/
├── docker-compose.yml      # Configuraciones
├── .env                   # Variables de entorno  
├── plugins/               # Plugins personalizados
├── *.tar.gz              # Volúmenes de datos comprimidos
├── database_backup.sql   # Backup de PostgreSQL (si aplica)
└── backup_manifest.txt   # Información del backup
```

### Fase 3: Actualización
1. **Detención de servicios** actuales
2. **Actualización de configuraciones** (docker-compose.yml, Dockerfile, .env)
3. **Descarga de nueva imagen** SonarQube
4. **Inicio de servicios** con nueva versión
5. **Espera hasta que esté disponible** (máximo 5 minutos)

### Fase 4: Validación Post-Actualización
1. **Verificación de estado** de SonarQube
2. **Confirmación de versión** actualizada
3. **Conteo de plugins** instalados
4. **Reporte de éxito/fallo**

## 💾 Sistema de Backup

### Qué se Respalda
- **Configuraciones**: docker-compose.yml, .env, Dockerfile
- **Plugins**: Directorio completo de plugins personalizados
- **Volúmenes**: Todos los volúmenes Docker (datos, logs, temp, extensions)
- **Base de datos**: Backup SQL para PostgreSQL externas

### Estructura del Backup
```
backups/
├── sonarqube_backup_20250722_143022/
│   ├── docker-compose.yml
│   ├── .env
│   ├── plugins/
│   ├── sonarqube_data.tar.gz
│   ├── sonarqube_extensions.tar.gz
│   ├── sonarqube_logs.tar.gz
│   ├── database_backup.sql
│   └── backup_manifest.txt
├── sonarqube_backup_20250721_120000/
└── latest_backup.txt              # Referencia al último backup
```

## 🔧 Configuraciones Específicas

### Para Base de Datos PostgreSQL
```bash
# En .env
SONAR_JDBC_URL=jdbc:postgresql://localhost:5432/sonarqube
SONAR_JDBC_USERNAME=sonarqube_user
SONAR_JDBC_PASSWORD=secure_password
```

El script detecta automáticamente PostgreSQL y crea backups SQL usando `pg_dump`.

### Para Base de Datos H2 (Desarrollo)
```bash
# En .env
SONAR_EMBEDDEDDATABASE_PORT=9092
SONAR_JDBC_USERNAME=sonar
SONAR_JDBC_PASSWORD=sonar
```

Los datos H2 se respaldan como parte de los volúmenes.

## 🛠️ Solución de Problemas

### Error: "SonarQube no responde después de la actualización"
```bash
# Verificar logs
docker-compose logs sonarqube

# Restaurar último backup
./migrate-sonarqube.sh --restore $(cat backups/latest_backup.txt | xargs basename)
```

### Error: "Plugin incompatible con nueva versión"
1. **Verificar compatibilidad** del plugin en su repositorio
2. **Actualizar plugin** manualmente en `plugins/`
3. **Reintentar migración**:
```bash
docker-compose restart
```

### Error: "Base de datos corrupta"
```bash
# Restaurar desde backup más reciente
./migrate-sonarqube.sh --list-backups
./migrate-sonarqube.sh --restore TIMESTAMP_DEL_BACKUP
```

## 📊 Validación de Compatibilidad

### Cambios de Versión Menor (25.1.x → 25.2.x)
- ✅ Automático sin confirmación
- ✅ Migración transparente
- ✅ Plugins generalmente compatibles

### Cambios de Versión Mayor (25.x.x → 26.x.x)
- ⚠️ Requiere confirmación del usuario
- ⚠️ Posibles incompatibilidades de plugins
- ⚠️ Cambios en esquema de base de datos

### Versiones LTS (Long Term Support)
- 🔄 Recomendado para producción
- 🔄 Soporte extendido
- 🔄 Migración más estable

## 🚨 Mejores Prácticas

### Antes de Actualizar
1. **Crear backup manual** adicional:
```bash
./migrate-sonarqube.sh --backup-only
```

2. **Verificar compatibilidad** de plugins en sus repositorios
3. **Probar en entorno de desarrollo** primero
4. **Programar ventana de mantenimiento**

### Durante la Actualización
1. **No interrumpir** el proceso de migración
2. **Monitorear logs** en tiempo real:
```bash
docker-compose logs -f sonarqube
```

3. **Verificar espacio en disco** suficiente para backups

### Después de Actualizar
1. **Verificar funcionalidad** completa:
   - Login de usuarios
   - Análisis de proyectos
   - Generación de reportes
   - Plugins funcionando

2. **Actualizar proyectos** si es necesario:
```bash
# Ejecutar análisis de prueba
sonar-scanner -Dsonar.projectKey=test -Dsonar.sources=.
```

3. **Mantener backups** por al menos 30 días

## 📅 Programación de Actualizaciones

### Script para Cron (Backup Automático)
```bash
# Backup diario a las 2:00 AM
0 2 * * * /path/to/migrate-sonarqube.sh --backup-only

# Limpiar backups antiguos (más de 30 días)
0 3 * * 0 find /path/to/backups -name "sonarqube_backup_*" -mtime +30 -exec rm -rf {} \;
```

### Calendario de Actualizaciones Sugerido
- **Desarrollo**: Inmediato tras release
- **Staging**: 1 semana después
- **Producción**: 2-4 semanas después (tras validación)

## 🔍 Monitoreo y Alertas

### Verificación de Estado Post-Migración
```bash
#!/bin/bash
# health-check.sh

# Verificar que SonarQube responde
if curl -f http://localhost:9000/api/system/status; then
    echo "✅ SonarQube está funcionando"
else
    echo "❌ SonarQube no responde"
    # Enviar alerta/notificación
fi

# Verificar plugins críticos
plugin_count=$(curl -s http://localhost:9000/api/plugins/installed | jq '.plugins | length')
echo "📊 Plugins instalados: $plugin_count"
```

## 📞 Soporte y Troubleshooting

### Logs Importantes
```bash
# Logs del contenedor
docker-compose logs sonarqube

# Logs específicos de SonarQube
docker exec -it sonarqube-container tail -f /opt/sonarqube/logs/sonarqube.log

# Logs de Elasticsearch
docker exec -it sonarqube-container tail -f /opt/sonarqube/logs/es.log
```

### Información de Debug
```bash
# Estado de volúmenes
docker volume ls

# Información del contenedor
docker inspect sonarqube-container

# Uso de recursos
docker stats sonarqube-container
```

---

## 📝 Changelog del Script

### v1.0 (2025-07-22)
- ✨ Migración automática con backup
- ✨ Soporte para PostgreSQL y H2
- ✨ Validación de compatibilidad
- ✨ Sistema de restore completo
- ✨ Verificación post-actualización

---

**¡Importante!** Siempre probar las migraciones en un entorno de desarrollo antes de aplicar en producción.