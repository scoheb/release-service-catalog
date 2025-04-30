#!/usr/bin/env bash

set -eo pipefail

if [ -z "$GITHUB_TOKEN" ] ; then
  echo "error: missing env var GH_TOKEN"
  exit 1
fi
if [ -z "$VAULT_PASSWORD_FILE" ] ; then
  echo "error: missing env var VAULT_PASSWORD_FILE"
  exit 1
fi
if [ ! -f "$VAULT_PASSWORD_FILE" ] ; then
  echo "error: env var VAULT_PASSWORD_FILE points to a non-existent file"
  exit 1
fi
if [ -n "$RELEASE_CATALOG_GIT_URL" ] ; then
  echo "Using provided RELEASE_CATALOG_GIT_URL: ${RELEASE_CATALOG_GIT_URL}"
else
  RELEASE_CATALOG_GIT_URL=https://github.com/konflux-ci/release-service-catalog.git
  export RELEASE_CATALOG_GIT_URL
  echo "Defaulting to RELEASE_CATALOG_GIT_URL: ${RELEASE_CATALOG_GIT_URL}"
fi
if [ -n "$RELEASE_CATALOG_GIT_REVISION" ] ; then
  echo "Using provided RELEASE_CATALOG_GIT_REVISION: ${RELEASE_CATALOG_GIT_REVISION}"
else
  RELEASE_CATALOG_GIT_REVISION=development
  export RELEASE_CATALOG_GIT_REVISION
  echo "Defaulting to RELEASE_CATALOG_GIT_REVISION: ${RELEASE_CATALOG_GIT_REVISION}"
fi
if [ -n "$KUBECONFIG" ] ; then
  echo "Using provided KUBECONFIG"
fi

cleanup() {
  local err=$1
  local line=$2
  local command="$3"

  if [ "$err" -ne 0 ] ; then
    echo -n \
    "$0: ERROR $command failed at line $line - exited with status $err"
  fi

  # cleanup...so we can ignore errors
  set +eo pipefail

  echo ""
  echo "Delete Github branch..."
  ${SCRIPT_DIR}/../scripts/delete-single-branch.sh "${component_repo_name}" "${component_branch}" 2> /dev/null

  echo ""
  echo "Delete test resources..."
  kubectl delete -f "$tmpDir/tenant-resources.yaml" 2> /dev/null
  kubectl delete -f "$tmpDir/managed-resources.yaml" 2> /dev/null

  exit $err
}
trap 'cleanup $? $LINENO "$BASH_COMMAND"' EXIT

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

. "${SCRIPT_DIR}/test.env"

mkdir -p "${SCRIPT_DIR}/resources/tenant/secrets"
mkdir -p "${SCRIPT_DIR}/resources/managed/secrets"

if [ ! -f "${SCRIPT_DIR}/resources/tenant/secrets/tenant-secrets.yaml" ]; then
  echo "Secrets missing...decrypting"
  ansible-vault decrypt "${SCRIPT_DIR}/vault/collector-tenant-secrets.yaml" --output "${SCRIPT_DIR}/resources/tenant/secrets/tenant-secrets.yaml" --vault-password-file $VAULT_PASSWORD_FILE
fi
if [ ! -f "${SCRIPT_DIR}/resources/managed/secrets/managed-secrets.yaml" ]; then
  echo "Secrets missing...decrypting"
  ansible-vault decrypt "${SCRIPT_DIR}/vault/collector-managed-secrets.yaml" --output "${SCRIPT_DIR}/resources/managed/secrets/managed-secrets.yaml" --vault-password-file $VAULT_PASSWORD_FILE
fi

# create GH branch
echo ""
echo "Create component branch..."
$SCRIPT_DIR/../scripts/create-branch-from-base.sh "${component_repo_name}" "${component_base_branch}" "${component_branch}"

echo ""
echo "Setup namespaces..."
set +eo pipefail
kubectl get ns ${managed_namespace}
if [ $? -eq 1 ]; then
  echo "Error: managed namespace ${managed_namespace} does not exist"
  exit 2
fi

kubectl get ns ${tenant_namespace}
if [ $? -eq 1 ]; then
  echo "Error: tenant namespace ${tenant_namespace} does not exist"
  exit 2
fi
set -eo pipefail

kubectl config set-context --current --namespace=$tenant_namespace

echo ""
echo "Creating resources on cluster..."
tmpDir=$(mktemp -d)
kustomize build "$SCRIPT_DIR/resources/tenant" | envsubst  > $tmpDir/tenant-resources.yaml
kustomize build "$SCRIPT_DIR/resources/managed" | envsubst > $tmpDir/managed-resources.yaml

echo ""
echo "Cleanup resources can be done with:"
echo "% kubectl delete -f $tmpDir/tenant-resources.yaml"
echo "% kubectl delete -f $tmpDir/managed-resources.yaml"
echo ""

