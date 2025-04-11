# Push to Developer Portal Pipeline

Tekton pipeline to sign and release Red Hat binaries to the Red Hat Developer Portal.

## Parameters

| Name                            | Description                                                                                                                        | Optional | Default value                                             |
|---------------------------------|------------------------------------------------------------------------------------------------------------------------------------|----------|-----------------------------------------------------------|
| release                         | The namespaced name (namespace/name) of the Release custom resource initiating this pipeline execution                             | No       | -                                                         |
| releasePlan                     | The namespaced name (namespace/name) of the releasePlan                                                                            | No       | -                                                         |
| releasePlanAdmission            | The namespaced name (namespace/name) of the releasePlanAdmission                                                                   | No       | -                                                         |
| releaseServiceConfig            | The namespaced name (namespace/name) of the releaseServiceConfig                                                                   | No       | -                                                         |
| snapshot                        | The namespaced name (namespace/name) of the snapshot                                                                               | No       | -                                                         |
| enterpriseContractPolicy        | JSON representation of the policy to be applied when validating the enterprise contract                                            | No       | -                                                         |
| enterpriseContractExtraRuleData | Extra rule data to be merged into the policy specified in params.enterpriseContractPolicy. Use syntax "key1=value1,key2=value2..." | Yes      | pipeline_intention=release                                |
| enterpriseContractTimeout       | Timeout setting for `ec validate`                                                                                                  | Yes      | 40m0s                                                     |
| postCleanUp                     | Cleans up workspace after finishing executing the pipeline                                                                         | Yes      | true                                                      |
| verify_ec_task_bundle           | The location of the bundle containing the verify-enterprise-contract task                                                          | No       | -                                                         |
| verify_ec_task_git_revision     | The git revision to be used when consuming the verify-conforma task                                                                | No       | -                                                         |
| taskGitUrl                      | The url to the git repo where the release-service-catalog tasks to be used are stored                                              | No        | "" |
| taskGitRevision                 | The revision in the taskGitUrl repo to be used                                                                                     | No       | -                                                         |

## Changes in 1.8.0
* Update all tasks that now support trusted artifacts to specify the taskGit* parameters for the step action resolvers

## Changes in 1.7.0
* Add new parameter `verify_ec_task_git_revision` needed for consuming the verify-conforma task
  via git resolver

## Changes in 1.6.0
* Update all task pathInRepo values as they are now in `tasks/managed`

## Changes in 1.5.0
* Add the `check-data-keys` task to validate the `data.json` file using the JSON schema.

## Changes in 1.4.0
* Use results from `sign-binaries` task for `push-to-cdn` and `publish-to-cgw` instead of `extract-binaries-from-image`

## Changes in 1.3.0
* Add more params for `sign-binaries` task

## Changes in 1.2.0
* Add new reduce-snapshot task

## Changes in 1.1.0
* Add the `sign-binaries` task to this pipeline.

## Changes in 1.0.0
* Drop the `enterpriseContractPublicKey` param. The verify task will take the value from the policy.

## Changes in 0.3.0
* Add `requireInternalServices` parameter to the 'verify-access-to-resources' task.

## Changes in 0.2.4
* Increase `enterpriseContractTimeout` parameter default value.

## Changes in 0.2.3
* Add `enterpriseContractTimeout` parameter.

## Changes in 0.2.2
* Fixed incorrect task references
  * Some of the references incorrectly specified a name

## Changes in 0.2.1
* Update params for `push-to-cdn`and `publish-to-cgw` tasks

## Changes in 0.2.0
* Removed `verify-access-to-resources` script and replaced it with a task.
