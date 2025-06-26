#!/usr/bin/env bash

TASK_PATH="$1"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Add mocks to the beginning of task step script
yq -i '.spec.steps[2].script = load_str("'$SCRIPT_DIR'/mocks.sh") + .spec.steps[2].script' "$TASK_PATH"

# Delete existing secrets if they exist
kubectl delete secret push-koji-test --ignore-not-found

# Create the fake secrets for koji
kubectl create secret generic push-koji-test \
  --from-literal=base64_keytab="$(base64 <<< "some keytab")"
