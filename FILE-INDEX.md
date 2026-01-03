# EKS GUI Configuration - File Index

## Core Documentation
- `README.md` - Complete 4-phase EKS setup MOP
- `prerequisites-checklist.md` - Pre-setup requirements and validation
- `required-iam-roles.md` - IAM roles with trust policies
- `get-oidc-provider-gui.md` - OIDC provider information from GUI

## Configuration Files
- `cluster-role-trust-policy.json` - EKS cluster service role trust policy
- `node-role-trust-policy.json` - EKS node group role trust policy
- `cluster-autoscaler-policy-gui.json` - IAM policy for cluster autoscaler
- `launch-template-userdata.sh` - User data script for launch template

## Kubernetes Manifests
- `serviceaccount-gui.yaml` - Service account with IAM role annotation
- `rbac-gui.yaml` - RBAC configuration for cluster autoscaler
- `deployment-gui.yaml` - Cluster autoscaler deployment

## Additional Guides
- `security-groups.md` - Security group configuration
- `troubleshooting-guide.md` - Common issues and solutions
- `post-installation-config.md` - Post-setup configurations

## Usage Order
1. Review `prerequisites-checklist.md`
2. Follow `README.md` phases 1-4
3. Use `get-oidc-provider-gui.md` for OIDC setup
4. Reference `required-iam-roles.md` for IAM roles
5. Apply configurations from manifest files
6. Use `troubleshooting-guide.md` if issues arise
7. Implement `post-installation-config.md` enhancements

## Quick Start
For immediate setup, focus on:
- `README.md` (main procedure)
- `required-iam-roles.md` (IAM setup)
- `get-oidc-provider-gui.md` (OIDC for cluster autoscaler)
- Kubernetes manifest files (serviceaccount, rbac, deployment)
