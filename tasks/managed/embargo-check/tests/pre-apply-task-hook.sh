#!/usr/bin/env bash

# Add mocks to the beginning of task step script
TASK_PATH="$1"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
yq -i '.spec.steps[2].script = load_str("'$SCRIPT_DIR'/mocks.sh") + .spec.steps[2].script' "$TASK_PATH"
yq -i '.spec.steps[3].script = load_str("'$SCRIPT_DIR'/mocks.sh") + .spec.steps[3].script' "$TASK_PATH"
