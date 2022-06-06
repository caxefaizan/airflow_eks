#!/bin/bash

source ./scripts/eks-login.sh
source ./scripts/config.sh

echo "Fetching Parameters"
# Multi-Git-Sync Pod Secrets
aws ssm get-parameter --name ${GIT_PRIVATEKEY_PATH} --with-decryption --query Parameter.Value --output text > ./helperChart/secrets/id_rsa
aws ssm get-parameter --name ${GIT_KNOWNHOSTS_PATH}  --with-decryption --query Parameter.Value --output text > ./helperChart/secrets/known_hosts
export DAGS_REPO=$(aws ssm get-parameter --name ${DAGS_REPO_PATH} --with-decryption --query Parameter.Value | tr -d \")

# Flask Secrets
aws ssm get-parameter --name ${FERNET_KEY_PATH}     --with-decryption --query Parameter.Value --output text > ./helperChart/secrets/fernet_key
aws ssm get-parameter --name ${WEBSERVER_SECRET_KEY_PATH} --with-decryption --query Parameter.Value --output text > ./helperChart/secrets/webserver_key
aws ssm get-parameter --name ${WEBSERVER_SECRET_CACERT_PATH} --with-decryption --query Parameter.Value --output text > ./helperChart/secrets/cacert.pem
aws ssm get-parameter --name ${WEBSERVER_SECRET_CACERT_KEY_PATH} --with-decryption --query Parameter.Value --output text > ./helperChart/secrets/private.pem

echo "Updating Helper Chart Deployment"
# Create Resources from Templates
helm upgrade airflow-helper ./helperChart  \
    --install \
    --set env=${ENV} \
    --set cluster.namespace=${NAMESPACE} \
    -f ./helperChart/values.yaml

export KNOWN_HOSTS=$(cat ./helperChart/secrets/known_hosts)

# Remove Secrets
rm -rf ./helperChart/secrets

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