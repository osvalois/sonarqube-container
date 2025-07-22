# Use SonarQube Community Build - Version 25.5.0.107428
# Enhanced with AI Code Assurance, Advanced Security, and modern DevSecOps features
# Optimized for both local development and Railway deployment
FROM sonarqube:25.5.0.107428-community

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
LABEL org.opencontainers.image.title="SonarQube DevSecOps 25.5"
LABEL org.opencontainers.image.description="SonarQube Community Build 25.5.0.107428 with AI-powered code analysis and advanced security features"
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

# Create configuration file in a writable location
RUN { \
        echo "# Enhanced Security and Compliance Settings for SonarQube 2025 Latest"; \
        echo "sonar.pdf.report.enabled=true"; \
        echo "sonar.security.hotspots.inheritFromParent=true"; \
        echo "sonar.qualitygate.wait=true"; \
        echo "# Performance tuning optimized for Railway and containers"; \
        echo "sonar.web.javaOpts=-Xmx2g -Xms1g -XX:+UseG1GC -XX:MaxGCPauseMillis=200"; \
        echo "sonar.ce.javaOpts=-Xmx2g -Xms512m -XX:+UseG1GC"; \
        echo "sonar.search.javaOpts=-Xmx1g -Xms1g -XX:+UseG1GC"; \
        echo "# Railway compatibility"; \
        echo "sonar.web.host=0.0.0.0"; \
        echo "sonar.web.port=\${PORT:-8080}"; \
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
        echo "# Railway-specific settings"; \
        echo "sonar.web.gracefulStopTimeoutInMs=60000"; \
        echo "sonar.process.gracefulStopTimeout=60"; \
        echo "sonar.cluster.enabled=false"; \
        echo "sonar.search.initialStateTimeout=120"; \
    } > /usr/local/bin/sonar-config.properties;

