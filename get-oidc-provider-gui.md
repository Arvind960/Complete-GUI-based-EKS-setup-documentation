# Get OIDC Provider Information from GUI

## Method 1: EKS Console
1. **EKS Console** → **Clusters** → Select your cluster
2. **Overview** tab → **Details** section
3. **OpenID Connect provider URL** - Copy this URL
4. **Example**: `https://oidc.eks.us-west-2.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E`

## Method 2: IAM Console
1. **IAM Console** → **Identity providers**
2. Look for provider with type **OpenID Connect**
3. **Provider URL** matches your EKS cluster region
4. **Provider ARN**: `arn:aws:iam::ACCOUNT-ID:oidc-provider/oidc.eks.REGION.amazonaws.com/id/OIDC-ID`

## Method 3: CloudFormation Console (if cluster created via CFN)
1. **CloudFormation Console** → **Stacks**
2. Select your EKS cluster stack
3. **Outputs** tab → Look for **OIDCIssuerURL**

## Extract OIDC ID from URL
**From**: `https://oidc.eks.us-west-2.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E`
**OIDC ID**: `EXAMPLED539D4633E53DE1B716D3041E`

## Use in IAM Role Trust Policy
**Identity Provider**: `arn:aws:iam::YOUR-ACCOUNT-ID:oidc-provider/oidc.eks.REGION.amazonaws.com/id/OIDC-ID`

**Condition**:
- **Key**: `oidc.eks.REGION.amazonaws.com/id/OIDC-ID:sub`
- **Value**: `system:serviceaccount:kube-system:cluster-autoscaler`
