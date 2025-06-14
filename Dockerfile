# Use official SonarQube LTS Community Edition as base
FROM sonarqube:lts-community

# Build arguments for metadata
ARG BUILD_DATE
ARG BUILD_VERSION
ARG VCS_REF

# Switch to root for installation
USER root

# Metadata following OCI Image Specification
LABEL org.opencontainers.image.created="${BUILD_DATE}"
LABEL org.opencontainers.image.url="https://github.com/osvalois/sonarqube-container"
LABEL org.opencontainers.image.source="https://github.com/osvalois/sonarqube-container"
LABEL org.opencontainers.image.version="${BUILD_VERSION}"
LABEL org.opencontainers.image.revision="${VCS_REF}"
LABEL org.opencontainers.image.vendor="Oscar Valois"
LABEL org.opencontainers.image.title="SonarQube DevSecOps"
LABEL org.opencontainers.image.description="SonarQube LTS Community Edition with enhanced plugins for DevSecOps"
LABEL org.opencontainers.image.licenses="MIT"
LABEL maintainer="Oscar Valois <osvaloismtz@gmail.com>"

# Install dependencies and create plugin directory
RUN set -eux; \
    apt-get update && apt-get install -y --no-install-recommends curl=7.* && rm -rf /var/lib/apt/lists/*; \
    mkdir -p "${SONARQUBE_HOME}/extensions/plugins"; \
    chown -R sonarqube:sonarqube "${SONARQUBE_HOME}/extensions/plugins";

# Add custom configuration
RUN { \
        echo "# Enhanced Security and Compliance Settings"; \
        echo "sonar.pdf.report.enabled=true"; \
        echo "sonar.security.hotspots.inheritFromParent=true"; \
        echo "sonar.qualitygate.wait=true"; \
        echo "# Performance tuning"; \
        echo "sonar.web.javaOpts=-Xmx512m -Xms128m"; \
        echo "sonar.ce.javaOpts=-Xmx512m -Xms128m"; \
        echo "sonar.search.javaOpts=-Xmx512m -Xms512m"; \
    } >> "${SONARQUBE_HOME}/conf/sonar.properties";

# Create custom entrypoint script for dynamic JAR detection
RUN { \
        printf "#!/bin/bash\n"; \
        printf "set -e\n"; \
        printf "\n"; \
        printf "# If running as root, switch to sonarqube user (except for Railway)\n"; \
        printf "if [ \"\$(id -u)\" = \"0\" ] && [ \"\$RUN_AS_ROOT\" != \"true\" ]; then\n"; \
        printf "    echo \"Switching to sonarqube user...\"\n"; \
        printf "    exec su-exec sonarqube \"\$0\" \"\$@\"\n"; \
        printf "fi\n"; \
        printf "\n"; \
        printf "# Find the sonar-application JAR dynamically\n"; \
        printf "SONAR_APP_JAR=\$(find /opt/sonarqube/lib -name \"sonar-application-*.jar\" -type f | head -1)\n"; \
        printf "\n"; \
        printf "if [ -z \"\$SONAR_APP_JAR\" ]; then\n"; \
        printf "    echo \"ERROR: Could not find sonar-application JAR file\"\n"; \
        printf "    exit 1\n"; \
        printf "fi\n"; \
        printf "\n"; \
        printf "echo \"Starting SonarQube with: \$SONAR_APP_JAR\"\n"; \
        printf "\n"; \
        printf "# Execute with proper Java options\n"; \
        printf "exec java \\\\\n"; \
        printf "    \${SONAR_WEB_JAVAADDITIONALOPTS} \\\\\n"; \
        printf "    \${SONAR_CE_JAVAADDITIONALOPTS} \\\\\n"; \
        printf "    -jar \"\$SONAR_APP_JAR\" \\\\\n"; \
        printf "    \"\$@\"\n"; \
    } > /usr/local/bin/docker-entrypoint.sh && \
    chmod +x /usr/local/bin/docker-entrypoint.sh

# Switch back to sonarqube user for security
USER sonarqube

# Environment variables for plugins (can be configured at runtime)
ENV SONAR_WEB_JAVAADDITIONALOPTS=""
ENV SONAR_CE_JAVAADDITIONALOPTS=""

# Allow running as root only when explicitly set (for Railway compatibility)
ENV RUN_AS_ROOT=false

# Use the dynamic entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]