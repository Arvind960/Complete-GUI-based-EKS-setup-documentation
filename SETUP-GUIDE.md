# Complete EKS GUI-Based MOP (Updated 2026)

## Phase 1: Create Launch Template

### Step 1: Create Launch Template
1. **EC2 Console** → **Launch Templates** → **Create Launch Template**
2. **Template Name**: `eks-worker-nodes-template`
3. **AMI**: Search for `amazon-eks-node-1.31-v*` (latest EKS optimized AMI)
4. **Instance Type**: `t3.medium` (or as required)
5. **Key Pair**: Select existing or create new
6. **Security Groups**: Create/select worker node security group
7. **Storage**: 20GB gp3 (minimum)
8. **Advanced Details**:
   - **IAM Instance Profile**: `AmazonEKSNodeInstanceProfile`
   - **User Data**: Use `launch-template-userdata.sh`
9. **Create Launch Template**

## Phase 2: Provision EKS Cluster (Updated Console Flow)

### Step 2: Create EKS Cluster
1. **EKS Console** → **Clusters** → **Create Cluster**
2. **Configuration Options**: Select **Custom configuration**
3. **EKS Auto Mode**: Toggle **Use EKS Auto Mode** OFF (for traditional setup)
4. **Configure Cluster Page**:
   - **Name**: `my-eks-cluster`
   - **Kubernetes Version**: `1.31` (latest supported)
   - **Cluster IAM Role**: `AmazonEKSClusterServiceRole`
   - **Support Type**: Standard support
   - **Secrets Encryption**: Optional (KMS key)
   - **Tags**: Optional
   - **ARC Zonal Shift**: Optional
5. **Cluster Access Section**:
   - **Bootstrap cluster administrator access**: Keep enabled
   - **Cluster authentication mode**: API and ConfigMap
6. **Specify Networking Page**:
   - **VPC**: Select your VPC
   - **Subnets**: Select private subnets (minimum 2 AZs)
   - **Security Groups**: Optional additional groups
   - **Choose cluster IP address family**: IPv4
   - **Configure Kubernetes Service IP address range**: Optional
   - **Cluster endpoint access**: Public and private (recommended)
7. **Configure Observability Page**:
   - **Metrics**: Enable Prometheus metrics (optional)
   - **Control plane logging**: Enable all log types
8. **Select Add-ons Page**:
   - Keep default add-ons: VPC CNI, CoreDNS, kube-proxy
   - Add EBS CSI Driver (recommended)
9. **Configure Selected Add-ons Settings**: Use latest versions
10. **Review and Create** (takes 10-15 minutes)

### Step 3: Create Node Group
1. **EKS Console** → **Clusters** → Select cluster → **Compute** → **Add Node Group**
2. **Node Group Configuration**:
   - **Name**: `worker-nodes`
   - **Node IAM Role**: `AmazonEKSNodeGroupRole`
   - **Launch Template**: Select `eks-worker-nodes-template`
   - **Version**: Latest
3. **Node Group Compute Configuration**:
   - **AMI Type**: Amazon Linux 2 (AL2_x86_64)
   - **Capacity Type**: On-Demand
   - **Instance Types**: `t3.medium`
   - **Disk Size**: 20 GB
4. **Node Group Scaling Configuration**:
   - **Desired Size**: 2
   - **Minimum Size**: 1
   - **Maximum Size**: 4
   - **Maximum Unavailable**: 1
5. **Node Group Network Configuration**:
   - **Subnets**: Select private subnets
   - **Configure SSH Access**: Optional
6. **Create Node Group**

## Phase 3: Add Cluster Autoscaler

### Step 4: Get OIDC Provider Information
```bash
# Get OIDC Provider ID
aws eks describe-cluster --name my-eks-cluster --query "cluster.identity.oidc.issuer" --output text
# Get AWS Account ID
aws sts get-caller-identity --query Account --output text
```

### Step 5: Create IAM Policy for Cluster Autoscaler
1. **IAM Console** → **Policies** → **Create Policy**
2. **JSON tab** → Use `cluster-autoscaler-policy-gui.json`
3. **Name**: `AmazonEKSClusterAutoscalerPolicy`

