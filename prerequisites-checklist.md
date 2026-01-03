# Prerequisites Checklist for EKS GUI Setup

## AWS Account Requirements
- [ ] AWS Account with appropriate permissions
- [ ] IAM user/role with EKS, EC2, IAM permissions
- [ ] AWS CLI configured (for kubeconfig update)
- [ ] kubectl installed locally

## Network Prerequisites
- [ ] VPC with public and private subnets
- [ ] Minimum 2 Availability Zones
- [ ] Internet Gateway attached to VPC
- [ ] NAT Gateway in public subnets (for private subnet internet access)
- [ ] Route tables configured properly
- [ ] Security groups allowing required traffic

## VPC Requirements
**CIDR Blocks:**
- VPC CIDR: e.g., `10.0.0.0/16`
- Public Subnets: e.g., `10.0.1.0/24`, `10.0.2.0/24`
- Private Subnets: e.g., `10.0.10.0/24`, `10.0.20.0/24`

**Security Groups:**
- EKS Cluster Security Group (auto-created)
- Worker Node Security Group
- Additional application security groups as needed

## Tools Required
- [ ] Web browser for AWS Console access
- [ ] Kubernetes Dashboard, Lens, or Rancher (for K8s management)
- [ ] Text editor for YAML files
- [ ] Terminal access for kubectl commands

## Permissions Required
**IAM Permissions for User/Role:**
- `eks:*`
- `ec2:*`
- `iam:CreateRole`, `iam:AttachRolePolicy`, `iam:CreateInstanceProfile`
- `autoscaling:*`
- `cloudformation:*` (if using CFN templates)

## Cost Considerations
**Estimated Monthly Costs:**
- EKS Cluster: $73.00/month
- EC2 Instances (2x t3.medium): ~$60/month
- EBS Storage: ~$10/month
- NAT Gateway: ~$45/month
- **Total**: ~$188/month (us-west-2 pricing)

## Pre-Setup Validation
```bash
# Verify AWS CLI access
aws sts get-caller-identity

# Check available regions
aws ec2 describe-regions --query 'Regions[].RegionName'

# Verify VPC exists
aws ec2 describe-vpcs --query 'Vpcs[].{VpcId:VpcId,CidrBlock:CidrBlock}'
```
