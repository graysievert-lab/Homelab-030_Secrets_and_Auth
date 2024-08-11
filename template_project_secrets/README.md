# Example Project

This example project demonstrates how to structure a terraform configuration to manage Vault resources for individual projects.

In this example, it is assumed that all project secrets are represented as shell variables that need to be exported into the environment.

## Resources
Terraform mounts a few kv2 secrets for the project `template_project_secrets`
```text
secret/template_project_secrets/some/secrets
secret/template_project_secrets/multiline/secret
secret/template_project_secrets/empty/secret
```
registers associated read and update access policies for each secret
```text
template_project_secrets_some_secret_[read]
template_project_secrets_some_secret_[update]
...
```
and creates a `secrets.list` file containing paths in a format compatible with the `gen_token.sh` script.

## Post-deployment steps
Note: For security reasons, secrets are initialized without any data. The management of secret contents should be handled through the Vault UI, CLI, or API.

To populate secrets with data navigate to [Secrets/secret/template_project_secrets/some/secrets](https://aegis.lan:8200/ui/vault/secrets/secret/kv/template_project_secrets%2Fsome%2Fsecrets/details?version=1) and add two key-value pairs:
```bash
"PROJECT_SOME_SECRET_A":"first value"
"PROJECT_SOME_SECRET_B":"second value"
```

Then go to [Secrets/secret/template_project_secrets/multiline/secret](https://aegis.lan:8200/ui/vault/secrets/secret/kv/template_project_secrets%2Fmultiline%2Fsecret/details?version=1) and add  key-value pair
```bash
"PROJECT_MULTILINE_SECRET":"-----BEGIN MULTILINE SECRET-----
bwAAAAtzc2gtZWQyNTUxOQAAACAb/iRcI5vYlDWMC2yUSwEVAJnSTYFhCqs5eixLloYt0Q
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
AAAECiqq+yiCkL6lXlOvZiPU5N26wGA1Ne1bzUsxIjwDQ5Hxv+JFwjm9iUNYwLbJRLARUA
QyNTUxOQAAACAb/iRcI5vYlDWMC2yUSwEVAJnSTYFhCqs5eixLloYt0QAAAIgdUMlvHVDJ
mdJNgWEKqzl6LEuWhi3RAAAAAAECAwQF
-----END MULTILINE SECRET-----
"
```

And for testing purposes let's leave the [third secret](https://aegis.lan:8200/ui/vault/secrets/secret/kv/template_project_secrets%2Fempty%2Fsecret/details?version=1) empty.

## Fetching secrets
The following scripts can assist in initializing the environment with the secrets mentioned:
- `gen_token.sh`: Reads a list of secret paths from stdin, generates a short-lived token, and outputs it. This token can then be used with the `prime_env.sh` script.

- `prime_env.sh`: Uses the token’s metadata to retrieve a list of secrets’ paths, fetches the corresponding key-value pairs and sets them as environment variables. This script needs to be sourced to function correctly.

Typically, `gen_token.sh` should be executed in a secure environment with privileged access to Vault. In contrast, `prime_env.sh` is supposed to run in an environment where access is restricted to only the project's specific secrets.

This separation ensures that sensitive operations are confined to secure environments, while project-specific secrets are managed with minimal access.


### Example
We would need two terminal sessions.

In the first session log in to Vault:
```bash
$ unset VAULT_TOKEN
$ export VAULT_ADDR=https://aegis.lan:8200
$ vault login -method=oidc
```
Generate access token:
```bash
$ ./gen_token.sh < secrets.list
hvb.AAAAAQLbc5FZoDMH--Cj_gWE44zkVnCIXE0Nl8pCFhyyDSCRwhjfFVp7hf1Ca3SXoUtbwzr03lWXMWPQG3htUuL8wTsiW7-X0uR43RsMvs-hU0PcUPPZFxMy4JOXBtZ98TIFfYSylHaTAoM07FEm-1mX9wb2T1Piwfq0ki5XvpUX8ZRbluDcwc0UXRPmk9aCf9IQilkPLFfzHivsGj4FDBt0_TtjIodQd14LH75Exz3ewca1r3IZstgguXhnkES4zOzCLTAxR2aM6fvUqk3aC3EemAIfkbw1UQvbMpqjXFlbanGRTbY6Apk0GozDx0cudoCKB1YCcDY2CTopQswXln6NhlShzv0TghNO-E1P_vWiAvUSm62aggRzriZZ3vi_7swVZS0MT6-Xv7xONWIjyRBzfUOWyw0mVxxnT34ISyx0uJ5ns59B5FbcfGL_k63zVNXsaGpZPyGW46QKVWF4nuyVC9YR_AxGvRkBUZCkRMo
```

In another terminal session source the second script and paste the token received on the previous step (to finish enter `crtl+d` on an empty line).
```bash
$ export VAULT_ADDR=https://aegis.lan:8200

$ source prime_env.sh
Enter vault token
hvb.AAAAAQLbc5FZoDMH--Cj_gWE44zkVnCIXE0Nl8pCFhyyDSCRwhjfFVp7hf1Ca3SXoUtbwzr03lWXMWPQG3htUuL8wTsiW7-X0uR43RsMvs-hU0PcUPPZFxMy4JOXBtZ98TIFfYSylHaTAoM07FEm-1mX9wb2T1Piwfq0ki5XvpUX8ZRbluDcwc0UXRPmk9aCf9IQilkPLFfzHivsGj4FDBt0_TtjIodQd14LH75Exz3ewca1r3IZstgguXhnkES4zOzCLTAxR2aM6fvUqk3aC3EemAIfkbw1UQvbMpqjXFlbanGRTbY6Apk0GozDx0cudoCKB1YCcDY2CTopQswXln6NhlShzv0TghNO-E1P_vWiAvUSm62aggRzriZZ3vi_7swVZS0MT6-Xv7xONWIjyRBzfUOWyw0mVxxnT34ISyx0uJ5ns59B5FbcfGL_k63zVNXsaGpZPyGW46QKVWF4nuyVC9YR_AxGvRkBUZCkRMo
Priming your environment with secrets...
Your env is ready
```

Check environment variables
```bash
$ printenv PROJECT_SOME_SECRET_A PROJECT_SOME_SECRET_B PROJECT_MULTILINE_SECRET
first value
second value
-----BEGIN MULTILINE SECRET-----
bwAAAAtzc2gtZWQyNTUxOQAAACAb/iRcI5vYlDWMC2yUSwEVAJnSTYFhCqs5eixLloYt0Q
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
AAAECiqq+yiCkL6lXlOvZiPU5N26wGA1Ne1bzUsxIjwDQ5Hxv+JFwjm9iUNYwLbJRLARUA
QyNTUxOQAAACAb/iRcI5vYlDWMC2yUSwEVAJnSTYFhCqs5eixLloYt0QAAAIgdUMlvHVDJ
mdJNgWEKqzl6LEuWhi3RAAAAAAECAwQF
-----END MULTILINE SECRET-----
```

If you need to configure the project environment in the same shell where Vault is accessible, you can use the following one-liner:
```bash
$ . prime_env.sh <<< $(./gen_token.sh < secrets.list)
```

