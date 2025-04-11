# embargo-check

Tekton task to check if any issues or CVEs in the releaseNotes key of the data.json are embargoed. It checks the issues
by server using curl and checks the CVEs via an InternalRequest. If any issue does not exist or any CVE is embargoed,
the task will fail. The task will also fail if a Jira issue listed is for a component that does not exist in the
releaseNotes.content.images section or if said component does not list the CVE from the issue.

Finally, the task will inject the `public` key to each issue listed for `issues.redhat.com`. This is a boolean value that is set
based on the issues visibility

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

## Changes in 2.0.0
* This task now supports Trusted artifacts

## Changes in 1.1.4
* Use a temp file for `internal-request` result instead of a fixed file in the workspace to reduce risk
  of interference with other tasks

## Changes in 1.1.3
* Enable CVE IDs check
  * Previous change disabled both Downstream Component check as well as the general check the CVE ID in each
    Jira is included in the releaseNotes field. This change enables a less strict version of the latter again.
    * Now we check that the CVE ID is included in some item of releaseNotes.content.images

## Changes in 1.1.2
* Disable checking of Downstream Component Name Jira field for CVEs while we figure out
  the right way of doing this

## Changes in 1.1.1
* Deal with Jira API rate limiting using a new `curl-with-retry` script from utils image
  * Bump the utils image to a version containing the new script

## Changes in 1.1.0
* The task injects the `public` key to each issue for the `issues.redhat.com` server based on if the issue is
  publicly visible

## Changes in 1.0.0
* Authentication is added to checking issues in issues.redhat.com
* If the issue exists and is not of type `Vulnerability`, the task will pass on that issue
* If the issue is of type `Vulnerability`
  * If the `Downstream Component Name` from the issue is not listed in the `releaseNotes.content.images`
    section, the task will fail
  * If the `CVE ID` from the issue is not present in its component's fixed cves section, the task will fail

## Changes in 0.5.0
* Added taskGiturl and taskGitRevision parameters to be passed to the internalRequest
* The pipeline is called via git resolver now instead of cluster resolver
  * This was done by changing from `-r` to `--pipeline` in the `internal-request` call
  * The base image was updated to include this new functionality
* Updated logic to determine InternalRequest name more reliably

## Changes in 0.4.1
* fix linting issues in embargo-check task

## Changes in 0.4.0
* updated the base image used in this task

## Changes in 0.3.0
* updated the base image used in this task

## Changes in 0.2.0
* remove `dataPath` default value
