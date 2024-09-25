# upload-signature

StepAction to upload a simple signature to Pyxis. Used in the simple signing pipeline

## Parameters

| Name                      | Description                                                                   | Optional | Default value                                         |
|---------------------------|-------------------------------------------------------------------------------|----------|-------------------------------------------------------|
| pipeline_image            | An image of operator-pipeline-images for the steps to run in.                 | Yes      | quay.io/redhat-isv/operator-pipelines-images:released |
| signature_data_file       | Json file containing the list of signature data to upload to Pyxis signature. | No       | -                                                     |
| pyxis_ssl_secret_name     | Kubernetes secret name that contains the Pyxis SSL files.                     | No       | -                                                     |
| pyxis_ssl_cert_secret_key | The key within the Kubernetes secret that contains the Pyxis SSL cert         | No       | -                                                     |                                                    
| pyxis_ssl_key_secret_key  | The key within the Kubernetes secret that contains the Pyxis SSL key          | Yes      | 4096R/55A34A82 SHA-256                                |
| pyxis_url                 | Pyxis instance to upload the signature to.                                    | Yes      | https://pyxis.engineering.redhat.com                  |
