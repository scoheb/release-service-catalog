# collect-mrrc-params

Tekton task that collects MRRC(maven.repository.redhat.com) configuration options from the data file. MRRC is used to host maven artifacts of Red Hat Middleware products.
This task looks at the data file in the workspace to extract the params like `mrrc.*`, `cosignPubKeySecret` and `charonAWSSecret` keys for MRRC. `mrrc.*` will be stored in a mrrc.env file and are emitted as task results with other three for downstream tasks to use.

## Parameters

| Name                     | Description                                                                                                                         | Optional | Default value                                             |
|--------------------------|-------------------------------------------------------------------------------------------------------------------------------------|----------|-----------------------------------------------------------|
| dataJsonPath             | Path to data json file                                                                                                              | No       | -                                                         |
| snapshotPath             | Path to the JSON string of the Snapshot spec in the data workspace                                                                 | No       | -                                                         |
| ociStorage               | The OCI repository where the Trusted Artifacts are stored                                                                          | Yes      | empty                                                     |
| ociArtifactExpiresAfter  | Expiration date for the trusted artifacts created in the OCI repository. An empty string means the artifacts do not expire        | Yes      | 1d                                                        |
| trustedArtifactsDebug    | Flag to enable debug logging in trusted artifacts. Set to a non-empty string to enable                                             | Yes      | ""                                                        |
| orasOptions              | oras options to pass to Trusted Artifacts calls                                                                                    | Yes      | ""                                                        |
| sourceDataArtifact       | Location of trusted artifacts to be used to populate data directory                                                                | Yes      | ""                                                        |
| dataDir                  | The location where data will be stored                                                                                             | Yes      | $(workspaces.data.path)                                   |
| taskGitUrl               | The url to the git repo where the release-service-catalog tasks and stepactions to be used are stored                             | No       | -                                                         |
| taskGitRevision          | The revision in the taskGitUrl repo to be used                                                                                     | No       | -                                                         |

