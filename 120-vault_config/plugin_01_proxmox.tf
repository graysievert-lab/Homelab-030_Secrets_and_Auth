############
## This registeres plugin https://github.com/mollstam/vault-plugin-secrets-proxmox 
## Binary needs to be downloaded and renamed to `proxmox` prior to execution of terraform
############

resource "vault_plugin" "proxmox" {
  type    = "secret"
  name    = "proxmox"
  command = "proxmox"
  version = "v1.1.0"
  sha256  = "0fd1633c052ccf715e5712e0b338bf81eb468ab61a4b40dd9f54c7dd7bdd0f09"
}











