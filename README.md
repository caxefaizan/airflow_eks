# Deploying a Production Grade Airflow 2.3.x on AWS-EKS

## Dependencies:
* linux
* kubectl
* eksctl
* minikube
* helm
* jinja2
* git
* awscli

## Sections
* [Section1](./Section1/Readme.md) - Getting Started
* [Section2](./Section2/Readme.md) - Local Airflow Deployment (Minikube)
* [Section3](./Section3/Readme.md) - Creating Helper Chart using HELM
* [Section4](./Section4/Readme.md) - Creating AWS Resources (EKS, RDS, SSM)
* [Section5](./Section5/Readme.md) - Exposing the UI and Persisting Logs
* [Section6](./Section6/Readme.md) - Cluster Auto Scaler
* [Section7](./Section7/Readme.md) - CI/CD Pipeline
* [Section8](./Section8/Readme.md) - Enabling SSL (Optional)

## Cleanup
**Do remember to clean up the resources to avoid being billed for when not in use.**

Following items are a reminder to make sure you delete them.

## Delete EKS
    - eksctl delete cluster --name airflow
## Delete RDS
    - Databases
## Delete EC2 resources
    - Volumes 
    - Load Balancers
    - Instances
    - Security Group
## Delete EFS
    - File Systems
## Delete SystemsManager
    - Parameter Store
        - Parameters
## Delete ACM
    - Certificates
## Delete EKS CloudFormation Stack
    - Stacks
## Delete CodePipeline
    - Pipeline
## Delete CodeBuild
    - Build Project
    - Connections
## Delete IAM
    - Roles
    - Policies
## Delete VPC
