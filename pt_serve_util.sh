#!/usr/bin/env bash
# Util functions to be used by scripts in this directory

replace_text_in_file() {
  local FIND_TEXT=$1
  local REPLACE_TEXT=$2
  local SRC_FILE=$3

  sed -i.bak "s ${FIND_TEXT} ${REPLACE_TEXT} g" ${SRC_FILE}
  rm $SRC_FILE.bak
}

check_installed_deps() {
  declare -a pt_deps=("aws" "eksctl" "kubectl")

  for pt_dep in "${pt_deps[@]}"; do
    if ! which "${pt_dep}" &>/dev/null && ! type -a "${pt_dep}" &>/dev/null ; then
      echo "You don't have ${pt_dep} installed. Please install ${pt_dep}."
      exit 1
    fi
  done
}

check_aws_iam_authenticator() {
  if ! which "aws-iam-authenticator" &>/dev/null && ! type -a "aws-iam-authenticator" &>/dev/null ; then
    echo "You don't have aws-iam-authenticator installed. Please install aws-iam-authenticator. https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html"
    exit 1
  fi
}

check_env_variables() {
  if [ -z ${K8S_MANIFESTS_DIR+x} ]; then 
    echo "K8S_MANIFESTS_DIR is unset"
    exit 1
  else 
    echo "K8S_MANIFESTS_DIR is set to '$K8S_MANIFESTS_DIR'"; 
  fi

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

  if [ -z ${AWS_ACCOUNT+x} ]; then 
    echo "AWS_ACCOUNT is unset"
    exit 1
  else 
    echo "AWS_ACCOUNT is set to '$AWS_ACCOUNT'"; 
  fi

  if [ -z ${PT_SERVE_NAME+x} ]; then 
    echo "PT_SERVE_NAME is unset"
    exit 1
  else 
    echo "PT_SERVE_NAME is set to '$PT_SERVE_NAME'"; 
  fi
}

## Prepare Infrastrcture Configurations
generate_aws_infra_configs() {
  # Create the infrastructure configs if they don't exist.
  if [ ! -d "${K8S_MANIFESTS_DIR}" ]; then
    echo "Creating AWS infrastructure configs in directory ${K8S_MANIFESTS_DIR}"
    mkdir -p "${K8S_MANIFESTS_DIR}"
  else
    echo AWS infrastructure configs already exist in directory "${K8S_MANIFESTS_DIR}"
  fi

  # copy template yaml files into the manifest dir
  cp template/pt_inference.yaml ${K8S_MANIFESTS_DIR}/pt_inference.yaml
  cp template/cluster.yaml ${K8S_MANIFESTS_DIR}/cluster.yaml
  cp template/eks_ami_policy.json eks_ami_policy.json

  # Replace placehold with user configurations
  replace_text_in_file "your_cluster_name" ${AWS_CLUSTER_NAME} ${K8S_MANIFESTS_DIR}/cluster.yaml
  replace_text_in_file "your_cluster_region" ${AWS_REGION} ${K8S_MANIFESTS_DIR}/cluster.yaml

  image=torchserve
  # Get account and region (must have previously configured your AWS cli)
  # account=$(aws sts get-caller-identity --query Account --output text)
  #region=$(aws configure get region)
  IMAGE_URI="${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/${image}"
  replace_text_in_file "your_image_ecr_uri" ${IMAGE_URI} ${K8S_MANIFESTS_DIR}/pt_inference.yaml
  replace_text_in_file "your_service_name" ${PT_SERVE_NAME} ${K8S_MANIFESTS_DIR}/pt_inference.yaml
  replace_text_in_file '{$REGION}' ${AWS_REGION} eks_ami_policy.json
  replace_text_in_file '{$ACCOUNT}' ${AWS_ACCOUNT} eks_ami_policy.json
}

check_installed_deps
check_aws_iam_authenticator
check_env_variables
generate_aws_infra_configs
