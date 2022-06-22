# Section 7 - CI/CD Pipeline

## Create CodePipeline
- Create CodePipeline
- Go to Services -> CodePipeline -> Create Pipeline
- **Pipeline Settings**
  - Pipeline Name: airflow-pipeline
  - Service Role: New Service Role (leave to defaults)
  - Role Name: Auto-populated
  - Rest all leave to defaults and click Next
- **Source**
  - Source Provider: GitHub (Version 2)
  - Connection -> Connect to GitHub
  - Connection name: Airflow-AWS-Connection -> Connect to GitHub
  - Install a new app -> Configure your account -> Only select repositories -> Select your airflow repo -> Save
  - Connect
  - Repository Name: repo_name
  - Branch Name: main
  - Rest leave to defaults
- **Build**
  - Build Provider:  AWS CodeBuild
  - Region: US East (N.Virginia)  
  - Project Name:  Click on **Create Project**
- **Create Build Project**
  - **Project Configuration**
    - Project Name: airflow-code-build
  - **Environment**
    - Environment Image: Managed Image
    - Operating System: Amazon Linux 2
    - Runtimes: Standard
    - Image: aws/codebuild/amazonlinux2-x86_64-standard:3.0
    - Image Version: Always use the latest version for this runtime
    - Environment Type: Linux
    - Privileged: Enable
    - Role Name: Auto-populated
    - All leave to defaults 
- Click on **Continue to CodePipeline**
- Click **Next**
- **Deploy**
  - Click on **Skip Deploy Stage**
- **Review**
  - Review and click on **Create Pipeline**

## Create the buildspec 
```
version: 0.2

env:
  variables:
    EKS_KUBECTL_ROLE_ARN: arn:aws:iam::YOUR_ACCOUNT_ID:role/EksCodeBuildKubectlRole
    EKS_CLUSTER_NAME: airflow
    AWS_DEFAULT_REGION: us-east-1

phases:
  pre_build:
    commands:
      - echo Entered the pre_build phase...
      - pip3 install j2cli
      - curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash -s -- --version v3.8.2
  build:
    commands:
      # Extracting AWS Credential Information using STS Assume Role for kubectl
      - echo "Setting Environment Variables related to AWS CLI for Kube Config Setup"          
      - CREDENTIALS=$(aws sts assume-role --role-arn $EKS_KUBECTL_ROLE_ARN --role-session-name codebuild-kubectl --duration-seconds 900)
      - export AWS_ACCESS_KEY_ID="$(echo ${CREDENTIALS} | jq -r '.Credentials.AccessKeyId')"
      - export AWS_SECRET_ACCESS_KEY="$(echo ${CREDENTIALS} | jq -r '.Credentials.SecretAccessKey')"
      - export AWS_SESSION_TOKEN="$(echo ${CREDENTIALS} | jq -r '.Credentials.SessionToken')"
      - export AWS_EXPIRATION=$(echo ${CREDENTIALS} | jq -r '.Credentials.Expiration')
      # Setup kubectl with our EKS Cluster              
      - echo "Update Kube Config"      
      - aws eks update-kubeconfig --name $EKS_CLUSTER_NAME
      - echo Build started on `date`
      - chmod 777 ./scripts/deploy.sh
      - ./scripts/deploy.sh
  post_build:
    commands:
      - echo Build completed on `date`
```

