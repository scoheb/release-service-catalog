#!/usr/bin/env bash

TASK_PATH="$1"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Inject mocks.sh into the task's first step
yq -i '.spec.steps[2].script = load_str("'"$SCRIPT_DIR"'/mocks.sh") + .spec.steps[2].script' "$TASK_PATH"
