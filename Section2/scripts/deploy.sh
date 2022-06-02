#!/bin/bash

source ./scripts/config.sh

# Create Resources from Templates
helm upgrade airflow-helper ./helperChart  \
    --install \
    --set env=${ENV} \
    --set cluster.namespace=${NAMESPACE} \
    -f ./helperChart/values.yaml