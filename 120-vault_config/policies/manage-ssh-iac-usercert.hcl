# manage "ssh-iac-usercert" roles
path "ssh-iac-usercert/roles/*" {
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}