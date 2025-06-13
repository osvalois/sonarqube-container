# SonarQube Docker

This repository contains the configuration files and instructions for deploying a customized SonarQube Community Edition server using Docker. Our setup includes additional plugins and configurations to enhance the capabilities of SonarQube for enterprise use.

## Features

- **Effortless Setup**: Quick deployment of a SonarQube 2025.1 LTA server using Docker.
- **Highly Customizable**: Adaptable SonarQube configuration for various environments.
- **Comprehensive Language Support**: Includes default plugins for multiple programming languages including Rust and Dart/Flutter.
- **Persistent Storage**: Ensures data persistence for SonarQube analyses.
- **Version Flexibility**: Allows dynamic specification of SonarQube version.
- **DevSecOps Integration**: Full CI/CD pipeline integration with GitHub Actions and Quality Gates.
- **Security-First Approach**: Advanced security configurations with CWE Top 25 2024 and OWASP Mobile Top 10 compliance.
- **Enhanced Plugins**: Includes additional plugins for extended functionality:
  1. [sonarqube-community-branch-plugin](https://github.com/mc1arke/sonarqube-community-branch-plugin) - Branch analysis
  2. [sonar-cnes-report](https://github.com/cnescatlab/sonar-cnes-report) - PDF reporting
  3. [sonar-gitlab-plugin](https://github.com/gabrie-allaigre/sonar-gitlab-plugin) - GitLab integration
  4. [sonar-cxx-plugin](https://github.com/SonarOpenCommunity/sonar-cxx) - C/C++ analysis
  5. [eslint-plugin-sonarjs](https://github.com/SonarSource/eslint-plugin-sonarjs) - JavaScript/TypeScript
  6. [dependency-check-sonar-plugin](https://github.com/dependency-check/dependency-check-sonar-plugin) - Vulnerability scanning
  7. [sonar-flutter](https://github.com/insideapp-oss/sonar-flutter) - Dart/Flutter analysis
  8. [community-rust](https://github.com/C4tWithShell/community-rust) - Rust language support
  
## Prerequisites

- Docker and Docker Compose installed on your local machine.
- Sufficient disk space for SonarQube data and PostgreSQL database.

## Quick Start

1. Clone this repository:
```sh
git clone https://github.com/osvalois/sonarqube-container.git
cd sonarqube-container
```

2. (Optional) Set the desired SonarQube version:
```sh
export SONARQUBE_VERSION=2025.1.3.79154
```

3. Start the SonarQube server:
```sh
docker-compose up -d
```

4. Access SonarQube at `http://localhost:9000` (default credentials: admin/admin)

## Configuration

### Customizing SonarQube Version

You can specify the SonarQube version by setting the `SONARQUBE_VERSION` environment variable before running docker-compose:
```sh
export SONARQUBE_VERSION=2025.1.3.79154
docker-compose up -d
```
### Plugin Configuration

The Dockerfile includes several plugins. You can customize their versions by modifying the ARG instructions in the Dockerfile.

### Database Configuration

The `docker-compose.yml` file sets up a PostgreSQL database for SonarQube. You can modify the database credentials in this file.

## Maintenance

### Upgrading SonarQube

To upgrade SonarQube:

1. Stop the current containers:
```sh
docker-compose down
```

2. Set the new SonarQube version:
```sh
export SONARQUBE_VERSION=new.version.number
```

3. Rebuild and start the containers:
```sh
docker-compose up -d --build
```

### Backing Up Data

It's recommended to regularly backup the volumes used by SonarQube and PostgreSQL. You can use Docker volume backup strategies for this purpose.

## Troubleshooting

If you encounter issues:

1. Check the logs:
```sh
docker-compose logs sonarqube
```

2. Ensure the required ports are not in use by other services.

3. Verify that the volumes have correct permissions.

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for more details.

## License

This project is licensed under the [MIT License](LICENSE).

## New Features in 2025

### DevSecOps Integration
- **GitHub Actions Workflow**: Automated SonarQube analysis on every push and pull request
- **Quality Gates**: Configurable quality gates with security-first approach
- **Compliance Reporting**: Built-in support for CWE Top 25 2024, OWASP Mobile Top 10 2024

### Security Enhancements
- **Advanced Secrets Detection**: 300+ patterns for detecting credentials and API keys
- **Vulnerability Scanning**: Integrated with OWASP Dependency Check
- **Security Hotspots**: Automated security review workflow

### Language Support
- **Rust Analysis**: Community plugin for Rust language support
- **Dart/Flutter**: Full analysis support for mobile app development
- **Enhanced C/C++**: Improved static analysis for system programming

## Quick Commands

Using the enhanced Makefile:

```bash
# Build the container
make build

# Start services
make run

# View logs
make logs

# Run security scan
make security-scan

# Stop services
make stop

# See all available commands
make help
```

## SonarLint Integration

For development teams, we provide comprehensive SonarLint setup documentation:
- See [SONARLINT_SETUP.md](SONARLINT_SETUP.md) for detailed IDE configuration
- Real-time code analysis as you write
- Pre-commit hooks integration
- Team collaboration guidelines

## Security Configuration

Advanced security features are configured in `security-config/advanced-security.properties`:
- Secrets detection patterns
- Compliance reporting
- Quality gate security thresholds
- Vulnerability scanning settings

## CI/CD Integration

The project includes:
- **GitHub Actions workflow** (`.github/workflows/sonarqube-analysis.yml`)
- **Quality Gates configuration** (`quality-gates.json`)
- **Project properties** (`sonar-project.properties`)

## Disclaimer

This is not an official SonarSource product. It's a community-driven project to enhance SonarQube deployment for enterprise use with a focus on DevSecOps best practices.