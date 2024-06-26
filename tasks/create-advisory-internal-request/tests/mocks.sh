#!/usr/bin/env sh
set -eux

# mocks to be injected into task step scripts

function kubectl() {
  # The IR won't actually be acted upon, so mock it to return Success as the task wants
  if [[ "$*" == "get internalrequest "*"-o=jsonpath={.status.results}" ]]
  then
    echo '{"result":"Success"}'
  else
    kubectl $*
  fi
}
