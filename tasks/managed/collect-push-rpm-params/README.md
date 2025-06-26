# collect-push-rpm-params

Tekton task to get params for task(push-rpm-to-koji) of pushing konflux build rpms to koji instance.

## Parameters

| Name                     | Description                                                                                                                | Optional | Default value               |
|--------------------------|----------------------------------------------------------------------------------------------------------------------------|---------|-----------------------------|
| dataPath                 | Path to the JSON file of the merged data to use in the data workspace                                                     | No      | -                           |
| ociStorage               | The OCI repository where the Trusted Artifacts are stored                                                                 | Yes     | "empty"                     |
| sourceDataArtifact       | Location of trusted artifacts to be used to populate data directory                                                       | Yes     | ""                          |
| ociArtifactExpiresAfter  | Expiration date for the trusted artifacts created in the OCI repository. An empty string means the artifacts do not expire | Yes     | "1d"                        |
| trustedArtifactsDebug    | Flag to enable debug logging in trusted artifacts. Set to a non-empty string to enable                                    | Yes     | ""                          |
| orasOptions              | oras options to pass to Trusted Artifacts calls                                                                           | Yes     | ""                          |
| dataDir                  | The location where data will be stored                                                                                     | Yes     | $(workspaces.data.path)     |
| taskGitUrl               | The url to the git repo where the release-service-catalog tasks and stepactions to be used are stored                    | No      | -                           |
| taskGitRevision          | The revision in the taskGitUrl repo to be used                                                                            | No      | -                           |

