# setup-pulp-helpers

Writes Pulp helper functions to a shell script that can be sourced by subsequent steps. Includes helpers for cli.toml parsing, authentication (basic/OAuth2), and async task polling with queue position reporting.

## Parameters

| Name            | Description                                                                   | Optional | Default value                |
|-----------------|-------------------------------------------------------------------------------|----------|------------------------------|
| pulpSecretPath  | Path to the mounted Pulp secret containing cli.toml                           | Yes      | /etc/secrets                 |
| helpersPath     | Path where pulp-helpers.sh will be written                                    | Yes      | /var/workdir/pulp-helpers.sh |
| pulpTaskTimeout | Maximum time in seconds to wait for Pulp async tasks (default 7200 = 2 hours) | Yes      | 7200                         |
