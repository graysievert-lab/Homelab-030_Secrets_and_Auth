#### Creates empty secrets and read policies
#### do not enter secrets vaules - they will be exposed in tf state

locals {
  secret_mount_path = "secret"
  project_name      = "infra-swarm"
  secrets = [
    "traefik",
    "portainer"
  ]
}

resource "vault_kv_secret_v2" "secrets" {
  for_each = toset(local.secrets)
  mount               = local.secret_mount_path
  name                = "${local.project_name}/${each.key}"
  data_json           = jsonencode({})
  disable_read        = true # disable drift detection 
  delete_all_versions = true # delete all version on resource deletion
    lifecycle {
    # prevent_destroy = true
  }
}


locals {
  secrets_list = join("\n", [for secret in local.secrets : "${local.project_name}/${secret}"])
}
resource "local_file" "list" {
  filename = "${path.module}/secrets.list"
  content  = local.secrets_list
}

resource "vault_policy" "read_policies" {
  for_each = toset(local.secrets)
  name = "${local.project_name}_${replace(each.key,"/","_")}_[read]"
  policy = <<EOT
path "${local.secret_mount_path}/data/${local.project_name}/${each.key}" {
  capabilities = ["read"]
}
EOT
}

resource "vault_policy" "update_policies" {
  for_each = toset(local.secrets)
  name = "${local.project_name}_${replace(each.key,"/","_")}_[update]"
  policy = <<EOT
path "${local.secret_mount_path}/data/${local.project_name}/${each.key}" {
  capabilities = ["update"]
}
EOT
}
