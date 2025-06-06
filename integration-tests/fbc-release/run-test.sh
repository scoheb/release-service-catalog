#!/usr/bin/env bash
#
# Summary:
#   This script executes an end-to-end test for a software release process.
#   It simulates a complete workflow including:
#     - Setting up the environment and parsing command-line options.
#     - Decrypting secrets using Ansible Vault.
#     - Interacting with GitHub to create branches and merge pull requests.
#     - Creating and managing Kubernetes resources (namespaces, custom resources)
#       using kustomize and envsubst.
#     - Monitoring the initialization of Konflux Components.
#     - Waiting for and monitoring Tekton PipelineRuns related to component builds.
#     - Waiting for a Release custom resource to complete its lifecycle.
#     - Verifying the contents of the Release, including checking for
#       Jira issues, advisory details (fetched via a helper script), and CVE data.
#     - Performing cleanup of created resources upon script completion or error,
#       unless explicitly skipped.
#
# Command-line Options:
#   -sc, --skip-cleanup   : If set, the script will not perform cleanup operations
#                           (GitHub branches, Kubernetes resources) on exit.
#   -nocve, --no-cve       : If set, the script will not simulate the addition of a CVE. This
#                           affects the commit message during PR merge and the
#                           expected CVE data during release verification.
#                           The default mode is to include CVE data.
#
# Environment Variables (Expected, typically sourced from 'test.env'):
#   Required:
#     GITHUB_TOKEN                  - GitHub Personal Access Token for API interactions.
#     VAULT_PASSWORD_FILE           - Path to the Ansible Vault password file for secret decryption.
#     RELEASE_CATALOG_GIT_URL       - Git URL for the release service catalog (used by helper scripts).
#     RELEASE_CATALOG_GIT_REVISION  - Git revision (branch/tag) for the release service catalog.
#     component_branch              - The name of the component branch to be created.
#     component_base_branch         - The base branch from which the component branch is created.
#     component_repo_name           - The GitHub repository name (e.g., "owner/repo").
#     managed_namespace             - Kubernetes namespace for managed resources.
#     tenant_namespace              - Kubernetes namespace for tenant-specific resources and Release CR.
#     application_name              - The name of the AppStudio Application.
#     component_name                - The name of the AppStudio Component.
#     managed_sa_name               - ServiceAccount name in the managed namespace (used by get-advisory-content.sh).
#   Optional:
#     KUBECONFIG                    - Path to the Kubernetes configuration file.
#
# Dependencies:
#   External commands: ansible-vault, kubectl, kustomize, envsubst, curl, jq,
#                      oc, tkn, yq, mktemp.
#   Helper scripts: Located in the SCRIPT_DIR/../scripts/ directory, including:
#                     - delete-single-branch.sh
#                     - create-branch-from-base.sh
#                     - add-retry-comment-to-pr.sh
#                     - wait-for-release.sh
#                     - get-advisory-content.sh
#
# Exit Behavior:
#   - Exits 0 on successful completion of all steps and verifications.
#   - Exits with a non-zero status code on error.
#   - A trap is set to call the 'cleanup_resources' function on EXIT, regardless
#     of success or failure (unless --skip-cleanup is used).

set -eo pipefail

# --- Configuration & Global Variables ---
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
LIB_DIR="${SCRIPT_DIR}/../lib"

# Source environment variables (ensure this file exists and is correctly populated)
if [ -f "${SCRIPT_DIR}/test.env" ]; then
    . "${SCRIPT_DIR}/test.env"
else
    echo "error: test.env not found in ${SCRIPT_DIR}"
    exit 1
fi

# Source the function library
if [ -f "${LIB_DIR}/test-functions.sh" ]; then
    . "${LIB_DIR}/test-functions.sh"
else
    echo "error: Function library test-functions.sh not found in ${LIB_DIR}"
    exit 1
fi

# --- Global Script Variables (Defaults) ---
CLEANUP="true"
NO_CVE="true" # Default to true

# Variables that will be set by functions and used globally:
# component_branch, component_base_branch, component_repo_name (from test.env or similar)
# managed_namespace, tenant_namespace, application_name, component_name (from test.env or similar)
# managed_sa_name (from test.env or similar)
# GITHUB_TOKEN, VAULT_PASSWORD_FILE (from test.env)
# SCRIPT_DIR (defined above)
# LIB_DIR (defined above)
# tmpDir (set by create_kubernetes_resources)
# component_pr, pr_number (set by wait_for_component_initialization)
# SHA (set by merge_github_pr)
# component_push_plr_name (set by wait_for_plr_to_appear)
# RELEASE_NAME, RELEASE_NAMESPACE (set and exported by wait_for_release)
# advisory_yaml_dir (set by verify_release_contents)

