
############
## Additional policy, entity, entity alias for webhook to mutate secrets or configmaps
## It is assuemed that during installation webhook's service account is `system:serviceaccount:vault-infra:vault-secrets-webhook`
## If webhook is installed into namespace other than `vault-infra` and helmrelease name is other than `vault-secrets-webhook`
## adjust accordingly
############
locals {
  webhook-serviceaccount = "vault-secrets-webhook"
  webhook-namespace = "vault-infra"
  webhook-clusteraccess-policy_name  = "infra-kube_lab_webhook_cluster_[read]"
}


############
## Access policy
############
resource "vault_policy" "webhook_policy" {
  name   = local.webhook-clusteraccess-policy_name
  policy = <<EOF
# Allow access to any secret for the cluster
path "secret/data/cluster.lan/*" {
  capabilities = ["read"]
}
EOF
}

############
## Identity for webhook
############
resource "vault_identity_entity" "webhook" {
  name      = local.webhook-serviceaccount
  policies  = [vault_policy.webhook_policy.name]
}


############
## Identity alias
############
resource "vault_identity_entity_alias" "webhook" {
  name            = "system:serviceaccount:${local.webhook-namespace}:${local.webhook-serviceaccount}"
  mount_accessor  = vault_jwt_auth_backend.this.accessor
  canonical_id    = vault_identity_entity.webhook.id
}