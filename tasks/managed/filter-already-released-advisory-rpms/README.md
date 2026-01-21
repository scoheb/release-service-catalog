## filter-already-released-advisory-rpms

Managed Tekton task that **reduces a snapshot** to only the RPMs that still need to be published to Pulp.

### What it does

- **Pulls RPM files** from each snapshot component’s `containerImage` (OCI artifact).
- **Checks Pulp** for each RPM by querying content using NEVRA and then comparing **sha256** (local file vs server artifact).
- **Annotates the snapshot** by adding `.components[].rpmsToPublish[]` entries describing which RPMs still need to be published and to which repositories.
- **Removes components** whose `rpmsToPublish` list is empty.
- **Overwrites the snapshot file in place** (same `snapshotPath`).

### Snapshot mutation

For each remaining component, this task adds:

- **`rpmsToPublish`**: an array of objects with:
  - **`rpm`**: RPM filename (relative; as pulled from the OCI artifact)
  - **`rpmname`**, **`epoch`**, **`version`**, **`release`**, **`arch`**: parsed from RPM header (fallback to filename parsing for empty/mock RPMs)
  - **`sha256`**: local sha256 of the RPM file
  - **`targetRepos`**: list of Pulp repos where this RPM is missing (e.g. `["x86_64"]`, `["source"]`, or multiple arches for `noarch`)

Components with no remaining RPMs to publish are removed from `.components`.

### Results

- **`skip_release`**:
  - `"true"` if the filtered snapshot has **0 components**
  - `"false"` otherwise

### Downstream usage

`tasks/managed/push-rpms-to-pulp/push-rpms-to-pulp.yaml` detects `rpmsToPublish` and will **only attempt uploads for the RPMs/repos listed there**, avoiding wasted uploads and duplicate work.
