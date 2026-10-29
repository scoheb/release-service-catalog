#!/usr/bin/env python3
"""Promote the image from the exact, passed PR Snapshot for a merged RPM PR."""

import json
import os
import re
import ssl
from pathlib import Path
from urllib.error import HTTPError
from urllib.parse import urlencode
from urllib.request import Request, urlopen

SHA_RE = re.compile(r"[0-9a-f]{40}\Z")
IMAGE_RE = re.compile(r"[^@]+@sha256:[0-9a-f]{64}\Z")
PAC_PREFIX = "pac.test.appstudio.openshift.io"
CA_FILE = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"


def read_json(url, token=None, ca_file=None):
    headers = {
        "Accept": "application/json",
        "User-Agent": "hum-5186-rpm-promotion-test",
    }
    if token:
        headers["Authorization"] = f"Bearer {token}"
    context = ssl.create_default_context(cafile=ca_file) if ca_file else None
    with urlopen(
        Request(url, headers=headers), timeout=20, context=context
    ) as response:
        return json.load(response)


def create_snapshot(url, manifest, token):
    request = Request(
        url,
        data=json.dumps(manifest).encode(),
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {token}",
        },
        method="POST",
    )
    try:
        with urlopen(
            request, timeout=20, context=ssl.create_default_context(cafile=CA_FILE)
        ) as response:
            return json.load(response)
    except HTTPError as error:
        if error.code != 409:
            raise
        existing = read_json(f"{url}/{manifest['metadata']['name']}", token, CA_FILE)
        if existing.get("spec") != manifest["spec"]:
            raise ValueError(
                "existing promoted Snapshot has different component data"
            ) from error
        for key, value in manifest["metadata"]["labels"].items():
            if existing.get("metadata", {}).get("labels", {}).get(key) != value:
                raise ValueError(
                    f"existing promoted Snapshot has different {key} label"
                ) from error
        return existing


def main():
    merge_sha = os.environ["MERGE_SHA"]
    repo = os.environ["GITHUB_REPO"]
    branch = os.environ["TARGET_BRANCH"]
    application = os.environ["APPLICATION"]
    component = os.environ["COMPONENT"]
    namespace = os.environ["NAMESPACE"]
    if not SHA_RE.fullmatch(merge_sha) or not re.fullmatch(r"[\w.-]+/[\w.-]+", repo):
        raise ValueError("invalid merge SHA or repository")

    pulls = read_json(
        f"https://api.github.com/repos/{repo}/commits/{merge_sha}/pulls?per_page=100",
        os.environ.get("GITHUB_TOKEN"),
    )
    matches = [
        pull
        for pull in pulls
        if pull.get("merged_at")
        and pull.get("merge_commit_sha") == merge_sha
        and pull.get("base", {}).get("ref") == branch
    ]
    if len(matches) != 1:
        raise ValueError(
            f"expected one merged PR for {merge_sha} on {branch}; found {len(matches)}"
        )
    pr_number = matches[0]["number"]
    pr_sha = matches[0]["head"]["sha"]
    if not isinstance(pr_number, int) or not SHA_RE.fullmatch(pr_sha):
        raise ValueError("merged PR has no valid number or head SHA")

    host = os.environ["KUBERNETES_SERVICE_HOST"]
    port = os.environ.get("KUBERNETES_SERVICE_PORT_HTTPS", "443")
    url = f"https://{host}:{port}/apis/appstudio.redhat.com/v1alpha1/namespaces/{namespace}/snapshots"
    selector = ",".join(
        (
            f"appstudio.openshift.io/application={application}",
            f"appstudio.openshift.io/component={component}",
            f"{PAC_PREFIX}/pull-request={pr_number}",
            "test.appstudio.openshift.io/type=component",
        )
    )
    token = Path("/var/run/secrets/kubernetes.io/serviceaccount/token").read_text()
    snapshots = read_json(
        f"{url}?{urlencode({'labelSelector': selector})}", token, CA_FILE
    )["items"]
    candidates = [
        snapshot
        for snapshot in snapshots
        if snapshot["metadata"].get("labels", {}).get(f"{PAC_PREFIX}/event-type")
        == "pull_request"
        and snapshot["metadata"]["labels"].get(f"{PAC_PREFIX}/sha") == pr_sha
        and snapshot["spec"].get("application") == application
    ]
    if not candidates:
        raise ValueError(f"no PR Snapshot for {component} PR #{pr_number} at {pr_sha}")
    pr_snapshot = max(
        candidates, key=lambda item: item["metadata"].get("creationTimestamp", "")
    )
    if not any(
        condition.get("type") == "AppStudioTestSucceeded"
        and condition.get("status") == "True"
        for condition in pr_snapshot.get("status", {}).get("conditions", [])
    ):
        raise ValueError(
            f"PR Snapshot {pr_snapshot['metadata']['name']} has not passed"
        )
    built = [
        item for item in pr_snapshot["spec"]["components"] if item["name"] == component
    ]
    if len(built) != 1:
        raise ValueError(f"PR Snapshot has {len(built)} entries for {component}")
    source = built[0]["source"]["git"]
    if (
        source["revision"] != pr_sha
        or source["url"].removesuffix(".git").rstrip("/")
        != f"https://github.com/{repo}"
    ):
        raise ValueError("PR Snapshot source differs from merged PR")
    if not IMAGE_RE.fullmatch(built[0].get("containerImage", "")):
        raise ValueError("PR image is not digest pinned")

    owner, repository = repo.split("/", 1)
    manifest = {
        "apiVersion": "appstudio.redhat.com/v1alpha1",
        "kind": "Snapshot",
        "metadata": {
            "name": f"promoted-rpm-{merge_sha}",
            "namespace": namespace,
            "labels": {
                "appstudio.openshift.io/application": application,
                "appstudio.openshift.io/component": component,
                "test.appstudio.openshift.io/type": "component",
                f"{PAC_PREFIX}/event-type": "push",
                f"{PAC_PREFIX}/sha": merge_sha,
                f"{PAC_PREFIX}/url-org": owner,
                f"{PAC_PREFIX}/url-repository": repository,
                "release.appstudio.openshift.io/auto-release": "false",
            },
            "annotations": {
                "build.appstudio.redhat.com/commit_sha": merge_sha,
                "build.appstudio.redhat.com/target_branch": branch,
                f"{PAC_PREFIX}/source-branch": f"refs/heads/{branch}",
                f"{PAC_PREFIX}/repo-url": f"https://github.com/{repo}",
                "test.appstudio.openshift.io/result-pr-snapshot": pr_snapshot[
                    "metadata"
                ]["name"],
                "hum-5186.konflux-ci.dev/pr-build-commit": pr_sha,
                "hum-5186.konflux-ci.dev/merge-commit": merge_sha,
            },
        },
        "spec": {"application": application, "components": [built[0]]},
    }
    promoted = create_snapshot(url, manifest, token)
    Path(os.environ["RESULT_PR_SNAPSHOT_PATH"]).write_text(
        pr_snapshot["metadata"]["name"]
    )
    Path(os.environ["RESULT_PUSH_SNAPSHOT_PATH"]).write_text(
        promoted["metadata"]["name"]
    )
    print(
        json.dumps(
            {
                "pr_snapshot": pr_snapshot["metadata"]["name"],
                "push_snapshot": promoted["metadata"]["name"],
                "pr_sha": pr_sha,
                "merge_sha": merge_sha,
                "image": built[0]["containerImage"],
            }
        )
    )


if __name__ == "__main__":
    main()
