FROM eclipse-temurin:17.0.6_10-jre

LABEL org.opencontainers.image.url="https://github.com/osvalois/sonarqube-container"
LABEL org.opencontainers.image.description="SonarQube Docker image with additional plugins"
LABEL maintainer="Oscar Valois osvaloismtz@gmail.com"

ENV LANG='en_US.UTF-8' \
    LANGUAGE='en_US:en' \
    LC_ALL='en_US.UTF-8'

ENV SONARQUBE_VERSION=${SONARQUBE_VERSION:-9.9.4.87374}
ARG SONARQUBE_ZIP_URL=https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-${SONARQUBE_VERSION}.zip
ARG PLUGIN_VERSION=1.14.0
ARG PLUGIN_URL=https://github.com/mc1arke/sonarqube-community-branch-plugin/releases/download/${PLUGIN_VERSION}/sonarqube-community-branch-plugin-${PLUGIN_VERSION}.jar
ARG SONAR_REPORT_PLUGIN_VERSION=1.7.1
ARG SONAR_REPORT_PLUGIN_URL=https://github.com/SonarSource/sonar-report/releases/download/${SONAR_REPORT_PLUGIN_VERSION}/sonar-report-plugin-${SONAR_REPORT_PLUGIN_VERSION}.jar
ARG ENTERPRISE_AUTH_PLUGIN_VERSION=1.9.0
ARG ENTERPRISE_AUTH_PLUGIN_URL=https://github.com/SonarSource/sonarqube-enterprise-auth/releases/download/${ENTERPRISE_AUTH_PLUGIN_VERSION}/sonar-enterprise-auth-plugin-${ENTERPRISE_AUTH_PLUGIN_VERSION}.jar
ARG GITHUB_PLUGIN_VERSION=1.13.0
ARG GITHUB_PLUGIN_URL=https://github.com/SonarSource/sonar-github/releases/download/${GITHUB_PLUGIN_VERSION}/sonar-github-plugin-${GITHUB_PLUGIN_VERSION}.jar
ARG GITLAB_PLUGIN_VERSION=4.6.0
ARG GITLAB_PLUGIN_URL=https://github.com/gabrie-allaigre/sonar-gitlab-plugin/releases/download/${GITLAB_PLUGIN_VERSION}/sonar-gitlab-plugin-${GITLAB_PLUGIN_VERSION}.jar

ENV JAVA_HOME='/opt/java/openjdk' \
    SONARQUBE_HOME=/opt/sonarqube \
    SONAR_VERSION="${SONARQUBE_VERSION}" \
    SQ_DATA_DIR="/opt/sonarqube/data" \
    SQ_EXTENSIONS_DIR="/opt/sonarqube/extensions" \
    SQ_LOGS_DIR="/opt/sonarqube/logs" \
    SQ_TEMP_DIR="/opt/sonarqube/temp"

RUN set -eux; \
    groupadd --system --gid 1000 sonarqube; \
    useradd --system --uid 1000 --gid sonarqube sonarqube; \
    apt-get update && apt-get install -y gnupg unzip curl bash fonts-dejavu; \
    echo "networkaddress.cache.ttl=5" >> "${JAVA_HOME}/conf/security/java.security"; \
    sed --in-place --expression="s?securerandom.source=file:/dev/random?securerandom.source=file:/dev/urandom?g" "${JAVA_HOME}/conf/security/java.security"; \
    mkdir --parents /opt; \
    cd /opt; \
    curl --fail --location --output sonarqube.zip --silent --show-error "${SONARQUBE_ZIP_URL}" || (echo "Failed to download SonarQube" && exit 1); \
    unzip -q sonarqube.zip; \
    mv "sonarqube-${SONARQUBE_VERSION}" sonarqube; \
    rm sonarqube.zip*; \
    rm -rf ${SONARQUBE_HOME}/bin/*; \
    ln -s "${SONARQUBE_HOME}/lib/sonar-application-${SONARQUBE_VERSION}.jar" "${SONARQUBE_HOME}/lib/sonarqube.jar"; \
    chmod -R 555 ${SONARQUBE_HOME}; \
    chmod -R ugo+wrX "${SQ_DATA_DIR}" "${SQ_EXTENSIONS_DIR}" "${SQ_LOGS_DIR}" "${SQ_TEMP_DIR}"; \
    mkdir -p ${SQ_EXTENSIONS_DIR}/plugins; \
    for plugin_url in "${PLUGIN_URL}" "${SONAR_REPORT_PLUGIN_URL}" "${ENTERPRISE_AUTH_PLUGIN_URL}" "${GITHUB_PLUGIN_URL}" "${GITLAB_PLUGIN_URL}"; do \
        curl --fail --location --output ${SQ_EXTENSIONS_DIR}/plugins/$(basename ${plugin_url}) "${plugin_url}" || echo "Failed to download plugin: ${plugin_url}"; \
    done; \
    apt-get remove -y gnupg unzip curl; \
    apt-get autoremove -y; \
    rm -rf /var/lib/apt/lists/*;

COPY entrypoint.sh ${SONARQUBE_HOME}/docker/
RUN chmod +x ${SONARQUBE_HOME}/docker/entrypoint.sh && chown sonarqube:sonarqube ${SONARQUBE_HOME}/docker/entrypoint.sh

RUN echo "sonar.pdf.report.enabled=true" >> ${SONARQUBE_HOME}/conf/sonar.properties && \
    echo "sonar.pdf.report.path=${SQ_DATA_DIR}/report.pdf" >> ${SONARQUBE_HOME}/conf/sonar.properties

WORKDIR ${SONARQUBE_HOME}
EXPOSE 9000

USER sonarqube
STOPSIGNAL SIGINT

ENTRYPOINT ["/opt/sonarqube/docker/entrypoint.sh"]

ENV SONAR_WEB_JAVAADDITIONALOPTS="-javaagent:${SQ_EXTENSIONS_DIR}/plugins/sonarqube-community-branch-plugin-${PLUGIN_VERSION}.jar=web"
ENV SONAR_CE_JAVAADDITIONALOPTS="-javaagent:${SQ_EXTENSIONS_DIR}/plugins/sonarqube-community-branch-plugin-${PLUGIN_VERSION}.jar=ce"