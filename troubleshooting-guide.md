# Common Issues and Solutions

## Issue 1: Cluster Creation Fails
**Symptoms**: Cluster stuck in "Creating" state
**Solutions**:
- Check IAM role has `AmazonEKSClusterPolicy`
- Verify subnets are in different AZs
- Ensure VPC has DNS resolution enabled
- Check service-linked role permissions

## Issue 2: Nodes Not Joining Cluster
**Symptoms**: Nodes show as "NotReady" or don't appear
**Solutions**:
- Verify node IAM role has all 3 required policies
- Check security group allows cluster communication
- Ensure subnets have route to internet (via NAT Gateway)
- Verify launch template user data script

## Issue 3: Cluster Autoscaler Not Working
**Symptoms**: Pods pending, no new nodes created
**Solutions**:
- Check ASG tags are correct
- Verify IAM role for service account (IRSA) setup
- Ensure cluster autoscaler has proper permissions
- Check cluster autoscaler logs for errors

## Issue 4: Pod Identity/IRSA Issues
**Symptoms**: Pods can't access AWS services
**Solutions**:
- Verify OIDC provider is associated with cluster
- Check IAM role trust policy includes correct OIDC conditions
- Ensure service account annotation is correct
- Validate IAM policy permissions

## Issue 5: LoadBalancer Service Fails
**Symptoms**: External IP shows as "Pending"
**Solutions**:
- Check AWS Load Balancer Controller is installed
- Verify subnets are tagged for load balancer discovery
- Ensure security groups allow load balancer traffic
- Check IAM permissions for load balancer controller

## Issue 6: DNS Resolution Problems
**Symptoms**: Pods can't resolve service names
**Solutions**:
- Verify CoreDNS pods are running
- Check VPC DNS settings (enableDnsHostnames, enableDnsSupport)
- Ensure security groups allow DNS traffic (port 53)
- Restart CoreDNS deployment if needed

## Debugging Commands
```bash
# Check cluster status
kubectl get nodes
kubectl get pods --all-namespaces

# Check system pods
kubectl get pods -n kube-system

# Check cluster autoscaler
kubectl logs -n kube-system -l app=cluster-autoscaler

# Check node conditions
kubectl describe nodes

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp
```

## AWS Console Checks
- **EKS Console**: Cluster status, node group status
- **EC2 Console**: Instance status, security groups
- **IAM Console**: Role policies, trust relationships
- **VPC Console**: Route tables, NAT gateways
- **CloudWatch**: Log groups, metrics
