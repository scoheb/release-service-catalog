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

suite=$1
if [ -z "$suite" ] ; then
  echo "🔴 error: missing parameter suite"
  exit 1
fi

# --- Configuration & Global Variables ---
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
LIB_DIR="${SCRIPT_DIR}/lib"

SUITE_DIR="${SCRIPT_DIR}/${suite}" # e.g. "${SCRIPT_DIR}/fbc-release"

# Source environment variables (ensure this file exists and is correctly populated)
if [ -f "${SUITE_DIR}/test.env" ]; then
    . "${SUITE_DIR}/test.env"
else
    echo "error: test.env not found in ${SUITE_DIR}"
    exit 1
fi

# Source the function library
if [ -f "${LIB_DIR}/test-functions.sh" ]; then
    . "${LIB_DIR}/test-functions.sh"
else
    echo "error: Function library test-functions.sh not found in ${LIB_DIR}"
    exit 1
fi

# Source test script (ensure this file exists and is correctly populated)
if [ -f "${SUITE_DIR}/test.sh" ]; then
    . "${SUITE_DIR}/test.sh"
else
    echo "error: test.sh not found in ${SUITE_DIR}"
    exit 1
fi

# --- Main Script Execution ---

# Trap EXIT signal to call cleanup function
# Pass error code, line number, and command to the cleanup function
trap 'cleanup_resources $? $LINENO "$BASH_COMMAND"' EXIT

check_env_vars "$@" # Pass all args for consistency, though check_env_vars doesn't use them
parse_options "$@" # Parses options and sets CLEANUP, NO_CVE

decrypt_secrets
delete_old_branches "${component_repo_name}" 2
create_github_branch
setup_namespaces # Ensures correct context before resource creation
cleanup_old_resources "${originating_tool}"
create_kubernetes_resources # tmpDir is set here

wait_for_component_initialization # component_pr and pr_number are set here
merge_github_pr # SHA is set here

wait_for_plr_to_appear # component_push_plr_name is set here
wait_for_plr_to_complete

wait_for_releases # RELEASE_NAME, RELEASE_NAMESPACE are set and exported here
verify_release_contents

echo "✅️ End-to-end test script completed successfully."
exit 0
