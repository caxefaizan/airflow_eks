# Section 3 - Creating Helper Chart using HELM
## CleanUp
Remove previous Minimal Airflow Deployment from the default namespace
```
helm uninstall airflow
kubectl delete pvc --all
```
## DAGS Repo
Create a separate DAGS repo on Github where we will store all our DAGS in the root folder.

Now on the top right copy the SSH url under Code > SSH and define the path in the config script as. 
```
# ./scripts/config.sh
export DAGS_REPO="git@github.com:YOUR_USERNAME/YOUR_DAGS_REPO.git"
```
Now lets deploy Airflow using the values.yaml file with our own secrets managed by our Helper Chart.
```
# Copy airflow configuration values file 
cp Section3/yamls ./ -r
```

Add the following code to `deploy.sh` or simply copy it `cp Section3/scripts/ ./ -r -f`
```
helm repo add apache-airflow https://airflow.apache.org
helm repo update

echo "Checking Previous Deployments"
if helm history --max 1 $RELEASE_NAME -n $NAMESPACE 2>/dev/null | grep -i FAILED | cut -f1 | grep -q 1; then
 	echo "Deleting Airflow"
    helm uninstall  $RELEASE_NAME -n $NAMESPACE
fi

# Create Values File from Templated Values File
j2 ./yamls/values.yaml.j2 > ./yamls/values.yaml

unset KNOWN_HOSTS

echo "Installing Airflow"
helm upgrade --install $RELEASE_NAME apache-airflow/airflow -n $NAMESPACE --create-namespace\
    -f ./yamls/values.yaml \
    --timeout=5m 

rm ./yamls/values.yaml
```

Run `./scripts/deploy.sh`