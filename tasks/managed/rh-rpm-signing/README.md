# rh-rpm-signing

STUB TASK - Signs RPMs and uploads them to the public Pulp domain.

This is a placeholder task that passes through artifacts unchanged.
It will be replaced with the real signing implementation when delivered
by the signing team.

When fully implemented, this task will:
- Read unsigned RPMs from the unsigned Pulp domain
- Sign the RPMs using the specified signing key
- Upload signed RPMs to the public Pulp domain
- Output the final signed RPM locations and digests

## Parameters

| Name                    | Description                                                                                                                | Optional | Default value        |
|-------------------------|----------------------------------------------------------------------------------------------------------------------------|----------|----------------------|
| pulpSecretName          | The name of the secret containing the Pulp cli.toml file                                                                   | No       | -                    |
| unsignedDomain          | The Pulp domain to read unsigned RPMs from                                                                                 | No       | -                    |
| publicDomain            | The Pulp domain to write signed RPMs to                                                                                    | No       | -                    |
| signingKey              | The signing key ID to use for signing RPMs                                                                                 | Yes      | ""                   |
| artifactsJsonPath       | Path to the artifacts.json file containing RPM information                                                                 | Yes      | ""                   |
| snapshotPath            | Path to the JSON Snapshot spec in the data workspace                                                                       | Yes      | ""                   |
| resultsDirPath          | Path to the results directory in the data workspace                                                                        | Yes      | ""                   |
| ociStorage              | The OCI repository where the Trusted Artifacts are stored                                                                  | Yes      | empty                |
| ociArtifactExpiresAfter | Expiration date for the trusted artifacts created in the OCI repository. An empty string means the artifacts do not expire | Yes      | 1d                   |
| trustedArtifactsDebug   | Flag to enable debug logging in trusted artifacts. Set to a non-empty string to enable                                     | Yes      | ""                   |
| orasOptions             | oras options to pass to Trusted Artifacts calls                                                                            | Yes      | ""                   |
| sourceDataArtifact      | Location of trusted artifacts to be used to populate data directory                                                        | Yes      | ""                   |
| dataDir                 | The location where data will be stored                                                                                     | Yes      | /var/workdir/release |
| taskGitUrl              | The url to the git repo where the release-service-catalog tasks and stepactions to be used are stored                      | No       | -                    |
| taskGitRevision         | The revision in the taskGitUrl repo to be used                                                                             | No       | -                    |
