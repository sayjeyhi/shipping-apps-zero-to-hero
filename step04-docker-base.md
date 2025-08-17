# Base
We will use this repository as a base for our entire workshop examples.
It contains a simple calendar application built with React and Next.js, which we will containerize using Docker.

```bash
git clone https://github.com/sayjeyhi/calendar-app.git
```

# Build your Docker image
Navigate to the project directory and build the Docker image using the provided Dockerfile.
```bash
docker build -t calendar-app .
```

# Test locally
This will run the container and map port 3000 of the container to port 3000 on your host machine.
```bash
docker run -p 3000:3000 calendar-app
```

# Docker compose
With Docker Compose, you can do the same thing as above but with a `docker-compose.yml` file.
There is a `docker-compose.yml` file in the root of the project that defines the service.
It will build the image and run the container with the specified port mapping.
```bash
docker run -p 3000:3000 calendar-app
```

# Login to Docker (use GitHub PAT)
We will use GitHub Container Registry to push our Docker image.
Make sure you have a Personal Access Token (PAT) with `write:packages` and `read:packages` scopes.
You can create a PAT in your GitHub account settings under Developer settings > Personal access tokens.
Replace `YOUR_TOKEN` with your actual token and `USERNAME` with your GitHub username.

```bash
export CR_PAT=YOUR_TOKEN
echo $CR_PAT | docker login ghcr.io -u USERNAME --password-stdin
```

# Push to registry
Lets push our Docker image to GitHub Container Registry.
Make sure to replace `USERNAME` with your GitHub username.
You can also change the image name if you want.
```bash
docker tag calendar-app:latest ghcr.io/USERNAME/calendar-app:latest
docker push ghcr.io/sayjeyhi/calendar-app:latest
```
