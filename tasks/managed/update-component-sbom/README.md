# update-component-sbom

Tekton task to update component-level SBOMs with purls containing release-time info.

## Parameters

| Name                    | Description                                                                                                                | Optional  | Default value           |
|-------------------------|----------------------------------------------------------------------------------------------------------------------------|-----------|-------------------------|
| sbomJsonPath            | Path to the JSON string of the merged data containing the release notes                                                    | No        | -                       |
| downloadedSbomPath      | Path to the directory holding previously downloaded SBOMs to be updated.                                                   | No        | -                       |
| ociStorage              | The OCI repository where the Trusted Artifacts are stored                                                                  | Yes       | empty                   |
| ociArtifactExpiresAfter | Expiration date for the trusted artifacts created in the OCI repository. An empty string means the artifacts do not expire | Yes       | 1d                      |
| trustedArtifactsDebug   | Flag to enable debug logging in trusted artifacts. Set to a non-empty string to enable                                     | Yes       | ""                      |
| orasOptions             | oras options to pass to Trusted Artifacts calls                                                                            | Yes       | ""                      | 
| sourceDataArtifact      | Location of trusted artifacts to be used to populate data directory                                                        | Yes       | ""                      |
| subdirectory            | Subdirectory inside the workspace to be used                                                                               | Yes       | ""                      |
| dataDir                 | The location where data will be stored                                                                                     | Yes       | $(workspaces.data.path) |
| taskGitUrl              | The url to the git repo where the release-service-catalog tasks and stepactions to be used are stored                      | No        | ""                      |
| taskGitRevision         | The revision in the taskGitUrl repo to be used                                                                             | No        | ""                      |

## Changes in 1.0.0
* This task now supports Trusted artifacts

## Changes in 0.2.0
- Rename dataPath parameter to sbomJsonPath to better reflect usage

## Changes in 0.1.1
- (ISV-5321) Set a `name` of SPDX document to external reference of the component. The name is set to external image pullspec given by the public registry + repository + digest. Example: registry.redhat.io/ubi8/ubi-minimal@sha256:1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef.
