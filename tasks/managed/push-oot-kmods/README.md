# push-oot-kmods

Task to upload out-of-tree kernel modules to private vendor repo

## Parameters

| Name                    | Description                                                                                                                | Optional | Default value                                             |
|-------------------------|----------------------------------------------------------------------------------------------------------------------------|----------|-----------------------------------------------------------|
| signedKmodsPath         | Path where the kernel modules are stored in the workspace                                                                  | No       | -                                                         |
| vendor                  | vendor of the kernel modules                                                                                               | No       | -                                                         |
| artifactRepoUrl         | Repository URL where the signed modules will be pushed                                                                     | No       | -                                                         |
| artifactBranch          | Specific branch in the repository                                                                                          | Yes      | main                                                      |
| artifactRepoToken       | Secret containing the Project Access Token for the artifact repos                                                          | No       | -                                                         |
| ociStorage              | The OCI repository where the Trusted Artifacts are stored                                                                  | Yes      | empty                                                     |
| ociArtifactExpiresAfter | Expiration date for the trusted artifacts created in the OCI repository. An empty string means the artifacts do not expire | Yes      | 1d                                                        |
| trustedArtifactsDebug   | Flag to enable debug logging in trusted artifacts. Set to a non-empty string to enable                                     | Yes      | ""                                                        |
| orasOptions             | oras options to pass to Trusted Artifacts calls                                                                            | Yes      | ""                                                        |
| sourceDataArtifact      | Location of trusted artifacts to be used to populate data directory                                                        | Yes      | ""                                                        |
| dataDir                 | The location where data will be stored                                                                                     | Yes      | /var/workdir/release                                      |
| taskGitUrl              | The git repository URL for task and StepAction resolution                                                                  | Yes      | https://github.com/konflux-ci/release-service-catalog.git |
| taskGitRevision         | The git revision for task and StepAction resolution                                                                        | Yes      | main                                                      |
