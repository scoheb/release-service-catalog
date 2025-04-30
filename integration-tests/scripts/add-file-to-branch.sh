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
branch_name=$2
if [ -z "$branch_name" ] ; then
  echo "error: missing parameter branch_name"
  exit 1
fi
file_name=$3
if [ -z "$file_name" ] ; then
  echo "error: missing parameter file_name"
  exit 1
fi
commit_msg=$4
if [ -z "$commit_msg" ] ; then
  echo "error: missing parameter commit_msg"
  exit 1
fi

tmpFile=$(mktemp)
cat > "${tmpFile}" << EOF
{
  "message": "${commit_msg}",
  "branch": "${branch_name}",
  "committer": {
    "name": "e2e test user",
    "email": "dummy@redhat.com"
  },
  "content": "bXkgbmV3IGZpbGUgY29udGVudHM="
}
EOF

new_commit=$(curl -L -s \
  -X PUT \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/${repo_name}/contents/${file_name} \
  -d "@${tmpFile}")
SHA=$(jq -r '.commit.sha // ""' <<< "${new_commit}")

if [ -z "${SHA}" ]; then
  echo "error: could not get SHA for new commit on branch $branch_name"
  echo "${new_commit}"
  exit 1
fi
echo "new commit created: $SHA"
