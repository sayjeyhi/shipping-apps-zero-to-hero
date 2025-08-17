# SSL and CertManager Installation
In this step, we will install cert-manager to manage SSL certificates and Rancher for Kubernetes management.

### Install cert manager
We need our website to have https, and having http protocol means we need a SSL Certification.


```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.15.3/cert-manager.yaml

# kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
```

get the cert-manager pod name

```bash
kubectl get pods -n cert-manager
```

Create a ClusterIssuer to use Let's Encrypt for SSL certificates. This will allow us to automatically issue and renew SSL certificates for our domains.

certificates.yaml
```bash
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: ssl-cert-production
  namespace: default
spec:
  secretName: ssl-cert-production
  issuerRef:
    name: letsencrypt-production
    kind: ClusterIssuer
  commonName: iwaskidding.com
  dnsNames:
    - iwaskidding.com
    - sub.iwaskidding.com
```

cluster-issuer.yaml
```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-production
  namespace: default
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: mail@gmail.com
    privateKeySecretRef:
      name: letsencrypt-production
    solvers:
      - selector: {}
        http01:
          ingress:
            class: traefik
```
