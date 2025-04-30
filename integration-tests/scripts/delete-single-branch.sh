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
branch=$2
if [ -z "$branch" ] ; then
  echo "error: missing parameter branch"
  exit 1
fi

echo "deleting $branch in $repo_name"
curl -L \
  -X DELETE \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/$repo_name/git/refs/heads/$branch
