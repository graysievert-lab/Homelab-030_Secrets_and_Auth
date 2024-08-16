
############
## SSH CA for providing short-live ssh certificates that allow access to:
##  - proxmox nodes
##  - 
############

resource "vault_mount" "sengine_ssh_iac_usercert" {
  ## Related:
  ##  policies/manage-ssh-iac-usercert.hcl
  path                      = "ssh-iac-usercert"
  type                      = "ssh"
  description               = "Signer for user ssh keys to access proxmox nodes"
  default_lease_ttl_seconds = 3600
  max_lease_ttl_seconds     = 3600
}

#SSH CA config
resource "vault_ssh_secret_backend_ca" "sengine_ssh_iac_usercert_cfg" {
  backend              = vault_mount.sengine_ssh_iac_usercert.path
  generate_signing_key = true # Vault will generate the CA keypair

  lifecycle {
    prevent_destroy = true
  }
}

# SSH secrets engine role to get ssh key and signed ssh certificate for user `iac`
resource "vault_ssh_secret_backend_role" "sengine_ssh_iac_usercert_role_iac" {
  ## Related:
  ##  policies/use-ssh-iac-usercert-iac.hcl
  name                    = "iac"
  backend                 = vault_mount.sengine_ssh_iac_usercert.path
  key_type                = "ca"
  allow_user_certificates = true
  allow_host_certificates = false
  allow_user_key_ids      = false
  allowed_extensions      = ""
  default_extensions = {
    "permit-pty" : ""
  }
  allowed_users = "iac"
  default_user  = "iac"
  ttl           = "3600" #1h
  max_ttl       = "3600" #1h
}

output "sengine_ssh_iac_usercert_public_key" {
  description = "Public key for ssh-iac-usercert CA"
  value       = vault_ssh_secret_backend_ca.sengine_ssh_iac_usercert_cfg.public_key
}