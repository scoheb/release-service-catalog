#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

nonCompatibleTrustedArtifactsBasedTasks=()
for dir in $(find . ${SCRIPT_DIR}/tasks/managed/ -maxdepth 1 -type d)
do
  baseDir=$(basename "${dir}")
  taskFile="${dir}/${baseDir}.yaml"
  if [ -f "${taskFile}" ]; then
    ociStageParam=$(yq '.spec.params[] | select(.name == "ociStorage") | .name' "${taskFile}")
    if [ -z "${ociStageParam}" ]; then
      echo "X - $(basename ${dir})"
      nonCompatibleTrustedArtifactsBasedTasks+=($dir)
    fi
  fi
done
#echo "nonCompatibleTrustedArtifactsBasedTasks: ${nonCompatibleTrustedArtifactsBasedTasks[@]}"
