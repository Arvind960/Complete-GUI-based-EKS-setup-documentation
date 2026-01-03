# Security Groups for EKS

## 1. EKS Cluster Security Group (Auto-created)
**Name**: `eks-cluster-sg-CLUSTER-NAME-*`
**Description**: EKS created security group applied to ENI that is attached to EKS Control Plane master nodes
**Rules**: Managed automatically by EKS

## 2. Worker Node Security Group
**Name**: `eks-worker-node-sg`
**Description**: Security group for EKS worker nodes

### Inbound Rules:
| Type | Protocol | Port Range | Source | Description |
|------|----------|------------|---------|-------------|
| All Traffic | All | All | Cluster Security Group | Allow all from cluster |
| HTTPS | TCP | 443 | 0.0.0.0/0 | HTTPS access |
| SSH | TCP | 22 | Your IP/CIDR | SSH access (optional) |

### Outbound Rules:
| Type | Protocol | Port Range | Destination | Description |
|------|----------|------------|-------------|-------------|
| All Traffic | All | All | 0.0.0.0/0 | Allow all outbound |

## 3. Additional Security Group (Optional)
**Name**: `eks-additional-sg`
**Description**: Additional security group for specific application requirements

### Common Ports:
- **HTTP**: 80
- **HTTPS**: 443
- **NodePort Range**: 30000-32767
- **Kubelet API**: 10250
- **DNS**: 53

## GUI Creation Steps:
1. **EC2 Console** → **Security Groups** → **Create Security Group**
2. **Name**: `eks-worker-node-sg`
3. **VPC**: Select your EKS VPC
4. **Add Rules**: As per table above
5. **Create Security Group**
