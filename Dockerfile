# Use official SonarQube Community Edition as base
FROM sonarqube:10.6-community

# Switch to root for installation
USER root

# Metadata
LABEL org.opencontainers.image.url="https://github.com/osvalois/sonarqube-container"
LABEL org.opencontainers.image.description="SonarQube LTS Community Edition with enhanced plugins for DevSecOps"
LABEL maintainer="Oscar Valois osvaloismtz@gmail.com"
LABEL version="2025.1-lts"

# Download and install plugins
ARG CNES_REPORT_URL=https://github.com/cnescatlab/sonar-cnes-report/releases/download/5.0.2/sonar-cnes-report-5.0.2.jar
ARG COMMUNITY_BRANCH_URL=https://github.com/mc1arke/sonarqube-community-branch-plugin/releases/download/1.21.0/sonarqube-community-branch-plugin-1.21.0.jar
ARG GITLAB_PLUGIN_URL=https://github.com/gabrie-allaigre/sonar-gitlab-plugin/releases/download/4.1.0-SNAPSHOT/sonar-gitlab-plugin-4.1.0-SNAPSHOT.jar
ARG SONARCXX_URL=https://github.com/SonarOpenCommunity/sonar-cxx/releases/download/cxx-2.2.1/sonar-cxx-plugin-2.2.1.jar
ARG DEPENDENCY_CHECK_URL=https://github.com/dependency-check/dependency-check-sonar-plugin/releases/download/5.0.0/sonar-dependency-check-plugin-5.0.0.jar
ARG SONAR_FLUTTER_URL=https://github.com/insideapp-oss/sonar-flutter/releases/download/0.5.0/sonar-flutter-plugin-0.5.0.jar
ARG COMMUNITY_RUST_URL=https://github.com/C4tWithShell/community-rust/releases/download/0.2.1/sonar-rust-plugin-0.2.1.jar

RUN set -eux; \
    apt-get update; \
    apt-get install -y curl; \
    mkdir -p ${SONARQUBE_HOME}/extensions/plugins; \
    echo "Downloading plugins..."; \
    curl --fail --location --output ${SONARQUBE_HOME}/extensions/plugins/sonar-cnes-report-5.0.2.jar "${CNES_REPORT_URL}" || echo "Failed to download CNES Report plugin"; \
    curl --fail --location --output ${SONARQUBE_HOME}/extensions/plugins/sonarqube-community-branch-plugin-1.21.0.jar "${COMMUNITY_BRANCH_URL}" || echo "Failed to download Community Branch plugin"; \
    curl --fail --location --output ${SONARQUBE_HOME}/extensions/plugins/sonar-gitlab-plugin-4.1.0-SNAPSHOT.jar "${GITLAB_PLUGIN_URL}" || echo "Failed to download GitLab plugin"; \
    curl --fail --location --output ${SONARQUBE_HOME}/extensions/plugins/sonar-cxx-plugin-2.2.1.jar "${SONARCXX_URL}" || echo "Failed to download SonarCXX plugin"; \
    curl --fail --location --output ${SONARQUBE_HOME}/extensions/plugins/sonar-dependency-check-plugin-5.0.0.jar "${DEPENDENCY_CHECK_URL}" || echo "Failed to download Dependency Check plugin"; \
    curl --fail --location --output ${SONARQUBE_HOME}/extensions/plugins/sonar-flutter-plugin-0.5.0.jar "${SONAR_FLUTTER_URL}" || echo "Failed to download Flutter plugin"; \
    curl --fail --location --output ${SONARQUBE_HOME}/extensions/plugins/sonar-rust-plugin-0.2.1.jar "${COMMUNITY_RUST_URL}" || echo "Failed to download Rust plugin"; \
    chown -R sonarqube:sonarqube ${SONARQUBE_HOME}/extensions/plugins; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*;

# Add custom configuration
RUN echo "# Enhanced Security and Compliance Settings" >> ${SONARQUBE_HOME}/conf/sonar.properties; \
    echo "sonar.pdf.report.enabled=true" >> ${SONARQUBE_HOME}/conf/sonar.properties; \
    echo "sonar.security.hotspots.inheritFromParent=true" >> ${SONARQUBE_HOME}/conf/sonar.properties; \
    echo "sonar.qualitygate.wait=true" >> ${SONARQUBE_HOME}/conf/sonar.properties;

# Copy custom entrypoint if needed
COPY entrypoint.sh /opt/sonarqube/docker/entrypoint-custom.sh
RUN chmod +x /opt/sonarqube/docker/entrypoint-custom.sh

# Switch back to sonarqube user
USER sonarqube

# Configure Community Branch Plugin (compatible version)
ENV SONAR_WEB_JAVAADDITIONALOPTS="-javaagent:${SONARQUBE_HOME}/extensions/plugins/sonarqube-community-branch-plugin-1.21.0.jar=web"
ENV SONAR_CE_JAVAADDITIONALOPTS="-javaagent:${SONARQUBE_HOME}/extensions/plugins/sonarqube-community-branch-plugin-1.21.0.jar=ce"
