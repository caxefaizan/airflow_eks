#!/bin/bash

export NAMESPACE="airflow"
export RELEASE_NAME="airflow"
export ENV="dev"
export DAGS_REPO="git@github.com:caxefaizan/airflow-dag-repo.git"
KNOWN_HOSTS=$(cat ./helperChart/secrets/known_hosts)
export KNOWN_HOSTS