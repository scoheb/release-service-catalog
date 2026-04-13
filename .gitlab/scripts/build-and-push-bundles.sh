#!/usr/bin/env bash
set -euo pipefail

# Build and push Tekton bundles for the release-service-catalog.
#
# Copies source files to a temp directory, converts git resolver references to
# bundle resolver, then pushes everything as OCI bundles. The working tree is
# never modified.
#
# Usage:
#   ./build-and-push-bundles.sh --registry <registry> --tag <tag> [options]
#
# Required:
#   --registry <reg>   Bundle registry (e.g. quay.io/scoheb)
#   --tag <tag>        Bundle tag (e.g. test-20260409)
#
# Optional:
#   --expire <dur>     Set quay.expires-after label (e.g. 7d)
#   --dry-run          Convert files but skip pushing
#   --pipeline <name>  Only build a specific managed pipeline (and its tasks)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CONVERT_SCRIPT="${SCRIPT_DIR}/convert-to-bundle-resolver.py"

REGISTRY=""
TAG=""
EXPIRE=""
DRY_RUN=false
SINGLE_PIPELINE=""
REMOTE_USERNAME=""
REMOTE_PASSWORD=""
ALSO_TAG_LATEST=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --registry) REGISTRY="$2"; shift 2 ;;
        --tag)      TAG="$2"; shift 2 ;;
        --expire)   EXPIRE="$2"; shift 2 ;;
        --dry-run)  DRY_RUN=true; shift ;;
        --pipeline) SINGLE_PIPELINE="$2"; shift 2 ;;
        --username) REMOTE_USERNAME="$2"; shift 2 ;;
        --password) REMOTE_PASSWORD="$2"; shift 2 ;;
        --latest)   ALSO_TAG_LATEST=true; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

if [[ -z "$REGISTRY" || -z "$TAG" ]]; then
    echo "Usage: $0 --registry <registry> --tag <tag> [--expire <dur>] [--dry-run] [--pipeline <name>]"
    echo "       [--username <user>] [--password <pass>]"
    exit 1
fi

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT
echo "Working directory: $WORKDIR"

EXTRA_ARGS=""
if [[ -n "$EXPIRE" ]]; then
    EXTRA_ARGS="--label quay.expires-after=${EXPIRE}"
fi
if [[ -n "$REMOTE_USERNAME" && -n "$REMOTE_PASSWORD" ]]; then
    EXTRA_ARGS="${EXTRA_ARGS} --remote-username ${REMOTE_USERNAME} --remote-password ${REMOTE_PASSWORD}"
fi

push_bundle() {
    local file="$1"
    local ref="$2"

    if [[ "$DRY_RUN" == true ]]; then
        echo "  [dry-run] would push $ref"
        return
    fi

    tkn bundle push ${EXTRA_ARGS} -f "$file" "$ref" 2>&1 | tail -1
}

# --- Determine which tasks are needed ---

collect_pipeline_tasks() {
    local pipeline_file="$1"
    python3 -c "
import re, sys
with open(sys.argv[1]) as f:
    text = f.read()
for m in re.finditer(r'tasks/managed/([^/]+)/', text):
    print('managed/' + m.group(1))
for m in re.finditer(r'hub/([^/]+)/', text):
    print('hub/' + m.group(1))
for m in re.finditer(r'stepactions/([^/]+)/', text):
    print('stepaction/' + m.group(1))
" "$pipeline_file" | sort -u
}

# --- Step 1: Identify resources to bundle ---

declare -A TASKS_TO_PUSH
declare -A STEPACTIONS_TO_PUSH
declare -A PIPELINES_TO_PUSH

if [[ -n "$SINGLE_PIPELINE" ]]; then
    pipeline_file="${REPO_ROOT}/pipelines/managed/${SINGLE_PIPELINE}/${SINGLE_PIPELINE}.yaml"
    if [[ ! -f "$pipeline_file" ]]; then
        echo "Error: Pipeline not found: $pipeline_file"
        exit 1
    fi
    PIPELINES_TO_PUSH["$SINGLE_PIPELINE"]=1

    while IFS= read -r entry; do
        kind="${entry%%/*}"
        name="${entry#*/}"
        case "$kind" in
            managed)     TASKS_TO_PUSH["managed/$name"]=1 ;;
            hub)         TASKS_TO_PUSH["hub/$name"]=1 ;;
            stepaction)  STEPACTIONS_TO_PUSH["$name"]=1 ;;
        esac
    done < <(collect_pipeline_tasks "$pipeline_file")

    # Also scan the managed tasks for stepaction refs
    for key in "${!TASKS_TO_PUSH[@]}"; do
        kind="${key%%/*}"
        name="${key#*/}"
        if [[ "$kind" == "managed" ]]; then
            task_file="${REPO_ROOT}/tasks/managed/${name}/${name}.yaml"
            if [[ -f "$task_file" ]]; then
                while IFS= read -r entry; do
                    sa_kind="${entry%%/*}"
                    sa_name="${entry#*/}"
                    if [[ "$sa_kind" == "stepaction" ]]; then
                        STEPACTIONS_TO_PUSH["$sa_name"]=1
                    fi
                done < <(collect_pipeline_tasks "$task_file")
            fi
        fi
    done
