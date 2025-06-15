# SonarQube Official Report Plugins

Este contenedor incluye dos plugins oficiales para la generación de reportes de análisis de SonarQube:

## Plugins Instalados

### 1. CNES Report Plugin (v5.0.2)
**Desarrollador**: CATLab (CNES)  
**Repositorio**: https://github.com/cnescatlab/sonar-cnes-report  
**Compatibilidad**: SonarQube 7.9.x - 25.1.x  

#### Características:
- ✅ Exportación a múltiples formatos: **DOCX**, **XLSX**, **CSV**, **Markdown**, **TXT**
- ✅ Reportes personalizables con plantillas OpenXML
- ✅ Tablas dinámicas de issues
- ✅ Soporte multiidioma (Francés/Inglés)
- ✅ Métricas completas de calidad de código

#### Uso:
1. Accede a SonarQube: `http://localhost:9000`
2. Navega a tu proyecto
3. Ve al menú: **More** → **CNES Report**
4. Selecciona el formato deseado y genera el reporte

#### Uso por línea de comandos (Standalone):
```bash
# Dentro del contenedor
docker exec sonarqube-2025 java -jar /opt/sonarqube/extensions/plugins/sonar-cnes-report-plugin.jar \
  -s http://localhost:9000 \
  -p PROJECT_KEY \
  -t TOKEN \
  -o /opt/sonarqube/reports/
```

### 2. SonarQube PDF Report Plugin (v4.0.1)
**Desarrollador**: SonarQube Community  
**Repositorio**: https://github.com/SonarQubeCommunity/sonar-pdf-report  

#### Características:
- ✅ Generación automática de reportes **PDF**
- ✅ Dos tipos de reporte: **Executive** y **Workbook**
- ✅ Integración como post-job task
- ✅ Dashboard, violaciones y hotspots incluidos
- ✅ Métricas de reglas más violadas y clases complejas

#### Configuración:
El plugin se configura a nivel global o por proyecto en:
**Administration** → **Configuration** → **PDF Report**

#### Opciones disponibles:
- **Skip report generation**: Omitir generación automática
- **Report type**: Executive (resumen) o Workbook (completo)
- **Username/Password**: Para proyectos seguros

## Formatos de Reporte Disponibles

| Plugin | PDF | DOCX | XLSX | CSV | Markdown | TXT |
|--------|-----|------|------|-----|----------|-----|
| CNES Report | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| PDF Report | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |

## Acceso a Reportes Generados

Los reportes se guardan en `/opt/sonarqube/reports` y están disponibles a través del volumen Docker:

```bash
# Listar reportes generados
docker exec sonarqube-2025 ls -la /opt/sonarqube/reports/

# Copiar reportes al host
docker cp sonarqube-2025:/opt/sonarqube/reports ./sonarqube-reports

# Montar directorio local para acceso directo (docker-compose)
volumes:
  - ./reports:/opt/sonarqube/reports
```

## Configuración en docker-compose.yml

```yaml
services:
  sonarqube:
    # ... configuración existente
    volumes:
      - sonarqube_reports:/opt/sonarqube/reports
    environment:
      # Variables opcionales para CNES Report
      - SONAR_HOST_URL=http://localhost:9000
      - SONAR_PROJECT_KEY=your_project_key
      - SONAR_TOKEN=your_token
```

## Mejores Prácticas

### 1. Para reportes ejecutivos (stakeholders):
- Usar **PDF Report Plugin** con tipo "Executive"
- Formato limpio y profesional para presentaciones

### 2. Para análisis detallado (desarrolladores):
- Usar **CNES Report Plugin** con formato XLSX
- Incluye tablas dinámicas para análisis profundo

### 3. Para integración CI/CD:
- Usar **CNES Report Plugin** con formato CSV/JSON
- Facilita procesamiento automático

### 4. Para documentación:
- Usar **CNES Report Plugin** con formato Markdown
- Integrable en wikis y documentación técnica

## Solución de Problemas

### Plugin no aparece en el menú
```bash
# Verificar que los plugins están instalados
docker exec sonarqube-2025 ls -la /opt/sonarqube/extensions/plugins/

# Reiniciar SonarQube
docker-compose restart sonarqube
```

### Error 500 al generar reporte
```bash
# Verificar logs de SonarQube
docker-compose logs sonarqube

# Verificar permisos
docker exec sonarqube-2025 chown -R 1000:0 /opt/sonarqube/reports
```

### Incompatibilidad de versiones
- CNES Report v5.0.2 es compatible con SonarQube 10.x+
- PDF Report v4.0.1 verificar compatibilidad en su repositorio

## Variables de Entorno Útiles

```bash
# Para CNES Report standalone mode
SONAR_HOST_URL=http://localhost:9000
SONAR_PROJECT_KEY=your_project
SONAR_TOKEN=your_sonar_token

# Para configuración de proxy (si aplica)
SONAR_PROXY_HOST=proxy.company.com
SONAR_PROXY_PORT=8080
```

## Automatización con CI/CD

### GitHub Actions ejemplo:
```yaml
- name: Generate SonarQube Reports
  run: |
    # Esperar a que SonarQube esté listo
    timeout 300 bash -c 'until curl -fs http://localhost:9000/api/system/status; do sleep 5; done'
    
    # Generar reporte CNES (ejemplo)
    docker exec sonarqube-2025 java -jar /opt/sonarqube/extensions/plugins/sonar-cnes-report-plugin.jar \
      -s http://localhost:9000 \
      -p ${{ github.event.repository.name }} \
      -t ${{ secrets.SONAR_TOKEN }} \
      -o /opt/sonarqube/reports/
    
    # Copiar reportes
    docker cp sonarqube-2025:/opt/sonarqube/reports ./sonarqube-reports

- name: Upload Reports as Artifacts
  uses: actions/upload-artifact@v3
  with:
    name: sonarqube-reports
    path: sonarqube-reports/
```

Los plugins están correctamente configurados y listos para usar según los estándares oficiales de SonarQube.