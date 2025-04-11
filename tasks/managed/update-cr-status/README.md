# update-cr-status

A tekton task that updates the passed CR status with the contents stored in the files in the resultsDir.

## Parameters

| Name                    | Description                                                                                                                | Optional | Default value           |
|-------------------------|----------------------------------------------------------------------------------------------------------------------------|----------|-------------------------|
| resourceType            | The type of resource that is being patched                                                                                 | Yes      | release                 |
| statusKey               | The top level key to overwrite in the resource status                                                                      | Yes      | artifacts               |
| resource                | The namespaced name of the resource to be patched                                                                          | No       | -                       |
| resultsDirPath          | Path to the directory containing the result files in the data workspace which will be added to the resource's status       | No       | -                       |
| ociStorage              | The OCI repository where the Trusted Artifacts are stored                                                                  | Yes      | empty                   |
| ociArtifactExpiresAfter | Expiration date for the trusted artifacts created in the OCI repository. An empty string means the artifacts do not expire | Yes      | 1d                      |
| trustedArtifactsDebug   | Flag to enable debug logging in trusted artifacts. Set to a non-empty string to enable                                     | Yes      | ""                      |
| orasOptions             | oras options to pass to Trusted Artifacts calls                                                                            | Yes      | ""                      | 
| sourceDataArtifact      | Location of trusted artifacts to be used to populate data directory                                                        | Yes      | ""                      |
| dataDir                 | The location where data will be stored                                                                                     | Yes      | $(workspaces.data.path) |
| taskGitUrl              | The url to the git repo where the release-service-catalog tasks and stepactions to be used are stored                      | No       | ""                      |
| taskGitRevision         | The revision in the taskGitUrl repo to be used                                                                             | No       | ""                      |

## Changes in 1.0.0
* This task now supports Trusted artifacts

## Changes in 0.3.1
* Fix shellcheck/checkton linting issues in the task and tests

## Changes in 0.3.0
* Updated the base image used in this task

## Changes in 0.2.0
* Updated the base image used in this task
