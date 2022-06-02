# Minimal Installation
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
and opening up `localhost:8080` on your web browser.

>This is where all the meat lies. But from now onwards we will build a production grade Airflow deployment that follows the best practices as described [here](https://airflow.apache.org/docs/helm-chart/stable/production-guide.html).

# Production Grade Deployment

To make use of a single script that manages Airflow across all environments, we will be using Helm to create a Helper Chart that will seamlessly manage all the resources required for Airflow across all environments.

> We're using Helm because a production grade Airflow requires various Kubernetes objects such as secrets, namespace, persistent volumes etc. and it would be tedious to manage them both imperatively and declaratively across different environments such as [ Dev | Test | Prod ]. 

To create the Helper Chart we need to follow the directory structure as described [here](https://helm.sh/docs/chart_template_guide/getting_started/).