> The pipeline will fail as our role does not have permission to assume `sts assume role`
>
>`An error occurred (AccessDenied) when calling the AssumeRole operation: User: arn:aws:sts::YOUR_ACCOUNT_ID:assumed-role/codebuild-airflow-codebuild-service-role/AWSCodeBuild-f417c41f-5b04-44d5-bc85-e6967df26bfb is not authorized to perform: sts:AssumeRole on resource: arn:aws:iam::YOUR_ACCOUNT_ID:role/EksCodeBuildKubectlRole`
## Create STS Assume IAM Role for CodeBuild to interact with AWS EKS
- In an AWS CodePipeline, we are going to use AWS CodeBuild to deploy changes to our Kubernetes manifests. 
- This requires an AWS IAM role capable of interacting with the EKS cluster.
- In this step, we are going to create an IAM role and add an inline policy `EKS:Describe` that we will use in the CodeBuild stage to interact with the EKS cluster via kubectl.
```
# Export your Account ID
export ACCOUNT_ID=YOUR_ACCOUNT_ID

# Set Trust Policy
TRUST="{ \"Version\": \"2012-10-17\", \"Statement\": [ { \"Effect\": \"Allow\", \"Principal\": { \"AWS\": \"arn:aws:iam::${ACCOUNT_ID}:root\" }, \"Action\": \"sts:AssumeRole\" } ] }"

# Verify inside Trust policy, your account id got replacd
echo $TRUST

# Create IAM Role for CodeBuild to Interact with EKS
aws iam create-role --role-name EksCodeBuildKubectlRole --assume-role-policy-document "$TRUST" --output text --query 'Role.Arn'

# Define Inline Policy with eks Describe permission in a file iam-eks-describe-policy
echo '{ "Version": "2012-10-17", "Statement": [ { "Effect": "Allow", "Action": "eks:Describe*", "Resource": "*" },{"Effect": "Allow", "Action": "ssm:GetParameter", "Resource": "*" },{ "Effect": "Allow", "Action": "rds:DescribeDBInstances", "Resource": "*" } ] }' > /tmp/iam-eks-describe-policy

# Associate Inline Policy to our newly created IAM Role
aws iam put-role-policy --role-name EksCodeBuildKubectlRole --policy-name eks-describe --policy-document file:///tmp/iam-eks-describe-policy
```

## Update CodeBuild Role to have access to STS Assume Role we have created STS Assume Role Policy
### Create STS Assume Role Policy
- Go to Services IAM -> Policies -> Create Policy
- In **Visual Editor Tab**
- Service: STS
- Actions: Under Write - Select `AssumeRole`
- Resources: Specific
  - Add ARN
  - Specify ARN for Role: arn:aws:iam::YOUR_ACCOUNT_ID:role/EksCodeBuildKubectlRole
  - Click Add
  - Click Next
- Click on Review Policy  
- Name: eks-codebuild-sts-assume-role
- Description: CodeBuild to interact with EKS cluster to perform changes
- Click on **Create Policy**

### Associate Policy to CodeBuild Role
IAM > Roles > `codebuild-airflow-codebuild-service-role`
- Role Name: `codebuild-airflow-codebuild-service-role`
- Policy to be associated:  `eks-codebuild-sts-assume-role`
- Click on Add Permissions > Attach Policies
- Search `eks-codebuild-sts-assume-role` > Select > Attach Policies

## Update EKS Cluster aws-auth ConfigMap with new role created in previous step
- We are going to add the role to the `aws-auth ConfigMap` for the EKS cluster.
- Once the `EKS aws-auth ConfigMap` includes this new role, kubectl in the CodeBuild stage of the pipeline will be able to interact with the EKS cluster via the IAM role.
```
# Verify what is present in aws-auth configmap before change
kubectl get configmap aws-auth -o yaml -n kube-system

# Export your Account ID
export ACCOUNT_ID=YOUR_ACCOUNT_ID

# Set ROLE value
ROLE="    - rolearn: arn:aws:iam::$ACCOUNT_ID:role/EksCodeBuildKubectlRole\n      username: build\n      groups:\n        - system:masters"

# Get current aws-auth configMap data and attach new role info to it
kubectl get -n kube-system configmap/aws-auth -o yaml | awk "/mapRoles: \|/{print;print \"$ROLE\";next}1" > /tmp/aws-auth-patch.yml

# Patch the aws-auth configmap with new role
kubectl patch configmap/aws-auth -n kube-system --patch "$(cat /tmp/aws-auth-patch.yml)"
```

> Make sure you have all the Airflow config (as given below) done until now in your repo attached to code pipeline.
> 
```
- root/
  - helperChart/
    - templates/
      - efs.yaml
      - namespace.yaml
      - secrets.yaml
    - Chart.yaml
    - values.yaml
  - scripts/
    - config.sh
    - create_conn_uri.py
    - deploy.sh
    - eks-login.sh
  - yamls/
    - values.yaml.j2
  - buildspec.yaml
  - cluster.yaml
```
Commit to the repository and thats it.
