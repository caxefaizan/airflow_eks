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
Section1 - Setup
Section2 - Minimal Airflow Deployment (Minikube)
Section3 - Helper Chart
Section4 - Creating AWS Resources
Section5 - Ingress and EFS
Section6 - Auto Scaling
Section7 - Enabling TLS

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