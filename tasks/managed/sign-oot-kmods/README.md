# sign-oot-kmods 

Tekton task that signs out-of-tree kernel modules.

## Parameters

| Name                | Description                                                                | Optional | Default value         |
|---------------------|----------------------------------------------------------------------------|----------|-----------------------|
| dataPath            | Path to the data JSON in the data workspace                                | No       | -                     |
| signedKmodsPath     | Path where the kernel modules are stored in the workspace                  | No       | -                     |
| signingAuthor       | Human name responsible for the signing process                             | No       | -                     |
| checkSumFingerprint | Secret containing the host key database for SSH the server running signing | No       | -                     |
| checkSumKeytab      | Secret containing keytab file for the Kerberos user / server               | No       | -                     |
| signing-secret      | Secret containing the fields signHost, SignKey and SignUser                | No       | -                     |
| ociStorage               | The OCI repository where the Trusted Artifacts are stored             | Yes      | empty                 |
| ociArtifactExpiresAfter  | Expiration date for the trusted artifacts created                     | Yes      | 1d                    |
| trustedArtifactsDebug    | Flag (any string) to enable debug logging in trusted artifacts        | Yes      | ""                    |
| orasOptions              | oras options to pass to Trusted Artifacts calls                       | Yes      | ""                    |
| sourceDataArtifact       | Location of trusted artifacts to be used to populate data directory   | Yes      | ""                    |
| dataDir                  | The location where data will be stored                                | Yes      | $(workspaces.data.path)|
