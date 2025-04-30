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
if [ -z "$RELEASE_CATALOG_GIT_URL" ] ; then
  echo "error: missing env var RELEASE_CATALOG_GIT_URL"
  exit 1
fi
if [ -z "$RELEASE_CATALOG_GIT_REVISION" ] ; then
  echo "error: missing env var RELEASE_CATALOG_GIT_REVISION"
  exit 1
fi
if [ -n "$KUBECONFIG" ] ; then
  echo "Using provided KUBECONFIG"
fi

uuid=$(openssl rand -hex 4)

export tenant_namespace=shebert-tenant #release-catalog-tenant-e2e-tenant
export managed_namespace=managed-release-team-tenant #release-catalog-managed-e2e-tenant

export application_name=e2eapp-${uuid}
export component_name=collector-${uuid}
export component_branch=${component_name}

export component_base_branch=collector-base
export component_repo_name=scoheb/e2e-base
export component_git_url=https://github.com/$component_repo_name

export tenant_sa_name=collector-sa-${uuid}
export release_plan_name=collector-rp-${uuid}

export managed_sa_name=collector-sa-${uuid}
export release_plan_admission_name=collector-rpa-${uuid}

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

mkdir -p "${SCRIPT_DIR}/tenant/secrets"
mkdir -p "${SCRIPT_DIR}/managed/secrets"

if [ ! -f "${SCRIPT_DIR}/tenant/secrets/tenant-secrets.yaml" ]; then
  echo "Secrets missing...decrypting"
  ansible-vault decrypt "${SCRIPT_DIR}/collector-tenant-secrets.yaml" --output "${SCRIPT_DIR}/tenant/secrets/tenant-secrets.yaml" --vault-password-file $VAULT_PASSWORD_FILE
fi
if [ ! -f "${SCRIPT_DIR}/managed/secrets/managed-secrets.yaml" ]; then
  echo "Secrets missing...decrypting"
  ansible-vault decrypt "${SCRIPT_DIR}/collector-managed-secrets.yaml" --output "${SCRIPT_DIR}/managed/secrets/managed-secrets.yaml" --vault-password-file $VAULT_PASSWORD_FILE
fi

# create GH branch
$SCRIPT_DIR/../scripts/create-branch-from-base.sh "${component_repo_name}" "${component_base_branch}" "${component_branch}"

echo ""
echo "Setup namespaces..."
set +eo pipefail
#oc project ${managed_namespace} 2> /dev/null
kubectl get ns ${managed_namespace}
if [ $? -eq 1 ]; then
  kubectl create namespace ${managed_namespace}
fi
kubectl config set-context --current --namespace=$managed_namespace 2> /dev/null
$SCRIPT_DIR/../scripts/setup-namespace.sh

#oc project ${tenant_namespace} 2> /dev/null
kubectl get ns ${tenant_namespace}
if [ $? -eq 1 ]; then
  kubectl create namespace ${tenant_namespace}
  #oc project ${tenant_namespace} 2> /dev/null
fi
kubectl config set-context --current --namespace=$tenant_namespace 2> /dev/null
$SCRIPT_DIR/../scripts/setup-namespace.sh
set -eo pipefail

echo ""
echo "Creating resources on cluster..."
tmpDir=$(mktemp -d)
kustomize build "$SCRIPT_DIR/tenant" | envsubst  > $tmpDir/tenant-resources.yaml
kustomize build "$SCRIPT_DIR/managed" | envsubst > $tmpDir/managed-resources.yaml

echo ""
echo "Cleanup resources can be done with:"
echo "kubectl delete -f $tmpDir/tenant-resources.yaml"
echo "kubectl delete -f $tmpDir/managed-resources.yaml"
echo ""

kubectl apply -f "$tmpDir/tenant-resources.yaml"
kubectl apply -f "$tmpDir/managed-resources.yaml"

echo ""
echo -n "Waiting for component to be initialized: "
component_annotations=
while [ -z "${component_annotations}" ]; do
  sleep 1
  echo -n "."
  component_annotations=$(kubectl get component/${component_name} -n ${tenant_namespace} -ojson | jq -r --arg k "build.appstudio.openshift.io/status" '.metadata.annotations[$k] // ""')
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
merge_result=$(curl -L \
  -X PUT \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/${component_repo_name}/pulls/${pr_number}/merge \
  -d '{"commit_title":"e2e test","commit_message":"merging for e2e testing"}' 2> /dev/null)

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

export RELEASE_NAME=$release_name
${SCRIPT_DIR}/../scripts/wait-for-release.sh

# check release
echo ""
echo "Verify Release contents..."
release_json=$(kubectl get release/${RELEASE_NAME} -ojson)
echo $release_json

num_issues=$(jq -r '.status.collectors.tenant."jira-collector".releaseNotes.issues.fixed | length // 0' <<< "${release_json}")
advisory_url=$(jq -r '.status.artifacts.advisory.url // ""' <<< "${release_json}")
catalog_url=$(jq -r '.status.artifacts.catalog_urls[].url // ""' <<< "${release_json}")

echo "checking that number of issues found is > 0"
test "${num_issues}" -gt 0
echo "checking advisory url is not empty"
test -n "${advisory_url}"
echo "checking catalog url  is not empty"
test -n "${catalog_url}"

echo ""
echo "Delete Github branch..."
${SCRIPT_DIR}/../scripts/delete-single-branch.sh ${component_repo_name} ${component_branch}

echo ""
echo "Delete test resources..."
kubectl delete -f "$tmpDir/tenant-resources.yaml"
kubectl delete -f "$tmpDir/managed-resources.yaml"
