# Managing Vault configuration via Terraform
Prerequisites: Installed Vault and Authentik as described in [Installing Vault and Authentik, setting up IdP, groups, and SSO](https://github.com/graysievert/Homelab-030_Secrets_and_Auth/tree/master/110-infra_vault_and_authentik).

This project is dedicated to bootstrapping and subsequent management of Vault configuration.

## Structure
**Access management**
- `access_control.tf` — Groups and Policies
- `/policies`	— hcl files for policies

**Plugins**
- `plugin_01_proxmox.tf` — registers plugin https://github.com/mollstam/vault-plugin-secrets-proxmox

**Authentication Methods**
- `auth_01_oidc.tf` — OIDC AUTH method

**Secrets Engines**
- `secrets_01_kv2_secret.tf` — KV Version 2 secret engine
- `secrets_02_ssh_vm_usercert.tf` — SSH CA for providing short-live SSH certificates that allow access to VMs in the lab
- `secrets_03_ssh_iac_usercert.tf` — SSH CA for providing short-live SSH certificates that allow access to Proxmox nodes
- `secrets_04_proxmox_tokens.tf` — Issuer of Proxmox API tokens that allow access to Proxmox nodes


## Preconditions
OIDC provider and application in Authentik must be [configured](https://github.com/graysievert/Homelab-030_Secrets_and_Auth/tree/master/110-infra_vault_and_authentik#configure-oidc-provider-for-vault) before terraform runs and local variables in `auth_01_oidc.tf` should correspond to that configuration.

Set the variables for the provider to work:
```bash
$ export VAULT_ADDR=https://aegis.lan:8200

$ export VAULT_TOKEN=$(cat)
hvs.VaultRootTokenContents
ctrl+d
```


## Post-bootstrap manual steps and checks
For security reasons, a few manual steps are required after the very first terraform run:

### Proxmox Secret Engine manual steps
To prevent the exposure of secrets in the codebase and tf-state we need to manually set the config for Proxmox secret engine. The plugin does not support configuration through UI, so CLI needs to be used.

Set the variable `TF_VAR_pvetoken` with the existing Proxmox API token (token generation is described in [Configuring Proxmox VE to be managed via Terraform](https://github.com/graysievert/Homelab-020_Proxmox_basic/tree/master/130-Terraform_access)):
```bash
$ export TF_VAR_pvetoken=$(cat)
user@realm!token_id=token_secret
ctrl+d
```

Overwrite the configuration for the Proxmox secrets engine (terraform mounts it to `proxmox-tokens`):
```bash
$ vault write proxmox-tokens/config \
user=$(awk -F'[@!]' '{print $1}' <<< "$TF_VAR_pvetoken") \
realm=$(awk -F'[@!]' '{print $2}' <<< "$TF_VAR_pvetoken") \
token_id=$(awk -F'[@!]' '{split($3, a, "="); print a[1]}' <<< "$TF_VAR_pvetoken") \
token_secret=$(awk -F'[@!]' '{split($3, a, "="); print a[2]}' <<< "$TF_VAR_pvetoken") \
proxmox_url=https://pve.lan:8006/api2/json
```

Test that a new token can be fetched from Vault:
```bash
$ vault read proxmox-tokens/creds/apitoken
Key            	Value
---            	-----
lease_id       	proxmox-tokens/creds/apitoken/E8zhojHxDmKIWPJltiqjPKZg
lease_duration 	1h
lease_renewable	true
secret         	b2cc48e0-f972-48bc-a822-ce8a32c2bbe8
token_id       	mpekjdcg-ljhh-khmp-oedg-eibehekdidmn
token_id_full  	iac@pam!mpekjdcg-ljhh-khmp-oedg-eibehekdidmn
```

Verify token info in a Proxmox shell:
``` bash
$ pveum user token list iac@pam --output-format=yaml
---
...
- comment: Managed by Vault
  expire: 1723163555
  privsep: 0
  tokenid: mpekjdcg-ljhh-khmp-oedg-eibehekdidmn
...
```

### OIDC Auth Method manual steps
Visit [https://aegis.lan:8200/ui/vault/settings/auth/configure/oidc/configuration](https://aegis.lan:8200/ui/vault/settings/auth/configure/oidc/configuration) (this should be the last time we used root token for login) and change `OIDC client secret` at `Auth Methods->oidc->Configure->OIDC Options` to the value configured [earlier](https://github.com/graysievert/Homelab-030_Secrets_and_Auth/tree/master/110-infra_vault_and_authentik#configure-oidc-provider-for-vault).

NOTE: `OIDC client ID` should be changed only via terraform as there are multiple dependencies on its value.

To check the OIDC login method:
```bash
$ unset VAULT_TOKEN
```

```bash
$ vault login -method=oidc
Complete the login via your OIDC provider. Launching browser to:

https://aegis.lan/application/o/authorize/?
client_id=NotThatSecretButUniqueRandomStringUsedForVault&
code_challenge=MqD4M2YssThoI7Py0FulBKHRiQ70yEIA77UFokB64vU&
code_challenge_method=S256&
nonce=n_IS6kurRUFF1QeyfISNhe&
redirect_uri=http%3A%2F%2Flocalhost%3A8250%2Foidc%2Fcallback&
response_type=code&
scope=openid+profile+email&
state=st_9ySAXXBmUMe5LuCbvMvl

Waiting for OIDC authentication to complete...
Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.

Key              	Value
---              	-----
token            	hvs.CAESIAUsESmRXEj.................
token_accessor   	8csawherUcm8atoO9pJkWTqr
token_duration   	8h
token_renewable  	true
token_policies   	["default"]
identity_policies	["init-devops"
                  	"init-root"
                  	"manage-ssh-iac-usercert"
                  	"manage-ssh-vm-usercert"
                  	"use-ssh-iac-usercert-iac"
                  	"use-ssh-vm-usercert-rocky"]
policies         	["default"
                  	"init-devops"
                  	"init-root"
                  	"manage-ssh-iac-usercert"
                  	"manage-ssh-vm-usercert"
                  	"use-ssh-iac-usercert-iac"
                  	"use-ssh-vm-usercert-rocky"]
token_meta_role  	login_mapper
```


## Usage

### Projects' secrets
The goal is to create a separate folder for each project, each containing its own Terraform files. Each folder should include Terraform configurations specific to that project’s Vault resources. This approach ensures that the lifecycle of Vault resources can be managed independently for each project.

Check example [`template_project_secrets`](https://github.com/graysievert/Homelab-030_Secrets_and_Auth/tree/master/template_project_secrets) for details.

###  Secrets for `bpg/proxmox` terraform provider
The resources defined in `secrets_03_ssh_iac_usercert.tf` and `secrets_04_proxmox_tokens.tf` enable short-term access to Proxmox by setting up the environment with the required secrets for [bpg/proxmox](https://registry.terraform.io/providers/bpg/proxmox/latest/docs) provider to operate.

See [Priming bpg/proxmox terraform provider with secrets from Vault](https://github.com/graysievert/Homelab-020_Proxmox_basic/tree/master/140-Priming_TF_provider_with_Vault) for details.

