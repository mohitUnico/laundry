# DoorSync Templates

This directory contains templates used by various commands in the DoorSync platform.

## Service Templates

### Project Structure

- `service/project/` - Templates for service project structure and configuration files
  - `constants.ftl` - Shared constants for dependency versions
  - `parent-pom.ftl` - Parent POM template for service modules
  - `root-project-json.ftl` - Root project.json template for Nx integration
  - `module-project-json.ftl` - Module-specific project.json template for Nx integration

### Module Templates

- `service/domain/` - Templates for domain module
  - `pom.xml.ftl` - Maven POM for domain module
  
- `service/application/` - Templates for application module
  - `pom.xml.ftl` - Maven POM for application module
  
- `service/infrastructure/` - Templates for infrastructure module
  - `pom.xml.ftl` - Maven POM for infrastructure module
  
- `service/interface/` - Templates for interface module
  - `pom.xml.ftl` - Maven POM for interface module
  - `formatter.xml` - Java code formatting rules
  - `spotbugs-exclude.xml` - SpotBugs exclusion patterns
  - `checkstyle.xml` - Checkstyle rules based on Google style

### Deployment Templates

- `service/deployment-manifest-template.yaml` - Base template for AWS CloudFormation/SAM deployment manifest
- `service/lambda-function-template.yaml` - Template for Lambda function configuration within deployment manifest

### API Documentation Templates

- `service/openapi-template.yaml` - Template for OpenAPI 3.0.3 specification
- `service/postman-collection-template.json` - Template for Postman collection v2.1.0

## Task Templates

- `task-template.md` - Template for creating task files

## Knowledge Base Templates

- `kb-article-template.md` - Template for creating knowledge base articles

## Using Templates

Templates are used by command files in the `.cursor/rules/commands/` directory. Commands process these templates with the appropriate variables to generate configuration files, documentation, and other artifacts.

Most template files use the FreeMarker template syntax (`.ftl` extension) which supports variable substitution, conditional logic, and includes.

### Variable Substitution

Templates use the following variable format: `${variableName}`

Example:
```xml
<groupId>${basePackage}</groupId>
<artifactId>${serviceName}-service-domain</artifactId>
```

### Includes

Some templates include other templates, particularly for constants or shared sections:

```
<#include "../project/constants.ftl">
```

## Adding New Templates

When adding new templates:

1. Place them in the appropriate subdirectory
2. Update this README.md file with information about the new template
3. Reference the template from the corresponding command file

## Template Guidelines

- Use consistent naming conventions
- Include comments explaining the purpose and usage of the template
- Follow the established directory structure
- Use variable substitution for all configurable values
- Add appropriate documentation in this README.md file 