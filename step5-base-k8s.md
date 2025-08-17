# Pods, Services, Deployments and Namespaces
> In this step, we will create a simple pod and expose it as a service.

### Create a Pod and Service
We will create a nginx pod to test our cluster.
```bash
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=8080 --type=NodePort
```

# Check the status of the pod
```bash
kubectl get pods
kubectl get services
```


We can also check the logs of the pod:
```bash
kubectl logs <nginx-pod-name>
```

Check the nginx service:
```bash
curl http://<your-server-ip>:<node-port>
```

### Create Pod with YAML
You can also create a pod using a YAML file. Create a file named `nginx-pod.yaml` with the following content:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod-file
  labels:
    app: nginx-file
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
```
Then apply the YAML file:
```bash
kubectl apply -f nginx-pod.yaml
```

# Check the status of the pod
```bash
kubectl get pods
```

This will create a pod named `nginx-pod` running the nginx container, but it will not expose it as a service.

### Expose the Pod as a Service
You can expose the pod as a service using a YAML file. Create a file named `nginx-service.yaml` with the following content:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service-file
spec:
  selector:
    app: nginx-file
  ports:
  - protocol: TCP
    port: 9090        # 👈 This is the SERVICE PORT (inside cluster)
    targetPort: 80    # 👈 This is the CONTAINER PORT (in the pod)
    nodePort: 30302   # 👈 This is the EXTERNAL PORT (on the node)
  type: NodePort
```

Then apply the YAML file:
```bash
kubectl apply -f nginx-service.yaml
```


#### Deployments

Deployments are a higher-level abstraction that manages pods. You can create a deployment using the following command:
```bash
kubectl create deployment nginx-deployment --image=nginx --replicas=3
```


### Namespaces
Namespaces are a way to divide cluster resources between multiple users. You can create a namespace using the following command:
```bash
kubectl create namespace my-namespace
```
You can also create a namespace using a YAML file. Create a file named `my-namespace.yaml` with the following content:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: my-namespace
```
Then apply the YAML file:
```bash
kubectl apply -f my-namespace.yaml
```
# Check the status of the namespace
```bash
kubectl get namespaces
```


# Clean Up
To clean up the resources created in this step, you can delete the pod, service, and
namespace using the following commands:
```bash
kubectl delete deployment nginx-deployment
kubectl delete pod nginx
kubectl delete pod nginx-pod-file
kubectl delete service nginx
kubectl delete service nginx-service-file
kubectl delete namespace my-namespace
```

### Install Lens (optional)
Lens is a simple, easy-to-use, and Kubernetes-native dashboard for the Kubernetes cluster. On your local machine, you can use Lens to manage your cluster.
https://k8slens.dev/

### Skaffold (optional)
Skaffold is a command-line tool that facilitates continuous development for Kubernetes applications. It handles the workflow for building, pushing, and deploying applications.
https://skaffold.dev/docs/install/#standalone-binary