kubectl apply -f "$tmpDir/tenant-resources.yaml"
kubectl apply -f "$tmpDir/managed-resources.yaml"

echo ""
echo -n "Waiting for component to be initialized: "
component_annotations=
while [ -z "${component_annotations}" ]; do
  sleep 1
  echo -n "."
  component_annotations=$(kubectl get component/${component_name} -n ${tenant_namespace} -ojson | \
    jq -r --arg k "build.appstudio.openshift.io/status" '.metadata.annotations[$k] // ""')
done

component_pr=$(jq -r '.pac."merge-url" // ""' <<< $component_annotations)
if [ -z "${component_pr}" ]; then
  echo "error: could not get component PR"
  exit 1
fi

pr_number=$(cut -f7 -d/ <<< ${component_pr})
echo ""
echo "found PR: $pr_number"

# merge PR
echo ""
echo "Merging PR"
# Merge PR using CVE info in commit message.
merge_result=$(curl -L \
  -X PUT \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/${component_repo_name}/pulls/${pr_number}/merge \
  -d '{"commit_title":"e2e test","commit_message":"This fixes CVE-2024-8260"}' 2> /dev/null)

# wait for push PR
SHA=$(jq -r '.sha' <<< $merge_result)

echo ""
echo -n "Waiting for Component push PLR to appear: "
component_push_plr_name=
while [ -z "${component_push_plr_name}" ]; do
  sleep 1
  echo -n "."
  component_push_plr_name=$(kubectl get pr -l pipelinesascode.tekton.dev/sha=$SHA -n ${tenant_namespace} --no-headers 2> /dev/null | awk '{print $1}')
done
echo ""
echo "found: $component_push_plr_name"

echo ""
echo -n "Waiting for Component push PLR to complete: "
completed=
retry_attempted=
while [ -z "${completed}" ];
do
  sleep 1
  component_plr_json=$(kubectl get pr/$component_push_plr_name -n ${tenant_namespace} -ojson)
  component_plr_status=$(jq -r '.status.conditions[] | select(.type=="Succeeded") | .status' <<< "${component_plr_json}" )
  if [ $component_plr_status == "True" ]; then
    completed="Success"
  else
    if [ $component_plr_status == "False" ]; then
      component_plr_reason=$(jq -r '.status.conditions[] | select(.type=="Succeeded") | .reason' <<< "${component_plr_json}" )
      if [ $component_plr_reason == "Failed" ]; then
        echo "FAILED. See logs:"
        /usr/bin/tkn pr logs "$component_push_plr_name" -f --timestamps -n "${tenant_namespace}"
        if [ -z "${retry_attempted}" ]; then
          ${SCRIPT_DIR}/../scripts/add-retry-comment-to-pr.sh "$component_repo_name" "$pr_number"
          retry_attempted=true
        else
          echo "Retry already attempted...exiting."
          exit 1
        fi
      fi
    fi
    echo -n "."
  fi
done
echo ""
echo "$completed"

echo ""
echo -n "Waiting for Release: "
release_name=
while [ -z "${release_name}" ]; do
  sleep 5
  echo -n "."
  release_name=$(kubectl get release -l appstudio.openshift.io/build-pipelinerun=$component_push_plr_name  -n ${tenant_namespace} -ojson 2> /dev/null | jq -r '.items[0].metadata.name // ""')
done
echo ""
echo "found: $release_name"

export RELEASE_NAME=${release_name}
export RELEASE_NAMESPACE=${tenant_namespace}
${SCRIPT_DIR}/../scripts/wait-for-release.sh

# check release
echo ""
echo "Verify Release contents..."
release_json=$(kubectl get release/${RELEASE_NAME} -ojson)
echo $release_json

num_issues=$(jq -r '.status.collectors.tenant."jira-collector".releaseNotes.issues.fixed | length // 0' <<< "${release_json}")
advisory_url=$(jq -r '.status.artifacts.advisory.url // ""' <<< "${release_json}")
catalog_url=$(jq -r '.status.artifacts.catalog_urls[].url // ""' <<< "${release_json}")
topic=$(jq -r '.status.collectors.tenant.convertyaml.releaseNotes.topic // ""' <<< "${release_json}")
description=$(jq -r '.status.collectors.tenant.convertyaml.releaseNotes.description // ""' <<< "${release_json}")
cve=$(jq -r '.status.collectors.tenant.cve.releaseNotes.cves[] | select(.key == "CVE-2024-8260") | .key' <<< "${release_json}")

echo "checking that number of issues found is > 0"
test "${num_issues}" -gt 0
echo "checking advisory url is not empty"
test -n "${advisory_url}"
echo "checking topic is 'from yaml topic'"
test "${topic}" == "from yaml topic"
echo "checking description is 'from yaml description'"
test "${description}" == "from yaml description"
echo "checking that CVE 'CVE-2024-8260' was found"
test "${cve}" == "CVE-2024-8260"
