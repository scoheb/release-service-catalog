# request-signature

StepAction to request a simple signature by contacting RADAS. Used in the simple signing pipeline

## Parameters

| Name                    | Description                                                                                            | Optional | Default value                                         |
|-------------------------|--------------------------------------------------------------------------------------------------------|----------|-------------------------------------------------------|
| pipeline_image          | An image of operator-pipeline-images for the steps to run in.                                          | Yes      | quay.io/redhat-isv/operator-pipelines-images:released |
| manifest_digest         | Docker reference for the signed content, e.g. registry.redhat.io/redhat/community-operator-index:v4.9< | No       | -                                                     |
| reference               | Docker reference for the signed content, e.g. registry.redhat.io/redhat/community-operator-index:v4.9  | No       | -                                                     |
| requester               | Name of the user that requested the signing, for auditing purposes                                     | No       | -                                                     |                                                    
| sig_key_id              | The signing key id that the content is signed with                                                     | Yes      | 4096R/55A34A82 SHA-256                                |
| sig_key_name            | The signing key name that the content is signed with                                                   | Yes      | containerisvsign                                      |
| umb_ssl_secret_name     | Kubernetes secret name that contains the umb SSL files                                                 | No       | -                                                     |
| umb_ssl_cert_secret_key | The key within the Kubernetes secret that contains the umb SSL cert.                                   | No       | -                                                     |
| umb_ssl_key_secret_key  | The key within the Kubernetes secret that contains the umb SSL key.                                    | No       | -                                                     |
| umb_client_name         | Client name to connect to umb, usually a service account name                                          | Yes      | operatorpipelines                                     |
| umb_listen_topic        | umb topic to listen to for responses with signed content                                               | Yes      | VirtualTopic.eng.robosignatory.isv.sign               |
| umb_publish_topic       | umb topic to publish to for requesting signing                                                         | Yes      | VirtualTopic.eng.operatorpipelines.isv.sign           |
| umb_url                 | umb host to connect to for messaging                                                                   | Yes      | umb.api.redhat.com                                    |
