variable "pveusername" {
  description = "PAM username for ssh use"
  type        = string
  default     = "iac"
}

variable "pvetoken" {
  ## set this var via environment variable TF_VAR_pvetoken
  description = "Proxmox API token for TF to use"
  type        = string
}

variable "public_ssh_key_for_VM" {
  ## set this var via environment variable TF_VAR_public_ssh_key_for_VM
  description = "Public ssh key to use in cloud-init config for test vm"
  type        = string
  ## see readme for setting token via shell variable
}


variable "TSIG_key" {
  ## set this var via environment variable TF_VAR_TSIG_key
  description = "TSIG key. Format: 'key_name.|key_secret')"
  type        = string
}


