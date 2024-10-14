# Use a more recent base image
FROM eclipse-temurin:21-jre

# Metadata
LABEL org.opencontainers.image.url="https://github.com/osvalois/sonarqube-container"
LABEL org.opencontainers.image.description="SonarQube Docker image with CNES Report, Community Branch, GitLab, SonarCXX, ESLint SonarJS, and Dependency-Check plugins"
LABEL maintainer="Oscar Valois osvaloismtz@gmail.com"

# Environment variables
ENV LANG='en_US.UTF-8' \
    LANGUAGE='en_US:en' \
    LC_ALL='en_US.UTF-8' \
    SONARQUBE_VERSION=10.4.1.88267 \
    JAVA_HOME='/opt/java/openjdk' \
    SONARQUBE_HOME=/opt/sonarqube \
    SQ_DATA_DIR="/opt/sonarqube/data" \
    SQ_EXTENSIONS_DIR="/opt/sonarqube/extensions" \
    SQ_LOGS_DIR="/opt/sonarqube/logs" \
    SQ_TEMP_DIR="/opt/sonarqube/temp"

# ARG for plugin versions and URLs
ARG SONARQUBE_ZIP_URL=https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-${SONARQUBE_VERSION}.zip \
    CNES_REPORT_VERSION=4.3.1 \
    COMMUNITY_BRANCH_VERSION=1.17.0 \
    GITLAB_PLUGIN_VERSION=4.8.0 \
    SONARCXX_VERSION=2.1.2 \
    ESLINT_SONARJS_VERSION=1.0.3 \
    DEPENDENCY_CHECK_VERSION=5.1.1

# Download URLs for plugins
ARG CNES_REPORT_URL=https://github.com/cnescatlab/sonar-cnes-report/releases/download/${CNES_REPORT_VERSION}/sonar-cnes-report-${CNES_REPORT_VERSION}.jar \
    COMMUNITY_BRANCH_URL=https://github.com/mc1arke/sonarqube-community-branch-plugin/releases/download/${COMMUNITY_BRANCH_VERSION}/sonarqube-community-branch-plugin-${COMMUNITY_BRANCH_VERSION}.jar \
    GITLAB_PLUGIN_URL=https://github.com/gabrie-allaigre/sonar-gitlab-plugin/releases/download/${GITLAB_PLUGIN_VERSION}/sonar-gitlab-plugin-${GITLAB_PLUGIN_VERSION}.jar \
    SONARCXX_URL=https://github.com/SonarOpenCommunity/sonar-cxx/releases/download/cxx-${SONARCXX_VERSION}/sonar-cxx-plugin-${SONARCXX_VERSION}.jar \
    ESLINT_SONARJS_URL=https://github.com/SonarSource/eslint-plugin-sonarjs/releases/download/${ESLINT_SONARJS_VERSION}/eslint-plugin-sonarjs-${ESLINT_SONARJS_VERSION}.tgz \
    DEPENDENCY_CHECK_URL=https://github.com/dependency-check/dependency-check-sonar-plugin/releases/download/sonar-dependency-check-${DEPENDENCY_CHECK_VERSION}/sonar-dependency-check-plugin-${DEPENDENCY_CHECK_VERSION}.jar

# Install dependencies, download and set up SonarQube and plugins
RUN set -eux; \
    groupadd --system --gid 1000 sonarqube; \
    useradd --system --uid 1000 --gid sonarqube sonarqube; \
    apt-get update && apt-get install -y --no-install-recommends \
        gnupg \
        unzip \
        curl \
        bash \
        fonts-dejavu; \
    echo "networkaddress.cache.ttl=5" >> "${JAVA_HOME}/conf/security/java.security"; \
    sed --in-place --expression="s?securerandom.source=file:/dev/random?securerandom.source=file:/dev/urandom?g" "${JAVA_HOME}/conf/security/java.security"; \
    mkdir --parents /opt; \
    cd /opt; \
    curl --fail --location --output sonarqube.zip --silent --show-error "${SONARQUBE_ZIP_URL}"; \
    unzip -q sonarqube.zip; \
    mv "sonarqube-${SONARQUBE_VERSION}" sonarqube; \
    rm sonarqube.zip*; \
    rm -rf ${SONARQUBE_HOME}/bin/*; \
    ln -s "${SONARQUBE_HOME}/lib/sonar-application-${SONARQUBE_VERSION}.jar" "${SONARQUBE_HOME}/lib/sonarqube.jar"; \
    chmod -R 555 ${SONARQUBE_HOME}; \
    chmod -R ugo+wrX "${SQ_DATA_DIR}" "${SQ_EXTENSIONS_DIR}" "${SQ_LOGS_DIR}" "${SQ_TEMP_DIR}"; \
    mkdir -p ${SQ_EXTENSIONS_DIR}/plugins; \
    for plugin in "${CNES_REPORT_URL}" "${COMMUNITY_BRANCH_URL}" "${GITLAB_PLUGIN_URL}" "${SONARCXX_URL}" "${ESLINT_SONARJS_URL}" "${DEPENDENCY_CHECK_URL}"; do \
        curl --fail --location --output ${SQ_EXTENSIONS_DIR}/plugins/$(basename ${plugin}) "${plugin}" || echo "Failed to download plugin: ${plugin}"; \
    done; \
    apt-get remove -y gnupg unzip curl; \
    apt-get autoremove -y; \
    rm -rf /var/lib/apt/lists/*; \
    echo "sonar.pdf.report.enabled=true" >> ${SONARQUBE_HOME}/conf/sonar.properties; \
    echo "sonar.pdf.report.path=${SQ_DATA_DIR}/report.pdf" >> ${SONARQUBE_HOME}/conf/sonar.properties

# Copy and set up entrypoint
COPY entrypoint.sh ${SONARQUBE_HOME}/docker/
RUN chmod +x ${SONARQUBE_HOME}/docker/entrypoint.sh && chown sonarqube:sonarqube ${SONARQUBE_HOME}/docker/entrypoint.sh

# Set working directory, expose port, and set user
WORKDIR ${SONARQUBE_HOME}
EXPOSE 9000
USER sonarqube
STOPSIGNAL SIGINT

# Set entrypoint
ENTRYPOINT ["/opt/sonarqube/docker/entrypoint.sh"]

# Set Java additional options for web and CE
ENV SONAR_WEB_JAVAADDITIONALOPTS="-javaagent:${SQ_EXTENSIONS_DIR}/plugins/sonarqube-community-branch-plugin-${COMMUNITY_BRANCH_VERSION}.jar=web"
ENV SONAR_CE_JAVAADDITIONALOPTS="-javaagent:${SQ_EXTENSIONS_DIR}/plugins/sonarqube-community-branch-plugin-${COMMUNITY_BRANCH_VERSION}.jar=ce"
