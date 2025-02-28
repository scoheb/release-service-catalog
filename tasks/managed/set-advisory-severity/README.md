# set-advisory-severity

Tekton task to set the severity level in the releaseNotes key of the data.json. It will use an InternalRequest to query
OSIDB for each CVE present. If the type is not RHSA, no action will be performed.

## Parameters

| Name                    | Description                                                                                                                | Optional | Default value           |
|-------------------------|----------------------------------------------------------------------------------------------------------------------------|----------|-------------------------|
| dataPath                | Path to data JSON in the data workspace                                                                                    | No       | -                       |
| requestTimeout          | InternalRequest timeout                                                                                                    | Yes      | 180                     |
| pipelineRunUid          | The uid of the current pipelineRun. Used as a label value when creating internal requests                                  | No       | -                       |
| taskGitUrl              | The url to the git repo where the release-service-catalog tasks to be used are stored                                      | No       | -                       |
| taskGitRevision         | The revision in the taskGitUrl repo to be used                                                                             | No       | -                       |
| ociStorage              | The OCI repository where the Trusted Artifacts are stored                                                                  | Yes      | empty                   |
| ociArtifactExpiresAfter | Expiration date for the trusted artifacts created in the OCI repository. An empty string means the artifacts do not expire | Yes      | 1d                      |
| sourceDataArtifact      | Location of trusted artifacts to be used to populate data directory                                                        | Yes      | ""                      |
| subdirectory            | Subdirectory inside the workspace to be used                                                                               | Yes      | ""                      |
| dataDir                 | The location where data will be stored                                                                                     | Yes      | $(workspaces.data.path) |

## Changes in 0.1.1
* If a non RHSA type is provided, remove the severity key in case the user provided it
