
############
## SSH CA for providing short-live ssh certificates that allow access to VMs in the lab
############

resource "vault_mount" "sengine_ssh_vm_usercert" {
  ## Related:
  ##  policies/manage-ssh-vm-usercert.hcl
  path        = "ssh-vm-usercert"
  type        = "ssh"
  description = "Signer for user ssh keys"
}

#SSH CA config
resource "vault_ssh_secret_backend_ca" "sengine_ssh_vm_usercert_cfg" {
  backend              = vault_mount.sengine_ssh_vm_usercert.path
  generate_signing_key = true # Vault will generate the CA keypair

  lifecycle {
    prevent_destroy = true
  }
}

# SSH secrets engine role to get ssh key and signed ssh certificate for user `rocky`
resource "vault_ssh_secret_backend_role" "sengine_ssh_vm_usercert_role_rocky" {
  ## Related:
  ##  policies/use-ssh-vm-usercert-rocky.hcl
  name                    = "rocky"
  backend                 = vault_mount.sengine_ssh_vm_usercert.path
  key_type                = "ca"
  allow_user_certificates = true
  allow_host_certificates = false
  allow_user_key_ids      = false
  allowed_extensions      = ""
  default_extensions = {
    "permit-pty" : ""
  }
  allowed_users = "rocky"
  default_user  = "rocky"
  ttl           = "14400" #4h
  max_ttl       = "14400" #4h
}

output "sengine_ssh_vm_usercert_public_key" {
  description = "Public key for ssh-vm-usercert CA"
  value       = vault_ssh_secret_backend_ca.sengine_ssh_vm_usercert_cfg.public_key
}