# extract-oot-kmods

Tekton task that extracts out-of-tree kernel modules from an image.
Paths for .ko files to be signed from image


## Parameters

| Name                     | Description                                                           | Optional | Default value |
|--------------------------|-----------------------------------------------------------------------|----------|---------------|
| kmodsPath                | Path for the unsigned .ko files to be extracted from the image        | No       | -             |
| signedKmodsPath          | Path to store the extracted file in the workspace                     | No       | -             |
| snapshot                 | The namespaced name (namespace/name) of the snapshot                  | No       | -             |
| ociStorage               | The OCI repository where the Trusted Artifacts are stored             | Yes      | empty         |
| ociArtifactExpiresAfter  | Expiration date for the trusted artifacts created                     | Yes      | 1d            |
| trustedArtifactsDebug    | Flag (any string) to enable debug logging in trusted artifacts        | Yes      | ""            |
| orasOptions              | oras options to pass to Trusted Artifacts calls                       | Yes      | ""            |
| sourceDataArtifact       | Location of trusted artifacts to be used to populate data directory   | Yes      | ""            |
| dataDir                  | The location where data will be stored                                | Yes      | $(workspaces.data.path)   |