else
    for task_dir in "${REPO_ROOT}"/tasks/managed/*/; do
        name=$(basename "$task_dir")
        TASKS_TO_PUSH["managed/$name"]=1
    done
    for task_dir in "${REPO_ROOT}"/hub/*/; do
        name=$(basename "$task_dir")
        TASKS_TO_PUSH["hub/$name"]=1
    done
    for sa_dir in "${REPO_ROOT}"/stepactions/*/; do
        name=$(basename "$sa_dir")
        STEPACTIONS_TO_PUSH["$name"]=1
    done
    for pipeline_dir in "${REPO_ROOT}"/pipelines/managed/*/; do
        name=$(basename "$pipeline_dir")
        PIPELINES_TO_PUSH["$name"]=1
    done
fi

echo ""
echo "=== Build Plan ==="
echo "Registry:     $REGISTRY"
echo "Tag:          $TAG"
echo "Tasks:        ${#TASKS_TO_PUSH[@]}"
echo "StepActions:  ${#STEPACTIONS_TO_PUSH[@]}"
echo "Pipelines:    ${#PIPELINES_TO_PUSH[@]}"
echo ""

# --- Step 2: Push stepaction bundles (unmodified) ---

echo "--- StepActions ---"
for sa_name in "${!STEPACTIONS_TO_PUSH[@]}"; do
    sa_file="${REPO_ROOT}/stepactions/${sa_name}/${sa_name}.yaml"
    if [[ -f "$sa_file" ]]; then
        echo "Pushing stepaction: $sa_name"
        push_bundle "$sa_file" "${REGISTRY}:stepaction-${sa_name}-${TAG}"
    else
        echo "Warning: stepaction not found: $sa_file"
    fi
done

# --- Step 3: Convert and push task bundles ---

echo ""
echo "--- Tasks ---"
for key in "${!TASKS_TO_PUSH[@]}"; do
    kind="${key%%/*}"
    name="${key#*/}"

    case "$kind" in
        managed) src_file="${REPO_ROOT}/tasks/managed/${name}/${name}.yaml" ;;
        hub)     src_file="${REPO_ROOT}/hub/${name}/${name}.yaml" ;;
    esac

    if [[ ! -f "$src_file" ]]; then
        echo "Warning: task not found: $src_file"
        continue
    fi

    # Tag prefix must match what convert-to-bundle-resolver.py generates:
    # managed tasks -> "task-", hub tasks -> "hub-"
    tag_prefix="$kind"
    if [[ "$kind" == "managed" ]]; then
        tag_prefix="task"
    fi

    out_file="${WORKDIR}/${tag_prefix}-${name}.yaml"
    echo "Converting task: ${kind}/${name}"
    python3 "$CONVERT_SCRIPT" "$src_file" "$out_file" "$REGISTRY" "$TAG"
    push_bundle "$out_file" "${REGISTRY}:${tag_prefix}-${name}-${TAG}"
done

# --- Step 4: Convert and push pipeline bundles ---

echo ""
echo "--- Pipelines ---"
for pipeline_name in "${!PIPELINES_TO_PUSH[@]}"; do
    src_file="${REPO_ROOT}/pipelines/managed/${pipeline_name}/${pipeline_name}.yaml"
    if [[ ! -f "$src_file" ]]; then
        echo "Warning: pipeline not found: $src_file"
        continue
    fi

    out_file="${WORKDIR}/pipeline-${pipeline_name}.yaml"
    echo "Converting pipeline: $pipeline_name"
    python3 "$CONVERT_SCRIPT" "$src_file" "$out_file" "$REGISTRY" "$TAG"
    push_bundle "$out_file" "${REGISTRY}:pipeline-${pipeline_name}-${TAG}"
done

# --- Step 5 (optional): Also push "latest" tags ---

if [[ "$ALSO_TAG_LATEST" == true ]]; then
    echo ""
    echo "--- Pushing latest tags ---"

    for sa_name in "${!STEPACTIONS_TO_PUSH[@]}"; do
        sa_file="${REPO_ROOT}/stepactions/${sa_name}/${sa_name}.yaml"
        if [[ -f "$sa_file" ]]; then
            push_bundle "$sa_file" "${REGISTRY}:stepaction-${sa_name}-latest"
        fi
    done

    for key in "${!TASKS_TO_PUSH[@]}"; do
        kind="${key%%/*}"
        name="${key#*/}"
        tag_prefix="$kind"
        if [[ "$kind" == "managed" ]]; then
            tag_prefix="task"
        fi
        case "$kind" in
            managed) src_file="${REPO_ROOT}/tasks/managed/${name}/${name}.yaml" ;;
            hub)     src_file="${REPO_ROOT}/hub/${name}/${name}.yaml" ;;
        esac
        if [[ -f "$src_file" ]]; then
            out_file="${WORKDIR}/${tag_prefix}-${name}-latest.yaml"
            python3 "$CONVERT_SCRIPT" "$src_file" "$out_file" "$REGISTRY" "latest"
            push_bundle "$out_file" "${REGISTRY}:${tag_prefix}-${name}-latest"
        fi
    done

    for pipeline_name in "${!PIPELINES_TO_PUSH[@]}"; do
        src_file="${REPO_ROOT}/pipelines/managed/${pipeline_name}/${pipeline_name}.yaml"
        if [[ -f "$src_file" ]]; then
            out_file="${WORKDIR}/pipeline-${pipeline_name}-latest.yaml"
            python3 "$CONVERT_SCRIPT" "$src_file" "$out_file" "$REGISTRY" "latest"
            push_bundle "$out_file" "${REGISTRY}:pipeline-${pipeline_name}-latest"
        fi
    done
fi

# --- Summary ---

echo ""
echo "=== Done ==="
echo "Pipeline bundle ref(s):"
for pipeline_name in "${!PIPELINES_TO_PUSH[@]}"; do
    echo "  ${REGISTRY}:pipeline-${pipeline_name}-${TAG}"
done
