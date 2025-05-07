#!/usr/bin/env bash

set -eo pipefail

if [ -z "$GITHUB_TOKEN" ] ; then
  echo "error: missing env var GH_TOKEN"
  exit 1
fi
repo_name=$1
if [ -z "$repo_name" ] ; then
  echo "error: missing parameter repo_name"
  exit 1
fi
pr_number=$2
if [ -z "$pr_number" ] ; then
  echo "error: missing parameter pr_number"
  exit 1
fi

echo "Add /retest to PR $pr_number in $repo_name"
curl -L \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/$repo_name/issues/$pr_number/comments \
  -d '{"body":"/retest"}'
