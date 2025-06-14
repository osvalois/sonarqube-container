# Docker Image Versioning Strategy

This document describes the versioning strategy for the SonarQube DevSecOps Docker images.

## Overview

We follow container image best practices by using Git SHA as the primary version identifier, along with multiple tags for different use cases.

## Tag Format

Each build creates multiple tags:

### 1. SHA-based Tags (Primary)
- **Short SHA**: `sha-2fd4e1c` (7 characters)
- **Long SHA**: `sha-2fd4e1c67a2d28fced849ee1bb76e7391b93eb12` (full commit)

**Example**: `osvalois/sonarqube-container:sha-2fd4e1c`

### 2. Branch Tags
- Reflects the current branch name
- Updates with each commit to that branch

**Examples**:
- `osvalois/sonarqube-container:main`
- `osvalois/sonarqube-container:develop`
- `osvalois/sonarqube-container:feature-branch`

### 3. Date-based Tags
- Format: `YYYYMMDD-{sha}`
- Useful for identifying when an image was built

**Example**: `osvalois/sonarqube-container:20240614-2fd4e1c`

### 4. Latest Tag
- Only applied to builds from the `main` branch
- Always points to the most recent main branch build

**Example**: `osvalois/sonarqube-container:latest`

### 5. Semantic Version Tags (when using git tags)
- Created when pushing git tags like `v1.0.0`
- Generates multiple variants:
  - Full version: `1.0.0`
  - Major.Minor: `1.0`
  - Major only: `1`

## Usage Examples

### Pull Specific Version
```bash
# Pull by SHA (immutable, recommended for production)
docker pull osvalois/sonarqube-container:sha-2fd4e1c

# Pull latest from main branch
docker pull osvalois/sonarqube-container:latest

# Pull latest from develop branch
docker pull osvalois/sonarqube-container:develop
```

### In docker-compose.yml
```yaml
services:
  sonarqube:
    # Use SHA for production (immutable)
    image: osvalois/sonarqube-container:sha-2fd4e1c
    
    # Or use branch for development
    image: osvalois/sonarqube-container:develop
```

### In Kubernetes
```yaml
spec:
  containers:
  - name: sonarqube
    # Always use SHA tags in production
    image: osvalois/sonarqube-container:sha-2fd4e1c
    imagePullPolicy: IfNotPresent
```

## Building and Publishing

### Using Make
```bash
# Show version info
make info

# Build locally with all tags
make build

# Publish to Docker Hub
make publish
```

### Using GitHub Actions
The CI/CD pipeline automatically:
1. Builds on every push to main/develop
2. Creates all appropriate tags
3. Pushes to Docker Hub and GitHub Container Registry
4. Generates SBOM (Software Bill of Materials)
5. Runs security scans

## Benefits of SHA-based Versioning

1. **Immutability**: SHA tags never change, ensuring reproducible deployments
2. **Traceability**: Direct link between image and source code commit
3. **Security**: Can verify image corresponds to audited code
4. **Rollback**: Easy to revert to any previous version
5. **Cache-friendly**: SHA tags work well with Docker layer caching

## Migration from Old Versioning

If you were using static version tags like `1.0.5`, migrate as follows:

```bash
# Old way (not recommended)
image: osvalois/sonarqube-container:1.0.5

# New way (recommended)
image: osvalois/sonarqube-container:sha-2fd4e1c
```

## Finding the Right Tag

### From GitHub
1. Go to the commit you want to deploy
2. Copy the short SHA
3. Use: `osvalois/sonarqube-container:sha-{SHORT_SHA}`

### From Docker Hub
1. Visit: https://hub.docker.com/r/osvalois/sonarqube-container/tags
2. Find the tag corresponding to your needs
3. Use the SHA-based tag for production

### From Command Line
```bash
# List all local tags
docker images osvalois/sonarqube-container --format "table {{.Tag}}\t{{.CreatedAt}}"

# Get current SHA
git rev-parse --short HEAD
```

## Best Practices

1. **Production**: Always use SHA tags
   ```yaml
   image: osvalois/sonarqube-container:sha-2fd4e1c
   ```

2. **Staging**: Use branch tags
   ```yaml
   image: osvalois/sonarqube-container:main
   ```

3. **Development**: Use branch or latest
   ```yaml
   image: osvalois/sonarqube-container:develop
   ```

4. **Never use `latest` in production** - it's mutable and can lead to unexpected updates

## Automation

The GitHub Actions workflow automatically handles all tagging. You just need to:

1. Commit your changes
2. Push to GitHub
3. Tags are automatically created and pushed

No manual version management required!