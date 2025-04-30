#!/usr/bin/env bash
#
# Summary:
#   Monitors a Kubernetes Release custom resource until it reaches a terminal state
#   (Succeeded or Failed). It periodically fetches the Release status, displays
#   a summary of its various processing stages (Tenant Collectors, Managed Collectors,
#   Tenant Pipeline, Managed Pipeline, Final Pipeline), and provides console URLs
#   for associated PipelineRuns. If the Release fails, it attempts to fetch and
#   display logs from the relevant PipelineRuns.
#
# Parameters:
#   None.
#
# Environment Variables:
#   RELEASE_NAME      - The name of the Release custom resource to monitor. Required.
#   RELEASE_NAMESPACE - The Kubernetes namespace where the Release resource exists. Required.
#   CONSOLEURL        - (Derived by the script) The base URL for the OpenShift console,
#                       used to construct links to PipelineRuns and Releases.
#                       It's fetched from the 'pipelines-as-code' ConfigMap.
#   APPLICATION       - (Derived by the script) The name of the application associated
#                       with the Release, extracted from the Release's labels.
#
# Dependencies:
#   kubectl, jq, tkn (for fetching PipelineRun logs), oc (for fetching CONSOLEURL).

function getPipelinerunFromStatus() { # args are json, statusSection
  json=$1
  statusSection=$2

  filter=".status."$statusSection".pipelineRun"
  PLR=$(jq -r $filter <<< "${json}")
  echo ${PLR//null/}
}

function getConsoleLogForRelease() { # args are application, ns, name
  app=$1
  ns=$2
  name=$3
  releaseUrl="${CONSOLEURL}ns/${ns}/applications/${app}/releases/${name}"
  echo "${releaseUrl}"
}

function getConsoleLogFromPLR() { # args are json, statusSection
  json=$1
  statusSection=$2

  PLR=$(getPipelinerunFromStatus "$json" "$statusSection")

  PLR_NAME=$(cut -f2 -d/ <<< "${PLR}")
  PLR_NS=$(cut -f1 -d/ <<< "${PLR}")
  if [ -z "${PLR_NAME}" ] || [ -z "${PLR_NS}" ]; then
    return
  fi
  prLogUrl="${CONSOLEURL}ns/${PLR_NS}/applications/${APPLICATION}/pipelineruns/${PLR_NAME}"
  echo "${prLogUrl}"
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

  #openshift-pipelines/configmaps/pipelines-as-code  custom-console-url
  consoleUrl=$(oc get cm/pipelines-as-code -n openshift-pipelines -ojson | jq -r '.data."custom-console-url"')
  prLogUrl="${consoleUrl}/ns/${PLR_NS}/applications/${APPLICATION}/pipelineruns/${PLR_NAME}"

  echo ""
  echo "Console log url: ${prLogUrl}"
  echo ""

}

if [ -z "$RELEASE_NAME" ]; then
  echo "🔴 error: missing env var RELEASE_NAME"
  exit 1
fi
if [ -z "$RELEASE_NAMESPACE" ]; then
  echo "🔴 error: missing env var RELEASE_NAMESPACE"
  exit 1
fi

CONSOLEURL=$(oc get cm/pipelines-as-code -n openshift-pipelines -ojson | jq -r '.data."custom-console-url"')

echo "======================================="
echo "Release           : ${RELEASE_NAME}"
echo "======================================="

RELEASE_JSON=$(kubectl get release/${RELEASE_NAME} -n ${RELEASE_NAMESPACE} -ojson)
RELEASE_NAMESPACE=$(jq -r .metadata.namespace <<< "${RELEASE_JSON}")
APPLICATION=$(jq -r '.metadata.labels."appstudio.openshift.io/application"' <<< "${RELEASE_JSON}")
RELEASE_URL=$(getConsoleLogForRelease "${APPLICATION}" "${RELEASE_NAMESPACE}" "${RELEASE_NAME}")

while true;
do
  RELEASE_JSON=$(kubectl get release/${RELEASE_NAME} -n ${RELEASE_NAMESPACE} -ojson)
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
  TENANT_COLLECTOR_PIPELINERUN_URL=$(getConsoleLogFromPLR "${RELEASE_JSON}" "collectorsProcessing?.tenantCollectorsProcessing?")

  MANAGED_COLLECTOR_PROCESSED=$(jq -r '.status.conditions[] | select(.type=="ManagedCollectorsPipelineProcessed") | [.status, .reason, .message] | @csv' \
    <<< "${RELEASE_JSON}" )
  MANAGED_COLLECTOR_STATUS=$(cut -f1 -d, <<< "${MANAGED_COLLECTOR_PROCESSED}")
  MANAGED_COLLECTOR_REASON=$(cut -f2 -d, <<< "${MANAGED_COLLECTOR_PROCESSED}")
  MANAGED_COLLECTOR_MESSAGE=$(cut -f3 -d, <<< "${MANAGED_COLLECTOR_PROCESSED}")
  MANAGED_COLLECTOR_PIPELINERUN=$(getPipelinerunFromStatus "${RELEASE_JSON}" "collectorsProcessing?.managedCollectorsProcessing?")
  MANAGED_COLLECTOR_PIPELINERUN_URL=$(getConsoleLogFromPLR "${RELEASE_JSON}" "collectorsProcessing?.managedCollectorsProcessing?")

  TENANT_PROCESSED=$(jq -r '.status.conditions[] | select(.type=="TenantPipelineProcessed") | [.status, .reason, .message] | @csv' \
    <<< "${RELEASE_JSON}" )
  TENANT_STATUS=$(cut -f1 -d, <<< "${TENANT_PROCESSED}")
  TENANT_REASON=$(cut -f2 -d, <<< "${TENANT_PROCESSED}")
  TENANT_MESSAGE=$(cut -f3 -d, <<< "${TENANT_PROCESSED}")
  TENANT_PIPELINERUN=$(getPipelinerunFromStatus "${RELEASE_JSON}" "tenantProcessing?")
  TENANT_PIPELINERUN_URL=$(getConsoleLogFromPLR "${RELEASE_JSON}" "tenantProcessing?")

  MANAGED_PROCESSED=$(jq -r '.status.conditions[] | select(.type=="ManagedPipelineProcessed") | [.status, .reason, .message] | @csv' \
    <<< "${RELEASE_JSON}" )
  MANAGED_STATUS=$(cut -f1 -d, <<< "${MANAGED_PROCESSED}")
  MANAGED_REASON=$(cut -f2 -d, <<< "${MANAGED_PROCESSED}")
  MANAGED_MESSAGE=$(cut -f3 -d, <<< "${MANAGED_PROCESSED}")
  MANAGED_PIPELINERUN=$(getPipelinerunFromStatus "${RELEASE_JSON}" "managedProcessing?")
  MANAGED_PIPELINERUN_URL=$(getConsoleLogFromPLR "${RELEASE_JSON}" "managedProcessing?")

  FINAL_PROCESSED=$(jq -r '.status.conditions[] | select(.type=="FinalPipelineProcessed") | [.status, .reason, .message] | @csv' \
    <<< "${RELEASE_JSON}" )
  FINAL_STATUS=$(cut -f1 -d, <<< "${FINAL_PROCESSED}")
  FINAL_REASON=$(cut -f2 -d, <<< "${FINAL_PROCESSED}")
  FINAL_MESSAGE=$(cut -f3 -d, <<< "${FINAL_PROCESSED}")
  FINAL_PIPELINERUN=$(getPipelinerunFromStatus "${RELEASE_JSON}" "finalProcessing?")
  FINAL_PIPELINERUN_URL=$(getConsoleLogFromPLR "${RELEASE_JSON}" "finalProcessing?")

  overAllStatus="Overall Status    : ${RELEASED_REASON} ${RELEASED_MESSAGE} ${RELEASE_NAMESPACE}/${RELEASE_NAME}"
  overAllStatusCount=$(echo "${overAllStatus}" | wc -c)
  overAllStatusLine=
  for ((i = 0 ; i <= ${overAllStatusCount} ; i++)); do
       overAllStatusLine="${overAllStatusLine}-"
  done
  message="
${overAllStatus}
  -> ${RELEASE_URL}
${overAllStatusLine}
Tenant Collector  : ${TENANT_COLLECTOR_REASON} ${TENANT_COLLECTOR_MESSAGE} ${TENANT_COLLECTOR_PIPELINERUN}
  -> ${TENANT_COLLECTOR_PIPELINERUN_URL}
Managed Collector : ${MANAGED_COLLECTOR_REASON} ${MANAGED_COLLECTOR_MESSAGE} ${MANAGED_COLLECTOR_PIPELINERUN}
  -> ${MANAGED_COLLECTOR_PIPELINERUN_URL}
Tenant            : ${TENANT_REASON} ${TENANT_MESSAGE} ${TENANT_PIPELINERUN}
  -> ${TENANT_PIPELINERUN_URL}
Managed           : ${MANAGED_REASON} ${MANAGED_MESSAGE} ${MANAGED_PIPELINERUN}
  -> ${MANAGED_PIPELINERUN_URL}
Final             : ${FINAL_REASON} ${FINAL_MESSAGE} ${FINAL_PIPELINERUN}
  -> ${FINAL_PIPELINERUN_URL}
${overAllStatusLine}"

  message=$(sed 's/""//g' <<< "$message")
  message=$(sed 's/->[[:space:]]*$//g' <<< "$message")
  message=$(sed '/^[[:space:]]*$/d' <<< "$message")
  message=$(sed 's/"Skipped"/⏭️/g' <<< "$message")
  message=$(sed 's/"Succeeded"/✅️/g' <<< "$message")
  message=$(sed 's/"Progressing"/⏳️/g' <<< "$message")

  if [ "${preMessage}" != "${message}" ]; then
    echo "$message"
    echo ""
    preMessage=$message
  fi

  if [ "${RELEASED_STATUS}" == "\"False\"" ] && [ "${RELEASED_REASON}" == "\"Failed\"" ]; then
    echo ""
    echo "❌ Error: Release failed!"
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
    echo "✅ Release succeeded!"
    exit 0
  fi
  sleep 5
done
