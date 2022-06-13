# Section 2 - Minimal Airflow Deployment (Minikube)
## Create a local Cluster
```
# Start a local CLuster
minikube start
# Check if Cluster is running and kubectl is working
minikube status
kubectl cluster-info
```
```
# Install Airflow using Helm
helm repo add apache-airflow https://airflow.apache.org
helm upgrade --install airflow apache-airflow/airflow \
    --set executor=LocalExecutor \
    --set triggerer.enabled=false \
    --set statsd.enabled=false \
    --debug
```
And thats it we have Airflow Installed and you can access the UI by running
```
kubectl port-forward svc/airflow-webserver 8080:8080 --namespace default
```
and opening up `localhost:8080` on your web browser and using `admin` as your default username and password.

>This is where all the meat lies. But from now onwards we will build a production grade Airflow deployment that follows the best practices as described [here](https://airflow.apache.org/docs/helm-chart/stable/production-guide.html).

# Production Grade Deployment

To make use of a single script that manages Airflow across all environments, we will be using Helm to create a Helper Chart that will seamlessly manage all the resources required for Airflow across all environments.

> We're using Helm because a production grade Airflow requires various Kubernetes objects such as secrets, namespace, persistent volumes etc. and it would be tedious to manage them both imperatively and declaratively across different environments such as [ Dev | Test | Prod ]. 

To create the Helper Chart we need to follow the directory structure as described [here](https://helm.sh/docs/chart_template_guide/getting_started/).

Follow the commands as below
```
# Copy the directory structure
cp Section2/helperChart/ ./ -r
```
## Create Airflow Secrets
```
# SetUp Git Access Keys
ssh-keygen -t rsa -b 2048
cp ~/.ssh/id_rsa ./helperChart/secrets/id_rsa

# Add the following Public Key to your Github Account under Settings > SSH and GPG Keys > New SSH Key
cat ~/.ssh/id_rsa.pub 

# Setup Fernet Key
python3 -c 'from cryptography.fernet import Fernet; fernet_key = Fernet.generate_key(); print(fernet_key.decode())' > ./helperChart/secrets/fernet_key

# Setup Webserver Key
python3 -c 'import secrets; print(secrets.token_hex(16))' > ./helperChart/secrets/webserver_key

# Setup Known Hosts
ssh-keyscan -t rsa github.com > ./helperChart/secrets/known_hosts
```
>Note: Make sure you store these keys safely for future use

Now lets create the scipt to make use of our Helper Chart
```
cp Section2/scripts ./ -r
chmod +x ./scripts/deploy.sh 
./scripts/deploy.sh
```
> Verify the resources created by `kubectl get secrets -n airflow`

Now we are all set for configuring our Airflow Build.