# Download and install SonarQube plugins for enhanced functionality
RUN set -eux; \
    # Create plugins directory if it doesn't exist
    mkdir -p "${SONARQUBE_HOME}/extensions/plugins"; \
    # Install CNES Report Plugin (latest version supporting SonarQube 10.x)
    wget --no-check-certificate --progress=bar:force:noscroll \
        -O "${SONARQUBE_HOME}/extensions/plugins/sonar-cnes-report-plugin.jar" \
        "https://github.com/cnescatlab/sonar-cnes-report/releases/download/5.0.2/sonar-cnes-report-5.0.2.jar"; \
    # Install Community Branch Plugin for branch/PR analysis (supports SonarQube 10.x)
    wget --no-check-certificate --progress=bar:force:noscroll \
        -O "${SONARQUBE_HOME}/extensions/plugins/sonar-community-branch-plugin.jar" \
        "https://github.com/mc1arke/sonarqube-community-branch-plugin/releases/download/1.19.0/sonarqube-community-branch-plugin-1.19.0.jar"; \
    # Install Rust Plugin for Rust language support
    wget --no-check-certificate --progress=bar:force:noscroll \
        -O "${SONARQUBE_HOME}/extensions/plugins/community-rust-plugin.jar" \
        "https://github.com/C4tWithShell/community-rust/releases/download/v0.2.6/community-rust-plugin-0.2.6.jar"; \
    # Install Flutter/Dart Plugin
    wget --no-check-certificate --progress=bar:force:noscroll \
        -O "${SONARQUBE_HOME}/extensions/plugins/sonar-flutter-plugin.jar" \
        "https://github.com/insideapp-oss/sonar-flutter/releases/download/0.5.2/sonar-flutter-plugin-0.5.2.jar"; \
    # Install GitLab Plugin for better GitLab integration
    wget --no-check-certificate --progress=bar:force:noscroll \
        -O "${SONARQUBE_HOME}/extensions/plugins/sonar-gitlab-plugin.jar" \
        "https://github.com/gabrie-allaigre/sonar-gitlab-plugin/releases/download/4.1.0-SNAPSHOT/sonar-gitlab-plugin-4.1.0-SNAPSHOT.jar"; \
    # Install YAML Plugin for YAML file analysis
    wget --no-check-certificate --progress=bar:force:noscroll \
        -O "${SONARQUBE_HOME}/extensions/plugins/sonar-yaml-plugin.jar" \
        "https://github.com/sbaudoin/sonar-yaml/releases/download/v1.9.1/sonar-yaml-plugin-1.9.1.jar"; \
    # Install ShellCheck Plugin for shell script analysis
    wget --no-check-certificate --progress=bar:force:noscroll \
        -O "${SONARQUBE_HOME}/extensions/plugins/sonar-shellcheck-plugin.jar" \
        "https://github.com/sbaudoin/sonar-shellcheck/releases/download/v2.5.0/sonar-shellcheck-plugin-2.5.0.jar"; \
    # Verify downloads
    ls -la "${SONARQUBE_HOME}/extensions/plugins/"; \
    # Check each plugin exists and is not empty
    for plugin in sonar-cnes-report-plugin.jar sonar-community-branch-plugin.jar community-rust-plugin.jar \
                  sonar-flutter-plugin.jar sonar-gitlab-plugin.jar sonar-yaml-plugin.jar sonar-shellcheck-plugin.jar; do \
        if [ ! -s "${SONARQUBE_HOME}/extensions/plugins/${plugin}" ]; then \
            echo "ERROR: Plugin ${plugin} download failed or is empty"; \
            exit 1; \
        fi; \
    done; \
    # Set proper permissions
    chown -R 1000:0 "${SONARQUBE_HOME}/extensions/plugins"; \
    chmod -R 755 "${SONARQUBE_HOME}/extensions/plugins"; \
    chmod 644 "${SONARQUBE_HOME}/extensions/plugins/"*.jar;

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
        printf "    curl -fs http://localhost:\${PORT:-8080}/api/system/status || exit 1\n"; \
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
        printf "echo \"Starting SonarQube 25.5 with: \$SONAR_APP_JAR\"\n"; \
        printf "echo \"Container optimized for 25.5 with Railway support\"\n"; \
        printf "echo \"Port: \${PORT:-8080}\"\n"; \
        printf "echo \"Database: \${SONAR_JDBC_URL:-Not configured}\"\n"; \
        printf "\n"; \
        printf "# Execute with Railway-compatible options\n"; \
        printf "exec java \\\\\n"; \
        printf "    -Djava.security.egd=file:/dev/./urandom \\\\\n"; \
        printf "    -Dfile.encoding=UTF-8 \\\\\n"; \
        printf "    -Dsonar.web.port=\${PORT:-8080} \\\\\n"; \
        printf "    \${SONAR_WEB_JAVAADDITIONALOPTS} \\\\\n"; \
        printf "    \${SONAR_CE_JAVAADDITIONALOPTS} \\\\\n"; \
        printf "    -jar \"\$SONAR_APP_JAR\" \\\\\n"; \
        printf "    \"\$@\"\n"; \
    } > /usr/local/bin/docker-entrypoint.sh && \
    chmod +x /usr/local/bin/docker-entrypoint.sh

# Add health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=300s --retries=3 \
    CMD curl -fs http://localhost:${PORT:-8080}/api/system/status || exit 1

# Copy Railway-specific startup script and make it executable (as root)
COPY start-railway.sh /usr/local/bin/start-railway.sh
RUN chmod +x /usr/local/bin/start-railway.sh

# Switch back to sonarqube user for security
USER sonarqube

# Environment variables optimized for Railway and containers
ENV SONAR_WEB_JAVAADDITIONALOPTS="-XX:+UseContainerSupport -XX:InitialRAMPercentage=50.0 -XX:MaxRAMPercentage=80.0"
ENV SONAR_CE_JAVAADDITIONALOPTS="-XX:+UseContainerSupport -XX:InitialRAMPercentage=50.0 -XX:MaxRAMPercentage=80.0"
ENV SONAR_SEARCH_JAVAADDITIONALOPTS="-Xmx1g -Xms512m -XX:MaxDirectMemorySize=256m -Des.enforce.bootstrap.checks=false"
ENV JAVA_OPTS="-XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+UseContainerSupport"

# Railway compatibility flags
ENV RUN_AS_ROOT=true
ENV SONAR_TELEMETRY_ENABLE=false
ENV SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true

# Additional Elasticsearch configuration
ENV ES_JAVA_OPTS="-Xms512m -Xmx512m"
ENV discovery.type=single-node

# Expose default port
EXPOSE 8080

# Use the optimized entrypoint - Railway will override with start-railway.sh if needed
ENTRYPOINT ["/usr/local/bin/start-railway.sh"]