# Function to verify Release contents
# Modifies global variable: advisory_yaml_dir
# Relies on global variables: RELEASE_NAMES, RELEASE_NAMESPACE, SCRIPT_DIR, managed_namespace, managed_sa_name, NO_CVE
verify_release_contents() {

    local failed_releases
    for RELEASE_NAME in ${RELEASE_NAMES};
    do
      echo "Verifying Release contents for ${RELEASE_NAME} in namespace ${RELEASE_NAMESPACE}..."
      local release_json
      release_json=$(kubectl get release/"${RELEASE_NAME}" -n "${RELEASE_NAMESPACE}" -ojson)
      if [ -z "$release_json" ]; then
          log_error "Could not retrieve Release JSON for ${RELEASE_NAME}"
      fi

      local failures=0
      local fbc_fragment ocp_version iib_log index_image index_image_resolved

      fbc_fragment=$(jq -r '.status.artifacts.components[0].fbc_fragment // ""' <<< "${release_json}")
      ocp_version=$(jq -r '.status.artifacts.components[0].ocp_version // ""' <<< "${release_json}")
      iib_log=$(jq -r '.status.artifacts.components[0].iibLog // ""' <<< "${release_json}")

      index_image=$(jq -r '.status.artifacts.index_image.index_image // ""' <<< "${release_json}")
      index_image_resolved=$(jq -r '.status.artifacts.index_image.index_image_resolved // ""' <<< "${release_json}")

      echo "Checking fbc_fragment..."
      if [ -n "${fbc_fragment}" ]; then
        echo "✅️ fbc_fragment: ${fbc_fragment}"
      else
        echo "🔴 fbc_fragment was empty!"
        failures=$((failures+1))
      fi
      echo "Checking ocp_version..."
      if [ -n "${ocp_version}" ]; then
        echo "✅️ ocp_version: ${ocp_version}"
      else
        echo "🔴 ocp_version was empty!"
        failures=$((failures+1))
      fi
      echo "Checking iib_log..."
      if [ -n "${iib_log}" ]; then
        echo "✅️ iib_log: ${iib_log}"
      else
        echo "🔴 iib_log was empty!"
        failures=$((failures+1))
      fi
      echo "Checking index_image..."
      if [ -n "${index_image}" ]; then
        echo "✅️ index_image: ${index_image}"
      else
        echo "🔴 index_image was empty!"
        failures=$((failures+1))
      fi
      echo "Checking index_image_resolved..."
      if [ -n "${index_image_resolved}" ]; then
        echo "✅️ index_image_resolved: ${index_image_resolved}"
      else
        echo "🔴 index_image_resolved was empty!"
        failures=$((failures+1))
      fi

      if [ "${failures}" -gt 0 ]; then
        echo "🔴 Test has FAILED with ${failures} failure(s)!"
        failed_releases="${RELEASE_NAME} ${failed_releases}"
      else
        echo "✅️ All release checks passed. Success!"
      fi
    done

    if [ -n "${failed_releases}" ]; then
      echo "🔴 Releases FAILED: ${failed_releases}"
      exit 1
    else
      echo "✅️ Success!"
    fi
}

# --- Main Script Execution ---

# Trap EXIT signal to call cleanup function
# Pass error code, line number, and command to the cleanup function
trap 'cleanup_resources $? $LINENO "$BASH_COMMAND"' EXIT

check_env_vars "$@" # Pass all args for consistency, though check_env_vars doesn't use them
parse_options "$@" # Parses options and sets CLEANUP, NO_CVE

decrypt_secrets
create_github_branch
setup_namespaces # Ensures correct context before resource creation
create_kubernetes_resources # tmpDir is set here

wait_for_component_initialization # component_pr and pr_number are set here
merge_github_pr # SHA is set here

wait_for_plr_to_appear # component_push_plr_name is set here
wait_for_plr_to_complete

wait_for_releases # RELEASE_NAME, RELEASE_NAMESPACE are set and exported here
verify_release_contents

echo "✅️ End-to-end test script completed successfully."
exit 0
