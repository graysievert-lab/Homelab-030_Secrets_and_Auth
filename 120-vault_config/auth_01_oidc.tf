############
## OIDC auth method
## Change oidc_client_secret through UI or CLI after applying
############


############
## WARNING: Vault should be able to reach and read discovery url or creation will fail
############
locals {
  oidc_client_id     = "NotThatSecretButUniqueRandomStringUsedForVault"
  oidc_client_secret = "change me through UI or CLI" 
  oidc_discovery_url = "https://aegis.lan/application/o/vault/"
  allowed_redirect_uris = [
    "https://aegis.lan:8200/ui/vault/auth/oidc/oidc/callback",
    "https://aegis.lan:8200/oidc/callback",
    "http://localhost:8250/oidc/callback"
  ]
}

resource "vault_jwt_auth_backend" "auth_oidc_authentik" {
  description        = "Authentik OIDC Auth backend"
  path               = "oidc"
  type               = "oidc"
  oidc_discovery_url = local.oidc_discovery_url
  oidc_client_id     = local.oidc_client_id
  oidc_client_secret = local.oidc_client_secret
  bound_issuer       = local.oidc_discovery_url
  jwt_supported_algs = ["RS256", "ES256"]
  default_role       = "login_mapper"
}

# Role which sole purpose is to map groups coming from OIDC claim `groups` to external group aliases in vault
resource "vault_jwt_auth_backend_role" "auth_oidc_authentik_role_login_mapper" {
  backend                = vault_jwt_auth_backend.auth_oidc_authentik.path
  role_name              = vault_jwt_auth_backend.auth_oidc_authentik.default_role
  role_type              = "oidc"
  bound_audiences        = [vault_jwt_auth_backend.auth_oidc_authentik.oidc_client_id]
  user_claim             = "email"
  oidc_scopes            = ["email", "profile"]
  groups_claim           = "groups"
  allowed_redirect_uris  = local.allowed_redirect_uris
  token_ttl              = 28800 # 8h
  token_explicit_max_ttl = 28800 # 8h
}

