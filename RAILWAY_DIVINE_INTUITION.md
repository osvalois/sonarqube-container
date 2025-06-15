# Railway Deployment: divine-intuition

## 🚀 Configuración Específica para tu Instancia

### Detalles del Despliegue
- **Nombre**: divine-intuition
- **URL**: https://sonarqube-container-production-a7e6.up.railway.app
- **Puerto**: 8080
- **Región**: US East (Virginia, USA) - METAL
- **Recursos**: 8 vCPU, 8GB RAM

### Configuraciones Aplicadas

#### 1. **Memoria Optimizada (8GB disponibles)**
```yaml
Web Server: 2GB máx, 1GB inicial
Compute Engine: 2GB máx, 512MB inicial  
ElasticSearch: 1GB fijo
Total uso: ~5GB (dejando 3GB para el sistema)
```

#### 2. **railway.toml**
```toml
[deploy]
healthcheckPath = "/api/system/status"
healthcheckTimeout = 600          # 10 minutos para arranque inicial
restartPolicyType = "on-failure"  # Reintentar si falla
restartPolicyMaxRetries = 3       # Máximo 3 reintentos
```

#### 3. **Variables de Entorno Configuradas**
- `SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true`
- `RUN_AS_ROOT=true`
- `SONAR_WEB_JAVAOPTS=-Xmx2g -Xms1g -XX:+UseG1GC`
- `SONAR_CE_JAVAOPTS=-Xmx2g -Xms512m -XX:+UseG1GC`
- `SONAR_SEARCH_JAVAOPTS=-Xmx1g -Xms1g`

### 📊 Plugin de Reportes

**CNES Report Plugin v5.0.2** instalado y configurado:
- Acceso: **More** → **CNES Report** en la interfaz web
- Formatos: DOCX, XLSX, CSV, Markdown, TXT
- Ubicación: `/opt/sonarqube/extensions/plugins/`

### 🔧 Solución de Problemas

#### Si el despliegue falla:
1. **Verificar logs en Railway**:
   - Ir a la pestaña "Logs" en tu dashboard
   - Buscar errores de memoria o puerto

2. **Timeout de healthcheck**:
   - SonarQube puede tardar 5-10 minutos en iniciar
   - El healthcheck está configurado para 600 segundos

3. **Errores de memoria**:
   - Si aparece "OutOfMemoryError", reducir los valores en railway.toml
   - Cambiar `-Xmx2g` a `-Xmx1g` para Web Server

### 🚦 Verificación del Despliegue

1. **Esperar el healthcheck**: 
   - Railway esperará hasta 10 minutos
   - El endpoint `/api/system/status` debe responder OK

2. **Acceder a SonarQube**:
   ```
   https://sonarqube-container-production-a7e6.up.railway.app
   ```

3. **Verificar plugin**:
   - Login → More → CNES Report
   - Debe aparecer la opción de generar reportes

### 📝 Notas Importantes

- **Base de datos**: Usando PostgreSQL Neon (configurada en las variables)
- **Puerto**: Railway usa 8080, no el 9000 por defecto de SonarQube
- **Dominio privado**: `sonarqube-container.railway.internal` para comunicación interna

### 🔄 Para Actualizar

```bash
# Hacer cambios locales
git add .
git commit -m "Update configuration"
git push origin main

# Railway detectará los cambios y desplegará automáticamente
```

El despliegue está optimizado para aprovechar los 8GB de RAM disponibles en tu plan Railway, con configuraciones específicas para estabilidad y rendimiento.