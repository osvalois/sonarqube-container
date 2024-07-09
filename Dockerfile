FROM eclipse-temurin:17.0.11_9-jre-jammy

LABEL org.opencontainers.image.url=https://github.com/SonarSource/docker-sonarqube

ENV LANG='en_US.UTF-8' \
    LANGUAGE='en_US:en' \
    LC_ALL='en_US.UTF-8'

#
# SonarQube setup
#
ARG SONARQUBE_VERSION=latest
ARG SONARQUBE_ZIP_URL=https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-${SONARQUBE_VERSION}.zip
ARG PLUGIN_VERSION=1.14.0
ARG PLUGIN_URL=https://github.com/mc1arke/sonarqube-community-branch-plugin/releases/download/${PLUGIN_VERSION}/sonarqube-community-branch-plugin-${PLUGIN_VERSION}.jar
ARG REPORT_PLUGIN_VERSION=5.3.4
ARG REPORT_PLUGIN_URL=https://github.com/SonarSource/sonar-report-plugin/releases/download/${REPORT_PLUGIN_VERSION}/sonar-report-plugin-${REPORT_PLUGIN_VERSION}.jar
ARG LDAP_PLUGIN_VERSION=2.3.0
ARG LDAP_PLUGIN_URL=https://github.com/SonarSource/sonar-ldap/releases/download/${LDAP_PLUGIN_VERSION}/sonar-ldap-plugin-${LDAP_PLUGIN_VERSION}.jar
ARG GITHUB_PLUGIN_VERSION=1.9.0
ARG GITHUB_PLUGIN_URL=https://github.com/SonarSource/sonar-github/releases/download/${GITHUB_PLUGIN_VERSION}/sonar-github-plugin-${GITHUB_PLUGIN_VERSION}.jar
ARG GITLAB_PLUGIN_VERSION=4.7.0
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
    apt-get update; \
    apt-get --no-install-recommends -y install gnupg unzip curl bash fonts-dejavu; \
    echo "networkaddress.cache.ttl=5" >> "${JAVA_HOME}/conf/security/java.security"; \
    sed --in-place --expression="s?securerandom.source=file:/dev/random?securerandom.source=file:/dev/urandom?g" "${JAVA_HOME}/conf/security/java.security"; \
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
    chmod -R 555 ${SONARQUBE_HOME}; \
    chmod -R ugo+wrX "${SQ_DATA_DIR}" "${SQ_EXTENSIONS_DIR}" "${SQ_LOGS_DIR}" "${SQ_TEMP_DIR}"; \
    curl --fail --location --output ${SQ_EXTENSIONS_DIR}/plugins/sonarqube-community-branch-plugin-${PLUGIN_VERSION}.jar "${PLUGIN_URL}"; \
    curl --fail --location --output ${SQ_EXTENSIONS_DIR}/plugins/sonar-report-plugin-${REPORT_PLUGIN_VERSION}.jar "${REPORT_PLUGIN_URL}"; \
    curl --fail --location --output ${SQ_EXTENSIONS_DIR}/plugins/sonar-ldap-plugin-${LDAP_PLUGIN_VERSION}.jar "${LDAP_PLUGIN_URL}"; \
    curl --fail --location --output ${SQ_EXTENSIONS_DIR}/plugins/sonar-github-plugin-${GITHUB_PLUGIN_VERSION}.jar "${GITHUB_PLUGIN_URL}"; \
    curl --fail --location --output ${SQ_EXTENSIONS_DIR}/plugins/sonar-gitlab-plugin-${GITLAB_PLUGIN_VERSION}.jar "${GITLAB_PLUGIN_URL}"; \
    apt-get remove -y gnupg unzip curl; \
    rm -rf /var/lib/apt/lists/*;

COPY entrypoint.sh ${SONARQUBE_HOME}/docker/
RUN chmod +x ${SONARQUBE_HOME}/docker/entrypoint.sh && chown sonarqube:sonarqube ${SONARQUBE_HOME}/docker/entrypoint.sh

VOLUME ["/opt/sonarqube/data", "/opt/sonarqube/extensions", "/opt/sonarqube/logs", "/opt/sonarqube/temp"]

WORKDIR ${SONARQUBE_HOME}
EXPOSE 9000

USER sonarqube
STOPSIGNAL SIGINT

ENTRYPOINT ["/opt/sonarqube/docker/entrypoint.sh"]

ENV SONAR_WEB_JAVAADDITIONALOPTS="-javaagent:${SQ_EXTENSIONS_DIR}/plugins/sonarqube-community-branch-plugin-${PLUGIN_VERSION}.jar=web -javaagent:${SQ_EXTENSIONS_DIR}/plugins/sonar-report-plugin-${REPORT_PLUGIN_VERSION}.jar=web -javaagent:${SQ_EXTENSIONS_DIR}/plugins/sonar-ldap-plugin-${LDAP_PLUGIN_VERSION}.jar=web -javaagent:${SQ_EXTENSIONS_DIR}/plugins/sonar-github-plugin-${GITHUB_PLUGIN_VERSION}.jar=web -javaagent:${SQ_EXTENSIONS_DIR}/plugins/sonar-gitlab-plugin-${GITLAB_PLUGIN_VERSION}.jar=web"
ENV SONAR_CE_JAVAADDITIONALOPTS="-javaagent:${SQ_EXTENSIONS_DIR}/plugins/sonarqube-community-branch-plugin-${PLUGIN_VERSION}.jar=ce -javaagent:${SQ_EXTENSIONS_DIR}/plugins/sonar-report-plugin-${REPORT_PLUGIN_VERSION}.jar=ce -javaagent:${SQ_EXTENSIONS_DIR}/plugins/sonar-ldap-plugin-${LDAP_PLUGIN_VERSION}.jar=ce -javaagent:${SQ_EXTENSIONS_DIR}/plugins/sonar-github-plugin-${GITHUB_PLUGIN_VERSION}.jar=ce -javaagent:${SQ_EXTENSIONS_DIR}/plugins/sonar-gitlab-plugin-${GITLAB_PLUGIN_VERSION}.jar=ce"