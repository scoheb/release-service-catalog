#!/usr/bin/env python3
"""
Convert git resolver references to bundle resolver references in Tekton YAML files.

Usage: convert-to-bundle-resolver.py <input-file> <output-file> <bundle-repo> <bundle-tag>

This script:
1. Reads the input Tekton YAML (Pipeline or Task)
2. Converts taskRef sections that use git resolver pointing to release-service-catalog
   MANAGED tasks to use bundle resolver instead
3. Converts stepAction refs that use git resolver to use bundle resolver
4. Writes the processed output to the output file

The following are NOT converted (remain as git resolver):
- External tasks (mobster, conforma, etc.) - have their own versioning strategy
- Internal tasks (tasks/internal/*) - not bundled
- Collector tasks (tasks/collectors/*) - not bundled
- Hub tasks (hub/*) - not bundled
"""

import sys
import re
from pathlib import Path

try:
    from ruamel.yaml import YAML
except ImportError:
    print("Error: ruamel.yaml is required. Install with: pip install ruamel.yaml")
    sys.exit(1)


def extract_task_info(path_in_repo: str) -> tuple[str, str, str] | None:
    """
    Extract task name and tag prefix from pathInRepo value.

    Returns: (task_name, tag_prefix, kind) or None if not a bundled task.

    The following are converted to bundles:
    - Managed tasks (tasks/managed/*)
    - Hub tasks (hub/*)

    The following remain as git resolver:
    - Internal tasks (tasks/internal/*)
    - Collector tasks (tasks/collectors/*)
    """
    # Check for managed tasks
    match = re.search(r"tasks/managed/([^/]+)/", path_in_repo)
    if match:
        task_name = match.group(1)
        return task_name, "task", "Task"

    # Check for hub tasks
    match = re.search(r"hub/([^/]+)/", path_in_repo)
    if match:
        task_name = match.group(1)
        return task_name, "hub", "Task"

    return None


def extract_stepaction_info(path_in_repo: str) -> tuple[str, str, str] | None:
    """
    Extract stepaction name and tag prefix from pathInRepo value.

    Returns: (stepaction_name, tag_prefix, kind) or None if not a stepaction.
    """
    match = re.search(r"stepactions/([^/]+)/", path_in_repo)
    if match:
        stepaction_name = match.group(1)
        return stepaction_name, "stepaction", "StepAction"

    return None


def is_release_service_catalog_ref(url: str) -> bool:
    """Check if the URL points to release-service-catalog."""
    patterns = [
        r"release-service-catalog",
        r"\$\(params\.taskGitUrl\)",
    ]
    return any(re.search(p, url) for p in patterns)


def get_param_value(params: list, name: str) -> str | None:
    """Get the value of a parameter by name."""
    for param in params:
        if param.get("name") == name:
            return param.get("value")
    return None


def convert_ref(ref: dict, bundle_repo: str, bundle_tag: str, ref_type: str = "task") -> dict | None:
    """
    Convert a git resolver ref (taskRef or stepAction ref) to a bundle resolver ref.

    Args:
        ref: The ref dict to convert
        bundle_repo: The single bundle repository (e.g., quay.io/hummingbird-ci/release-bundles)
        bundle_tag: The tag suffix to use (e.g., git-abc123)
        ref_type: Either "task" or "stepaction"

    Returns the new ref dict or None if no conversion needed.
    """
    if ref.get("resolver") != "git":
        return None

    params = ref.get("params", [])
    url = get_param_value(params, "url")
    path_in_repo = get_param_value(params, "pathInRepo")

    if not url or not path_in_repo:
        return None

    if not is_release_service_catalog_ref(url):
        return None

    if ref_type == "stepaction":
        info = extract_stepaction_info(path_in_repo)
    else:
        info = extract_task_info(path_in_repo)

    if not info:
        return None

    name, tag_prefix, kind = info

    # Extract the actual name from the YAML filename
    yaml_name = Path(path_in_repo).stem

    # Construct the bundle URL: repo:prefix-name-tag
    bundle_url = f"{bundle_repo}:{tag_prefix}-{name}-{bundle_tag}"

    return {
        "resolver": "bundles",
        "params": [
            {"name": "name", "value": yaml_name},
            {"name": "bundle", "value": bundle_url},
            {"name": "kind", "value": kind},
        ],
    }


