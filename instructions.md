# Instructions

## Getting Started

Please [install](https://github.com/smart-patrol/pytorch-serve-eks/blob/master/installation.md) required packages to complete this walkthrough.

## Setup Environment Variables

```
export AWS_ACCOUNT=<ACCOUNT ID>
export AWS_REGION=<AWS REGION>
export K8S_MANIFESTS_DIR=<Absolute path to store manifests>
export AWS_CLUSTER_NAME=<Name for the AWS EKS cluster>
export PT_SERVE_NAME=<Name of TorchServe in the EKS>
```

## Create EKS manifest files

```
git clone https://github.com/aws-samples/torchserve-eks

cd torchserve-eks

./pt_serve_util.sh
```

## Setup IAM Roles and Policies

An IAM user needs certain AWS resource permissions to set up the EKS cluster for TorchServe. However, if you set up the TorchServe EKS cluster using an AWS Admin account, this step on IAM policies should be skipped and jump directly to Step **Subscribe to EKS-optimized AMI with GPU Support in the AWS Marketplace** below.

(A pre-requisite to this step is having an IAM User named "*EKSUser*". To see how to create an IAM User see [Creating an IAM User](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html))

The following two steps require admin privilege

### Create IAM Policy

```
aws iam create-policy --policy-name eks_ami_policy \
    --policy-document file://eks_ami_policy.json
```

### Attach policy to user
```
aws iam attach-user-policy \
    --policy-arn arn:aws:iam::${AWS_ACCOUNT}:policy/eks_ami_policy \
    --user-name EKSUser
```

## Switch User
If the user designated to set up the TorchServe EKS cluster is *EKSUser*, switch to *EKSUser* for both AWS API and AWS Console interactions in order to execute all of the following steps.

## Subscribe to EKS-optimized AMI with GPU Support in the AWS Marketplace

Subscribe [here](https://aws.amazon.com/marketplace/pp/B07GRHFXGM)

<!---
## Building and Hosting the Docker Image

```
./build_push.sh
```
--->

## Creating an EKS Cluster

```
eksctl create cluster -f ${K8S_MANIFESTS_DIR}/cluster.yaml
```

## Install NVIDIA device plugin for Kubernetes

```
kubectl apply -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/master/deployments/static/nvidia-device-plugin.yml

kubectl get daemonset -n kube-system
```

## Deploy Pods to EKS cluster

```
NAMESPACE=pt-inference; kubectl create namespace ${NAMESPACE}

kubectl -n ${NAMESPACE} apply -f ${K8S_MANIFESTS_DIR}/pt_inference.yaml

kubectl get pods -n ${NAMESPACE}
```
Wait to proceed until you see `STATUS=Running`

## Setup Logging on CloudWatch

```
./cloud_watch_util.sh
```

Check out logs at: `/aws/containerinsights/${AWS_CLUSTER_NAME}/application/${PT_SERVE_NAME}*`

## Register Models with TorchServe

```
EXTERNAL_IP=`kubectl get svc -n ${NAMESPACE} -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}'`

response=$(curl --write-out %{http_code} --silent --output /dev/null --retry 5 -X POST "http://${EXTERNAL_IP}:8081/models?url=https://torchserve.s3.amazonaws.com/mar_files/resnet-18.mar&initial_workers=1&synchronous=true")

if [ ! "$response" == 200 ]
then
    echo "failed to register model with torchserve"
else
    echo "successfully registered model with torchserve"
fi
```

Optional, if you want to use port forwarding:

```
kubectl port-forward -n ${NAMESPACE} `kubectl get pods -n ${NAMESPACE} --selector=app=densenet-service -o jsonpath='{.items[0].metadata.name}'` 8080:8080 8081:8081 &
```

## Inference on Endpoint

```
# Get a sample image
wget https://raw.githubusercontent.com/pytorch/serve/master/docs/images/kitten_small.jpg

curl -X POST http://${EXTERNAL_IP}:8080/predictions/resnet-18 -T kitten_small.jpg
```

List out models.

```
curl -X GET http://${EXTERNAL_IP}:8081/models/
```

## Cleaning up

```
./delete_cluster.sh
```
