# CI/CD Pipeline Guide

This repository implements a comprehensive DevOps pipeline with security-first approach.

## Overview

Our CI/CD pipeline consists of three main workflows:

### 1. **CI Pipeline** (`ci.yml`)
Runs on every push and pull request.

#### Stages:
1. **Code Quality & Security**
   - Dockerfile linting (Hadolint)
   - Shell script checking (ShellCheck)
   - Secret scanning (Gitleaks)
   - YAML linting

2. **Security Analysis**
   - CodeQL static analysis
   - Trivy repository scanning
   - SARIF report upload to GitHub Security

3. **SonarCloud Analysis**
   - Code quality metrics
   - Security hotspot detection
   - Technical debt tracking

4. **Docker Build & Push**
   - Multi-platform builds (amd64/arm64)
   - SHA-based versioning
   - SBOM generation
   - Container signing with Cosign

5. **Container Security Scan**
   - Trivy vulnerability scanning
   - Docker Scout analysis
   - Security report generation

### 2. **Release Pipeline** (`release.yml`)
Triggered by version tags (v*.*.*)

#### Features:
- Automated changelog generation
- GitHub release creation
- Semantic versioning support
- Container attestation
- Helm chart publishing (when enabled)

### 3. **Security Scanning** (`security.yml`)
Daily automated security checks

#### Components:
- OWASP Dependency Check
- Container vulnerability scanning (Grype, Trivy, Snyk)
- Automated issue creation for vulnerabilities
- Dependency update PRs

### 4. **Code Quality Analysis** (`sonarqube-analysis.yml`)
SonarCloud integration for code quality

## Required Secrets

Configure these in GitHub repository settings:

```bash
# Docker Hub
DOCKER_USERNAME
DOCKER_PASSWORD

# SonarCloud
SONAR_TOKEN

# Security Scanning (optional)
SNYK_TOKEN
GITLEAKS_LICENSE
```

## Workflow Triggers

| Workflow | Triggers | Purpose |
|----------|----------|---------|
| CI | Push to main/develop, PRs | Build, test, scan |
| Release | Tags (v*.*.*) | Production releases |
| Security | Daily 2 AM UTC | Vulnerability monitoring |
| SonarQube | Push, PRs | Code quality |

## Version Tagging

Images are tagged with:
- `sha-{short-sha}` - Immutable reference
- `{branch-name}` - Latest from branch
- `YYYYMMDD-{sha}` - Date-based
- `latest` - Only from main branch
- `v{semver}` - Release versions

## Security Features

### 1. Supply Chain Security
- SBOM generation for all images
- Container signing with Cosign
- Provenance attestation

### 2. Vulnerability Scanning
- Repository scanning
- Container scanning
- Dependency scanning
- Secret detection

### 3. Compliance
- OWASP Top 10 coverage
- CWE Top 25 analysis
- Security hotspot tracking

## PR Workflow

1. Create feature branch
2. Push changes
3. CI pipeline runs automatically
4. Reviews:
   - SonarCloud quality gate
   - Security scan results
   - Docker build status
5. Merge when all checks pass

## Making a Release

```bash
# Tag the release
git tag v1.0.0
git push origin v1.0.0

# Release pipeline will:
# 1. Create GitHub release
# 2. Build and sign images
# 3. Generate changelog
# 4. Publish to registries
```

## Monitoring

### GitHub Security Tab
- CodeQL alerts
- Dependabot alerts
- Secret scanning alerts

### SonarCloud Dashboard
- Code coverage
- Technical debt
- Security hotspots

### Container Registry
- Vulnerability reports
- SBOM artifacts
- Signatures

## Best Practices

1. **Never skip security scans**
2. **Always use SHA tags in production**
3. **Review Dependabot PRs promptly**
4. **Keep secrets rotated regularly**
5. **Monitor security alerts**

## Troubleshooting

### Build Failures
```bash
# Check workflow logs
gh run list --workflow=ci.yml
gh run view <run-id>
```

### Security Issues
1. Check Security tab in GitHub
2. Review SonarCloud dashboard
3. Check workflow artifacts

### Version Conflicts
Always use SHA-based tags to avoid conflicts:
```yaml
image: osvalois/sonarqube-container:sha-abc123
```

## Cost Optimization

- Workflows use caching extensively
- Multi-platform builds only on releases
- Security scans are batched
- Old images are automatically cleaned up

## Future Enhancements

- [ ] Add performance testing
- [ ] Implement blue-green deployments
- [ ] Add chaos engineering tests
- [ ] Integrate with ArgoCD for GitOps