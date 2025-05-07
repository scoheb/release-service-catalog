#!/usr/bin/env bash

TASK_PATH="$1"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Add mocks to the beginning of task step script
yq -i '.spec.steps[0].script = load_str("'$SCRIPT_DIR'/mocks.sh") + .spec.steps[0].script' "$TASK_PATH"

kubectl delete secret create-advisory-secret --ignore-not-found
kubectl create secret generic create-advisory-secret --from-literal=git_author_email=tester@tester --from-literal=git_author_name=tester --from-literal=gitlab_access_token=abc --from-literal=gitlab_host=myurl --from-literal=git_repo=https://gitlab.com/org/repo.git

kubectl delete secret create-advisory-errata-secret --ignore-not-found
kubectl create secret generic create-advisory-errata-secret --from-literal=errata_api=https://errata/api/v1 --from-literal=name=errata-tester --from-literal=base64_keytab=Zm9vCg==

kubectl delete secret quay-token-konflux-release-trusted-artifacts-secret --ignore-not-found

if [ -z "${DOCKER_CONFIG_JSON}" ]; then
  DOCKER_CONFIG_JSON=$(mktemp)
  echo -n '{"auths": {}}' > "${DOCKER_CONFIG_JSON}"
fi
echo "Using docker config stored in ${DOCKER_CONFIG_JSON}"
kubectl create secret generic quay-token-konflux-release-trusted-artifacts-secret \
  --from-file=.dockerconfigjson="${DOCKER_CONFIG_JSON}" \
  --type=kubernetes.io/dockerconfigjson --dry-run=client -o yaml | kubectl apply -f -
