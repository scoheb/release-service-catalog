# push-oot-kmods

Tekton task to push signed out-of-tree kernel modules to a private GitLab repository. 

## Parameters

| Name              | Description                                                          | Optional | Default value |
|-------------------|----------------------------------------------------------------------|----------|---------------|
| signedKmodsPath   | Path where the signed kernel modules are stored in the workspace     | No       | -             |
| vendor            | Name of the vendor of the kernel modules                             | No       | -             |
| artifactRepoUrl   | Repository URL where the signed modules will be pushed               | No       | -             |
| artifactBranch    | Specific branch in the repository                                    | Yes      | "main"        |
| artifactRepoToken | Secret containing the Project Access Token for the artifact repos    | No       | -             |
| ociStorage               | The OCI repository where the Trusted Artifacts are stored             | Yes      | empty         |
| ociArtifactExpiresAfter  | Expiration date for the trusted artifacts created                     | Yes      | 1d            |
| trustedArtifactsDebug    | Flag (any string) to enable debug logging in trusted artifacts        | Yes      | ""            |
| orasOptions              | oras options to pass to Trusted Artifacts calls                       | Yes      | ""            |
| sourceDataArtifact       | Location of trusted artifacts to be used to populate data directory   | Yes      | ""            |
| dataDir                  | The location where data will be stored                                | Yes      | $(workspaces.data.path)   |

