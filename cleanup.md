Uninstall Airflow
helm uninstall airflow -n airflow
aws rds delete-db-instance --db-instance-identifier=airflow-db --skip-final-snapshot
eksctl delete cluster --name airflow

## Roles, Policies, SecurityGroups, RDS, EFS, EBS, EKS, EC2 LoadBalancers, Params

