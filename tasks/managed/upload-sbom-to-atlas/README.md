# upload-sbom-to-atlas
This Tekton task gathers SBOM data from a directory specified by the parameters
and uploads them to Atlas. Supports both CycloneDX and SPDX format. If the push 
to Atlas fails, the SBOM is pushed to an S3 bucket. The push to Atlas is then 
retried asynchronously from the bucket by another service.

The provided directory is searched for SBOMs recursively and all found SBOMs
are uploaded as-is to Atlas.

## Parameters
| Name                      | Description                                                                                                                | Optional | Default value                                                                 |
| ------------------------- | -------------------------------------------------------------------------------------------------------------------------- | -------- | ----------------------------------------------------------------------------- |
| sbomDir                   | Directory containing SBOM files relative to the data workspace.                                                            | No       | None                                                                          |
| httpRetries               | Max HTTP retry count.                                                                                                      | Yes      | 3                                                                             |
| atlasSecretName           | Name of the Secret containing SSO auth credentials for Atlas.                                                              | Yes      | atlas-prod-sso-secret                                                         |
| ATLAS_API_URL             | URL of the Atlas API host.                                                                                                 | Yes      | https://atlas.release.devshift.net                                            |
| ssoTokenUrl               | URL of the SSO token issuer.                                                                                               | Yes      | https://auth.redhat.com/auth/realms/EmployeeIDP/protocol/openid-connect/token |
| retryAWSSecretName        | Name of the Secret containg auth for AWS.                                                                                  | No       |                                                                               |
| retryS3Bucket             | Name of the S3 bucket to push failed SBOMs to.                                                                             | No       |                                                                               |
| ociStorage                | The OCI repository where the Trusted Artifacts are stored                                                                  | Yes      | empty                                                                         |
| ociArtifactExpiresAfter   | Expiration date for the trusted artifacts created in the OCI repository. An empty string means the artifacts do not expire | Yes      | 1d                                                                            |
| trustedArtifactsDebug     | Flag to enable debug logging in trusted artifacts. Set to a non-empty string to enable                                     | Yes      | ""                                                                            |
| orasOptions               | oras options to pass to Trusted Artifacts calls                                                                            | Yes      | ""                                                                            |
| sourceDataArtifact        | Location of trusted artifacts to be used to populate data directory                                                        | Yes      | ""                                                                            |
| subdirectory              | Subdirectory inside the workspace to be used                                                                               | Yes      | ""                                                                            |
| dataDir                   | The location where data will be stored                                                                                     | Yes      | $(workspaces.data.path)                                                       |
| taskGitUrl                | The url to the git repo where the release-service-catalog tasks and stepactions to be used are stored                      | No       | ""                                                                            |
| taskGitRevision           | The revision in the taskGitUrl repo to be used                                                                             | No       | ""                                                                            |

## Changes in 3.0.0
* Removed SBOM conversion functionality - SBOMs are now uploaded as-is to Atlas
* Conversion is no longer needed because Atlas V2 supports all SBOM versions
* Removed `supportedCycloneDxVersion` and `supportedSpdxVersion` parameters
* Simplified task implementation by removing conversion and format detection steps

## Changes in 2.2.0
* Added compute resource limits

## Changes in 2.1.0
* Deprecate the Atlas v1 API in favor of v2.
* A param `bombasticApiUrl` was renamed to `atlasApiUrl`.
* Atlas uploads routes are now pointing to the v2 API.

## Changes in 2.0.1
* Force curl to retry on all errors in S3 push.

## Changes in 2.0.0
* Add a step that pushes SBOMs to S3 if they failed to be pushed to Atlas.
* Add non-optional parameters to facilitate the S3 push.

## Changes in 1.0.0
* This task now supports Trusted artifacts

## Changes in 0.2.1
* Ignore error (but output a message) if upload request to Atlas fails.

## Changes in 0.2.0
* Remove option to skip uploading SBOMs. Skipping will be handled via Tekton.
* Rename productSBOMPath parameter to sbomDir. Use SBOM file names as Atlas IDs.
