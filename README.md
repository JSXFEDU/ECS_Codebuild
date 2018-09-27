# ECS_Codebuild

In AWS China Region, there is no CodeBuild service currently. This project let you build docker image on ECS base on EC2, and push them to ECR.

在基于EC2的ECS上构建容器镜像，并将其推送至ECR。这是适用于AWS中国Region的解决方案。如果使用AWS Global，建议使用CodeBuild服务。

## How to use
Befor use this project, you should build it on your own PC and deploy it to your AWS account.

First, make sure you have configured aws cli correctly. Then run deploy.sh