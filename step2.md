# K3s Cluster Setup
In your server we need to install k3s, which is a lightweight Kubernetes distribution.

## Install k3s
To run a quick kubernetes cluster, you can use k3s.

```bash
curl -sfL https://get.k3s.io | sh -
```

if
```bash
echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> ~/.bashrc
source ~/.bashrc
```

### Check k3s status
```bash
k3s kubectl get nodes
```
if you set permission error, you can run the following command to give permission to the user:
```bash
sudo chown $(whoami) /etc/rancher/k3s/k3s.yaml
```

get list of pods
```bash
kubectl get nodes
kubectl get pods
```

### Install lens app
Lens is a simple, easy-to-use, and Kubernetes-native dashboard for the Kubernetes cluster.
On your local machine, you can use Lens to manage your cluster.

https://k8slens.dev/

download and install lens.

Copy the k3s config file to the ~/.kube/config path after changing the IP address to your server IP and the name from `127.0.0.1` to `domain.com` or IP.
you can also change the context name to something more meaningful than `default`, like `k3s-cluster`.
```bash
cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
```
