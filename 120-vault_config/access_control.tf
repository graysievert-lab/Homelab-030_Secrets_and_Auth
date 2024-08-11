############################################################
## Policies
############################################################

## Devops policies 
locals {
  policies_devops = [
    "init-root",
    "init-devops",
    "manage-ssh-vm-usercert",
    "use-ssh-vm-usercert-rocky",
    "manage-ssh-iac-usercert",
    "use-ssh-iac-usercert-iac",
    "manage-proxmox-tokens",
    "use-proxmox-tokens-apitoken"
  ]
}
resource "vault_policy" "policies_4_devops" {
  for_each = toset(local.policies_devops)
  name     = each.key
  policy   = file("${path.module}/policies/${each.key}.hcl")
}


## common policies
locals {
  policies_common = [
    "lookup-self"
  ]
}
resource "vault_policy" "lookup_self" {
  for_each = toset(local.policies_common)
  name     = each.key
  policy   = file("${path.module}/policies/${each.key}.hcl")
}



############################################################
## Groups
############################################################

##
## Devops external group
##
resource "vault_identity_group" "group_ext_devops" {
  name                       = "Devops"
  type                       = "external"
  external_policies          = true
  external_member_entity_ids = true
  external_member_group_ids  = true
}
resource "vault_identity_group_policies" "group_ext_devops_policies" {
  group_id  = vault_identity_group.group_ext_devops.id
  policies  = local.policies_devops
  exclusive = true
}
resource "vault_identity_group_member_group_ids" "group_ext_devops_subgroups" {
  group_id         = vault_identity_group.group_ext_devops.id
  exclusive        = true
  member_group_ids = []
}
# External group alias mapped to "devops" coming from Authentik OIDC claim `groups`
resource "vault_identity_group_alias" "group_ext_devops_alias_for_auth_oidc_authentik" {
  canonical_id   = vault_identity_group.group_ext_devops.id
  mount_accessor = vault_jwt_auth_backend.auth_oidc_authentik.accessor
  name           = "devops"
}


