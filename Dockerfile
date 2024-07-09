# Use Eclipse Temurin as the base image for Java 17
FROM eclipse-temurin:17.0.6_10-jre

# Metadata
LABEL org.opencontainers.image.url="https://github.com/SonarSource/docker-sonarqube"
LABEL org.opencontainers.image.description="SonarQube Docker image with additional plugins"
LABEL org.opencontainers.image.version="${SONARQUBE_VERSION}"
LABEL maintainer="Your Name <your.email@example.com>"

# Set environment variables
ENV LANG='en_US.UTF-8' \
    LANGUAGE='en_US:en' \
    LC_ALL='en_US.UTF-8'

# SonarQube setup
ARG SONARQUBE_VERSION
ENV SONARQUBE_VERSION=${SONARQUBE_VERSION}
ARG SONARQUBE_ZIP_URL=https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-${SONARQUBE_VERSION}.zip

# Plugin versions and URLs
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

# SonarQube environment variables
ENV JAVA_HOME='/opt/java/openjdk' \
    SONARQUBE_HOME=/opt/sonarqube \
    SONAR_VERSION="${SONARQUBE_VERSION}" \
    SQ_DATA_DIR="/opt/sonarqube/data" \
    SQ_EXTENSIONS_DIR="/opt/sonarqube/extensions" \
    SQ_LOGS_DIR="/opt/sonarqube/logs" \
    SQ_TEMP_DIR="/opt/sonarqube/temp"

# Install dependencies, download and set up SonarQube
RUN set -eux; \
    # Create sonarqube user and group
    groupadd --system --gid 1000 sonarqube; \
    useradd --system --uid 1000 --gid sonarqube sonarqube; \
    # Install required packages
    apt-get update && apt-get --no-install-recommends -y install \
        gnupg \
        unzip \
        curl \
        bash \
        fonts-dejavu \
    && rm -rf /var/lib/apt/lists/*; \
    # Configure Java security
    echo "networkaddress.cache.ttl=5" >> "${JAVA_HOME}/conf/security/java.security"; \
    sed --in-place --expression="s?securerandom.source=file:/dev/random?securerandom.source=file:/dev/urandom?g" "${JAVA_HOME}/conf/security/java.security"; \
    # Download and verify SonarQube
    for server in $(shuf -e hkps://keys.openpgp.org \
                            hkps://keyserver.ubuntu.com) ; do \
        gpg --batch --keyserver "${server}" --recv-keys 679F1EE92B19609DE816FDE81DB198F93525EC1A && break || : ; \
    done; \
    mkdir --parents /opt; \
    cd /opt; \
    curl --fail --location --output sonarqube.zip --silent --show-error "${SONARQUBE_ZIP_URL}"; \
    curl --fail --location --output sonarqube.zip.asc --silent --show-error "${SONARQUBE_ZIP_URL}.asc"; \
    gpg --batch --verify sonarqube.zip.asc sonarqube.zip; \
    unzip -q sonarqube.zip; \
    mv "sonarqube-${SONARQUBE_VERSION}" sonarqube; \
    rm sonarqube.zip*; \
    rm -rf ${SONARQUBE_HOME}/bin/*; \
    ln -s "${SONARQUBE_HOME}/lib/sonar-application-${SONARQUBE_VERSION}.jar" "${SONARQUBE_HOME}/lib/sonarqube.jar"; \
    # Set permissions
    chmod -R 555 ${SONARQUBE_HOME}; \
    chmod -R ugo+wrX "${SQ_DATA_DIR}" "${SQ_EXTENSIONS_DIR}" "${SQ_LOGS_DIR}" "${SQ_TEMP_DIR}"; \
    # Download plugins
    mkdir -p ${SQ_EXTENSIONS_DIR}/plugins; \
    curl --fail --location --output ${SQ_EXTENSIONS_DIR}/plugins/sonarqube-community-branch-plugin-${PLUGIN_VERSION}.jar "${PLUGIN_URL}"; \
    curl --fail --location --output ${SQ_EXTENSIONS_DIR}/plugins/sonar-report-plugin-${SONAR_REPORT_PLUGIN_VERSION}.jar "${SONAR_REPORT_PLUGIN_URL}"; \
    curl --fail --location --output ${SQ_EXTENSIONS_DIR}/plugins/sonar-enterprise-auth-plugin-${ENTERPRISE_AUTH_PLUGIN_VERSION}.jar "${ENTERPRISE_AUTH_PLUGIN_URL}"; \
    curl --fail --location --output ${SQ_EXTENSIONS_DIR}/plugins/sonar-github-plugin-${GITHUB_PLUGIN_VERSION}.jar "${GITHUB_PLUGIN_URL}"; \
    curl --fail --location --output ${SQ_EXTENSIONS_DIR}/plugins/sonar-gitlab-plugin-${GITLAB_PLUGIN_VERSION}.jar "${GITLAB_PLUGIN_URL}"; \
    # Clean up
    apt-get remove -y gnupg unzip curl; \
    apt-get autoremove -y; \
    rm -rf /var/lib/apt/lists/*;

# Copy entrypoint script
COPY entrypoint.sh ${SONARQUBE_HOME}/docker/
RUN chmod +x ${SONARQUBE_HOME}/docker/entrypoint.sh && \
    chown sonarqube:sonarqube ${SONARQUBE_HOME}/docker/entrypoint.sh

# Configure report plugin
RUN echo "sonar.pdf.report.enabled=true" >> ${SONARQUBE_HOME}/conf/sonar.properties && \
    echo "sonar.pdf.report.path=${SQ_DATA_DIR}/report.pdf" >> ${SONARQUBE_HOME}/conf/sonar.properties

# Set working directory
WORKDIR ${SONARQUBE_HOME}

# Expose port 9000 for web access
EXPOSE 9000

# Switch to non-root user
USER sonarqube

# Set stop signal
STOPSIGNAL SIGINT

# Set entrypoint
ENTRYPOINT ["/opt/sonarqube/docker/entrypoint.sh"]

# Configure Java options for web and compute engine
ENV SONAR_WEB_JAVAADDITIONALOPTS="-javaagent:${SQ_EXTENSIONS_DIR}/plugins/sonarqube-community-branch-plugin-${PLUGIN_VERSION}.jar=web"
ENV SONAR_CE_JAVAADDITIONALOPTS="-javaagent:${SQ_EXTENSIONS_DIR}/plugins/sonarqube-community-branch-plugin-${PLUGIN_VERSION}.jar=ce"