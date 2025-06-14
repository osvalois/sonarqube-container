# Deployment Guide

This guide covers different deployment scenarios for the SonarQube container with DevSecOps enhancements.

## Local Development

Use the main `Dockerfile` for local development:

```bash
# Build and run locally
docker-compose up -d --build

# Or using the Makefile
make build
make run
```

## Railway Deployment

For Railway deployment, use the specialized `Dockerfile.railway`:

```bash
# Deploy to Railway
railway up
```

### Railway Configuration

Set the following environment variables in Railway:

```bash
RUN_AS_ROOT=false
SONAR_JDBC_URL=<your-database-url>
SONAR_JDBC_USERNAME=<username>
SONAR_JDBC_PASSWORD=<password>
```

## Production Deployment

### Security Considerations

1. **User Permissions**: The container runs as the `sonarqube` user by default
2. **Database Security**: Use strong credentials and SSL connections
3. **Network Security**: Configure proper firewall rules
4. **Plugin Verification**: All plugins are verified during download

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `RUN_AS_ROOT` | `false` | Allow running as root (Railway only) |
| `SONAR_JDBC_URL` | - | Database connection URL |
| `SONAR_JDBC_USERNAME` | - | Database username |
| `SONAR_JDBC_PASSWORD` | - | Database password |

## Plugin Compatibility

The following plugins are pre-installed and compatible with SonarQube 10.6:

- **sonar-cnes-report**: v5.0.2 - PDF reporting
- **sonarqube-community-branch-plugin**: v1.19.0 - Branch analysis
- **sonar-gitlab-plugin**: v4.1.0-SNAPSHOT - GitLab integration
- **sonar-cxx-plugin**: v2.2.1 - C/C++ analysis
- **sonar-dependency-check-plugin**: v5.0.0 - Security scanning
- **sonar-flutter-plugin**: v0.5.0 - Flutter/Dart analysis
- **sonar-rust-plugin**: v0.2.1 - Rust analysis

## Troubleshooting

### Plugin Download Failures

If plugins fail to download during build:

```bash
# Rebuild with verbose output
docker build --no-cache --progress=plain .
```

### Permission Issues

For Railway deployment with permission errors:

```bash
# Set Railway-specific environment
export RUN_AS_ROOT=true
```

### Memory Issues

Adjust memory settings in the Dockerfile or environment:

```bash
export SONARQUBE_WEB_JAVAOPTS="-Xmx1g -Xms256m"
export SONARQUBE_CE_JAVAOPTS="-Xmx1g -Xms256m"
```

## Health Checks

Monitor your SonarQube instance:

```bash
# Check if SonarQube is running
curl -f http://localhost:9000/api/system/health

# View container logs
docker-compose logs sonarqube
```