### Step 6: Create IAM Role for Cluster Autoscaler
1. **IAM** → **Roles** → **Create Role**
2. **Trusted Entity**: Web Identity
3. **Identity Provider**: Your cluster's OIDC provider URL
4. **Audience**: `sts.amazonaws.com`
5. **Add Condition**:
   - **Condition**: StringEquals
   - **Key**: `OIDC-URL:sub`
   - **Value**: `system:serviceaccount:kube-system:cluster-autoscaler`
6. **Attach Policy**: `AmazonEKSClusterAutoscalerPolicy`
7. **Role Name**: `AmazonEKSClusterAutoscalerRole`

### Step 7: Tag Auto Scaling Group
1. **EC2 Console** → **Auto Scaling Groups**
2. Select EKS node group ASG
3. **Tags tab** → **Add Tags**:
   - `k8s.io/cluster-autoscaler/enabled` = `true`
   - `k8s.io/cluster-autoscaler/my-eks-cluster` = `owned`

### Step 8: Deploy Cluster Autoscaler (Kubernetes Dashboard/Lens)
1. Apply `serviceaccount-gui.yaml` (update account ID)
2. Apply `rbac-gui.yaml`
3. Apply `deployment-gui.yaml`

## Phase 4: Test Cases

### Test Case 1: Cluster Connectivity
```bash
aws eks update-kubeconfig --name my-eks-cluster --region us-west-2
kubectl get nodes
```
**Expected**: All nodes in Ready state

### Test Case 2: Pod Scheduling
```bash
kubectl create deployment nginx-test --image=nginx --replicas=3
kubectl get pods -o wide
```
**Expected**: Pods distributed across nodes

### Test Case 3: Cluster Autoscaler Functionality
```bash
kubectl create deployment scale-test --image=nginx --replicas=10
kubectl get nodes -w
```
**Expected**: New nodes added automatically

### Test Case 4: Service Connectivity
```bash
kubectl expose deployment nginx-test --port=80 --type=LoadBalancer
kubectl get svc
```
**Expected**: External IP assigned

### Test Case 5: Cluster Autoscaler Logs
```bash
kubectl logs -n kube-system -l app=cluster-autoscaler
```
**Expected**: No errors, scaling events visible

### Test Case 6: Scale Down Test
```bash
kubectl delete deployment scale-test
# Wait 10-15 minutes
kubectl get nodes
```
**Expected**: Unused nodes terminated

### Test Case 7: Add-on Functionality
```bash
kubectl get pods -n kube-system
```
**Expected**: All system pods running (CoreDNS, VPC CNI, kube-proxy, EBS CSI)

### Test Case 8: EKS Auto Mode vs Traditional (Comparison)
- **Auto Mode**: Simplified setup, automatic node management
- **Traditional**: Manual node group configuration, more control

## Key Changes in 2026 Console
- **EKS Auto Mode** option prominently featured
- **Configuration Options** selection (Quick vs Custom)
- **Cluster Access** section with authentication modes
- **Support Type** selection (Standard vs Extended)
- **Enhanced Add-ons** page with marketplace options
- **Pod Identity** support for add-ons
- **Observability** configuration during creation

## Verification Checklist
- [ ] Cluster status: Active
- [ ] Node group status: Active  
- [ ] All nodes: Ready
- [ ] Cluster autoscaler pod: Running
- [ ] Auto scaling group: Tagged correctly
- [ ] OIDC provider: Associated
- [ ] IAM roles: Properly configured
- [ ] Add-ons: All running
- [ ] Test deployments: Successful

## Troubleshooting Commands
```bash
# Check cluster status
aws eks describe-cluster --name my-eks-cluster

# Check node group status
aws eks describe-nodegroup --cluster-name my-eks-cluster --nodegroup-name worker-nodes

# Check cluster autoscaler
kubectl get pods -n kube-system -l app=cluster-autoscaler
kubectl describe pod -n kube-system -l app=cluster-autoscaler

# Check add-ons
aws eks describe-addon --cluster-name my-eks-cluster --addon-name vpc-cni
```
