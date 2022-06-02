#!/bin/bash

source ./scripts/config.sh

# Create Resources from Templates
helm upgrade airflow-helper ./helperChart  \
    --install \
    --set env=${ENV} \
    --set cluster.namespace=${NAMESPACE} \
    -f ./helperChart/values.yaml

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