# Use SonarQube Community Edition - Latest stable version
# Enhanced with AI Code Assurance, Advanced Security, and modern DevSecOps features
# Optimized for both local development and Railway deployment
FROM sonarqube:community

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
LABEL org.opencontainers.image.title="SonarQube DevSecOps 2025"
LABEL org.opencontainers.image.description="SonarQube 2025 Latest with AI-powered code analysis and advanced security features"
LABEL org.opencontainers.image.licenses="MIT"
LABEL maintainer="Oscar Valois <osvaloismtz@gmail.com>"

# Install dependencies with security updates and create plugin directory
RUN set -eux; \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        gnupg \
        lsb-release \
        wget \
        unzip && \
    rm -rf /var/lib/apt/lists/*; \
    mkdir -p "${SONARQUBE_HOME}/extensions/plugins" \
             "${SONARQUBE_HOME}/reports"; \
    chown -R 1000:0 "${SONARQUBE_HOME}/extensions/plugins" \
                    "${SONARQUBE_HOME}/reports";

# Add custom configuration for SonarQube 2025 (Railway-compatible)
RUN { \
        echo "# Enhanced Security and Compliance Settings for SonarQube 2025 Latest"; \
        echo "sonar.pdf.report.enabled=true"; \
        echo "sonar.security.hotspots.inheritFromParent=true"; \
        echo "sonar.qualitygate.wait=true"; \
        echo "# Performance tuning optimized for Railway and containers"; \
        echo "sonar.web.javaOpts=-Xmx1024m -Xms512m -XX:+UseG1GC -XX:MaxGCPauseMillis=200"; \
        echo "sonar.ce.javaOpts=-Xmx768m -Xms256m -XX:+UseG1GC"; \
        echo "sonar.search.javaOpts=-Xmx1024m -Xms1024m -XX:+UseG1GC"; \
        echo "# Railway compatibility"; \
        echo "sonar.web.host=0.0.0.0"; \
        echo "sonar.web.port=\${PORT:-9000}"; \
        echo "# Modern SonarQube 2025 features with AI capabilities"; \
        echo "sonar.forceAuthentication=false"; \
        echo "sonar.log.level=INFO"; \
        echo "# Security hardening"; \
        echo "sonar.web.http.minThreads=5"; \
        echo "sonar.web.http.maxThreads=50"; \
        echo "sonar.web.http.acceptCount=25"; \
        echo "# Disable problematic features for Railway"; \
        echo "sonar.telemetry.enable=false"; \
        echo "sonar.updatecenter.activate=false"; \
        echo "# Enable modern security analysis"; \
        echo "sonar.security.config.javasecurity=true"; \
        echo "sonar.security.config.pythonsecurity=true"; \
        echo "sonar.security.config.phpsecurity=true"; \
        echo "# Report generation settings"; \
        echo "sonar.plugins.downloadOnlyRequired=false"; \
        echo "# Plugin configuration"; \
        echo "sonar.web.javaAdditionalOpts=-Duser.timezone=UTC"; \
    } >> "${SONARQUBE_HOME}/conf/sonar.properties";

# Download and install official SonarQube report plugins
RUN set -eux; \
    # Install CNES Report Plugin (latest version supporting SonarQube 10.x)
    wget -O "${SONARQUBE_HOME}/extensions/plugins/sonar-cnes-report-plugin.jar" \
        "https://github.com/cnescatlab/sonar-cnes-report/releases/download/5.0.2/sonar-cnes-report-5.0.2.jar"; \
    # Verify download
    ls -la "${SONARQUBE_HOME}/extensions/plugins/"; \
    # Set proper permissions
    chown -R 1000:0 "${SONARQUBE_HOME}/extensions/plugins";

# Create optimized entrypoint script with health checks and graceful shutdown
RUN { \
        printf "#!/bin/bash\n"; \
        printf "set -euo pipefail\n"; \
        printf "\n"; \
        printf "# Signal handlers for graceful shutdown\n"; \
        printf "trap 'echo \"Received SIGTERM, shutting down gracefully...\"; exit 0' SIGTERM\n"; \
        printf "trap 'echo \"Received SIGINT, shutting down gracefully...\"; exit 0' SIGINT\n"; \
        printf "\n"; \
        printf "# If running as root, switch to sonarqube user (except for Railway)\n"; \
        printf "if [ \"\$(id -u)\" = \"0\" ] && [ \"\$RUN_AS_ROOT\" != \"true\" ]; then\n"; \
        printf "    echo \"Switching to sonarqube user...\"\n"; \
        printf "    exec su-exec sonarqube \"\$0\" \"\$@\"\n"; \
        printf "fi\n"; \
        printf "\n"; \
        printf "# Health check function\n"; \
        printf "health_check() {\n"; \
        printf "    curl -fs http://localhost:9000/api/system/status || exit 1\n"; \
        printf "}\n"; \
        printf "\n"; \
        printf "# Find the sonar-application JAR dynamically\n"; \
        printf "SONAR_APP_JAR=\$(find /opt/sonarqube/lib -name \"sonar-application-*.jar\" -type f | head -1)\n"; \
        printf "\n"; \
        printf "if [ -z \"\$SONAR_APP_JAR\" ]; then\n"; \
        printf "    echo \"ERROR: Could not find sonar-application JAR file\"\n"; \
        printf "    exit 1\n"; \
        printf "fi\n"; \
        printf "\n"; \
        printf "echo \"Starting SonarQube 2025 with: \$SONAR_APP_JAR\"\n"; \
        printf "echo \"Container optimized for 2025 with Railway support\"\n"; \
        printf "echo \"Port: \${PORT:-9000}\"\n"; \
        printf "echo \"Database: \${SONAR_JDBC_URL:-Not configured}\"\n"; \
        printf "\n"; \
        printf "# Execute with Railway-compatible options\n"; \
        printf "exec java \\\\\n"; \
        printf "    -Djava.security.egd=file:/dev/./urandom \\\\\n"; \
        printf "    -Dfile.encoding=UTF-8 \\\\\n"; \
        printf "    -Dsonar.web.port=\${PORT:-9000} \\\\\n"; \
        printf "    \${SONAR_WEB_JAVAADDITIONALOPTS} \\\\\n"; \
        printf "    \${SONAR_CE_JAVAADDITIONALOPTS} \\\\\n"; \
        printf "    -jar \"\$SONAR_APP_JAR\" \\\\\n"; \
        printf "    \"\$@\"\n"; \
    } > /usr/local/bin/docker-entrypoint.sh && \
    chmod +x /usr/local/bin/docker-entrypoint.sh

# Add health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=300s --retries=3 \
    CMD curl -fs http://localhost:9000/api/system/status || exit 1

# Switch back to sonarqube user for security
USER sonarqube

# Environment variables optimized for Railway and containers
ENV SONAR_WEB_JAVAADDITIONALOPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=60.0"
ENV SONAR_CE_JAVAADDITIONALOPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=60.0"
ENV JAVA_OPTS="-XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+UseContainerSupport"

# Railway compatibility flags
ENV RUN_AS_ROOT=true
ENV SONAR_TELEMETRY_ENABLE=false
ENV SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true

# Expose default port
EXPOSE 9000

# Use the optimized entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]