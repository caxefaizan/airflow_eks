# udemy
Best Practices to Deploy a Production Grade Airflow

Dependencies:
* linux
* kubectl
* eksctl
* minikube
* helm
* jinja2
* docker

Follow the Respective Sections
* [Section1](./Section1/Readme.md) - Getting Started
* [Section2](./Section2/Readme.md) - Minimal Airflow Deployment (Minikube)
* [Section3](./Section3/Readme.md) - Creating Helper Chart using HELM
* [Section4](./Section4/Readme.md) - Creating AWS Resources (EKS, RDS, SSM)
* [Section5](./Section5/Readme.md) - Exposing the UI and Persisting Logs
* [Section6](./Section6/Readme.md) - Cluster Auto Scaler
* [Section7](./Section7/Readme.md) - Enabling TLS

## Uninstall Airflow
helm uninstall airflow -n airflow
## Delete RDS
aws rds delete-db-instance --db-instance-identifier=airflow-db --skip-final-snapshot
eksctl delete cluster --name airflow
## Delete EFS
## Delete EBS
## Delete EKS
## Delete EC2
## Delete SG
## Delete VPC
## Delete SSM
## Delete ACM
## Delete CloudFormation Stack
## Roles, Policies, SecurityGroups, RDS, EFS, EBS, EKS, EC2, SSM, ACM