# Prometheus + Grafana
This guide installs Prometheus + Grafana (via kube-prometheus-stack), enables Traefik metrics, and optionally adds Loki for logs and OpenCost for cost monitoring.


## Prepare
```bash
# Add repos
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Namespace
kubectl create ns monitoring
```

# Minimal Values for k3s

Create values-monitoring.yaml:
```yaml
defaultRules:
  create: true
  rules:
    etcd: false
kubeControllerManager:
  enabled: false
kubeScheduler:
  enabled: false
kubeProxy:
  enabled: true
kubeEtcd:
  enabled: false

prometheus:
  prometheusSpec:
    retention: 15d
    retentionSize: "10GB"
    scrapeInterval: "30s"
    evaluationInterval: "30s"
    resources:
      requests:
        cpu: 200m
        memory: 512Mi
    storageSpec:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 20Gi
    serviceMonitorSelectorNilUsesHelmValues: true
    podMonitorSelectorNilUsesHelmValues: true

alertmanager:
  alertmanagerSpec:
    resources:
      requests:
        cpu: 50m
        memory: 128Mi

kube-state-metrics:
  resources:
    requests:
      cpu: 50m
      memory: 128Mi

nodeExporter:
  tolerations:
    - operator: "Exists"

grafana:
  adminPassword: "changeme"
  ingress:
    enabled: true
    ingressClassName: traefik
    annotations:
      cert-manager.io/cluster-issuer: "letsencrypt-production"
      traefik.ingress.kubernetes.io/router.entrypoints: "web,websecure"
      traefik.ingress.kubernetes.io/router.tls: "true"
    hosts:
      - grafana.yourdomain.com
    tls:
      - secretName: grafana-tls
        hosts:
          - grafana.yourdomain.com
  persistence:
    enabled: true
    size: 5Gi
```

# Install kube-prometheus-stack
```bash
helm install monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring -f values-monitoring.yaml
```
Port-forward Grafana to access it:
```bash
kubectl -n monitoring port-forward svc/monitoring-grafana 3000:80

# http://localhost:3000 (admin / changeme)
```

## Enable Traefik Metrics
Edit the Traefik values file (values-traefik.yaml):
```yaml
---
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: traefik
  namespace: kube-system
spec:
  valuesContent: |
    metrics:
      prometheus:
        enabled: true
        addEntryPointsLabels: true
        addServicesLabels: true
    additionalArguments:
      - "--metrics.prometheus=true"
      - "--metrics.prometheus.addEntryPointsLabels=true"
      - "--metrics.prometheus.addServicesLabels=true"
---
apiVersion: v1
kind: Service
metadata:
  name: traefik-metrics
  namespace: kube-system
  labels:
    app.kubernetes.io/name: traefik
    app.kubernetes.io/component: metrics
spec:
  selector:
    app.kubernetes.io/name: traefik
  ports:
    - name: metrics
      port: 9100
      targetPort: 9100
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: traefik
  namespace: monitoring
  labels:
    release: monitoring
spec:
  selector:
    matchLabels:
      app.kubernetes.io/component: metrics
  namespaceSelector:
    matchNames: ["kube-system"]
  endpoints:
    - port: metrics
      interval: 30s
```
Apply the changes:
```bash
kubectl apply -f traefik-metrics.yaml
```

# Install Loki (optional)
Loki is a log aggregation system that integrates with Grafana. To install Loki, create a
values-loki.yaml file:
```yaml
```


### Sanity Check

```bash
# Prometheus
kubectl -n monitoring get pods -l app.kubernetes.io/name=prometheus
kubectl -n monitoring port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090
# http://localhost:9090 → Status → Targets

# Grafana
kubectl -n monitoring get ingress monitoring-grafana
```

### Const monitoring (optional)
To monitor Kubernetes costs, you can install OpenCost:
```bash
helm repo add opencost https://opencost.github.io/opencost-helm-chart
helm install opencost opencost/opencost -n monitoring \
  --set opencost.exporter.defaultClusterId="k3s"
```

### Logs (Optional)
```bash
helm upgrade --install loki grafana/loki -n monitoring
helm upgrade --install promtail grafana/promtail -n monitoring \
  --set "config.clients[0].url=http://loki:3100/loki/api/v1/push"
```
