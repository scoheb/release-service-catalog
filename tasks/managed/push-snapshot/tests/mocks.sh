#!/usr/bin/env bash
set -eux

# mocks to be injected into task step scripts

function cosign() {
  echo Mock cosign called with: $*
  echo $* >> "$(params.dataDir)/$(params.subdirectory)/mock_cosign.txt"

  # mock cosign failing the first 3x for the retry test
  if [[ "$*" == "copy -f registry.io/retry-image:tag "*":"* ]]
  then
    if [[ "$(wc -l < "$(params.dataDir)/$(params.subdirectory)/mock_cosign.txt")" -le 3 ]]
    then
      echo Expected cosign call failure for retry test
      return 1
    fi
  fi

  if [[ "$*" == "copy -f private-registry.io/image:tag "*":"* ]]
  then
    if [[ $(cat /etc/ssl/certs/ca-custom-bundle.crt) != "mycert" ]]
    then
      echo Custom certificate not mounted
      return 1
    fi
  fi

  if [[ "$*" != "copy -f "*":"*" "*":"* ]]
  then
    echo Error: Unexpected call
    exit 1
  fi
}

function skopeo() {
  echo Mock skopeo called with: $* >&2
  echo $* >> "$(workspaces.data.path)/$(params.subdirectory)/mock_skopeo.txt"
  if [[ "$*" == "inspect --raw docker://reg.io/test@sha256:abcdefg" ]]; then
    echo '{"mediaType": "application/vnd.oci.image.index.v1+json", "manifests": [{"platform":{"os":"linux","architecture":"amd64"}}, {"platform":{"os":"linux","architecture":"ppc64le"}}]}'
    return
  elif [[ "$*" == "inspect --raw docker://"* ]]; then
    echo '{"mediaType": "my_media_type"}'
    return
  fi

  # If neither of the above matched, it's an unexpected call
  echo Error: Unexpected call
  exit 1
}

function get-image-architectures() {
  echo '{"platform":{"architecture": "ppc64le", "os": "linux"}, "digest": "deadbeef"}'
  echo '{"platform":{"architecture": "amd64", "os": "linux"}, "digest": "abcdefg"}'
}

function select-oci-auth() {
  echo $* >> "$(params.dataDir)/$(params.subdirectory)/mock_select-oci-auth.txt"
}

function oras() {
  echo $* >> "$(workspaces.data.path)/$(params.subdirectory)/mock_oras.txt"
  if [[ "$*" == "resolve --registry-config "*" "* ]]; then
    if [[ "$*" =~ "--platform" && "$4" =~ ".src" ]]; then
      echo "Error: .src images should not use --platform" >&2
      exit 1
    fi
    if [[ "$4" == "reg.io/test@sha256:abcdefg" ]]; then
      echo "sha256:abcdefg"
    elif [[ "$4" == "reg.io/test:sha256-abcdefg.src" ]]; then
      echo "sha256:abcdefg"
    elif [[ "$4" == "prod.io/loc:sha256-abcdefg.src" ]]; then
      echo "sha256:abcdefg"
    elif [[ "$4" == "prod.io/loc:multi-tag-source" ]]; then
      echo "sha256:abcdefg"
    elif [[ "$4" == *skip-image*.src || "$4" == *skip-image*-source ]]; then
      echo "sha256:000000"
    elif [[ "$4" == *skip-image* ]]; then
      echo "sha256:111111"
    else
      # echo the shasum computed from the pull spec so the task knows if two images are the same
      echo -n "sha256:"
      echo $4 | sha256sum | cut -d ' ' -f 1
    fi
    return
  else
    echo Mock oras called with: $*
    echo Error: Unexpected call
    exit 1
  fi
}
