#!/bin/bash
/etc/eks/bootstrap.sh my-eks-cluster
/opt/aws/bin/cfn-signal --exit-code $? --stack ${AWS::StackName} --resource NodeGroup --region ${AWS::Region}
