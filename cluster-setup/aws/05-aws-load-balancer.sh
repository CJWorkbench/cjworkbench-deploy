# ref: https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html

curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.2.0/docs/install/iam_policy.json

aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

rm -f iam_policy.json

eksctl create iamserviceaccount \
  --cluster="$CLUSTER_NAME" \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::"$ACCOUNT_ID":policy/AWSLoadBalancerControllerIAMPolicy \
  --override-existing-serviceaccounts \
  --approve          

kubectl apply \
  --validate=false \
  -f https://github.com/jetstack/cert-manager/releases/download/v1.4.0/cert-manager.yaml

curl -o awslb.yaml https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.2.1/docs/install/v2_2_1_full.yaml

# Nix ServiceAccount from file (we already created it)
perl -0777 -p -e 's/---\napiVersion: v1\nkind: ServiceAccount.*?---/---/s' < awslb.yaml > awslb-noserviceaccount.yaml
# Add cluster name, region, VPC ID
vpc_id="$(aws ec2 describe-vpcs --filter Name=tag:alpha.eksctl.io/cluster-name,Values=workbench | jq -r .Vpcs[0].VpcId)"
sed -i -e "s/        - --cluster-name=your-cluster-name/        - --cluster-name=$CLUSTER_NAME\n        - --aws-region=$AWS_REGION\n        - --aws-vpc-id=$vpc_id/" awslb-noserviceaccount.yaml

kubectl apply -f awslb-noserviceaccount.yaml

rm -f awslb.yaml awslb-noserviceaccount.yaml
