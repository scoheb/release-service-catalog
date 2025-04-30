#!/usr/bin/env bash

set -eo pipefail

if [ -z $GITHUB_TOKEN ] ; then
  echo "error: missing env var GH_TOKEN"
  exit 1
fi

repo_name=$1
if [ -z "$repo_name" ] ; then
  echo "error: missing parameter repo_name"
  exit 1
fi
base_branch_name=$2
if [ -z "$base_branch_name" ] ; then
  echo "error: missing parameter base_branch_name"
  exit 1
fi
new_branch_name=$3
if [ -z "$new_branch_name" ] ; then
  echo "error: missing parameter new_branch_name"
  exit 1
fi

SHA=$(curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/repos/${repo_name}/git/refs/heads/${base_branch_name} 2> /dev/null | jq -r '.object.sha // ""')
if [ -z "${SHA}" ]; then
  echo "error: could not get SHA for base branch $base_branch_name"
  exit 1
fi
echo "Current SHA for base branch $base_branch_name is  $SHA"

echo "Creating new branch called ${new_branch_name} based on branch $base_branch_name"
curl -X POST -H "Authorization: token $GITHUB_TOKEN" \
 -d  "{\"ref\": \"refs/heads/${new_branch_name}\",\"sha\": \"$SHA\"}"  https://api.github.com/repos/${repo_name}/git/refs 2> /dev/null
