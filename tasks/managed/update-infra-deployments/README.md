# update-infra-deployments

* This task clones a GitHub repository specified in the 'targetGHRepo' key of the input data file.
* If 'targetGHRepo' is not provided, it defaults to 'defaultTargetGHRepo: redhat-appstudio/infra-deployments'.
* It then runs a script obtained from the 'infra-deployment-update-script' key in the data file, which can modify text files.
* Finally, it generates a pull request for the specified repository using the modified files.


## Parameters
| Name                           | Description                                                                                  | Optional | Default Value                                                                                                                                    |
|--------------------------------|----------------------------------------------------------------------------------------------|----------|--------------------------------------------------------------------------------------------------------------------------------------------------|
| dataJsonPath                   | Path to data json file. It should contain a key called 'infra-deployment-update-script'      | false    |                                                                                                                                                  |
| snapshotPath                   | Path to snapshot json file                                                                   | false    |                                                                                                                                                  |
| originRepo                     | URL of github repository which was built by the Pipeline                                     | false    |                                                                                                                                                  |
| revision                       | Git reference which was built by the Pipeline                                                | false    |                                                                                                                                                  |
| defaultTargetGHRepo            | GitHub repository of the infra-deployments code                                              | true     | redhat-appstudio/infra-deployments                                                                                                               |
| sharedSecret                   | Secret in the namespace which contains private key for the GitHub App                        | true     | infra-deployments-pr-creator                                                                                                                     |
| defaultGithubAppID             | ID of Github app used for updating PR                                                        | true     | 305606                                                                                                                                           |
| defaultGithubAppInstallationID | Installation ID of Github app in the organization                                            | true     | 35269675                                                                                                                                         |
| ociStorage                     | The OCI repository where the Trusted Artifacts are stored.                                   | true     | empty                                                                                                                                            |
| ociArtifactExpiresAfter        | Expiration date for the trusted artifacts created in the OCI repository. An empty string means the artifacts do not expire. | true | 1d                                                                                                                                               |
| trustedArtifactsDebug         | Flag to enable debug logging in trusted artifacts. Set to a non-empty string to enable.      | true     |                                                                                                                                                  |
| orasOptions                    | oras options to pass to Trusted Artifacts calls                                              | true     |                                                                                                                                                  |
| sourceDataArtifact            | Location of trusted artifacts to be used to populate data directory                          | true     |                                                                                                                                                  |
| dataDir                        | The location where data will be stored                                                       | true     | $(workspaces.data.path)                                                                                                                         |
| taskGitUrl                     | The url to the git repo where the release-service-catalog tasks and stepactions to be used are stored | false |                                                                                                                                                  |
| taskGitRevision                | The revision in the taskGitUrl repo to be used                                               | false    |                                                                                                                                                  |

## Changes in 2.0.0
* Updated task to use trusted artifacts for secure data flow between tasks
* Added trusted artifacts parameters: `ociStorage`, `ociArtifactExpiresAfter`, `trustedArtifactsDebug`, `orasOptions`, `sourceDataArtifact`, `dataDir`, `taskGitUrl`, `taskGitRevision`
* Added `sourceDataArtifact` result
* Updated file paths to use `$(params.dataDir)` instead of direct workspace paths
* Added trusted artifacts step actions: `skip-trusted-artifact-operations`, `use-trusted-artifact`, `create-trusted-artifact`, `patch-source-data-artifact-result`

## Changes in 1.4.0
* Added compute resource limits

## Changes in 1.3.0
* Updated the base image used in this task
  * Deprecated the `gitImage` and `scriptImage` parameters

## Changes in 1.2.1
* Fix shellcheck/checkton linting issues in the task

## Changes in 1.2.0
* Updated the base image used in this task

## Changes in 1.1.0
* Updated the base image used in this task

## Changes in 1.0.0
* Modified `update-infra-deployments` task to dynamically fetch
  `targetGHRepo`, `githubAppID`, and `githubAppInstallationID` from the dataJsonPath JSON file.
  (defaults to redhat-appstudio/infra-deployments for targetGHRepo,
  and provided defaults for githubAppID and githubAppInstallationID)
* Added `defaultTargetGHRepo`, `defaultGithubAppID`, and `defaultGithubAppInstallationID` parameters
  to the update-infra-deployments task to specify the default values
  for the GitHub repository and app configurations.

## Changes in 0.4.1
* Updated hacbs-release/release-utils image to reference redhat-appstudio/release-service-utils image instead

## Changes in 0.4.0
* add protection to prevent failures if there are no updated files.

## Changes in 0.3
* extraDataJsonPath is renamed to dataJsonPath to more closely match the API spec

## Changes in 0.2
* update Tekton API to v1

## Changes in 0.1
* extraDataJsonPath and snapshotPath are now required parameters
