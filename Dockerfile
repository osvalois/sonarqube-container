# Build stage
FROM eclipse-temurin:21-jre-alpine as builder

# Environment variables
ENV SONARQUBE_VERSION=10.4.1.88267 \
    SONARQUBE_HOME=/opt/sonarqube \
    SQ_DATA_DIR="/opt/sonarqube/data" \
    SQ_EXTENSIONS_DIR="/opt/sonarqube/extensions" \
    SQ_LOGS_DIR="/opt/sonarqube/logs" \
    SQ_TEMP_DIR="/opt/sonarqube/temp"

# Download SonarQube and plugins
ARG SONARQUBE_ZIP_URL=https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-${SONARQUBE_VERSION}.zip
ARG CNES_REPORT_URL=https://github.com/cnescatlab/sonar-cnes-report/releases/download/4.3.1/sonar-cnes-report-4.3.1.jar
ARG COMMUNITY_BRANCH_URL=https://github.com/mc1arke/sonarqube-community-branch-plugin/releases/download/1.17.0/sonarqube-community-branch-plugin-1.17.0.jar
ARG GITLAB_PLUGIN_URL=https://github.com/gabrie-allaigre/sonar-gitlab-plugin/releases/download/4.8.0/sonar-gitlab-plugin-4.8.0.jar
ARG SONARCXX_URL=https://github.com/SonarOpenCommunity/sonar-cxx/releases/download/cxx-2.1.2/sonar-cxx-plugin-2.1.2.jar
ARG ESLINT_SONARJS_URL=https://github.com/SonarSource/eslint-plugin-sonarjs/releases/download/1.0.3/eslint-plugin-sonarjs-1.0.3.tgz
ARG DEPENDENCY_CHECK_URL=https://github.com/dependency-check/dependency-check-sonar-plugin/releases/download/sonar-dependency-check-5.1.1/sonar-dependency-check-plugin-5.1.1.jar

RUN set -eux; \
    apk add --no-cache curl unzip; \
    mkdir -p /opt; \
    curl --fail --location --output sonarqube.zip --silent --show-error "${SONARQUBE_ZIP_URL}"; \
    unzip -q sonarqube.zip -d /opt; \
    mv /opt/sonarqube-${SONARQUBE_VERSION} ${SONARQUBE_HOME}; \
    rm -rf ${SONARQUBE_HOME}/bin/*; \
    rm sonarqube.zip*; \
    mkdir -p ${SQ_EXTENSIONS_DIR}/plugins; \
    for plugin in "${CNES_REPORT_URL}" "${COMMUNITY_BRANCH_URL}" "${GITLAB_PLUGIN_URL}" "${SONARCXX_URL}" "${ESLINT_SONARJS_URL}" "${DEPENDENCY_CHECK_URL}"; do \
        curl --fail --location --output ${SQ_EXTENSIONS_DIR}/plugins/$(basename ${plugin}) "${plugin}" || echo "Failed to download plugin: ${plugin}"; \
    done; \
    echo "sonar.pdf.report.enabled=true" >> ${SONARQUBE_HOME}/conf/sonar.properties; \
    echo "sonar.pdf.report.path=${SQ_DATA_DIR}/report.pdf" >> ${SONARQUBE_HOME}/conf/sonar.properties

# Final stage
FROM eclipse-temurin:21-jre-alpine

# Metadata
LABEL org.opencontainers.image.url="https://github.com/osvalois/sonarqube-container"
LABEL org.opencontainers.image.description="SonarQube Docker image with CNES Report, Community Branch, GitLab, SonarCXX, ESLint SonarJS, and Dependency-Check plugins"
LABEL maintainer="Oscar Valois osvaloismtz@gmail.com"

ENV LANG='en_US.UTF-8' \
    LANGUAGE='en_US:en' \
    LC_ALL='en_US.UTF-8' \
    SONARQUBE_HOME=/opt/sonarqube \
    SQ_DATA_DIR="/opt/sonarqube/data" \
    SQ_EXTENSIONS_DIR="/opt/sonarqube/extensions" \
    SQ_LOGS_DIR="/opt/sonarqube/logs" \
    SQ_TEMP_DIR="/opt/sonarqube/temp"

RUN apk add --no-cache bash su-exec ttf-dejavu; \
    addgroup -S sonarqube && adduser -S -G sonarqube sonarqube

COPY --from=builder --chown=sonarqube:sonarqube ${SONARQUBE_HOME} ${SONARQUBE_HOME}
COPY entrypoint.sh ${SONARQUBE_HOME}/docker/entrypoint.sh

RUN chmod +x ${SONARQUBE_HOME}/docker/entrypoint.sh; \
    chmod -R 777 "${SQ_DATA_DIR}" "${SQ_EXTENSIONS_DIR}" "${SQ_LOGS_DIR}" "${SQ_TEMP_DIR}"

WORKDIR ${SONARQUBE_HOME}
EXPOSE 9000

ENTRYPOINT ["/opt/sonarqube/docker/entrypoint.sh"]

ENV SONAR_WEB_JAVAADDITIONALOPTS="-javaagent:${SQ_EXTENSIONS_DIR}/plugins/sonarqube-community-branch-plugin-1.17.0.jar=web"
ENV SONAR_CE_JAVAADDITIONALOPTS="-javaagent:${SQ_EXTENSIONS_DIR}/plugins/sonarqube-community-branch-plugin-1.17.0.jar=ce"
