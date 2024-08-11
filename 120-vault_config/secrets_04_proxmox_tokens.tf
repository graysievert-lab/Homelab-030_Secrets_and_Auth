############
## Issuer of Proxmox API tokens that allow access to:
##  - proxmox nodes
##  - 
############


resource "vault_mount" "sengine_proxmox_tokens" {
  ## Related:
  ##  policies/manage-proxmox-tokens.hcl
  depends_on                = [vault_plugin.proxmox]
  path                      = "proxmox-tokens"
  type                      = "proxmox"
  description               = "Issuer of Proxmox API tokens"
  default_lease_ttl_seconds = 3600
  max_lease_ttl_seconds     = 3600
}

# ## Configure this resource via CLI to avoid leaking
# ## `token_secret` into the codebase and tf-state.
# ## see README.md
# resource "vault_generic_endpoint" "sengine_proxmox_tokens_cfg" {
#   depends_on           = [vault_mount.sengine_proxmox_tokens]
#   path                 = "${vault_mount.sengine_proxmox_tokens.path}/config"
#   ignore_absent_fields = true
#   disable_read         = true

#   ## proxmox token format: user@realm!token_id=token_secret
#   data_json            = <<EOT
# {
#     "user":"",
#     "realm":"",
#     "token_id":"",
#     "token_secret":"",
#     "proxmox_url":"https://fqdn:8006/api2/json"
# }
# EOT
# }

resource "vault_generic_endpoint" "sengine_proxmox_tokens_role_apitoken" {
  ## Related:
  ##  policies/use-proxmox-tokens-apitoken.hcl
  depends_on           = [vault_mount.sengine_proxmox_tokens]
  path                 = "${vault_mount.sengine_proxmox_tokens.path}/role/apitoken"
  ignore_absent_fields = true
  disable_read         = true
  data_json            = <<EOT
{
    "max_ttl":"3600",
    "realm":"pam",
    "ttl":"3600",
    "user":"iac"
}
EOT
}
