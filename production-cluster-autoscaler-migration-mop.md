# Production EKS Cluster Autoscaler Migration MOP

## Scenario: Existing Production Cluster with 10 Nodes

### Current State
- **Cluster**: EKS production cluster
- **Nodes**: 10 EC2 instances (manually managed)
- **Workloads**: Multiple applications across namespaces
- **Goal**: Enable Cluster Autoscaler without downtime

## Phase 1: Pre-Migration Assessment (Day 1)

### Step 1.1: Inventory Current Resources
```bash
# Check current nodes
kubectl get nodes -o wide

# Check workloads distribution
kubectl get pods --all-namespaces -o wide

# Check resource usage
kubectl top nodes
kubectl top pods --all-namespaces
```

### Step 1.2: Validate Prerequisites
```bash
# Check PodDisruptionBudgets
kubectl get pdb --all-namespaces

# Check resource requests/limits
kubectl describe pods --all-namespaces | grep -A 5 "Requests\|Limits"

# Verify StatefulSets
kubectl get statefulsets --all-namespaces
```

### Step 1.3: Document Current Setup
- Node instance types and sizes
- Application resource requirements
- Critical workloads identification
- Maintenance windows available

## Phase 2: Create Managed Node Group (Day 2-3)

### Step 2.1: Create IAM Roles (if not exists)
**GUI Steps:**
1. **IAM Console** → **Roles** → **Create Role**
2. **EKS Node Group Role** with policies:
   - `AmazonEKSWorkerNodePolicy`
   - `AmazonEKS_CNI_Policy`
   - `AmazonEC2ContainerRegistryReadOnly`

### Step 2.2: Create Launch Template
**EC2 Console:**
1. **Launch Templates** → **Create Launch Template**
2. **Name**: `eks-autoscaler-template`
3. **AMI**: Latest EKS optimized AMI
4. **Instance Type**: Same as existing nodes
5. **User Data**:
```bash
#!/bin/bash
/etc/eks/bootstrap.sh YOUR-CLUSTER-NAME
```

### Step 2.3: Create Managed Node Group
**EKS Console:**
1. **Clusters** → **Compute** → **Add Node Group**
2. **Configuration**:
   - **Name**: `autoscaler-nodegroup`
   - **Node IAM Role**: Created in Step 2.1
   - **Launch Template**: `eks-autoscaler-template`
3. **Scaling Configuration**:
   - **Desired**: 1
   - **Minimum**: 1
   - **Maximum**: 15
4. **Instance Types**: Match existing nodes
5. **Subnets**: Same as existing nodes

### Expected Result
```
Current State: 10 (existing) + 1 (ASG) = 11 nodes total
```

## Phase 3: Setup Cluster Autoscaler (Day 4)

### Step 3.1: Create IAM Policy for Cluster Autoscaler
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeLaunchConfigurations",
                "autoscaling:DescribeScalingActivities",
                "autoscaling:DescribeTags",
                "autoscaling:SetDesiredCapacity",
                "autoscaling:TerminateInstanceInAutoScalingGroup",
                "ec2:DescribeLaunchTemplateVersions",
                "ec2:DescribeInstanceTypes"
            ],
            "Resource": "*"
        }
    ]
}
```

### Step 3.2: Create IRSA Role
**IAM Console:**
1. **Roles** → **Create Role** → **Web Identity**
2. **Identity Provider**: Your cluster's OIDC provider
3. **Condition**: `StringEquals`
   - **Key**: `OIDC-URL:sub`
   - **Value**: `system:serviceaccount:kube-system:cluster-autoscaler`

### Step 3.3: Deploy Cluster Autoscaler
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cluster-autoscaler
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT-ID:role/ClusterAutoscalerRole
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cluster-autoscaler
  namespace: kube-system
spec:
  selector:
    matchLabels:
      app: cluster-autoscaler
  template:
    metadata:
      labels:
        app: cluster-autoscaler
      annotations:
        cluster-autoscaler.kubernetes.io/safe-to-evict: "false"
    spec:
      serviceAccountName: cluster-autoscaler
      containers:
      - image: registry.k8s.io/autoscaling/cluster-autoscaler:v1.31.0
        name: cluster-autoscaler
        command:
        - ./cluster-autoscaler
        - --v=4
        - --stderrthreshold=info
        - --cloud-provider=aws
        - --skip-nodes-with-local-storage=false
        - --expander=least-waste
        - --node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/YOUR-CLUSTER-NAME
        - --balance-similar-node-groups
        - --skip-nodes-with-system-pods=false
        env:
        - name: AWS_REGION
          value: YOUR-REGION
```

### Step 3.4: Tag Auto Scaling Group
**EC2 Console:**
1. **Auto Scaling Groups** → Select ASG
2. **Add Tags**:
   - `k8s.io/cluster-autoscaler/enabled` = `true`
   - `k8s.io/cluster-autoscaler/YOUR-CLUSTER-NAME` = `owned`

## Phase 4: Gradual Workload Migration (Week 1-2)

