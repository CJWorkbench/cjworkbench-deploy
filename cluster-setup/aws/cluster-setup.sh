#!/bin/bash

#echo 'This is more of a _log_ than an actual script you should run.'
#echo 'Exiting, to avoid breaking things in production.'
#exit 1

set -e
set -x
set -u  # unbound variables => error

type aws
type eksctl
type jq

ENV="production"  # "staging" or "production"
CLUSTER_NAME="workbench"
AWS_REGION=us-east-1
KUBERNETES_VERSION=1.20
$DOMAIN_NAME  # or exit
$ZONE_NAME  # or exit
DIR="$(dirname "$0")"

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"

eksctl create cluster \
  --name $CLUSTER_NAME \
  --version "$KUBERNETES_VERSION" \
  --with-oidc \
  --without-nodegroup \
  --disable-pod-imds

for service in frontend fetcher renderer cron migrate tusd; do
  aws iam create-policy \
    --policy-name $CLUSTER_NAME-$service-policy \
    --policy-document file://"$DIR"/iam/$service-policy.json

  eksctl create iamserviceaccount \
    --name $service-sa \
    --namespace default \
    --cluster $CLUSTER_NAME \
    --attach-policy-arn "arn:aws:iam::$ACCOUNT_ID:policy/$CLUSTER_NAME-$service-policy" \
    --approve \
    --override-existing-serviceaccounts
done

# TODO XXX SECURITY: disable SMT in frontend+fetcher+renderer node pools, like we do on GCP
# Research https://github.com/weaveworks/eksctl/pull/578/files
eksctl create nodegroup \
  --cluster $CLUSTER_NAME \
  --name ng-demand-v1 \
  --nodes-max 4 \
  --disable-pod-imds \
  --managed \
  --instance-types t3.large

eksctl create nodegroup \
  --cluster $CLUSTER_NAME \
  --name ng-spot-v2 \
  --nodes-max 4 \
  --disable-pod-imds \
  --managed \
  --instance-types m5d.large,m5a.large,m5.large,m4.large \
  --spot

# Install cluster autoscaler
# https://docs.aws.amazon.com/eks/latest/userguide/cluster-autoscaler.html
aws iam create-policy \
    --policy-name AmazonEKSClusterAutoscalerPolicy \
    --policy-document file://"$DIR"/cluster-autoscaler-policy.json
eksctl create iamserviceaccount \
  --cluster=workbench \
  --namespace=kube-system \
  --name=cluster-autoscaler \
  --attach-policy-arn=arn:aws:iam::$ACCOUNT_ID:policy/AmazonEKSClusterAutoscalerPolicy \
  --override-existing-serviceaccounts \
  --approve
kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml
kubectl patch deployment cluster-autoscaler \
  -n kube-system \
  -p '{"spec":{"template":{"metadata":{"annotations":{"cluster-autoscaler.kubernetes.io/safe-to-evict": "false"}}}}}'
kubectl patch deployment cluster-autoscaler \
  -n kube-system \
  -p'{"spec":{"template":{"spec":{"containers":[{"name":"cluster-autoscaler","command":["./cluster-autoscaler","--v=4","--stderrthreshold=info","--aws-use-static-instance-list=true","--cloud-provider=aws","--skip-nodes-with-local-storage=false","--expander=least-waste","--node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/workbench","--balance-similar-node-groups","--skip-nodes-with-system-pods=false"]}]}}}}'
kubectl set image deployment cluster-autoscaler \
  -n kube-system \
  cluster-autoscaler=k8s.gcr.io/autoscaling/cluster-autoscaler:v1.20.0


source "$DIR"/01-storage.sh
source "$DIR"/02-sql.sh
source "$DIR"/03-rabbitmq.sh
source "$DIR"/04-secrets.sh
source "$DIR"/05-aws-load-balancer.sh
source "$DIR"/06-ssl.sh
source "$DIR"/07-smtp.sh

# Migrate database and spin up servers
"$DIR"/../../advanced-deploy \
  workbench.$AWS_REGION.eksctl.io \
  f4fe78282b32339d3d00126a89bc4ea8e9bdce8d
