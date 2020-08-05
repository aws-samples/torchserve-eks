#!/usr/bin/env bash
# Util script for tearing down the cluster
NODE_INSTANCE_ROLE_NAME=$(eksctl get iamidentitymapping --cluster $AWS_CLUSTER_NAME | tail -1 | cut -f1  | cut -f2 -d/)                                              
aws iam delete-role-policy --role-name ${NODE_INSTANCE_ROLE_NAME} --policy-name cw-log-policy                                                                              
eksctl delete cluster --name ${AWS_CLUSTER_NAME}
