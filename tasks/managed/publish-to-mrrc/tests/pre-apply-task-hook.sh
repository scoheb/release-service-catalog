#!/usr/bin/env bash

TASK_PATH="$1"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Create a dummy charon aws crendentials secret (and delete it first if it exists)
aws_creds=$(cat <<- EOF
[test]
aws_user = test-user
aws_access_key_id = justadummykey
aws_secret_access_key = justadummyaccesskey
region = us-east-1
EOF
)
kubectl delete secret test-charon-aws-credentials --ignore-not-found
kubectl create secret generic test-charon-aws-credentials --from-literal=credentials="$aws_creds"

kubectl delete secret test-ca --ignore-not-found
kubectl create secret generic test-ca \
  --from-literal=client-key.pem="testkey" \
  --from-literal=client-key.password="testpass" \
  --from-literal=mrrc-signing.crt="testca"

# Add mocks to the beginning of scripts
yq -i '.spec.steps[1].script = load_str("'$SCRIPT_DIR'/mocks.sh") + .spec.steps[1].script' "$TASK_PATH"
yq -i '.spec.steps[2].script = load_str("'$SCRIPT_DIR'/mocks.sh") + .spec.steps[2].script' "$TASK_PATH"

# Create a dummy configmap (and delete it first if it exists)
kubectl delete configmap trusted-ca --ignore-not-found
kubectl create configmap trusted-ca --from-literal=cert=mycert
