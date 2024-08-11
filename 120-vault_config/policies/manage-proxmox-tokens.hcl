# manage "proxmox" roles
path "proxmox-tokens/role/*" {
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}