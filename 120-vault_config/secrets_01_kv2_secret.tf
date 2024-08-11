
############
## KV-V2 Secrets engines
############
resource "vault_mount" "sengine_kv2_secret" {
  path        = "secret"
  type        = "kv-v2"
  description = "KV Version 2 secret engine"

  lifecycle {
    prevent_destroy = true
  }
}