def convert_taskref(task_ref: dict, bundle_repo: str, bundle_tag: str) -> dict | None:
    """Convert a git resolver taskRef to a bundle resolver taskRef."""
    return convert_ref(task_ref, bundle_repo, bundle_tag, "task")


def process_pipeline_tasks(tasks: list, bundle_repo: str, bundle_tag: str) -> int:
    """Process a list of pipeline tasks and convert their taskRefs. Returns count of conversions."""
    conversions = 0
    for task in tasks:
        if "taskRef" not in task:
            continue

        new_taskref = convert_taskref(task["taskRef"], bundle_repo, bundle_tag)
        if new_taskref:
            task["taskRef"] = new_taskref
            conversions += 1

    return conversions


def process_task_steps(steps: list, bundle_repo: str, bundle_tag: str) -> int:
    """Process a list of task steps and convert their stepAction refs. Returns count of conversions."""
    conversions = 0
    for step in steps:
        if "ref" not in step:
            continue

        new_ref = convert_ref(step["ref"], bundle_repo, bundle_tag, "stepaction")
        if new_ref:
            step["ref"] = new_ref
            conversions += 1

    return conversions


def ensure_pipeline_param_defaults(doc: dict, git_url: str = None, git_revision: str = None) -> None:
    """
    Ensure pipeline parameters have default values for params needed by hub tasks
    and internal pipelines.

    Hub tasks and internal pipelines still use git resolver and need taskGitUrl
    and taskGitRevision. Since RPA with bundle resolver can't pass pipeline params,
    we need defaults in the pipeline.

    Args:
        doc: The pipeline document
        git_url: Override for taskGitUrl default (e.g., from CI_PROJECT_URL)
        git_revision: Override for taskGitRevision default (e.g., from CI_COMMIT_SHA)
    """
    import os

    if "spec" not in doc or "params" not in doc["spec"]:
        return

    # Use environment variables if not provided
    if git_url is None:
        git_url = os.environ.get("CI_PROJECT_URL", "https://github.com/konflux-ci/release-service-catalog")
        if not git_url.endswith(".git"):
            git_url = git_url + ".git"

    if git_revision is None:
        git_revision = os.environ.get("CI_COMMIT_SHA", "development")

    for param in doc["spec"]["params"]:
        name = param.get("name")
        if name == "taskGitUrl":
            param["default"] = git_url
            print(f"  Set taskGitUrl default to: {git_url}")
        elif name == "taskGitRevision":
            param["default"] = git_revision
            print(f"  Set taskGitRevision default to: {git_revision}")


def convert_file(input_file: str, output_file: str, bundle_repo: str, bundle_tag: str):
    """Convert a Tekton YAML file (Pipeline or Task) from git resolver to bundle resolver."""
    yaml = YAML()
    yaml.preserve_quotes = True
    yaml.width = 120

    with open(input_file, "r") as f:
        doc = yaml.load(f)

    conversions = 0
    kind = doc.get("kind", "")

    if kind == "Pipeline":
        # Ensure hub tasks have default values for git resolver params
        ensure_pipeline_param_defaults(doc)

        # Process spec.tasks
        if "spec" in doc and "tasks" in doc["spec"]:
            conversions += process_pipeline_tasks(doc["spec"]["tasks"], bundle_repo, bundle_tag)

        # Process spec.finally
        if "spec" in doc and "finally" in doc["spec"]:
            conversions += process_pipeline_tasks(doc["spec"]["finally"], bundle_repo, bundle_tag)

    elif kind == "Task":
        # Process spec.steps for stepAction refs
        if "spec" in doc and "steps" in doc["spec"]:
            conversions += process_task_steps(doc["spec"]["steps"], bundle_repo, bundle_tag)

    # Write output
    Path(output_file).parent.mkdir(parents=True, exist_ok=True)
    with open(output_file, "w") as f:
        yaml.dump(doc, f)

    print(f"Converted {input_file} -> {output_file} ({conversions} refs converted)")


def main():
    if len(sys.argv) != 5:
        print(f"Usage: {sys.argv[0]} <input-file> <output-file> <bundle-repo> <bundle-tag>")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]
    bundle_repo = sys.argv[3]
    bundle_tag = sys.argv[4]

    if not Path(input_file).exists():
        print(f"Error: Input file '{input_file}' not found")
        sys.exit(1)

    convert_file(input_file, output_file, bundle_repo, bundle_tag)


if __name__ == "__main__":
    main()
