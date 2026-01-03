# Post-Installation Configuration

## 1. Install AWS Load Balancer Controller
**Purpose**: Enable LoadBalancer and Ingress functionality

### GUI Steps:
1. **EKS Console** → **Clusters** → **Add-ons** → **Get more add-ons**
2. Search for **AWS Load Balancer Controller**
3. **Install** with default settings
4. **Alternative**: Use Helm via Kubernetes Dashboard

## 2. Install EBS CSI Driver
**Purpose**: Enable persistent volume support

### GUI Steps:
1. **EKS Console** → **Clusters** → **Add-ons**
2. **Add new** → **Amazon EBS CSI Driver**
3. **Install** with latest version

## 3. Configure Horizontal Pod Autoscaler (HPA)
**Purpose**: Auto-scale pods based on CPU/memory

### Kubernetes Dashboard:
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: nginx-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nginx-test
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

## 4. Install Metrics Server (if not present)
**Purpose**: Enable resource metrics for HPA

### Kubernetes Dashboard:
Apply: `https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml`

## 5. Configure Ingress Controller
**Purpose**: HTTP/HTTPS routing

### Example Ingress:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx-test
            port:
              number: 80
```

## 6. Set Up Monitoring
**Options**:
- **CloudWatch Container Insights**: Enable in EKS Console
- **Prometheus + Grafana**: Install via Helm
- **AWS X-Ray**: For distributed tracing

## 7. Configure Backup Strategy
**EBS Snapshots**:
- **EC2 Console** → **Snapshots** → **Create Snapshot Policy**
- Schedule daily snapshots of worker node volumes

**etcd Backup**:
- Managed automatically by EKS
- Point-in-time recovery available

## 8. Security Hardening
**Pod Security Standards**:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: secure-namespace
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

**Network Policies**:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```
