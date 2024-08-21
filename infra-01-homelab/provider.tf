terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = ">=4.4.0"
    }
  }
}

provider "vault" {
  # configure provider through the environment variables:
  #    - VAULT_ADDR
  #    - VAULT_TOKEN
  #    - etc.   
}