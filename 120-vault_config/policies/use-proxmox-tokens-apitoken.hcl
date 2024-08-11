# Allow requesting proxmox API token
path "proxmox-tokens/creds/apitoken" {
    capabilities = ["read"]
}