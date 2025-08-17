## CI/CD
We are using GitHub Actions to set up a CI/CD pipeline for our Calendar Application. This will automate the process of building, testing, and deploying our application whenever we push changes to the repository.
https://github.com/sayjeyhi/calendar-app/blob/main/.github/workflows/build-and-deploy.yml


### Create your repo
In order to setup github actions, you need to create a repository on GitHub. Then
you can push your code to the repository. Make sure to include the `.github/workflows` directory with the workflow file.

### Enable GitHub Actions
Go to your repository settings, scroll down to the "Actions" section, and enable GitHub Actions if it is not already enabled.
Give github actions permission to read and write to your repository and packages.

# GitHub Actions Workflow for CI/CD
This workflow will build the Docker image, push it to GitHub Container Registry, and deploy it to a Kubernetes cluster using the Azure Kubernetes Service github action.

```yaml
name: Build and Push Docker Image

on:
  push:
    branches:
      - main # Trigger when PR is merged into the 'main' branch

permissions:
  contents: read
  packages: write
  actions: read

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Kubernetes set context
        uses: Azure/k8s-set-context@v3
        with:
          method: kubeconfig
          kubeconfig: ${{ secrets.KUBE_CONFIG }}

      - name: Set commit SHA short
        run: |
          echo "COMMIT_SHA_SHORT=${GITHUB_SHA::8}" >> $GITHUB_ENV
          echo "CURRENT_DATE=$(date +'%Y-%m-%d')" >> $GITHUB_ENV
          echo "REPOSITORY_NAME=${GITHUB_REPOSITORY,,}" >> $GITHUB_ENV

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      - name: Log in to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}  # GitHub automatically provides this secret

      - name: Verify GHCR login
        run: docker info

      - name: Build and push Docker image
        uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          platforms: linux/amd64,linux/arm64
          tags: |
            ghcr.io/${{ env.REPOSITORY_NAME }}:${{ env.COMMIT_SHA_SHORT }}
            ghcr.io/${{ env.REPOSITORY_NAME }}:${{ env.CURRENT_DATE }}
            ghcr.io/${{ env.REPOSITORY_NAME }}:latest

      - name: Deploy
        uses: Azure/k8s-deploy@v5.0.1
        with:
          action: deploy
          strategy: basic
          imagepullsecrets: |
            dockerconfigjson-github-com
          manifests: |
            ./k8s/deployment.yaml
            ./k8s/service.yaml
            ./k8s/ingress.yaml
            ./k8s/middleware.yaml
          images: ghcr.io/${{ env.REPOSITORY_NAME }}:${{ env.COMMIT_SHA_SHORT }}
```
