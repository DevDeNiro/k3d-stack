# Templating Guidelines

## Required Helpers

### Common Templates

- **`common.namespace.name`**: Provides the release namespace, supporting both monorepo and individual project structures.
- **`common.name`**: Generates the base name for resources based on either an override or the chart's name.
- **`common.fullname`**: Constructs a full resource name using the release name combined with the base name.
- **`common.labels.standard`**: Provides standard labels (app name, instance, version).

### Ingress

Helpers like `common.ingress.hostname` dynamically generate hostnames using the format `<service>.<environment>.<base-domain>`.

## Values Schema

### Global Values (From `values-global.yaml`)

- **Environment**: Dynamically set during deployment (`CI_COMMIT_REF_SLUG`).
- **Project**: Default project name is 'votchain'.
- **Resource Limit**: Provides standard memory and CPU requests and limits.
- **Security Contexts**: Security and pod options are centralized here.
- **Ingress Configuration**: Includes default annotations and class specification.

### Service-Specific Values

Each service under global uses its own configuration such as:
- **Port and Target Port**
- **Image Repository and Tag**
- **Resource Requirements**

## Adding a New Micro-Service Entry

### Steps to Add a New Micro-Service:

1. **Define Values**: In `values-global.yaml`, add a new entry under `services` with service-specific configurations (ports, image repositories, environment variables.
2. **Utilize Templates**: Use `_deployment.tpl`, `_service.tpl`, and `_ingress.tpl` for common configuration templates.
3. **Namespace Management**: Setup required namespaces using templates in `_helpers.tpl` if necessary.
4. **RBAC Configurations**: Leverage RBAC templates to manage service accounts and roles if additional permissions are needed.
