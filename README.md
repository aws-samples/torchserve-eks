# Running TorchServe on Amazon Amazon Elastic Kubernets Service

![alt text](https://github.com/smart-patrol/pytorch-serve-eks/blob/master/img/TorchServeOnAWS.png)

[TorchServe](https://github.com/pytorch/serve) makes it easy to deploy and manage PyTorch models at scale in production environments. TorchServe is built and maintained by AWS in collaboration with Facebook and is available as part of the PyTorch open-source project. 

TorchServe supports any machine learning environment including, [Amazon Elastic Kubernets Service (EKS)](https://aws.amazon.com/eks/).

## The benefits of TorchServe

TorchServe makes it easy to deploy PyTorch models at scale in production environments. It delivers lightweight serving with low latency, so you can deploy your models for high performance inference. It provides default handlers for the most common applications such as object detection and text classification, so you don’t have to write custom code to deploy your models. With powerful TorchServe features including multi-model serving, model versioning for A/B testing, metrics for monitoring, and RESTful endpoints for application integration, you can take your models from research to production quickly. TorchServe supports any machine learning environment, including Amazon SageMaker, Kubernetes, Amazon EKS, and Amazon EC2.  

## The benefits of Amazon EKS

Amazon EKS takes advantage of the fact that it is running in the AWS cloud making great use of many AWS services and features, while ensuring that everything you already know about Kubernetes remains applicable and helpful. EKS is deeply integrated with services such as Amazon CloudWatch, Auto Scaling Groups, AWS Identity and Access Management (IAM), and Amazon Virtual Private Cloud (VPC), providing you a seamless experience to monitor, scale, and load-balance your applications. 

## The directory structure of this repository
``` bash
├── LICENSE                                 
├── README.md
├── cloud_watch_util.sh                     # Script to set up CloudWatch logs
├── delete_cluster.sh                       # Script to tear down the EKS cluster
├── img
│   ├── EKSCTL.png
│   └── TorchServeOnAWS.png
├── installation.md                         # How to install command line tools
├── instructions.md                         # Step-by-step setup instructions
├── pt_serve_util.sh                        # Script to auto-gen manifest files
└── template                                # A directory with all template files
    ├── cloud_watch_policy.json             # IAM CloudWatch policy template            
    ├── cluster.yaml                        # EKS cluster manifest template
    ├── eks_ami_policy.json                 # IAM user policy template 
    └── pt_inference.yaml                   # TorchServe manifest template
```
