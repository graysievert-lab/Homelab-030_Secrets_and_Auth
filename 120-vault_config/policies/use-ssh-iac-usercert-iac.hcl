# Allow access to SSH role
path "ssh-iac-usercert/sign/iac" {
 capabilities = ["create","update"]
}