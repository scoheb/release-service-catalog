#!/usr/bin/env bash
set -eux

function update_component_sbom() {
  echo Mock update_component_sbom called with: "$*"
  echo "$*" >> "$(params.dataDir)/mock_update.txt"

  if [[ "$*" != "--data-path $(params.dataDir)/$(params.subdirectory)/data.json --input-path $(params.dataDir)/$(params.subdirectory)/downloaded-sboms --output-path $(params.dataDir)/$(params.subdirectory)/downloaded-sboms" ]]
  then
    echo Error: Unexpected call
    exit 1
  fi
}
