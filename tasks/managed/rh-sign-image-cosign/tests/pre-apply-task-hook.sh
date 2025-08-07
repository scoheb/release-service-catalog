#!/usr/bin/env bash
#
# Create a dummy cosignSecretName secret (and delete it first if it exists)
kubectl delete secret test-cosign-secret test-cosign-secret-rekor --ignore-not-found

kubectl create secret generic test-cosign-secret\
  --from-literal=AWS_DEFAULT_REGION=us-test-1\
  --from-literal=AWS_ACCESS_KEY_ID=test-access-key\
  --from-literal=AWS_SECRET_ACCESS_KEY=test-secret-access-key\
  --from-literal=SIGN_KEY=aws://arn:mykey\
  --from-literal=REKOR_PUBLIC_KEY=rekor_public_key\
  --from-literal=PUBLIC_KEY=public_key

kubectl create secret generic test-cosign-secret-rekor\
  --from-literal=AWS_DEFAULT_REGION=us-test-1\
  --from-literal=AWS_ACCESS_KEY_ID=test-access-key\
  --from-literal=AWS_SECRET_ACCESS_KEY=test-secret-access-key\
  --from-literal=SIGN_KEY=aws://arn:mykey\
  --from-literal=REKOR_URL=https://fake-rekor-server\
  --from-literal=REKOR_PUBLIC_KEY=rekor_public_key\
  --from-literal=PUBLIC_KEY=public_key

# Add mocks to the beginning of task step script
TASK_PATH="$1"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
yq -i '.spec.steps[1].script = load_str("'$SCRIPT_DIR'/mocks.sh") + .spec.steps[1].script' "$TASK_PATH"
