#!/bin/bash

# SonarQube Migration Script
# Actualiza SonarQube preservando la base de datos y configuración
# Autor: Oscar Valois
# Versión: 1.0

set -euo pipefail

# Configuración
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${SCRIPT_DIR}/backups"
COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.yml"
ENV_FILE="${SCRIPT_DIR}/.env"
PLUGINS_DIR="${SCRIPT_DIR}/plugins"
CURRENT_VERSION=""
NEW_VERSION=""
BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funciones de logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Función para mostrar ayuda
show_help() {
    cat << EOF
SonarQube Migration Script

USAGE:
    $0 [OPTIONS] NEW_VERSION

OPTIONS:
    -h, --help              Mostrar esta ayuda
    -c, --compose FILE      Especificar archivo docker-compose (default: docker-compose.yml)
    -b, --backup-only       Solo crear backup, no actualizar
    -r, --restore BACKUP    Restaurar desde backup específico
    -l, --list-backups      Listar backups disponibles
    --skip-backup           Omitir creación de backup (NO RECOMENDADO)
    --force                 Forzar actualización sin validaciones

EXAMPLES:
    $0 25.6.0.108429-community        # Actualizar a nueva versión
    $0 --backup-only                  # Solo crear backup
    $0 --restore 20250722_143022      # Restaurar backup específico
    $0 --list-backups                 # Listar backups disponibles

EOF
}

# Validar dependencias
check_dependencies() {
    log_info "Validando dependencias..."
    
    local deps=("docker" "docker-compose")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log_error "$dep no está instalado"
            exit 1
        fi
    done
    
    # Verificar si Docker está corriendo
    if ! docker info &> /dev/null; then
        log_error "Docker no está corriendo"
        exit 1
    fi
    
    log_success "Todas las dependencias están disponibles"
}

