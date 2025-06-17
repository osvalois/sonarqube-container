# Guía de Uso del Plugin CNES Report en SonarQube 25.5

Este documento proporciona instrucciones detalladas sobre cómo utilizar el plugin CNES Report que ha sido instalado en la instancia de SonarQube Community Build 25.5.

## ¿Qué es el Plugin CNES Report?

El plugin CNES Report permite generar informes completos de análisis de código en múltiples formatos a partir de los datos de SonarQube. Estos informes son útiles para:

- Documentación de proyectos
- Revisiones de código
- Auditorías de calidad
- Seguimiento de métricas a lo largo del tiempo

## Formatos de Reporte Disponibles

El plugin puede generar reportes en los siguientes formatos:
- PDF
- DOCX (Microsoft Word)
- XLSX (Microsoft Excel)
- CSV
- Markdown

## Cómo Generar Reportes

### Opción 1: Usando la Interfaz Web

1. Accede a tu instancia de SonarQube (por defecto, http://localhost:9000 o la URL proporcionada por Railway)
2. Inicia sesión con tus credenciales (por defecto, admin/admin)
3. En la barra de navegación superior, haz clic en "More"
4. Selecciona "CNES Report" en el menú desplegable
5. En el formulario que aparece:
   - Selecciona el proyecto para el cual quieres generar el reporte
   - Selecciona la rama (si corresponde)
   - Marca las casillas para los tipos de reportes que deseas generar
   - Opcionalmente, introduce un autor y otros metadatos
6. Haz clic en "Generate" para crear y descargar el reporte

### Opción 2: Usando la API REST

El plugin expone un endpoint de API que puedes usar para automatizar la generación de reportes:

```
GET /api/cnesreport/report?project={projectKey}&branch={branchName}&author={authorName}&template={useTemplate}
```

Parámetros:
- `project`: Clave del proyecto (obligatorio)
- `branch`: Nombre de la rama (opcional, por defecto "master" o "main")
- `author`: Nombre del autor (opcional)
- `template`: Usar plantilla predeterminada (opcional, "true" o "false")

Ejemplo usando curl:
```bash
curl -X GET "http://localhost:9000/api/cnesreport/report?project=my-project&branch=master&author=SonarQube&template=true" -o sonar-report.zip
```

### Opción 3: Usando el Script Proporcionado

Hemos creado un script para facilitar la generación de reportes:

```bash
./generate-report.sh [project_key] [branch_name]
```

Ejemplo:
```bash
./generate-report.sh my-project master
```

Si no se proporciona ningún parámetro, el script generará reportes para todos los proyectos en la rama "master".

## Contenido de los Reportes

Los reportes generados incluyen:

1. **Resumen del Proyecto**:
   - Información general
   - Fecha de análisis
   - Versión

2. **Métricas de Calidad**:
   - Complejidad
   - Cobertura de código
   - Duplicaciones
   - Deuda técnica

3. **Problemas Detectados**:
   - Bugs
   - Vulnerabilidades
   - Code smells
   - Security hotspots

4. **Reglas Violadas**:
   - Lista de reglas
   - Severidad
   - Número de ocurrencias

5. **Resultados Detallados**:
   - Problemas por archivo
   - Ubicación exacta (línea, columna)
   - Recomendaciones para solucionar

## Consejos y Solución de Problemas

- **Tiempo de Generación**: Para proyectos grandes, la generación de reportes puede tomar varios minutos.
- **Memoria**: Si encuentras errores de memoria, considera aumentar la asignación de memoria para SonarQube.
- **Falta de Datos**: Si el reporte parece incompleto, asegúrate de que el análisis de SonarQube se haya completado correctamente.
- **Formatos no Disponibles**: Si algún formato no está disponible, verifica las propiedades de configuración en `/opt/sonarqube/conf/cnes-report.properties`.

## Configuración Avanzada

La configuración del plugin se encuentra en:
```
/opt/sonarqube/conf/cnes-report.properties
```

Propiedades principales:
- `sonar.cnes.report.enabled`: Habilitar/deshabilitar el plugin
- `sonar.cnes.report.exporters`: Habilitar/deshabilitar exportadores
- `sonar.cnes.report.confidential`: Marca el reporte como confidencial
- `sonar.cnes.report.author`: Autor predeterminado
- `sonar.cnes.report.template.default`: Usar plantilla predeterminada
- `sonar.pdf.report.enabled`: Habilitar reportes en PDF

## Referencias

- [Documentación oficial del plugin CNES Report](https://github.com/cnescatlab/sonar-cnes-report)
- [Documentación de SonarQube](https://docs.sonarsource.com/sonarqube-community-build/)