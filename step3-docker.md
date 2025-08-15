# Get this repo
```bash
git clone https://github.com/sayjeyhi/calendar-app.git
```

# Build your Docker image
```bash
docker build -t calendar-app .
```

# Test locally
```bash
docker run -p 3000:3000 calendar-app
```

# Login to Docker Hub (or GitHub Container Registry)
```bash
docker login
```

# Push to registry
```bash
docker tag calendar-app:latest localhost:5000/calendar-app:latest
docker push localhost:5000/calendar-app:latest
```
