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

Elasticsearch (used by SonarQube) requires specific kernel settings. The error message you might see is:

```
bootstrap check failure [1] of [1]: max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]
```

This happens because Elasticsearch requires a minimum number of memory-mapped areas (`vm.max_map_count`) to function properly. If your system's current value (typically 65530) is below the required threshold (262144), Elasticsearch will refuse to start, causing SonarQube to fail during startup.

#### 1. Temporary Adjustment (effective until restart)

On the host server, run with root permissions:

```bash
sudo sysctl -w vm.max_map_count=262144
```

Then restart or recreate the SonarQube container. This configuration applies immediately.

#### 2. Permanent Adjustment

To make the change persist after a reboot:

1. Edit `/etc/sysctl.conf` (or a file within `/etc/sysctl.d/`).
2. Add or adjust the line:
   ```
   vm.max_map_count = 262144
   ```
3. Apply the changes with:
   ```bash
   sudo sysctl -p
   ```
4. Then restart or recreate the container.

#### 3. For Docker Desktop on Mac/Windows:

These settings need to be applied to the VM that runs the Docker engine.

**Docker Desktop for Mac:**
```bash
# Connect to the Docker Desktop VM
docker run --rm -it --privileged --pid=host alpine:latest nsenter -t 1 -m -u -n -i sh

# Inside the VM, increase the setting
sysctl -w vm.max_map_count=262144
```

Alternatively, a simpler approach:
```bash
docker run --rm --privileged alpine sysctl -w vm.max_map_count=262144
```

**Docker Desktop for Windows:**
```powershell
# Connect to WSL
wsl -d docker-desktop

# Inside WSL, increase the setting
sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" >> /etc/sysctl.conf
```

#### 4. For Multi-Node Environments (Docker Swarm/Kubernetes)

You must change `vm.max_map_count` on **each host node** running affected containers. In Kubernetes, an init container with privileged access is often used:

```yaml
initContainers:
- name: init-sysctl
  image: busybox
  securityContext:
    privileged: true
  command: ["sh", "-c", "sysctl -w vm.max_map_count=262144"]
```

With `runAsUser: 0` to ensure it has permissions.

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

## Important Notes

* **Don't try to change this inside an unprivileged container**: The kernel will ignore it if not performed as root on the host.
* **Avoid disabling bootstrap checks** (such as `-Dsonar.es.bootstrap.checks.disable=true`): This is not safe or recommended for production environments.

## Recommended Steps

1. On your server (Linux or VM):
   ```bash
   sudo sysctl -w vm.max_map_count=262144
   ```

2. Confirm it:
   ```bash
   sysctl vm.max_map_count
   # Should show: vm.max_map_count = 262144
   ```

3. To make it permanent:
   * Edit `/etc/sysctl.conf`
   * Add: `vm.max_map_count = 262144`
   * Apply changes: `sudo sysctl -p`

4. Restart or recreate the SonarQube container.

If you're in a multi-host environment (like Swarm or Kubernetes), repeat these steps on **each host server**, or use an init container if you can't modify the host directly.

## Summary

| Action                                   | What it does                      |
| ---------------------------------------- | --------------------------------- |
| `sudo sysctl -w vm.max_map_count=262144` | Temporarily fixes the issue       |
| Edit `/etc/sysctl.conf`                  | Makes the change permanent        |
| Restart the container                    | Applies the configuration         |
| Do it on all hosts                       | Important in clusters             |

With these adjustments, SonarQube/Elasticsearch should start correctly.