# Obtener versión actual de SonarQube
get_current_version() {
    log_info "Obteniendo versión actual de SonarQube..."
    
    if docker-compose -f "$COMPOSE_FILE" ps | grep -q "sonarqube"; then
        # Intentar obtener versión de la API
        if CURRENT_VERSION=$(curl -s http://localhost:9000/api/server/version 2>/dev/null); then
            log_info "Versión actual detectada desde API: $CURRENT_VERSION"
        else
            # Obtener desde imagen Docker
            local image=$(docker-compose -f "$COMPOSE_FILE" config | grep "image:" | grep sonarqube | head -1 | awk '{print $2}')
            if [[ $image =~ :([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+-community) ]]; then
                CURRENT_VERSION="${BASH_REMATCH[1]}"
                log_info "Versión actual detectada desde imagen: $CURRENT_VERSION"
            else
                log_warning "No se pudo detectar la versión actual"
                CURRENT_VERSION="unknown"
            fi
        fi
    else
        log_info "No hay instancia de SonarQube corriendo"
        CURRENT_VERSION="none"
    fi
}

# Validar compatibilidad de versiones
validate_version_compatibility() {
    local new_version="$1"
    
    log_info "Validando compatibilidad de versiones..."
    
    # Extraer números de versión mayor
    local current_major=""
    local new_major=""
    
    if [[ $CURRENT_VERSION =~ ^([0-9]+)\.([0-9]+) ]]; then
        current_major="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
    fi
    
    if [[ $new_version =~ ^([0-9]+)\.([0-9]+) ]]; then
        new_major="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
    fi
    
    # Advertencias sobre cambios de versión mayor
    if [[ "$current_major" != "$new_major" ]] && [[ "$CURRENT_VERSION" != "none" ]]; then
        log_warning "Actualización de versión mayor detectada: $current_major -> $new_major"
        log_warning "Esto podría requerir migración manual de datos"
        
        if [[ "${FORCE:-false}" != "true" ]]; then
            read -p "¿Continuar con la actualización? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_info "Actualización cancelada por el usuario"
                exit 0
            fi
        fi
    fi
}

# Crear backup completo
create_backup() {
    log_info "Creando backup completo..."
    
    mkdir -p "$BACKUP_DIR"
    local backup_path="$BACKUP_DIR/sonarqube_backup_$BACKUP_TIMESTAMP"
    mkdir -p "$backup_path"
    
    # Backup de configuración
    log_info "Respaldando configuración..."
    cp -r "$SCRIPT_DIR"/*.yml "$backup_path/" 2>/dev/null || true
    cp "$ENV_FILE" "$backup_path/" 2>/dev/null || true
    cp -r "$PLUGINS_DIR" "$backup_path/" 2>/dev/null || true
    
    # Backup de volúmenes de datos
    log_info "Respaldando volúmenes de datos..."
    
    # Obtener nombres de volúmenes
    local volumes=$(docker-compose -f "$COMPOSE_FILE" config --volumes 2>/dev/null || echo "")
    
    if [[ -n "$volumes" ]]; then
        for volume in $volumes; do
            if docker volume inspect "$volume" &>/dev/null; then
                log_info "Respaldando volumen: $volume"
                docker run --rm -v "$volume:/source" -v "$backup_path:/backup" alpine \
                    tar czf "/backup/${volume}.tar.gz" -C /source .
            fi
        done
    fi
    
    # Backup de base de datos (si es PostgreSQL externa)
    if [[ -f "$ENV_FILE" ]] && grep -q "SONAR_JDBC_URL.*postgresql" "$ENV_FILE"; then
        log_info "Detectada base de datos PostgreSQL externa"
        backup_postgresql_database "$backup_path"
    fi
    
    # Crear manifiesto del backup
    cat > "$backup_path/backup_manifest.txt" << EOF
Backup creado: $(date)
Versión SonarQube: $CURRENT_VERSION
Script versión: 1.0
Contenido:
- Configuración Docker Compose
- Variables de entorno
- Plugins personalizados
- Volúmenes de datos
- Base de datos (si aplica)
EOF
    
    log_success "Backup creado en: $backup_path"
    echo "$backup_path" > "$BACKUP_DIR/latest_backup.txt"
}

# Backup específico para PostgreSQL
backup_postgresql_database() {
    local backup_path="$1"
    
    if [[ -f "$ENV_FILE" ]]; then
        source "$ENV_FILE"
        
        if [[ -n "${SONAR_JDBC_URL:-}" ]] && [[ "$SONAR_JDBC_URL" =~ postgresql://([^:]+):([0-9]+)/([^?]+) ]]; then
            local host="${BASH_REMATCH[1]}"
            local port="${BASH_REMATCH[2]}"
            local database="${BASH_REMATCH[3]}"
            
            log_info "Creando backup de base de datos PostgreSQL..."
            
            # Usar contenedor temporal para pg_dump
            docker run --rm \
                -e PGPASSWORD="${SONAR_JDBC_PASSWORD}" \
                -v "$backup_path:/backup" \
                postgres:15-alpine \
                pg_dump -h "$host" -p "$port" -U "${SONAR_JDBC_USERNAME}" -d "$database" \
                > "$backup_path/database_backup.sql"
                
            log_success "Backup de base de datos creado"
        fi
    fi
}

# Listar backups disponibles
list_backups() {
    log_info "Backups disponibles:"
    
    if [[ -d "$BACKUP_DIR" ]]; then
        find "$BACKUP_DIR" -name "sonarqube_backup_*" -type d | sort -r | while read -r backup; do
            local backup_name=$(basename "$backup")
            local timestamp=${backup_name#sonarqube_backup_}
            local date_formatted=$(date -d "${timestamp:0:8} ${timestamp:9:2}:${timestamp:11:2}:${timestamp:13:2}" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "$timestamp")
            
            if [[ -f "$backup/backup_manifest.txt" ]]; then
                local version=$(grep "Versión SonarQube:" "$backup/backup_manifest.txt" | cut -d: -f2 | xargs)
                echo "  $timestamp - $date_formatted (v$version)"
            else
                echo "  $timestamp - $date_formatted"
            fi
        done
    else
        log_info "No hay backups disponibles"
    fi
}

# Restaurar desde backup
restore_backup() {
    local backup_timestamp="$1"
    local backup_path="$BACKUP_DIR/sonarqube_backup_$backup_timestamp"
    
    if [[ ! -d "$backup_path" ]]; then
        log_error "Backup no encontrado: $backup_path"
        exit 1
    fi
    
    log_info "Restaurando desde backup: $backup_timestamp"
    
    # Detener servicios actuales
    log_info "Deteniendo servicios..."
    docker-compose -f "$COMPOSE_FILE" down || true
    
    # Restaurar configuración
    log_info "Restaurando configuración..."
    cp "$backup_path"/*.yml "$SCRIPT_DIR/" 2>/dev/null || true
    cp "$backup_path/.env" "$SCRIPT_DIR/" 2>/dev/null || true
    cp -r "$backup_path/plugins" "$SCRIPT_DIR/" 2>/dev/null || true
    
    # Restaurar volúmenes
    log_info "Restaurando volúmenes de datos..."
    for volume_backup in "$backup_path"/*.tar.gz; do
        if [[ -f "$volume_backup" ]]; then
            local volume_name=$(basename "$volume_backup" .tar.gz)
            
            # Recrear volumen
            docker volume rm "$volume_name" 2>/dev/null || true
            docker volume create "$volume_name"
            
            # Restaurar datos
            docker run --rm -v "$volume_name:/target" -v "$backup_path:/backup" alpine \
                tar xzf "/backup/${volume_name}.tar.gz" -C /target
                
            log_info "Volumen restaurado: $volume_name"
        fi
    done
    
    # Restaurar base de datos PostgreSQL si existe
    if [[ -f "$backup_path/database_backup.sql" ]]; then
        log_info "Restaurando base de datos PostgreSQL..."
        restore_postgresql_database "$backup_path/database_backup.sql"
    fi
    
    log_success "Restauración completada"
}

# Restaurar base de datos PostgreSQL
restore_postgresql_database() {
    local sql_file="$1"
    
    if [[ -f "$ENV_FILE" ]]; then
        source "$ENV_FILE"
        
        if [[ -n "${SONAR_JDBC_URL:-}" ]] && [[ "$SONAR_JDBC_URL" =~ postgresql://([^:]+):([0-9]+)/([^?]+) ]]; then
            local host="${BASH_REMATCH[1]}"
            local port="${BASH_REMATCH[2]}"
            local database="${BASH_REMATCH[3]}"
            
            # Restaurar usando contenedor temporal
            docker run --rm -i \
                -e PGPASSWORD="${SONAR_JDBC_PASSWORD}" \
                -v "$(dirname "$sql_file"):/backup" \
                postgres:15-alpine \
                psql -h "$host" -p "$port" -U "${SONAR_JDBC_USERNAME}" -d "$database" \
                < "$sql_file"
        fi
    fi
}

# Actualizar SonarQube
update_sonarqube() {
    local new_version="$1"
    
    log_info "Actualizando SonarQube a versión: $new_version"
    
    # Detener servicios
    log_info "Deteniendo servicios actuales..."
    docker-compose -f "$COMPOSE_FILE" down
    
    # Actualizar imagen en docker-compose.yml
    log_info "Actualizando configuración de imagen..."
    
    # Backup del archivo compose actual
    cp "$COMPOSE_FILE" "${COMPOSE_FILE}.backup"
    
    # Actualizar versión en docker-compose.yml
    sed -i.bak "s|sonarqube:[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*-community|sonarqube:$new_version|g" "$COMPOSE_FILE"
    
    # Actualizar versión en Dockerfile si existe
    if [[ -f "$SCRIPT_DIR/Dockerfile" ]]; then
        sed -i.bak "s|sonarqube:[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*-community|sonarqube:$new_version|g" "$SCRIPT_DIR/Dockerfile"
    fi
    
    # Actualizar variables de entorno si existen
    if [[ -f "$ENV_FILE" ]]; then
        sed -i.bak "s|SONARQUBE_VERSION=.*|SONARQUBE_VERSION=$new_version|g" "$ENV_FILE" || true
        sed -i.bak "s|BUILD_VERSION=.*|BUILD_VERSION=${new_version%%-*}|g" "$ENV_FILE" || true
    fi
    
    # Descargar nueva imagen
    log_info "Descargando nueva imagen de SonarQube..."
    docker pull "sonarqube:$new_version"
    
    # Iniciar servicios
    log_info "Iniciando servicios con nueva versión..."
    docker-compose -f "$COMPOSE_FILE" up -d
    
    # Esperar que SonarQube esté listo
    wait_for_sonarqube
    
    log_success "Actualización completada a versión: $new_version"
}

# Esperar que SonarQube esté disponible
wait_for_sonarqube() {
    log_info "Esperando que SonarQube esté disponible..."
    
    local max_attempts=30
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if curl -s http://localhost:9000/api/system/status &>/dev/null; then
            local status=$(curl -s http://localhost:9000/api/system/status | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
            if [[ "$status" == "UP" ]]; then
                log_success "SonarQube está disponible"
                return 0
            fi
        fi
        
        log_info "Intento $attempt/$max_attempts - SonarQube aún no está listo..."
        sleep 10
        ((attempt++))
    done
    
    log_warning "SonarQube tardó más de lo esperado en estar disponible"
    log_info "Verificar logs: docker-compose -f $COMPOSE_FILE logs"
}

# Validar integridad post-actualización
validate_update() {
    log_info "Validando integridad post-actualización..."
    
    # Verificar que SonarQube responde
    if ! curl -s http://localhost:9000/api/system/status &>/dev/null; then
        log_error "SonarQube no responde después de la actualización"
        return 1
    fi
    
    # Verificar versión actualizada
    local current_api_version=$(curl -s http://localhost:9000/api/server/version 2>/dev/null || echo "unknown")
    if [[ "$current_api_version" == *"$NEW_VERSION"* ]] || [[ "$current_api_version" != "unknown" ]]; then
        log_success "Versión actualizada confirmada: $current_api_version"
    else
        log_warning "No se pudo confirmar la nueva versión desde la API"
    fi
    
    # Verificar plugins
    log_info "Verificando plugins..."
    local plugins_count=$(curl -s http://localhost:9000/api/plugins/installed 2>/dev/null | grep -o '"key":' | wc -l || echo "0")
    log_info "Plugins instalados: $plugins_count"
    
    log_success "Validación completada"
}

# Limpiar archivos temporales
cleanup() {
    log_info "Limpiando archivos temporales..."
    
    # Remover backups de archivos de configuración
    rm -f "${COMPOSE_FILE}.backup" "${COMPOSE_FILE}.bak"
    rm -f "${SCRIPT_DIR}/Dockerfile.bak"
    rm -f "${ENV_FILE}.bak"
    
    log_success "Limpieza completada"
}

# Main function
main() {
    local backup_only=false
    local restore_mode=false
    local restore_timestamp=""
    local list_backups_only=false
    local skip_backup=false
    local force=false
    
    # Parsear argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -c|--compose)
                COMPOSE_FILE="$2"
                shift 2
                ;;
            -b|--backup-only)
                backup_only=true
                shift
                ;;
            -r|--restore)
                restore_mode=true
                restore_timestamp="$2"
                shift 2
                ;;
            -l|--list-backups)
                list_backups_only=true
                shift
                ;;
            --skip-backup)
                skip_backup=true
                shift
                ;;
            --force)
                force=true
                FORCE=true
                shift
                ;;
            -*)
                log_error "Opción desconocida: $1"
                show_help
                exit 1
                ;;
            *)
                NEW_VERSION="$1"
                shift
                ;;
        esac
    done
    
    # Validar dependencias
    check_dependencies
    
    # Listar backups si se solicita
    if [[ "$list_backups_only" == "true" ]]; then
        list_backups
        exit 0
    fi
    
    # Restaurar si se solicita
    if [[ "$restore_mode" == "true" ]]; then
        if [[ -z "$restore_timestamp" ]]; then
            log_error "Se requiere timestamp para restaurar"
            exit 1
        fi
        restore_backup "$restore_timestamp"
        
        # Iniciar servicios después de restaurar
        log_info "Iniciando servicios restaurados..."
        docker-compose -f "$COMPOSE_FILE" up -d
        wait_for_sonarqube
        exit 0
    fi
    
    # Obtener versión actual
    get_current_version
    
    # Solo backup si se solicita
    if [[ "$backup_only" == "true" ]]; then
        create_backup
        exit 0
    fi
    
    # Validar que se proporcionó nueva versión
    if [[ -z "$NEW_VERSION" ]]; then
        log_error "Se requiere especificar la nueva versión"
        show_help
        exit 1
    fi
    
    # Validar compatibilidad
    validate_version_compatibility "$NEW_VERSION"
    
    # Crear backup automático (a menos que se omita)
    if [[ "$skip_backup" != "true" ]]; then
        create_backup
    fi
    
    # Actualizar SonarQube
    update_sonarqube "$NEW_VERSION"
    
    # Validar actualización
    validate_update
    
    # Limpiar archivos temporales
    cleanup
    
    log_success "¡Migración completada exitosamente!"
    log_info "SonarQube actualizado de $CURRENT_VERSION a $NEW_VERSION"
    log_info "Acceder a: http://localhost:9000"
}

# Manejo de señales para limpieza
trap cleanup EXIT

# Ejecutar función principal
main "$@"