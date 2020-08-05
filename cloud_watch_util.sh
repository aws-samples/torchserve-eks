#!/usr/bin/env bash
# Util functions to be used by scripts in this directory

replace_text_in_file() {
  local FIND_TEXT=$1
  local REPLACE_TEXT=$2
  local SRC_FILE=$3

  sed -i.bak "s ${FIND_TEXT} ${REPLACE_TEXT} g" ${SRC_FILE}
  rm $SRC_FILE.bak
}

attach_inline_policy() {
  declare -r POLICY_NAME="$1" POLICY_DOCUMENT="$2" IAM_ROLE="$3"
  echo "Attach inline policy $POLICY_NAME for iam role $IAM_ROLE"
  if ! aws iam put-role-policy --role-name $IAM_ROLE --policy-name $POLICY_NAME --policy-document file://${POLICY_DOCUMENT}; then
      echo "Unable to attach iam inline policy $POLICY_NAME to role $IAM_ROLE" >&2
      exit 1
  fi
}

get_node_instance_role() {
    # i.e. convert from
    # ARN												USERNAME				GROUPS
    # arn:aws:iam::12345:role/eksctl-my-cluster-nodegroup-Gpu-NodeInstanceRole-ABCDEFG	system:node:{{EC2PrivateDNSName}}	system:bootstrappers,system:nodes
    # 
    # to
    # eksctl-my-cluster-nodegroup-Gpu-NodeInstanceRole-ABCDEFG
    echo "Getting NodeInstanceRoleName"
    export NODE_INSTANCE_ROLE_NAME=$(eksctl get iamidentitymapping --cluster $AWS_CLUSTER_NAME | tail -1 | cut -f1  | cut -f2 -d/)
    echo "NodeInstanceRoleName: $NODE_INSTANCE_ROLE_NAME"
  
}

if [ -z ${AWS_CLUSTER_NAME+x} ]; then
    echo "AWS_CLUSTER_NAME is unset"
    exit 1
  else 
    echo "AWS_CLUSTER_NAME is set to '$AWS_CLUSTER_NAME'"; 
fi

if [ -z ${AWS_REGION+x} ]; then 
    echo "AWS_REGION is unset"
    exit 1
  else 
    echo "AWS_REGION is set to '$AWS_REGION'"; 
fi

get_node_instance_role

if [[ -z "$NODE_INSTANCE_ROLE_NAME" ]]; then
    echo "NODE_INSTANCE_ROLE_NAME cannot be empty."
    exit 1
fi

cp template/cloud_watch_policy.json cloud_watch_policy.json
replace_text_in_file '{$AWS_CLUSTER_NAME}' ${AWS_CLUSTER_NAME} cloud_watch_policy.json
attach_inline_policy cw-log-policy cloud_watch_policy.json $NODE_INSTANCE_ROLE_NAME

# check https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights-setup-EKS-quickstart.html
curl https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluentd-quickstart.yaml \
| sed "s/{{cluster_name}}/${AWS_CLUSTER_NAME}/;s/{{region_name}}/${AWS_REGION}/" | kubectl apply -f -