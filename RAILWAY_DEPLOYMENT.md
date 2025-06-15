# Railway Deployment Guide for SonarQube 2025

## Why SonarQube Fails on Railway

The main issues are:

1. **Root User Requirement**: Railway runs containers as root, but SonarQube expects to run as a non-root user
2. **Port Configuration**: Railway assigns a dynamic PORT environment variable
3. **Elasticsearch Bootstrap Checks**: These fail in Railway's environment
4. **Memory Constraints**: Railway has memory limits that need optimization

## Solution

Use the specialized `Dockerfile.railway` which:
- Allows running as root with `RUN_AS_ROOT=true`
- Uses Railway's dynamic PORT variable
- Disables Elasticsearch bootstrap checks
- Optimizes memory settings for Railway

## Deployment Steps

1. **Set Environment Variables in Railway**:
   ```
   SONAR_JDBC_URL=jdbc:postgresql://ep-floral-bush-a5ns5s26-pooler.us-east-2.aws.neon.tech/shsonar?user=shsonar_owner&password=npg_3oPHcnhxz7er&sslmode=require
   SONAR_JDBC_USERNAME=shsonar_owner
   SONAR_JDBC_PASSWORD=npg_3oPHcnhxz7er
   SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true
   RUN_AS_ROOT=true
   ```

2. **Configure Railway Service**:
   - Set health check path to `/api/system/status`
   - Set health check timeout to 300 seconds
   - Enable restart on failure

3. **Memory Settings** (optional):
   ```
   JAVA_OPTS=-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0
   ```

## Important Notes

- SonarQube takes 2-5 minutes to start completely
- The health check will fail initially - this is normal
- Check logs for "SonarQube is operational" message
- Railway will automatically use the `Dockerfile.railway` if present

## Troubleshooting

If deployment fails:

1. Check that all environment variables are set
2. Ensure database is accessible from Railway
3. Monitor logs during startup
4. Verify Railway has sufficient memory allocated