# Docker Host Requirements for SonarQube

This document outlines the necessary system requirements and configurations for running SonarQube in Docker.

## System Requirements

### Memory and CPU
- At least 4GB of RAM for the container
- At least 2 CPU cores recommended

### Disk Space
- At least 5GB of free disk space

## Essential Host Configurations

### Virtual Memory Settings

Elasticsearch (used by SonarQube) requires specific kernel settings. Before running the container, execute this command on the host:

```bash
# Increase the vm.max_map_count kernel setting
sudo sysctl -w vm.max_map_count=262144

# To make this setting permanent, add it to /etc/sysctl.conf
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
```

#### For Docker Desktop on Mac/Windows:
These settings need to be applied to the VM that runs the Docker engine.

**Docker Desktop for Mac:**
```bash
# Connect to the Docker Desktop VM
docker run --rm -it --privileged --pid=host alpine:latest nsenter -t 1 -m -u -n -i sh

# Inside the VM, increase the setting
sysctl -w vm.max_map_count=262144
```

**Docker Desktop for Windows:**
```powershell
# Connect to WSL
wsl -d docker-desktop

# Inside WSL, increase the setting
sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" >> /etc/sysctl.conf
```

### File Descriptors

SonarQube requires a high number of file descriptors. The container sets appropriate `ulimits`, but ensure your host allows these settings:

```bash
# Check current limits
ulimit -n

# If needed, increase the limits on the host
sudo nano /etc/security/limits.conf
# Add these lines:
# *               soft    nofile          65536
# *               hard    nofile          65536
```

## Troubleshooting

If you encounter the following error when starting SonarQube:

```
ERROR: [1] bootstrap checks failed. You must address the points described in the following [1] lines before starting Elasticsearch.
bootstrap check failure [1] of [1]: max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]
```

This indicates that you need to increase the `vm.max_map_count` setting as described above.

If you continue to have issues after applying these settings, you can try adding `SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true` to your environment variables, but this is not recommended for production use.