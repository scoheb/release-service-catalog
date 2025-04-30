# Collector test
## Setup
### Dependencies
* Github repo: https://github.com/scoheb/e2e-base
* Github personal access token (classic) for above repo with **admin:repo_hook**, **delete_repo**, **repo** scopes.
* The password to the vault files. (Contact a member of the Release team should you want to run this
  test suite.)
### Required Environment Variables
- GITHUB_TOKEN
  - The Github personal access token needed for repo operations
  - The repo in question can be located in [test.env](test.env)
- VAULT_PASSWORD_FILE
  - This is the path to a file that contains the ansible vault
    password needed to decrypt the secrets needed for testing.
### Optional Environment Variables
- RELEASE_CATALOG_GIT_URL
  - The release service catalog URL to use in the RPA
  - This is provided when testing PRs
- RELEASE_CATALOG_GIT_REVISION
  - The release service catalog revision to use in the RPA
  - This is provided when testing PRs
- KUBECONFIG
  - The KUBECONFIG file to used to login to the target cluster
  - This is provided when testing PRs 
### Test Properties
#### [test.env](test.env)
- This file contains resource names and configuration values needed for testing.
- Since this test requires internal services, the tenant and managed namespaces
  should remain as-is.
### Secrets
- Secrets needed for testing are stored in ansible vault files.
  - [vault/collector-managed-secrets.yaml](vault/collector-managed-secrets.yaml)
  - [vault/collector-tenant-secrets.yaml](vault/collector-tenant-secrets.yaml)
- Most secrets required are contained in the files above.
- Some tests have their secret name hardcoded and therefore must exist prior to running this test:
  - konflux-advisory-jira-secret
  - atlas-staging-sso-secret
  - atlas-retry-s3-staging-secret
### Running the test

```shell
run-test.sh
```
- Should you needed to update a secret, perform these steps:

### Maintenance
- Should you require to add or update a secret, follow these steps:
```shell
ansible-vault decrypt vault/collector-tenant-secrets.yaml --output "/tmp/tenant-secrets.yaml" --vault-password-file <vault password file>
```

```shell
vi /tmp/tenant-secrets.yaml
```

```shell
ansible-vault encrypt /tmp/tenant-secrets.yaml --output "vault/collector-tenant-secrets.yaml" --vault-password-file <vault password file>
```

```shell
rm /tmp/tenant-secrets.yaml
```
