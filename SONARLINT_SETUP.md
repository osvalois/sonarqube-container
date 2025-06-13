# SonarLint Setup Guide for Development Teams

## Overview
SonarLint is a free IDE extension that helps you detect and fix quality issues as you write code. It's like having a spell checker for your code - it squiggles flaws and provides clear remediation guidance so you can fix them before the code is committed.

## Installation Instructions

### Visual Studio Code
1. Open VS Code
2. Go to Extensions (Ctrl+Shift+X or Cmd+Shift+X)
3. Search for "SonarLint"
4. Install the official SonarLint extension by SonarSource
5. Restart VS Code

### IntelliJ IDEA / PyCharm / WebStorm
1. Open your IDE
2. Go to File → Settings (or Preferences on macOS)
3. Navigate to Plugins
4. Search for "SonarLint"
5. Install SonarLint plugin by SonarSource
6. Restart the IDE

### Eclipse
1. Open Eclipse
2. Go to Help → Eclipse Marketplace
3. Search for "SonarLint"
4. Install SonarLint for Eclipse
5. Restart Eclipse

## Configuration

### Connect to SonarQube Server
1. Open SonarLint settings in your IDE
2. Add new SonarQube connection:
   - **URL**: `http://localhost:9000` (or your SonarQube server URL)
   - **Token**: Generate from SonarQube → My Account → Security → Generate Token
3. Test the connection
4. Bind your project to the SonarQube project key: `sonarqube-container`

### Language-Specific Configuration

#### For Docker Projects
- Enable analysis for Dockerfile
- Configure file associations: `*.Dockerfile` → Docker

#### For Shell Scripts
- Enable Bash/Shell analysis
- Include `.sh` files in analysis

#### For YAML/Docker Compose
- Enable YAML analysis
- Configure for Docker Compose files

## Supported Languages (Open Source)
- **Java** (full support)
- **JavaScript/TypeScript** (full support)
- **Python** (full support)
- **PHP** (full support)
- **C/C++** (basic support)
- **HTML/CSS** (full support)
- **XML** (full support)
- **YAML** (basic support)
- **Dockerfile** (basic support)
- **Shell scripts** (basic support)

## Custom Rules Configuration

### Security Rules
Enable security-focused rules by adding to your workspace settings:

```json
{
    "sonarlint.rules": {
        "javascript:S2068": "on",    // Hard-coded credentials
        "javascript:S3330": "on",    // Cookies security
        "python:S2068": "on",        // Hard-coded credentials
        "python:S5445": "on",        // Insecure temporary file
        "dockerfile:S6476": "on",    // Instructions should not contain secrets
        "dockerfile:S6477": "on"     // Version pinning
    }
}
```

### Code Quality Rules
```json
{
    "sonarlint.rules": {
        "javascript:S1186": "on",    // Empty methods
        "javascript:S1854": "on",    // Dead stores
        "python:S1226": "on",        // Unused method parameters
        "python:S1481": "on",        // Unused local variables
        "java:S1186": "on",          // Empty methods
        "java:S1854": "on"           // Dead stores
    }
}
```

## Team Workflow Integration

### Pre-commit Hooks
Create `.pre-commit-config.yaml`:
```yaml
repos:
  - repo: local
    hooks:
      - id: sonarlint-check
        name: SonarLint Analysis
        entry: sonarlint
        language: system
        pass_filenames: false
        always_run: true
```

### Git Integration
1. Configure SonarLint to analyze only modified files
2. Set up automatic analysis on file save
3. Enable problem highlighting in git diff views

## Best Practices

### Development Workflow
1. **Write Code** → SonarLint highlights issues in real-time
2. **Fix Issues** → Address problems before committing
3. **Commit Clean Code** → Only commit code without SonarLint issues
4. **Push to Repository** → Automated SonarQube analysis runs

### Team Standards
- **Zero Tolerance Policy**: No commits with SonarLint violations
- **Security First**: Always fix security vulnerabilities immediately
- **Code Review**: Include SonarLint compliance in review checklist

### Performance Optimization
- Exclude large files and directories from analysis
- Configure file patterns for your project type
- Use incremental analysis for large codebases

## Troubleshooting

### Common Issues

#### SonarLint Not Working
1. Check if the plugin is enabled
2. Verify file associations
3. Restart IDE
4. Check SonarLint logs

#### Connection Issues
1. Verify SonarQube server URL
2. Check authentication tokens
3. Ensure network connectivity
4. Validate server certificates

#### False Positives
1. Review rule documentation
2. Add suppression comments if justified:
   ```java
   @SuppressWarnings("squid:S1186") // Empty method is intentional
   ```
3. Configure rule exceptions in SonarQube server

### Performance Issues
- Increase IDE memory allocation
- Exclude unnecessary file types
- Use SonarLint in "manual trigger" mode for large files

## Advanced Configuration

### Custom Quality Profiles
1. Create custom quality profile in SonarQube
2. Assign profile to your project
3. SonarLint automatically inherits the profile

### Rule Customization
```json
{
    "sonarlint.connectedMode.project": {
        "projectKey": "sonarqube-container",
        "serverId": "local-sonarqube"
    },
    "sonarlint.rules": {
        "Web:TableWithoutCaptionCheck": "off",
        "Web:S5254": "off"
    }
}
```

## Security Configuration

### Secrets Detection
Enable enhanced secrets detection:
```json
{
    "sonarlint.rules": {
        "*:S6287": "on",  // AWS credentials
        "*:S6290": "on",  // Google API keys  
        "*:S6291": "on",  // Azure keys
        "*:S6292": "on"   // Generic secrets
    }
}
```

### Vulnerability Scanning
Configure vulnerability detection rules:
```json
{
    "sonarlint.rules": {
        "security:*": "on"
    },
    "sonarlint.pathToNodeExecutable": "/usr/bin/node"
}
```

## Compliance Integration

### CWE Top 25 2024
SonarLint automatically includes rules covering:
- CWE-79: Cross-site Scripting
- CWE-89: SQL Injection  
- CWE-20: Input Validation
- CWE-200: Information Exposure
- And 21 more critical weakness types

### OWASP Integration
Rules aligned with:
- OWASP Top 10 2021
- OWASP Mobile Top 10 2024
- OWASP API Security Top 10

## Support and Resources

### Documentation
- [SonarLint Official Docs](https://www.sonarsource.com/products/sonarlint/)
- [IDE-specific guides](https://www.sonarsource.com/products/sonarlint/features/)

### Community
- [SonarSource Community](https://community.sonarsource.com/)
- [GitHub Issues](https://github.com/SonarSource)

### Training
- Regular team training sessions on new rules
- Monthly review of SonarLint findings
- Best practices sharing sessions