# push-rpms-to-pulp Test

This test validates the pushing of rpms to pulp pipeline. When the release includes noarch RPMs, the integration test asserts they are published to all default arch repos (x86_64, aarch64, s390x, ppc64le). Task-level test `tasks/managed/push-rpms-to-pulp/tests/test-push-rpms-to-pulp-noarch-all-default-arches.yaml` covers the same noarch fanout behavior in isolation.

## Test-Specific Dependencies

- A pulp domain is required for these tests. One has already been created. It is called `konflux-release-integration-tests`
- In the event that you need to recreate it, a helper script is available.
  - See `integration-tests/push-rpms-to-pulp/utils/README.md`

## Test-Specific Secrets

This test uses specialized vault files with different naming:

- **`vault/managed-secrets.yaml`** - Secrets for the managed namespace
- **`vault/tenant-secrets.yaml`** - Secrets for the tenant namespace

## Test-Specific Configuration

### Files Structure

- **`test.env`** - Contains resource names and configuration values
- **`test.sh`** - Contains test-specific variables and functions

### Pipeline Resolver Mode

The test supports two ways to reference the release pipeline: **git resolver** (default) and **bundle resolver**.

#### Git Resolver (default)

Set `RELEASE_CATALOG_GIT_URL` and `RELEASE_CATALOG_GIT_REVISION` to point to the
release-service-catalog repository and branch:

```bash
export RELEASE_CATALOG_GIT_URL=https://gitlab.example.com/my-fork/release-service-catalog.git
export RELEASE_CATALOG_GIT_REVISION=my-branch

cd integration-tests
./run-test.sh push-rpms-to-pulp
```

#### Bundle Resolver

Use `RELEASE_CATALOG_BUNDLE_REF` instead when running against pre-built OCI bundles.
This variable and `RELEASE_CATALOG_GIT_URL`/`RELEASE_CATALOG_GIT_REVISION` are
mutually exclusive — setting both is an error.

**Prerequisites — Authenticate to Quay.io:**

The `tkn bundle push` command uses your container registry credentials. Log in
with any of the following before building bundles:

```bash
# Using oras
oras login quay.io

# Using podman
podman login quay.io

# Using docker
docker login quay.io
```

Credentials are stored in `~/.docker/config.json` (or `${XDG_RUNTIME_DIR}/containers/auth.json`
for podman) and are picked up automatically by `tkn bundle push`.

**Step 1 — Build and push bundles:**

If your branch includes changes to internal tasks or collector tasks, you must
export your repository URL and branch name before running the script. This ensures
the generated pipeline bundle uses your branch as the default `taskGitUrl` and `taskGitRevision`
for internal requests, rather than falling back to the upstream `development` branch.

```bash
export CI_PROJECT_URL="https://github.com/<your-username>/release-service-catalog.git"
export CI_COMMIT_SHA="$(git branch --show-current)"

# Build bundles for the push-rpms-to-pulp pipeline (and all its tasks/stepactions).
# Files are processed in a temp directory — the working tree is never modified.
TAG="test-$(date +%Y%m%d-%H%M%S)"
.gitlab/scripts/build-and-push-bundles.sh \
  --registry quay.io/<your-namespace>/release-bundles \
  --tag "$TAG" \
  --pipeline push-rpms-to-pulp \
  --expire 7d
```

Each resource is tagged as `<type>-<name>-<tag>` to avoid collisions in the
shared repository. For example, with `--tag test-20260409-153000`:

- Pipeline: `pipeline-push-rpms-to-pulp-test-20260409-153000`
- Task: `managed-reduce-snapshot-test-20260409-153000`
- StepAction: `stepaction-create-trusted-artifact-test-20260409-153000`

The script prints the pipeline bundle ref at the end. Use `--dry-run` to
preview what would be pushed without contacting the registry. Omit `--pipeline`
to build bundles for all managed pipelines.

**Step 2 — Run the test:**

```bash
export RELEASE_CATALOG_BUNDLE_REF=quay.io/<your-namespace>/release-bundles:pipeline-push-rpms-to-pulp-$TAG

cd integration-tests
./run-test.sh push-rpms-to-pulp
```

### Overriding Build Pipelines

Due to the type of artifact being built ... rpms ... we need to override what is proposed by Konflux as a build template. Therefore, the `patch_component_source_before_merge()` method is overidden to use:

- integration-tests/push-rpms-to-pulp/resources/tenant/templates/tekton/pull-request-template.yaml
- integration-tests/push-rpms-to-pulp/resources/tenant/templates/tekton/push-template.yaml

as the source for the PR that Konflux is being proposed for the onboarding step.
