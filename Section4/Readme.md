# Section 4 - Creating AWS Resources (EKS, RDS, SSM)
## Setting up AWS CLI
- To create access keys for an IAM user
- Sign in to the AWS Management Console and open the IAM console.
- In the navigation pane, choose Users.
- Choose the name of the user whose access keys you want to create, and then choose the Security credentials tab.
- In the Access keys section, choose Create access key.
> To view the new access key pair, choose Show. You will not have access to the secret access key again after this dialog box closes. Your credentials will look something like this:
> 
> ```
> Access key ID: AKIAIOSFODNN7EXAMPLE`
>Secret access key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
> ```

To download the key pair, choose Download .csv file. Store the keys in a secure location.
- Open the terminal
- `aws configure` (When you enter this command, the AWS CLI prompts you for four pieces of information:
Access key ID Secret access key AWS Region Output format))
```
$ aws configure
AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
Default region name [None]: us-east-1
Default output format [None]: json
```
You're all set to use aws cli.
## Setting up the Cluster in AWS-EKS
Create the cluster using EKSCTL
```
cp Section4/cluster.yaml ./
eksctl create cluster -f cluster.yaml
eksctl utils associate-iam-oidc-provider --region us-east-1 --cluster airflow --approve
```
> **If you wish to deploy a cluster auto scaler (you should) for your cluster. Follow [Section6](./Section6.Readme.md) and then come back here**.
## Creating Postgres Database
Create RDS using Console
* Same VPC
* Same Security Group
* Set DB Identifier
* Set Username/Password
* Set DB name
* Set Region
Verify you get the endpoint 
```
aws rds describe-db-instances --db-instance-identifier airflow-db | jq -r '.DBInstances[0].Endpoint.Address'
```
## Using ParamStore
Now lets modify our script to use AWS SSM Paramstore
```
aws ssm put-parameter --name "/global/airflow/webserver/flask-secret-key" --value "1cdd4a48f6586831ac8d5921693d5ec0" --type "SecureString"
```
```
aws ssm get-parameter --name "parameter-name" --with-decryption --query Parameter.Value --output text
```
Some Parameters to be Stored
* Webserver Key     - `"/global/airflow/webserver/flask-secret-key"`
* Fernet Key        - `"/global/airflow/fernet-key"`
* Git KnownHosts    - `"/global/airflow/github/known-hosts"`
* Git Private Key   - `"/global/airflow/github/private-key"`
* DAG Repo URL      - `"/global/airflow/github/dags-repo"`
* DB Identifier     - `"/dev/airflow/rds/identifier"`
* DB Password       - `"/dev/airflow/rds/password"`
>```
># How to set multi line values like Privatekey, KnownHosts etc.
>
>VAL=$(cat helperChart/secrets/known_hosts)
>
>aws ssm put-parameter --name "/global/airflow/github/known-hosts" --value "$VAL" --type "SecureString"
```
aws ssm put-parameter --name "/global/airflow/webserver/flask-secret-key" --value "VALUE" --type "SecureString"
aws ssm put-parameter --name "/global/airflow/fernet-key" --value "VALUE" --type "SecureString"
KH=$(cat helperChart/secrets/known_hosts)
aws ssm put-parameter --name "/global/airflow/github/known-hosts" --value "$KH" --type "SecureString"
PK=$(cat ~/.ssh/id_rsa)
aws ssm put-parameter --name "/global/airflow/github/private-key" --value "$PK" --type "SecureString"
aws ssm put-parameter --name "/global/airflow/github/dags-repo" --value "VALUE" --type "SecureString"
aws ssm put-parameter --name "/dev/airflow/rds/identifier" --value "VALUE" --type "SecureString"
aws ssm put-parameter --name "/dev/airflow/rds/password" --value "VALUE" --type "SecureString"
```
## Modify the values.yaml file to Remove Postgres, Use RDS Connection Secrets
```
cp Section4/scripts ./ -r -f
cp Section4/yamls ./ -r -f
cp Section4/helperChart ./ -r -f
./scripts/deploy.sh
```
