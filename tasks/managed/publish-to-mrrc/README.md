# publish-to-mrrc

Tekton task that publishes the maven artifacts to MRRC(maven.repository.redhat.com) service. MRRC is used to host maven artifacts of Red Hat Middleware products.
This task will work with [collect-mrrc-task](../collect-mrrc-params/README.md) together to do the MRRC publishment work. It accepts the `mrrc.env` file from the [collect-mrrc-task](../collect-mrrc-params/README.md) and use the variables in it as parameters for the MRRC publishing task.

## Parameters

| Name                     | Description                                                                                                                         | Optional | Default value                                             |
|--------------------------|-------------------------------------------------------------------------------------------------------------------------------------|----------|-----------------------------------------------------------|
| mrrcParamFilePath        | Path of the mrrc.env file which contains the MRRC parameters as environment variables                                              | No       | -                                                         |
| charonConfigFilePath     | Path of the charon config file for charon to consume                                                                               | No       | -                                                         |
| charonAWSSecret          | The secret name for charon aws credential file                                                                                     | No       | -                                                         |
| ociStorage               | The OCI repository where the Trusted Artifacts are stored                                                                          | Yes      | empty                                                     |
| ociArtifactExpiresAfter  | Expiration date for the trusted artifacts created in the OCI repository. An empty string means the artifacts do not expire        | Yes      | 1d                                                        |
| trustedArtifactsDebug    | Flag to enable debug logging in trusted artifacts. Set to a non-empty string to enable                                             | Yes      | ""                                                        |
| orasOptions              | oras options to pass to Trusted Artifacts calls                                                                                    | Yes      | ""                                                        |
| sourceDataArtifact       | Location of trusted artifacts to be used to populate data directory                                                                | Yes      | ""                                                        |
| dataDir                  | The location where data will be stored                                                                                             | Yes      | $(workspaces.data.path)                                   |
| taskGitUrl               | The url to the git repo where the release-service-catalog tasks and stepactions to be used are stored                             | No       | -                                                         |
| taskGitRevision          | The revision in the taskGitUrl repo to be used                                                                                     | No       | -                                                         |

