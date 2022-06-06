#!/bin/bash

export NAMESPACE="airflow"
export RELEASE_NAME="airflow"
export ENV="dev"

export AWS_DEFAULT_REGION="us-east-1"
export WEBSERVER_SECRET_KEY_PATH="/global/airflow/webserver/flask-secret-key"
export WEBSERVER_SECRET_CACERT_PATH="/global/airflow/webserver/cacert"
export WEBSERVER_SECRET_CACERT_KEY_PATH="/global/airflow/webserver/private"
export FERNET_KEY_PATH="/global/airflow/fernet-key"

export GIT_KNOWNHOSTS_PATH="/global/airflow/github/known-hosts"
export GIT_PRIVATEKEY_PATH="/global/airflow/github/private-key"
export DAGS_REPO_PATH="/global/airflow/github/dags-repo"

rm -rf ./helperChart/secrets && mkdir -p ./helperChart/secrets

# To generate Connection strings refer file create_conn_uri.py
# Postgres Connection
export POSTGRES_ID_PATH="/${ENV}/airflow/rds/identifier"
export POSTGRES_PASS_PATH="/${ENV}/airflow/rds/password"
# export AIRFLOW_DB_ID=$(aws ssm get-parameter --name ${POSTGRES_ID_PATH} --with-decryption --query Parameter.Value | tr -d \")
export AIRFLOW_DB_ID="airflow-db"
# Airflow DB Connection URL
export CONN_ID="postgres_uri"
export CONN_TYPE="postgresql"
export LOGIN="postgres"
export PASSWORD=$(aws ssm get-parameter --name ${POSTGRES_PASS_PATH} --with-decryption --query Parameter.Value | tr -d \")
# export HOST=$(aws rds describe-db-instances --db-instance-identifier $AIRFLOW_DB_ID | jq -r '.DBInstances[0].Endpoint.Address')
export HOST="localhost"
export PORT=5432
export SCHEMA="airflow"
python3 ./scripts/create_conn_uri.py

# for celery result backend
export CONN_TYPE="db+postgresql"
export CONN_ID="celery_uri"
python3 ./scripts/create_conn_uri.py

unset PASSWORD