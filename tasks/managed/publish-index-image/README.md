# publish-index-image

Publish a built FBC index image using skopeo

## Parameters

| Name                       | Description                                                                                                                | Optional | Default value        |
|----------------------------|----------------------------------------------------------------------------------------------------------------------------|----------|----------------------|
| dataPath                   | Path to the JSON string of the merged data to use in the data workspace                                                    | No       | -                    |
| targetIndex                | Pullspec to push the image to                                                                                              | No       | -                    |
| internalRequestResultsFile | File containing the results of the build                                                                                   | No       | -                    |
| retries                    | Number of skopeo retries                                                                                                   | Yes      | 0                    |
| requestTimeout             | Max seconds waiting for the status update                                                                                  | Yes      | 360                  |
| buildTimestamp             | Build timestamp for the publishing image                                                                                   | No       | -                    |
| pipelineRunUid             | The uid of the current pipelineRun. Used as a label value when creating internal requests                                  | No       | -                    |
| ociStorage                 | The OCI repository where the Trusted Artifacts are stored                                                                  | Yes      | empty                |
| ociArtifactExpiresAfter    | Expiration date for the trusted artifacts created in the OCI repository. An empty string means the artifacts do not expire | Yes      | 1d                   |
| trustedArtifactsDebug      | Flag to enable debug logging in trusted artifacts. Set to a non-empty string to enable                                     | Yes      | ""                   |
| orasOptions                | oras options to pass to Trusted Artifacts calls                                                                            | Yes      | ""                   |
| sourceDataArtifact         | Location of trusted artifacts to be used to populate data directory                                                        | Yes      | ""                   |
| dataDir                    | The location where data will be stored                                                                                     | Yes      | /var/workdir/release |
| taskGitUrl                 | The url to the git repo where the release-service-catalog tasks and stepactions to be used are stored                      | No       | -                    |
| taskGitRevision            | The revision in the taskGitUrl repo to be used                                                                             | No       | -                    |
