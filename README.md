# SonarQube Docker

This repository contains the configuration files and instructions for deploying a customized SonarQube Community Edition server using Docker. Our setup includes additional plugins and configurations to enhance the capabilities of SonarQube for enterprise use.

## Features

- **Effortless Setup**: Quick deployment of a SonarQube server using Docker.
- **Highly Customizable**: Adaptable SonarQube configuration for various environments.
- **Comprehensive Language Support**: Includes default plugins for multiple programming languages.
- **Persistent Storage**: Ensures data persistence for SonarQube analyses.
- **Version Flexibility**: Allows dynamic specification of SonarQube version.
- **Enhanced Plugins**: Includes additional plugins for extended functionality:
  1. [sonarqube-community-branch-plugin](https://github.com/mc1arke/sonarqube-community-branch-plugin)
  2. [sonar-cnes-report](https://github.com/cnescatlab/sonar-cnes-report)
  3. [sonar-gitlab-plugin](https://github.com/gabrie-allaigre/sonar-gitlab-plugin)
  4. [sonar-cxx-plugin](https://github.com/SonarOpenCommunity/sonar-cxx)
  5. [eslint-plugin-sonarjs](https://github.com/SonarSource/eslint-plugin-sonarjs)
  6. [dependency-check-sonar-plugin](https://github.com/dependency-check/dependency-check-sonar-plugin)
  
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
export SONARQUBE_VERSION=9.9.4.87374
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
export SONARQUBE_VERSION=9.9.4.87374
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

## Disclaimer

This is not an official SonarSource product. It's a community-driven project to enhance SonarQube deployment for enterprise use.
```