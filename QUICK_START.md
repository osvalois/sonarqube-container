# Quick Start Guide

## ✅ Status: Ready to Use

Your SonarQube DevSecOps container is now compiled and running locally.

## Access Information

- **SonarQube Web Interface**: http://localhost:9000
- **Default Credentials**: admin / admin
- **Status**: ✅ UP (Version 9.9.8 LTS Community)
- **Database**: PostgreSQL 15 (configured automatically)

## Services Running

```bash
# Check services status
docker-compose ps

# Check SonarQube logs
docker-compose logs sonarqube

# Check database logs
docker-compose logs db
```

## Next Steps

1. **Access the Web Interface**:
   ```bash
   open http://localhost:9000
   ```

2. **Login with Default Credentials**:
   - Username: `admin`
   - Password: `admin`
   - You'll be prompted to change the password on first login

3. **Create Your First Project**:
   - Click "Create Project" → "Manually"
   - Enter project key and name
   - Generate a token for analysis

4. **Install SonarQube Scanner**:
   ```bash
   # macOS
   brew install sonar-scanner
   
   # Or download from: https://docs.sonarsource.com/sonarqube/latest/analyzing-source-code/scanners/sonarscanner/
   ```

5. **Analyze a Project**:
   ```bash
   cd your-project-directory
   sonar-scanner \
     -Dsonar.projectKey=your-project \
     -Dsonar.sources=. \
     -Dsonar.host.url=http://localhost:9000 \
     -Dsonar.login=your-token
   ```

## Container Features

- ✅ **Security Optimized**: Runs as non-root user
- ✅ **Dynamic JAR Detection**: Automatically finds SonarQube version
- ✅ **Performance Tuned**: Optimized memory settings
- ✅ **Plugin Ready**: Directory prepared for additional plugins
- ✅ **DevSecOps Ready**: Enhanced security configurations

## Available Commands

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f sonarqube

# Restart SonarQube only
docker-compose restart sonarqube

# Check SonarQube status
curl http://localhost:9000/api/system/status
```

## Adding Plugins

To add plugins later, you can:

1. Download plugin JARs to `/opt/sonarqube/extensions/plugins/` inside the container
2. Restart the SonarQube service
3. Or rebuild the image with plugins included in the Dockerfile

## Troubleshooting

### Elasticsearch Bootstrap Check Failed (vm.max_map_count)
If you see this error: `max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]`

This error occurs because Elasticsearch (used by SonarQube) requires a minimum number of memory-mapped areas to function properly.

#### 1. Temporary Fix (until host restart)

```bash
# For Linux:
sudo sysctl -w vm.max_map_count=262144

# For macOS (Docker Desktop):
docker run --rm --privileged alpine sysctl -w vm.max_map_count=262144

# For Windows (WSL-based Docker Desktop):
wsl -d docker-desktop -e sysctl -w vm.max_map_count=262144
```

#### 2. Permanent Fix

```bash
# For Linux - edit sysctl.conf:
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# For Windows (WSL-based Docker Desktop):
wsl -d docker-desktop -e sh -c "echo 'vm.max_map_count=262144' >> /etc/sysctl.conf"
```

#### 3. Restart SonarQube

```bash
docker-compose down && docker-compose up -d
```

⚠️ **Important Notes**:
- You must set this on the **host system**, not inside the container
- For multi-node environments, set this on **every host**
- Avoid using `-Dsonar.es.bootstrap.checks.disable=true` as it's not recommended for production

See [DOCKER_HOST_REQUIREMENTS.md](DOCKER_HOST_REQUIREMENTS.md) for complete instructions.

### Port Already in Use
```bash
# Check what's using port 9000
lsof -i :9000

# Stop the service using the port or change SonarQube port in docker-compose.yml
```

### Memory Issues
```bash
# Check container memory usage
docker stats sonarqube-container-sonarqube-1

# Adjust memory settings in Dockerfile if needed
```

### Database Connection Issues
```bash
# Check database logs
docker-compose logs db

# Verify database is running
docker-compose ps db
```

## Production Deployment

For production use:
- Change default admin password
- Configure external database
- Set up reverse proxy (nginx/apache)
- Configure SSL/TLS
- Set up backup strategy
- Use the Railway Dockerfile for cloud deployment

---

**Your SonarQube DevSecOps environment is ready for code analysis!** 🎉