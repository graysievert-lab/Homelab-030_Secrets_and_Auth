# Integration with Secret injection webhook from bank-vaults.dev

[Webhook docs](https://bank-vaults.dev/docs/mutating-webhook/)

## Introduction

The idea is to authenticate each ServiceAccount using its token to the Vault.
Then vault access policy should permit a webhook (which would use the pod's service account) to read secrets from:

- Anything shared for a namespace at `secret/data/cluster.lan/<ServiceAccount's namespace>/`
- Anything (incl. subpaths) at `secret/data/cluster.lan/<ServiceAccount's namespace>/<ServiceAccount's name>/`

When operational webhook would be able to substitute records like below with actual material stored in the vault on pod start

```yaml
...
        env:
        - name: NS_SECRET
          value: vault:secret/data/cluster.lan/default/sharedsecret#SHARED

        - name: SA_SECRET
          value: vault:secret/data/cluster.lan/default/vault/key#SECRET
...
```

Note: Webhook is also able to mutate Kubernetes secrets and configmaps. But this is disabled as that would fail the purpose of using the webhook: avoid secret material landing into the `etcd`. Thus in this configuration records `vault:secret/data/....` that were put into secrets or configmaps would stay there as text without mutation and would be processed only upon connecting them to a pod. For injections of secret material into secrets probably better to use [`ESO`](https://external-secrets.io) as it constantly keeps secrets in sync (in contrast with webhook from bank-vaults).

As for the vault auth method there are 3 options available:

- use `kubernetes` auth and create lasting service account tokens (legacy)
- use `kubernetes` auth and use service account short-lived tokens, though each service account would need a binding to a ClusterRole `system:auth-delegator`
- use `jwt` auth which does not require intervention into service accounts properties.

This integration uses `jwt` auth with the JWT Signing Key used by Kubernetes to sign serviceAccount's tokens. It has its [dark side](https://developer.hashicorp.com/vault/docs/auth/kubernetes#how-to-work-with-short-lived-kubernetes-tokens) though that is acceptable in this case.

## Install Vault JWT authentication Method

``` shell
tofu init
tofu plan
tofu apply
```

NOTE: Use the following command to get public jwt signing key(s), and then convert to PEM [for example here](https://8gwifi.org/jwkconvertfunctions.jsp)

```shell
$ kubectl get --raw "$(kubectl get --raw /.well-known/openid-configuration | jq -r '.jwks_uri' | sed -r 's/.*\.[^/]+(.*)/\1/')" |jq '.keys[]'
```

NOTE: use the following command to verify the jwt audience(s)

```shell
$ kubectl create token default | cut -f2 -d. | base64 --decode | jq '.aud[]'
"https://kubernetes.default.svc.cluster.local"
```

## Webhook installation

First, create the namespace. (Note: It is not fully clear from the docs whether this step is mandatory for modern Kubernetes clusters or namespace could be created by helm)

```shell
$ kubectl create ns vault-infra
```

Create `values.yaml`.

```yaml
# -- Number of replicas
replicaCount: 2

# -- Enable debug logs for webhook
debug: false

# -- Custom environment variables available to webhook
env:
  VAULT_ADDR: "https://aegis.lan:8200"
  VAULT_AUTH_METHOD: jwt
  VAULT_PATH: kube-lab-jwt
## -- Define the webhook's role in Vault used for authentication, if not defined individually in resources by annotations
  VAULT_ROLE: default

# -- Extra volume definitions for webhook deployment
volumes:
  - name: ca-bundle
    hostPath:
      path: /etc/ssl/certs/ca-bundle.crt
      type: File
# -- Extra volume mounts for webhook deployment
volumeMounts:
  - name: ca-bundle
    mountPath: /etc/ssl/certs/ca-bundle.crt

serviceAccount:
  # -- Specifies whether a service account should be created
  create: false # no as we are not going to mutate secrets and configmaps
rbac:
  authDelegatorRole:
    # -- Bind `system:auth-delegator` ClusterRoleBinding to given `serviceAccount`
    enabled: false # not needed for jwt auth method

# -- Enable injecting values from Vault to ConfigMaps.
# This can cause issues when used with Helm, so it is disabled by default.
configMapMutation: false
# -- Enable injecting values from Vault to Secrets.
# Set to `false` in order to prevent secret values from being persisted in Kubernetes.
secretsMutation: false
# -- List of CustomResources to inject values from Vault, for example: ["ingresses", "servicemonitors"]
customResourceMutations: []
```

Install helm chart:

```shell
$ helm upgrade --install --wait vault-secrets-webhook \
oci://ghcr.io/bank-vaults/helm-charts/vault-secrets-webhook \
--version 1.21.4 \
--namespace vault-infra \
--values values.yaml

## helm uninstall vault-secrets-webhook --namespace vault-infra
```

Integration should be operational at this point. If something does not work, then change the number of replicas to 1 and enable debug in `values.yaml`.

To test prepare 3 secrets in the vault:

- `secret/data/cluster.lan/default/sharedsecret` with key `SHARED` and value `secret`
- `secret/data/cluster.lan/default/vault/key` with key `SECRET` and value `secret`
- `secret/data/cluster.lan/default/vault2/key` with key `SECRET` and value `secret`

then apply the following manifest:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: vault
  # namespace: test
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: stest
  # namespace: test
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: vault
  template:
    metadata:
      labels:
        app.kubernetes.io/name: vault
      annotations:
        vault.security.banzaicloud.io/vault-skip-verify: "true" # optional, skip TLS verification of the Vault server certificate
    spec:
      serviceAccountName: vault
      containers:
      - name: vault
        image: hashicorp/vault
        command:
          - "sh"
          - "-c"
          - >-
            vault token lookup &&
            echo "NS_SECRET: $NS_SECRET" &&
            echo "SA_SECRET: $SA_SECRET" &&
            echo "ALIEN_SECRET: $ALIEN_SECRET" &&
            echo going to sleep... &&
            sleep 10000
        env:
        - name: VAULT_TOKEN
          value: vault:login

        - name: NS_SECRET
          value: vault:secret/data/cluster.lan/default/sharedsecret#SHARED

        - name: SA_SECRET
          value: vault:secret/data/cluster.lan/default/vault/key#SECRET

        # - name: ALIEN_SECRET
        #   value: vault:secret/data/cluster.lan/default/vault2/key#SECRET
```

Pod's logs should look similar to this

```text
Defaulted container "vault" out of: vault, copy-vault-env (init)
time=2025-02-02T18:59:55.883Z level=INFO msg="received new Vault token" app=vault-env role=default path=kube-lab-jwt addr=""
time=2025-02-02T18:59:55.883Z level=INFO msg="initial Vault token arrived" app=vault-env
time=2025-02-02T18:59:55.899Z level=INFO msg="spawning process" app=vault-env entrypoint="[sh -c vault token lookup && echo \"NS_SECRET: $NS_SECRET\" && echo \"SA_SECRET: $SA_SECRET\" && echo \"ALIEN_SECRET: $ALIEN_SECRET\" && echo going to sleep... && sleep 10000]"
Key                 Value
---                 -----
accessor            n/a
creation_time       1738522795
creation_ttl        10m
display_name        kube-lab-jwt-system:serviceaccount:default:vault
entity_id           ddb2b564-e756-bce1-793b-dbe0e49b173d
expire_time         2025-02-02T19:09:55Z
explicit_max_ttl    0s
id                  hvb.AAAAAQKqUk4........41ajCD2N3        
issue_time          2025-02-02T18:59:55Z
meta                map[namespace:default role:default serviceaccount:vault uid:c5473ddf-bcd0-4e9f-9e1d-346311113acc]
num_uses            0
orphan              true
path                auth/kube-lab-jwt/login
policies            [default infra-kube_lab_ns_sa_path_read_[read] lookup-self]
renewable           false
ttl                 9m59s
type                batch
NS_SECRET: secret
SA_SECRET: secret
ALIEN_SECRET:
going to sleep...
```

If uncomment `ALIEN_SECRET` env var, the container should err like this

```text
Defaulted container "vault" out of: vault, copy-vault-env (init)
time=2025-02-02T19:02:31.199Z level=INFO msg="received new Vault token" app=vault-env addr="" role=default path=kube-lab-jwt
time=2025-02-02T19:02:31.199Z level=INFO msg="initial Vault token arrived" app=vault-env
time=2025-02-02T19:02:31.205Z level=ERROR msg="failed to inject secrets from vault: failed to read secret from path: secret/data/cluster.lan/default/vault2/key: Error making API request.\n\nURL: GET https://aegis.lan:8200/v1/secret/data/cluster.lan/default/vault2/key?version=-1\nCode: 403. Errors:\n\n* 1 error occurred:\n\t* permission denied\n\n" app=vault-env
```
