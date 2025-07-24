# Guía de Solución para SonarQube en Railway

## 🚨 Problema Identificado
El error principal es que Elasticsearch está iniciando con memoria insuficiente (`-Xms4m -Xmx64m`) y Railway tiene límites estrictos de memoria (512MB en el plan gratuito).

## 🛠️ Solución Implementada

He creado una configuración completamente nueva que:
1. **Optimiza el uso de memoria al máximo**
2. **Maneja correctamente la base de datos PostgreSQL de Railway**
3. **Configura Elasticsearch con memoria mínima viable**

## 📝 Pasos para Implementar

### Opción 1: Usar la Nueva Configuración (RECOMENDADO)

1. **Renombra los archivos actuales (backup):**
   ```bash
   mv Dockerfile.railway Dockerfile.railway.backup
   mv railway.toml railway.toml.backup
   mv start-railway.sh start-railway.sh.backup
   ```

2. **Activa la nueva configuración:**
   ```bash
   mv Dockerfile.railway-fix Dockerfile.railway
   mv railway-fix.toml railway.toml
   mv start-railway-fix.sh start-railway.sh
   chmod +x start-railway.sh
   ```

3. **Commit y push:**
   ```bash
   git add .
   git commit -m "fix: implementar configuración optimizada para Railway"
   git push
   ```

### Opción 2: Configuración Manual en Railway

Si los errores persisten, configura estas variables de entorno directamente en Railway:

```env
# Memoria
JAVA_OPTS=-Xmx384m -Xms128m -XX:+UseSerialGC
SONAR_WEB_JAVAOPTS=-Xmx384m -Xms128m
SONAR_CE_JAVAOPTS=-Xmx384m -Xms128m
SONAR_SEARCH_JAVAOPTS=-Xmx512m -Xms512m

# Elasticsearch
SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true
SONAR_SEARCH_JAVAADDITIONALOPTS=-Des.enforce.bootstrap.checks=false

# Base de datos (Railway la proporciona automáticamente)
# No necesitas configurar DATABASE_URL manualmente

# Puerto
PORT=${{PORT}}

# Otros
RUN_AS_ROOT=true
SONAR_TELEMETRY_ENABLE=false
```

## 🔍 Verificación

1. **Revisa los logs en Railway:**
   - Elasticsearch debe iniciar con al menos 512MB
   - No debe haber errores de "bootstrap checks"
   - La conexión a PostgreSQL debe establecerse

2. **Endpoints de salud:**
   - `/api/system/status` - Estado del sistema
   - `/api/system/health` - Salud detallada

## 🚀 Alternativas si Railway no Funciona

Railway tiene límites muy estrictos. Si continúan los problemas, considera:

1. **Render.com** (1GB RAM gratis)
2. **Fly.io** (256MB RAM gratis, pero más flexible)
3. **Google Cloud Run** (2GB RAM, pago por uso)

## 💡 Configuración Mínima Probada

La configuración que he creado usa:
- Web Server: 384MB máximo
- Compute Engine: 384MB máximo  
- Elasticsearch: 512MB (mínimo requerido)
- Total: ~1.3GB (puede funcionar en 512MB con swapping)

## ⚠️ Notas Importantes

1. **Primera vez:** El inicio puede tardar 5-10 minutos
2. **Base de datos:** Debe estar lista antes de iniciar SonarQube
3. **Plugins:** Evita instalar plugins adicionales para ahorrar memoria
4. **Análisis:** Los análisis grandes pueden fallar por falta de memoria

## 📊 Monitoreo

Vigila estos indicadores en Railway:
- Memory Usage < 90%
- CPU Usage (picos durante análisis son normales)
- Restart count (no debe reiniciarse constantemente)