# Hummingbird Release Service Catalog - Bundle Deployment

This directory contains GitLab CI/CD configuration for building and deploying Tekton bundles
from the release-service-catalog.

## Overview

The hummingbird fork of release-service-catalog uses Tekton bundles instead of git resolver
to avoid git resolver errors and improve reliability. At merge time, all tasks and pipelines
are packaged as OCI bundles and pushed to quay.io/hummingbird-ci.

## Architecture

### Git Resolver vs Bundle Resolver

**Before (Git Resolver):**
```yaml
taskRef:
  resolver: "git"
  params:
    - name: url
      value: $(params.taskGitUrl)
    - name: revision
      value: $(params.taskGitRevision)
    - name: pathInRepo
      value: tasks/managed/some-task/some-task.yaml
```

**After (Bundle Resolver):**
```yaml
taskRef:
  resolver: bundles
  params:
    - name: name
      value: some-task
    - name: bundle
      value: quay.io/hummingbird-ci/release-task-some-task:git-abc123
    - name: kind
      value: Task
```

### Bundle Naming Convention

- **Managed task bundles**: `quay.io/hummingbird-ci/release-task-<task-name>:<tag>`
- **Managed pipeline bundles**: `quay.io/hummingbird-ci/release-pipeline-<pipeline-name>:<tag>`

**Not bundled** (remain as git resolver):
- Internal tasks (`tasks/internal/*`)
- Collector tasks (`tasks/collectors/*`)
- Hub tasks (`hub/*`)
- Internal pipelines (`pipelines/internal/*`)

### Bundle Tags

- **MR testing**: `pipeline-<CI_PIPELINE_ID>` (expires after 7 days)
- **Release**: `git-<CI_COMMIT_SHA>` (permanent)
- **Latest**: `latest` (always points to main branch)

## CI/CD Pipeline

### Stages

1. **check** - Validate YAML syntax
2. **build** - Build test bundles for MRs
3. **deploy** - Build and push release bundles on merge

### Jobs

| Job | Stage | Trigger | Description |
|-----|-------|---------|-------------|
| `yaml:validate` | check | MR | Validates YAML syntax |
| `bundles:test` | build | MR | Pushes test bundles (7-day TTL) |
| `bundles:release` | deploy | Main/Manual | Pushes release bundles |

## Tasks Not Converted

The following remain as git resolver and are NOT bundled:

### External Tasks
- **Conforma** (`https://github.com/conforma/cli`) - Enterprise contract verification
- **Mobster** (`https://github.com/konflux-ci/mobster.git`) - SBOM processing

### Internal Resources (not bundled)
- **Internal tasks** (`tasks/internal/*`) - Used by internal pipelines
- **Collector tasks** (`tasks/collectors/*`) - Data collection tasks
- **Hub tasks** (`hub/*`) - Shared Tekton Hub tasks
- **Internal pipelines** (`pipelines/internal/*`) - Internal workflow pipelines

These resources continue to use git resolver and are resolved at runtime.

## Scripts

### convert-to-bundle-resolver.py

Converts pipeline YAML files from git resolver to bundle resolver for release-service-catalog
tasks while preserving external task references.

```bash
python3 .gitlab/scripts/convert-to-bundle-resolver.py \
  <input-file> <output-file> <bundle-registry> <bundle-tag>
```

## Keeping in Sync with Upstream

The hummingbird branch should be periodically rebased on upstream konflux-ci/release-service-catalog.

Current status:
- Branch: `hummingbird-rpm-signing`
- Upstream: `konflux-ci/release-service-catalog` (development branch)

To sync:
```bash
git fetch upstream
git rebase upstream/development
# Resolve any conflicts
git push --force-with-lease hummingbird hummingbird-rpm-signing
```

## Environment Variables

Required CI/CD variables:

| Variable | Description |
|----------|-------------|
| `QUAY_USERNAME` | Quay.io robot account username |
| `QUAY_PASSWORD` | Quay.io robot account password |

## Statistics

**Bundled:**
- **Managed tasks**: 72
- **Managed pipelines**: 22

**Not bundled (git resolver):**
- **Internal tasks**: ~10
- **Internal pipelines**: 15
- **Collector tasks**: ~5
- **Hub tasks**: ~3
