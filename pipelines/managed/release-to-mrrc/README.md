# release-to-mrrc pipeline

Tekton release pipeline to release maven artifacts extracted from the maven repository zip built through Middleware product in Konflux. The artifacts will be released to maven.repository.redhat.com.

## Parameters

| Name                            | Description                                                                                                                        | Optional | Default value                                             |
| ------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |----------|-----------------------------------------------------------|
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
| taskGitRevision                 | The revision in the taskGitUrl repo to be used                                                                                     | No        | ""                                                |

## Changes in 0.5.0
* Update all tasks that now support trusted artifacts to specify the stepAction* parameters

## Changes in 0.4.0
* Add new parameter `verify_ec_task_git_revision` needed for consuming the verify-conforma task
  via git resolver

## Changes in 0.3.0
* Update all task pathInRepo values as they are now in `tasks/managed`

## Changes in 0.2.0
* Add the `check-data-keys` task to validate the `data.json` file using the JSON schema.
