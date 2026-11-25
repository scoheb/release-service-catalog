# push-rpms-to-pulp Test

This test validates the push-rpms-to-pulp pipeline with two components:

- **Component A (hello)**: multi-arch binaries (x86_64, aarch64, s390x, ppc64le) plus a noarch subpackage
- **Component B (hello2)**: noarch-only — only `*.noarch.rpm` and `*.src.rpm` (no arch-specific binaries)

hello2 was simplified from a x86_64 binary package to a data-only noarch spec so the E2E can verify a noarch-only component in a multi-component release: hello2 publishes only `*.noarch.rpm` and `*.src.rpm`, and `hello2.noarch` is fanned out to all four binary repos (hello already supplies the arch repos).

Auto-release is disabled. The test waits for both builds, creates a Release from the multi-component Snapshot, then retriggering it to confirm already-published RPMs are filtered (`skip_release=true`).

## Advisory failure and retry

Set `RPM_ADVISORY_RETRY_TEST=true` and `RPM_ADVISORY_FAILURE_GIT_REVISION` to a catalog branch that
contains the retry fix plus a failure injected at the start of `create-advisory`. Run the normal
`push-rpms-to-pulp` suite with `RELEASE_CATALOG_GIT_REVISION` set to the fixed catalog branch.
The test uses its own ReleasePlanAdmission and leaves other releases untouched.

The first Release publishes signed RPMs, then fails at advisory creation. The suite verifies
the signing and signed Pulp tasks succeeded and `create-advisory` failed. It changes its
ReleasePlanAdmission back to the fixed revision, creates a second Release from the same Snapshot,
and verifies that the original signed OCI artifact was reused without another signing request.
The successful release is checked for signed Pulp upload, advisory creation, advisory URLs,
RPM fanout, and release artifacts. The regular suite's private GitLab advisory YAML fetch and
final retrigger check are outside this focused retry mode.

The failure branch is a test fixture: its `create-advisory` Task prints a GitLab access error and
exits before creating an advisory. Keep that branch separate from the production fix.

## Partial signed Pulp push and retry

Set `RPM_SIGNED_PUSH_RETRY_TEST=true` and `RPM_SIGNED_PUSH_FAILURE_GIT_REVISION` to a catalog
fixture revision that runs `fail_after_first_signed_repo.py` in the signed Pulp Task. Set
`RELEASE_CATALOG_GIT_REVISION` to the fixed catalog revision. These flags are exclusive with
`RPM_ADVISORY_RETRY_TEST`.

The fixture calls the real Pulp repository update, waits for it to complete, then raises before
the next repository update. The suite checks that signing succeeded, the signed Pulp Task failed,
advisory creation did not start, `hello2` is present in the first signed repository and absent
from a later one. It then starts a second Release from the same Snapshot using the fixed catalog
revision and checks that signing reuses the same OCI artifact, the pending repository is filled,
and the advisory succeeds. The Pulp queries read credentials from the suite's managed Secret
without printing them.

The fixture script is in the `release-service-utils` image under
`/home/integration-tests/fault_injection/`. Use an image built from the utils revision that
contains this script. The normal catalog branch continues to invoke the production RPM push.

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

### Overriding Build Pipelines

Due to the type of artifact being built ... rpms ... we need to override what is proposed by Konflux as a build template. Therefore, the `patch_component_source_before_merge()` method is overidden to use:

- integration-tests/push-rpms-to-pulp/resources/tenant/templates/tekton/pull-request-template.yaml
- integration-tests/push-rpms-to-pulp/resources/tenant/templates/tekton/push-template.yaml

as the source for the PR that Konflux is being proposed for the onboarding step.
