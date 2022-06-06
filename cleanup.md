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
## Roles, Policies, SecurityGroups, RDS, EFS, EBS, EKS, EC2 LoadBalancers, Params

