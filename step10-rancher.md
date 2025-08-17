
### Install Rancher
Rancher is an open source software stack cloud native kubernetes management, and allows monitor and scale

#### 1. prepare subdomain
Before installing Rancher, you need to create a subdomain for Rancher.
add a DNS record for rancher.domain.com pointing to your server IP.

| Type | Name | Value |
| --- | --- | --- |
| A   | rancher | YOUR_SERVER_IP |

Check if the DNS record is created:
```bash
nslookup rancher.domain.co
```

#### 2. Add the Rancher Helm Repository
To install Rancher, we will use Helm, a package manager for Kubernetes. First, we need to add the Rancher Helm repository.
```bash
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
helm repo update
```

#### 3. Create a Namespace for Rancher

```bash
kubectl create namespace cattle-system
```

#### 4. Install Rancher

Install Rancher for that subdomain:
```bash
helm upgrade --install rancher rancher-stable/rancher \
  --namespace cattle-system \
  --set hostname=rancher.domain.com \
  --set ingress.tls.source=letsEncrypt \
  --set letsEncrypt.email=your@email.com \
  --set replicas=1
```

Check if rancher is ready:
```bash
kubectl -n cattle-system get pods
```
