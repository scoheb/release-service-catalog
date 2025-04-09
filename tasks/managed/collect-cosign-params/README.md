# collect-cosign-params

Tekton task that collects cosign options from the data file.

## Parameters

| Name                    | Description                                                                                                                | Optional | Default value                                             |
|-------------------------|----------------------------------------------------------------------------------------------------------------------------|----------|-----------------------------------------------------------|
| dataPath                | Path to the JSON string of the merged data to use in the data workspace                                                    | No       | -                                                         |
| ociStorage              | The OCI repository where the Trusted Artifacts are stored                                                                  | Yes      | empty                                                     |
| ociArtifactExpiresAfter | Expiration date for the trusted artifacts created in the OCI repository. An empty string means the artifacts do not expire | Yes      | 1d                                                        |
| trustedArtifactsDebug   | Flag to enable debug logging in trusted artifacts. Set to a non-empty string to enable                                     | Yes      | ""                                                        |
| orasOptions             | oras options to pass to Trusted Artifacts calls                                                                            | Yes      | ""                                                        | 
| sourceDataArtifact      | Location of trusted artifacts to be used to populate data directory                                                        | Yes      | ""                                                        |
| subdirectory            | Subdirectory inside the workspace to be used                                                                               | Yes      | ""                                                        |
| dataDir                 | The location where data will be stored                                                                                     | Yes      | $(workspaces.data.path)                                   |
| stepActionGitUrl        | The url to the git repo where the release-service-catalog stepActions to be used are stored                                | Yes      | https://github.com/konflux-ci/release-service-catalog.git |
| stepActionGitRevision   | The revision in the stepActionGitUrl repo to be used                                                                       | Yes      | production                                                |

## Changes in 1.0.0
* This task now supports Trusted artifacts

## Changes in 0.1.1
  * Fix linting issues in this task
