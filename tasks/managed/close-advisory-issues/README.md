# close-advisory-issues

Tekton task to close all issues referenced in the releaseNotes. It is meant to run after the advisory is published.
A comment will be added to each closed issue with a link to the advisory it was fixed in.

Note: This task currently only supports issues in issues.redhat.com due to it requiring authentication.
Issues in other servers will be skipped without the task failing.

## Parameters

| Name                  | Description                                                                                 | Optional | Default value                                             |
|-----------------------|---------------------------------------------------------------------------------------------|----------|-----------------------------------------------------------|
| dataPath              | Path to data JSON in the data workspace                                                     | No       | -                                                         |
| advisoryUrl           | The url of the advisory the issues were fixed in. This is added in a comment on the issue   | No       | -                                                         |
| stepActionGitUrl      | The url to the git repo where the release-service-catalog stepActions to be used are stored | Yes      | https://github.com/konflux-ci/release-service-catalog.git |
| stepActionGitRevision | The revision in the stepActionGitUrl repo to be used                                        | Yes      | production                                                |

## Changes in 1.0.0
* This task now supports Trusted artifacts

## Changes in 0.1.1
* Deal with Jira API rate limiting using a new `curl-with-retry` script from utils image
  * Bump the utils image to a version containing the new script
