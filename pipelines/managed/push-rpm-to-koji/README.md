# push-rpm-to-koji pipeline

Tekton pipeline to push rpms into the koji instance.

## Parameters

| Name                            | Description                                                                                                                        | Optional | Default value                                             |
|---------------------------------|------------------------------------------------------------------------------------------------------------------------------------|----------|-----------------------------------------------------------|
| release                         | The namespaced name (namespace/name) of the Release custom resource initiating this pipeline execution                             | No       | -                                                         |
| releasePlan                     | The namespaced name (namespace/name) of the releasePlan                                                                            | No       | -                                                         |
| releasePlanAdmission            | The namespaced name (namespace/name) of the releasePlanAdmission                                                                   | No       | -                                                         |
| releaseServiceConfig            | The namespaced name (namespace/name) of the releaseServiceConfig                                                                   | No       | -                                                         |
| snapshot                        | The namespaced name (namespace/name) of the snapshot                                                                               | No       | -                                                         |
| postCleanUp                     | Cleans up workspace after finishing executing the pipeline                                                                         | Yes      | true                                                      |
| taskGitUrl                      | The url to the git repo where the release-service-catalog tasks to be used are stored                                              | Yes      | https://github.com/konflux-ci/release-service-catalog.git |
| taskGitRevision                 | The revision in the taskGitUrl repo to be used                                                                                     | No       | -                                                         |
| enterpriseContractPolicy        | JSON representation of the EnterpriseContractPolicy                                                                                | Yes      | brew-rhel-sst-prod                                        |
| enterpriseContractExtraRuleData | Extra rule data to be merged into the policy specified in params.enterpriseContractPolicy. Use syntax "key1=value1,key2=value2..." | Yes      | pipeline_intention=release                                |
| enterpriseContractTimeout       | Timeout setting for `ec validate`                                                                                                  | Yes      | 8h0m0s                                                    |
| enterpriseContractWorkerCount   | Number of parallel workers for policy evaluation                                                                                   | Yes      | 4                                                         |
| verify_ec_task_git_revision     | The git revision to be used when consuming the verify-conforma task                                                                | No       | -                                                         |
| ociStorage                      | OCI registry for storing trusted artifacts                                                                                         | Yes      | quay.io/konflux-ci/release-service-trusted-artifacts     |
| orasOptions                     | oras options to pass to Trusted Artifacts calls                                                                                   | Yes      | ""                                                        |
| trustedArtifactsDebug          | Flag to enable debug logging in trusted artifacts. Set to a non-empty string to enable.                                          | Yes      | ""                                                        |
| dataDir                         | The location where data will be stored                                                                                            | Yes      | /var/workdir/release                                      |

