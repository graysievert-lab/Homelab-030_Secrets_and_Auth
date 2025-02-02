
############
## JWT auth backend for lab k8s cluster
############
locals {

  auth_path    = "kube-lab-jwt"
  jwt_audience = "https://kubernetes.default.svc.cluster.local"

  jwt_validation_pubkey = <<EOF
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA4NaxWhMRZ9aEbQw4dVyy
a2z1nvibn/eVo6IPKJvjgDLke5Moo845WGjGud8aLdb83xMRm6aHbHqjNlFn7dvF
/vj/zmpPgW10Mxil3saPZGkJjYy2wbDt9a3fV7iO34Swzx3wmKEaImdWdOEvE+Dz
lFhDwuQXeS2pFsLIlrK1UlYjn+NX9QiPE3D7sWGydzF96fDTWdzE1WZWuXWzu1rL
QQIcGRfR/1ELNPISg8wSwOv01fIwSQF0k4nYGdjBqx7pwLi0dUAxCpcaBx7kpB4R
GbRtlOWEus+n0TPkXbMCtMB6csQOgk8achKc4HkQGZ2E0L7B82JebD31v+2SUNdG
1QIDAQAB
-----END PUBLIC KEY-----
EOF

  default_role = "default"
  policy_name  = "infra-kube_lab_ns_sa_path_read_[read]"

}


############
## JWT auth method
############
resource "vault_jwt_auth_backend" "this" {
  description = "JWT auth backend for lab k8s cluster"
  type        = "jwt"
  path        = local.auth_path
  jwt_validation_pubkeys = [
    local.jwt_validation_pubkey
  ]
  default_role = local.default_role
}

############
## JWT auth default role
############
resource "vault_jwt_auth_backend_role" "default" {
  backend    = vault_jwt_auth_backend.this.id
  role_name  = vault_jwt_auth_backend.this.default_role
  role_type  = "jwt"
  user_claim = "sub"
  token_type = "batch"
  token_ttl  = 600

  bound_audiences = [
    local.jwt_audience
  ]

  claim_mappings = {
    "/kubernetes.io/namespace" : "namespace",
    "/kubernetes.io/serviceaccount/name" : "serviceaccount",
    "/kubernetes.io/serviceaccount/uid" : "uid"
  }


  token_policies = [
    "lookup-self",
    vault_policy.this.name
  ]
}


############
## Access policy
############
resource "vault_policy" "this" {
  name   = local.policy_name
  policy = <<EOF
# Allow access only to secrets under a specific service account
path "secret/data/cluster.lan/{{identity.entity.aliases.${vault_jwt_auth_backend.this.accessor}.metadata.namespace}}/{{identity.entity.aliases.${vault_jwt_auth_backend.this.accessor}.metadata.serviceaccount}}/*" {
  capabilities = ["read"]
}

# Allow access to all secrets under a specific namespace, but not deeper into service accounts subpaths
path "secret/data/cluster.lan/{{identity.entity.aliases.${vault_jwt_auth_backend.this.accessor}.metadata.namespace}}/+" {
  capabilities = ["read"]
}
EOF
}
