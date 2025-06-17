# Guía de Uso del Community Branch Plugin (v25.5.0)

Este documento proporciona instrucciones para utilizar el Community Branch Plugin que ha sido instalado en la instancia de SonarQube Community Build 25.5.

## ¿Qué es el Community Branch Plugin?

El Community Branch Plugin permite el análisis de diferentes ramas y la decoración de pull requests en la versión Community de SonarQube, funcionalidades que normalmente solo están disponibles en las ediciones comerciales.

## Capacidades Principales

1. **Análisis de Ramas**: Analizar diferentes ramas de tu proyecto (master, develop, feature, etc.)
2. **Análisis de Pull Requests**: Obtener análisis específicos para cada pull request
3. **Decoración de Pull Requests**: Mostrar los resultados del análisis directamente en tus pull requests en GitHub, GitLab, etc.

## Cómo Utilizar el Análisis de Ramas

### En la Línea de Comandos

Para analizar una rama específica, agrega el parámetro `sonar.branch.name` a tu comando de análisis:

```bash
# Usando Maven
mvn sonar:sonar -Dsonar.branch.name=nombre-de-rama

# Usando Gradle
./gradlew sonarqube -Dsonar.branch.name=nombre-de-rama

# Usando SonarScanner
sonar-scanner -Dsonar.branch.name=nombre-de-rama
```

### En CI/CD Pipelines

En tus pipelines de integración continua, configura el parámetro `sonar.branch.name` con el nombre de la rama que se está construyendo.

#### Ejemplo en GitHub Actions

```yaml
- name: SonarQube Scan
  uses: SonarSource/sonarqube-scan-action@master
  env:
    SONAR_HOST_URL: ${{ secrets.SONAR_HOST_URL }}
    SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
  with:
    args: >
      -Dsonar.branch.name=${{ github.ref_name }}
```

#### Ejemplo en GitLab CI

```yaml
sonarqube-check:
  script:
    - sonar-scanner
      -Dsonar.branch.name=${CI_COMMIT_REF_NAME}
```

## Cómo Utilizar el Análisis de Pull Requests

Para analizar pull requests, necesitas configurar los siguientes parámetros:

```
sonar.pullrequest.key=<ID_DEL_PULL_REQUEST>
sonar.pullrequest.branch=<RAMA_ORIGEN>
sonar.pullrequest.base=<RAMA_DESTINO>
```

> **IMPORTANTE**: No utilices parámetros `sonar.branch.*` cuando estés analizando un pull request.

### Ejemplo en GitHub Actions

```yaml
- name: SonarQube Scan for PR
  if: github.event_name == 'pull_request'
  uses: SonarSource/sonarqube-scan-action@master
  env:
    SONAR_HOST_URL: ${{ secrets.SONAR_HOST_URL }}
    SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
  with:
    args: >
      -Dsonar.pullrequest.key=${{ github.event.pull_request.number }}
      -Dsonar.pullrequest.branch=${{ github.head_ref }}
      -Dsonar.pullrequest.base=${{ github.base_ref }}
      -Dsonar.scm.revision=${{ github.event.pull_request.head.sha }}
```

### Ejemplo en GitLab CI

```yaml
sonarqube-pr-check:
  script:
    - sonar-scanner
      -Dsonar.pullrequest.key=${CI_MERGE_REQUEST_IID}
      -Dsonar.pullrequest.branch=${CI_MERGE_REQUEST_SOURCE_BRANCH_NAME}
      -Dsonar.pullrequest.base=${CI_MERGE_REQUEST_TARGET_BRANCH_NAME}
```

## Configuración de Decoración de Pull Requests

Para que SonarQube pueda comentar directamente en tus pull requests, debes configurar la integración con tu plataforma de control de versiones:

1. Accede a SonarQube con credenciales de administrador
2. Ve a Administración > Configuración > Integraciones de ALM
3. Configura la integración con tu proveedor (GitHub, GitLab, Azure DevOps, etc.)
4. Proporciona los tokens de acceso necesarios

### URL Base para Imágenes en Pull Requests

Si tu servidor SonarQube está detrás de un firewall o tu servicio de PR no tiene acceso al servidor, debes cambiar la propiedad "URL base de imágenes" en Administración > Configuración general > Pull Requests.

Puedes usar la URL `https://raw.githubusercontent.com/mc1arke/sonarqube-community-branch-plugin/master/src/main/resources/static` o descargar los archivos de esta ubicación y alojarlos tú mismo.

## Viendo el Análisis en la Interfaz Web

1. Accede a tu instancia de SonarQube
2. Navega a tu proyecto
3. En la esquina superior izquierda, encontrarás un selector de ramas que te permitirá cambiar entre la rama principal y otras ramas analizadas
4. Para ver los pull requests, usa el selector de ramas y selecciona la pestaña "Pull Requests"

## Consideraciones Importantes

- Este plugin **no es mantenido ni respaldado por SonarSource**
- No existe una ruta de actualización oficial para migrar desde la edición Community a las ediciones comerciales
- Si planeas migrar a una edición comercial, ten en cuenta que esto puede resultar en la pérdida de algunos o todos tus datos

## Solución de Problemas

Si encuentras problemas con el plugin:

1. Verifica los logs de SonarQube en `/opt/sonarqube/logs`
2. Asegúrate de que los parámetros de rama o pull request están configurados correctamente
3. Verifica que no estés mezclando parámetros de rama y pull request en el mismo análisis
4. Asegúrate de que el plugin esté instalado correctamente y que el JavaAgent esté configurado
5. Si usas GitHub, asegúrate de incluir el parámetro `sonar.scm.revision` con el SHA del commit

## Referencias

- [Documentación oficial del plugin](https://github.com/mc1arke/sonarqube-community-branch-plugin)
- [Guía de SonarQube para decoración de Pull Requests](https://docs.sonarsource.com/sonarqube-server/latest/analyzing-source-code/pull-request-analysis/)