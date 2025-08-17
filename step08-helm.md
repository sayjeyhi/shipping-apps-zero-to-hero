# Use Helm
We need to first create a Helm chart for our Calendar Application. 
Helm charts are packages of pre-configured Kubernetes resources that can be easily deployed and managed.


### Install helm
If you haven't installed Helm yet, you can do so with the following command:
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### Create a Helm Chart
We need to create a Helm chart for our Calendar Application.
Helm charts are packages of pre-configured Kubernetes resources that can be easily deployed and managed.
This will allow us to package our application and deploy it easily to Kubernetes.
```bash
# Create the Helm chart directory
helm create helm/calendar-app

# Navigate to the chart directory
cd helm/calendar-app
```

This directory contains Helm charts for deploying applications to Kubernetes.


### Get the chart values and templates
Go to `https://github.com/sayjeyhi/calendar-app` and download the `helm/calendar-app` directory.

#### Quick Start

```bash
# Install with default values
helm install calendar-app ./calendar-app

# Install with local development values
helm install calendar-app ./calendar-app -f values-local.yaml

# Upgrade existing installation
helm upgrade calendar-app ./calendar-app

# Uninstall
helm uninstall calendar-app
```

#### Configuration

The chart supports environment-specific configurations:

- **Default values**: `values.yaml` - Production configuration
- **Local development**: `values-local.yaml` - Local development setup

#### Features

- Configurable deployment with rolling updates
- Health checks (liveness and readiness probes)
- Ingress configuration with TLS support
- Traefik middleware for HTTPS redirects
- Resource limits and requests
- Environment-specific configurations

#### Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- Traefik Ingress Controller (if using ingress)
- cert-manager (if using TLS)

For more detailed information, see the [calendar-app README](./calendar-app/README.md).


```bash
# Test the chart (dry run)
helm install calendar-app ./helm/calendar-app --dry-run

# Or just render the templates
helm template calendar-app ./helm/calendar-app

# Install with default values
helm install calendar-app ./helm/calendar-app

# Install with local development values
helm install calendar-app ./helm/calendar-app -f values-local.yaml
```
