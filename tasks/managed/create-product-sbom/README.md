# create-product-sbom

Tekton task to create a product-level SBOM to be uploaded to Atlas from
releaseNotes content.

## Parameters

| Name                    | Description                                                                                                                | Optional   | Default value           |
|-------------------------|----------------------------------------------------------------------------------------------------------------------------|------------|-------------------------|
| dataJsonPath            | Path to the JSON string of the merged data containing the release notes                                                    | No         | -                       |
| ociStorage              | The OCI repository where the Trusted Artifacts are stored                                                                  | Yes        | empty                   |
| ociArtifactExpiresAfter | Expiration date for the trusted artifacts created in the OCI repository. An empty string means the artifacts do not expire | Yes        | 1d                      |
| trustedArtifactsDebug   | Flag to enable debug logging in trusted artifacts. Set to a non-empty string to enable                                     | Yes        | ""                      |
| orasOptions             | oras options to pass to Trusted Artifacts calls                                                                            | Yes        | ""                      | 
| sourceDataArtifact      | Location of trusted artifacts to be used to populate data directory                                                        | Yes        | ""                      |
| dataDir                 | The location where data will be stored                                                                                     | Yes        | $(workspaces.data.path) |
| taskGitUrl              | The url to the git repo where the release-service-catalog tasks and stepactions to be used are stored                      | No         | ""                      | 
| taskGitRevision         | The revision in the taskGitUrl repo to be used                                                                             | No         | ""                      |

## Changes in 1.0.0
* This task now supports Trusted artifacts

## Changes in 0.2.1
* Fixed component-product relationship in SBOM.

## Changes in 0.2.0
* Output directory path instead of a file path.

## Changes in 0.1.1
* The release-service-utils image was updated to include a fix when generating name of product level SBOM - it should be based on "{product name} {product version}"
