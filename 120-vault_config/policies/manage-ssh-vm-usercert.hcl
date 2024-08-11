# manage "ssh-vm-usercert" roles
path "ssh-vm-usercert/roles/*" {
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}