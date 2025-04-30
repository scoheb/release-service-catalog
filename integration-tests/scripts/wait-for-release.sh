#!/usr/bin/env bash

function getPipelinerunFromStatus() { # args are json, statusSection
  json=$1
  statusSection=$2

  filter=".status."$statusSection".pipelineRun"
  PLR=$(jq -r $filter <<< "${json}")
  echo ${PLR//null/}
}

function getLogs() { # args are json, statusSection
  json=$1
  statusSection=$2

  PLR=$(getPipelinerunFromStatus "$json" "$statusSection")

  PLR_NAME=$(cut -f2 -d/ <<< "${PLR}")
  PLR_NS=$(cut -f1 -d/ <<< "${PLR}")
  if [ -z "${PLR_NAME}" ] || [ -z "${PLR_NS}" ]; then
    return
  fi
  echo ""
  echo "Getting logs from pipelineRun $PLR"
  echo ""
  /usr/bin/tkn pr logs "${PLR_NAME}" -f --timestamps -n "${PLR_NS}"
}

if [ -z "$RELEASE_NAME" ]; then
  echo "error: missing env var RELEASE_NAME"
  exit 1
fi
if [ -z "$RELEASE_NAMESPACE" ]; then
  echo "error: missing env var RELEASE_NAMESPACE"
  exit 1
fi

echo "======================================="
echo "Release           : ${RELEASE_NAME}"
echo "======================================="

while true;
do
  RELEASE_JSON=$(kubectl get release/${RELEASE_NAME} -n ${RELEASE_NAMESPACE} -ojson)
  RELEASE_NAMESPACE=$(jq -r .metadata.namespace <<< "${RELEASE_JSON}")
  #jq -r '.status.conditions[] | [.type, .status, .reason, .message] | @csv' <<< "${RELEASE_JSON}"
  RELEASED=$(jq -r '.status.conditions[] | select(.type=="Released") | [.status, .reason, .message] | @csv' \
    <<< "${RELEASE_JSON}" )
  RELEASED_STATUS=$(cut -f1 -d, <<< "${RELEASED}")
  RELEASED_REASON=$(cut -f2 -d, <<< "${RELEASED}")
  RELEASED_MESSAGE=$(cut -f3 -d, <<< "${RELEASED}")

  TENANT_COLLECTOR_PROCESSED=$(jq -r '.status.conditions[] | select(.type=="TenantCollectorsPipelineProcessed") | [.status, .reason, .message] | @csv' \
    <<< "${RELEASE_JSON}" )
  TENANT_COLLECTOR_STATUS=$(cut -f1 -d, <<< "${TENANT_COLLECTOR_PROCESSED}")
  TENANT_COLLECTOR_REASON=$(cut -f2 -d, <<< "${TENANT_COLLECTOR_PROCESSED}")
  TENANT_COLLECTOR_MESSAGE=$(cut -f3 -d, <<< "${TENANT_COLLECTOR_PROCESSED}")
  TENANT_COLLECTOR_PIPELINERUN=$(getPipelinerunFromStatus "${RELEASE_JSON}" "collectorsProcessing?.tenantCollectorsProcessing?")

  MANAGED_COLLECTOR_PROCESSED=$(jq -r '.status.conditions[] | select(.type=="ManagedCollectorsPipelineProcessed") | [.status, .reason, .message] | @csv' \
    <<< "${RELEASE_JSON}" )
  MANAGED_COLLECTOR_STATUS=$(cut -f1 -d, <<< "${MANAGED_COLLECTOR_PROCESSED}")
  MANAGED_COLLECTOR_REASON=$(cut -f2 -d, <<< "${MANAGED_COLLECTOR_PROCESSED}")
  MANAGED_COLLECTOR_MESSAGE=$(cut -f3 -d, <<< "${MANAGED_COLLECTOR_PROCESSED}")
  MANAGED_COLLECTOR_PIPELINERUN=$(getPipelinerunFromStatus "${RELEASE_JSON}" "collectorsProcessing?.managedCollectorsProcessing?")

  TENANT_PROCESSED=$(jq -r '.status.conditions[] | select(.type=="TenantPipelineProcessed") | [.status, .reason, .message] | @csv' \
    <<< "${RELEASE_JSON}" )
  TENANT_STATUS=$(cut -f1 -d, <<< "${TENANT_PROCESSED}")
  TENANT_REASON=$(cut -f2 -d, <<< "${TENANT_PROCESSED}")
  TENANT_MESSAGE=$(cut -f3 -d, <<< "${TENANT_PROCESSED}")
  TENANT_PIPELINERUN=$(getPipelinerunFromStatus "${RELEASE_JSON}" "tenantProcessing?")

  MANAGED_PROCESSED=$(jq -r '.status.conditions[] | select(.type=="ManagedPipelineProcessed") | [.status, .reason, .message] | @csv' \
    <<< "${RELEASE_JSON}" )
  MANAGED_STATUS=$(cut -f1 -d, <<< "${MANAGED_PROCESSED}")
  MANAGED_REASON=$(cut -f2 -d, <<< "${MANAGED_PROCESSED}")
  MANAGED_MESSAGE=$(cut -f3 -d, <<< "${MANAGED_PROCESSED}")
  MANAGED_PIPELINERUN=$(getPipelinerunFromStatus "${RELEASE_JSON}" "managedProcessing?")

  FINAL_PROCESSED=$(jq -r '.status.conditions[] | select(.type=="FinalPipelineProcessed") | [.status, .reason, .message] | @csv' \
    <<< "${RELEASE_JSON}" )
  FINAL_STATUS=$(cut -f1 -d, <<< "${FINAL_PROCESSED}")
  FINAL_REASON=$(cut -f2 -d, <<< "${FINAL_PROCESSED}")
  FINAL_MESSAGE=$(cut -f3 -d, <<< "${FINAL_PROCESSED}")
  FINAL_PIPELINERUN=$(getPipelinerunFromStatus "${RELEASE_JSON}" "finalProcessing?")

  message="
Overall Status    : ${RELEASED_REASON} ${RELEASED_MESSAGE} ${RELEASE_NAMESPACE}/${RELEASE_NAME}
Tenant Collector  : ${TENANT_COLLECTOR_REASON} ${TENANT_COLLECTOR_MESSAGE} ${TENANT_COLLECTOR_PIPELINERUN}
Managed Collector : ${MANAGED_COLLECTOR_REASON} ${MANAGED_COLLECTOR_MESSAGE} ${MANAGED_COLLECTOR_PIPELINERUN}
Tenant            : ${TENANT_REASON} ${TENANT_MESSAGE} ${TENANT_PIPELINERUN}
Managed           : ${MANAGED_REASON} ${MANAGED_MESSAGE} ${MANAGED_PIPELINERUN}
Final             : ${FINAL_REASON} ${FINAL_MESSAGE} ${FINAL_PIPELINERUN}
-------------------------------------"
  message=$(sed 's/""//g' <<< "$message")

  if [ "${preMessage}" != "${message}" ]; then
    echo "$message"
    preMessage=$message
  fi

  if [ "${RELEASED_STATUS}" == "\"False\"" ] && [ "${RELEASED_REASON}" == "\"Failed\"" ]; then
    echo ""
    echo "Error: Release failed!"
    echo ""

    RELEASE_JSON=$(kubectl get release/${RELEASE_NAME} -n ${RELEASE_NAMESPACE} -ojson)
    jq -r '.status.conditions[] | [.type, .status, .reason, .message] | @csv' <<< "${RELEASE_JSON}"

    getLogs "${RELEASE_JSON}" "collectorsProcessing?.tenantCollectorsProcessing?"
    getLogs "${RELEASE_JSON}" "collectorsProcessing?.managedCollectorsProcessing?"
    getLogs "${RELEASE_JSON}" "tenantProcessing?"
    getLogs "${RELEASE_JSON}" "managedProcessing?"
    getLogs "${RELEASE_JSON}" "finalProcessing?"

    exit 1
  fi

  if [ "${RELEASED_STATUS}" == "\"True\"" ] && [ "${RELEASED_REASON}" == "\"Succeeded\"" ]; then
    echo "Tests succeeded!"
    exit 0
  fi
  sleep 5
done