### Step 4.1: Label Nodes for Identification
```bash
# Label existing nodes
kubectl label nodes node1 node2 ... node10 nodegroup=legacy

# Label ASG nodes
kubectl label nodes <asg-node> nodegroup=autoscaled
```

### Step 4.2: Create Test Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-migration
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: test-migration
  template:
    metadata:
      labels:
        app: test-migration
    spec:
      nodeSelector:
        nodegroup: autoscaled
      containers:
      - name: nginx
        image: nginx
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
```

### Step 4.3: Migrate Non-Critical Workloads First
```bash
# Edit deployment to add nodeSelector
kubectl patch deployment <deployment-name> -n <namespace> -p '
{
  "spec": {
    "template": {
      "spec": {
        "nodeSelector": {
          "nodegroup": "autoscaled"
        }
      }
    }
  }
}'
```

### Step 4.4: Monitor and Validate
```bash
# Check pod placement
kubectl get pods -o wide --all-namespaces | grep <asg-node>

# Monitor cluster autoscaler logs
kubectl logs -n kube-system -l app=cluster-autoscaler

# Check resource utilization
kubectl top nodes
```

## Phase 5: Scale ASG and Migrate Critical Workloads (Week 2-3)

### Step 5.1: Increase ASG Capacity
**EKS Console:**
1. **Node Groups** → **autoscaler-nodegroup** → **Edit**
2. **Update Scaling**:
   - **Desired**: 5
   - **Minimum**: 3
   - **Maximum**: 15

### Expected Result
```
Current State: 10 (legacy) + 5 (ASG) = 15 nodes total
```

### Step 5.2: Migrate Critical Workloads
```bash
# For each critical deployment
kubectl patch deployment <critical-app> -n <namespace> -p '
{
  "spec": {
    "template": {
      "spec": {
        "nodeSelector": {
          "nodegroup": "autoscaled"
        }
      }
    }
  }
}'

# Wait and monitor
kubectl rollout status deployment/<critical-app> -n <namespace>
```

### Step 5.3: Validate Application Health
```bash
# Check application endpoints
curl -f http://<service-endpoint>/health

# Check logs for errors
kubectl logs -l app=<critical-app> -n <namespace>

# Monitor metrics
kubectl top pods -n <namespace>
```

## Phase 6: Remove Legacy Nodes (Week 3-4)

### Step 6.1: Drain Legacy Nodes One by One
```bash
# Drain first legacy node
kubectl drain node1 --ignore-daemonsets --delete-emptydir-data --force

# Wait 10-15 minutes and monitor
kubectl get pods --all-namespaces | grep Pending

# If no issues, terminate EC2 instance
aws ec2 terminate-instances --instance-ids i-xxxxxxxxx

# Repeat for remaining nodes (one per day for safety)
```

### Step 6.2: Monitor During Drainage
```bash
# Watch pod rescheduling
kubectl get events --sort-by=.metadata.creationTimestamp

# Check cluster autoscaler activity
kubectl logs -n kube-system -l app=cluster-autoscaler --tail=50

# Verify no service disruption
curl -f http://<service-endpoints>
```

## Phase 7: Final Optimization (Week 4)

### Step 7.1: Adjust ASG to Production Needs
**EKS Console:**
1. **Update Scaling Configuration**:
   - **Desired**: 8
   - **Minimum**: 5
   - **Maximum**: 20

### Step 7.2: Test Auto Scaling
```bash
# Create load test
kubectl create deployment scale-test --image=nginx --replicas=50

# Watch nodes scale up
kubectl get nodes -w

# Clean up and watch scale down
kubectl delete deployment scale-test
# Wait 10-15 minutes for scale down
```

## Scenario Outcomes

### Before Migration
```
Nodes: 10 (manual)
Scaling: Manual intervention required
Cost: Fixed regardless of load
Management: High operational overhead
```

### After Migration
```
Nodes: 5-20 (auto-managed)
Scaling: Automatic based on demand
Cost: Optimized for actual usage
Management: Minimal operational overhead
```

## Risk Mitigation Strategies

### Rollback Plan
```bash
# If issues during migration
kubectl patch deployment <app> -n <namespace> -p '
{
  "spec": {
    "template": {
      "spec": {
        "nodeSelector": {
          "nodegroup": "legacy"
        }
      }
    }
  }
}'
```

### Monitoring Checklist
- [ ] Application response times
- [ ] Error rates in logs
- [ ] Resource utilization
- [ ] Pod scheduling success
- [ ] Cluster autoscaler logs
- [ ] Cost tracking

## Success Criteria
- ✅ Zero application downtime
- ✅ All workloads running on ASG nodes
- ✅ Cluster autoscaler functioning
- ✅ Cost optimization achieved
- ✅ Legacy nodes removed

## Timeline Summary
- **Week 1**: Setup ASG, deploy cluster autoscaler
- **Week 2**: Migrate non-critical workloads
- **Week 3**: Migrate critical workloads, increase ASG
- **Week 4**: Remove legacy nodes, optimize scaling

**Total Duration**: 3-4 weeks for safe production migration
