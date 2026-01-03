# Required IAM Roles for EKS

## 1. EKS Cluster Service Role
**Role Name**: `AmazonEKSClusterServiceRole`
**Trusted Entity**: `eks.amazonaws.com`
**Trust Policy**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```
**Managed Policies**:
- `AmazonEKSClusterPolicy`

## 2. EKS Node Group Role
**Role Name**: `AmazonEKSNodeGroupRole`
**Trusted Entity**: `ec2.amazonaws.com`
**Trust Policy**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```
**Managed Policies**:
- `AmazonEKSWorkerNodePolicy`
- `AmazonEKS_CNI_Policy`
- `AmazonEC2ContainerRegistryReadOnly`

## 3. EKS Node Instance Profile
**Instance Profile Name**: `AmazonEKSNodeInstanceProfile`
**Role**: `AmazonEKSNodeGroupRole`

## GUI Creation Steps

### Create Cluster Role:
1. **IAM** → **Roles** → **Create Role**
2. **Trusted Entity**: AWS Service → EKS
3. **Use Case**: EKS - Cluster
4. **Permissions**: AmazonEKSClusterPolicy (auto-attached)
5. **Role Name**: `AmazonEKSClusterServiceRole`

### Create Node Group Role:
1. **IAM** → **Roles** → **Create Role**
2. **Trusted Entity**: AWS Service → EC2
3. **Permissions**: Attach all three policies:
   - AmazonEKSWorkerNodePolicy
   - AmazonEKS_CNI_Policy
   - AmazonEC2ContainerRegistryReadOnly
4. **Role Name**: `AmazonEKSNodeGroupRole`

### Create Instance Profile:
1. **IAM** → **Instance Profiles** → **Create**
2. **Name**: `AmazonEKSNodeInstanceProfile`
3. **Add Role**: `AmazonEKSNodeGroupRole`
