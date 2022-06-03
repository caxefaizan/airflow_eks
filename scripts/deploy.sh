#!/bin/bash

export ENV=sandpit ACCOUNT_ID=526742771915 
source ./scripts/eks-login.sh
source ./scripts/config.sh

# Multi-Git-Sync Pod Secrets
aws ssm get-parameter --name ${GIT_PRIVATEKEY_PATH} --with-decryption --query Parameter.Value --output text > ./helperChart/secrets/id_rsa
aws ssm get-parameter --name ${GIT_KNOWNHOSTS_PATH}  --with-decryption --query Parameter.Value --output text > ./helperChart/secrets/known_hosts

# Flask Secrets
aws ssm get-parameter --name ${FERNET_KEY_PATH}     --with-decryption --query Parameter.Value --output text > ./helperChart/secrets/fernet_key
aws ssm get-parameter --name ${WEBSERVER_SECRET_KEY_PATH} --with-decryption --query Parameter.Value --output text > ./helperChart/secrets/webserver_key

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