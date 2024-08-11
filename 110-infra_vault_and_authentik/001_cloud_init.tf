########################################
## Cloud-init custom configs
########################################


resource "proxmox_virtual_environment_file" "cloudinit_meta_config" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = local.node_name
  source_raw {
    file_name = "${local.hostname}-meta-config.yaml"
    data      = <<EOF
#cloud-config
local-hostname: ${local.hostname}.${local.zone_forward}
instance-id: ${md5(local.hostname)}
EOF
  }
}

resource "proxmox_virtual_environment_file" "cloudinit_user_config" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = local.node_name
  source_raw {
    file_name = "${local.hostname}-user-config.yaml"
    data      = <<EOF
#cloud-config
ssh_authorized_keys:
  - "${local.ssh_key}"
user:
  name: rocky
users:
  - default
EOF
  }
}

resource "proxmox_virtual_environment_file" "cloudinit_vendor_config" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = local.node_name
  source_raw {
    file_name = "${local.hostname}-vendor-config.yaml"
    data      = <<EOF
#cloud-config
packages:
    - wget
    - qemu-guest-agent
    - ansible-core

write_files:
- path: /opt/init/ansible.cfg
  encoding: b64
  content: ${filebase64("files/ansible.cfg")}
  owner: 'root:root'
  permissions: '0640'
  defer: true
- path: /opt/init/ansible-requirements.yaml
  encoding: b64
  content: ${filebase64("files/ansible-requirements.yaml")}
  owner: 'root:root'
  permissions: '0640'
  defer: true
- path: /opt/init/ansible-install-acme_sh.yaml
  encoding: b64
  content: ${filebase64("files/ansible-install-acme_sh.yaml")}
  owner: 'root:root'
  permissions: '0640'
  defer: true
- path: /opt/init/ansible-install-vault.yaml
  encoding: b64
  content: ${filebase64("files/ansible-install-vault.yaml")}
  owner: 'root:root'
  permissions: '0640'
  defer: true
- path: /opt/init/ansible-install-authentik.yaml
  encoding: b64
  content: ${filebase64("files/ansible-install-authentik.yaml")}
  owner: 'root:root'
  permissions: '0640'
  defer: true
- path: /opt/init/authentik/compose-authentik.yaml
  encoding: b64
  content: ${filebase64("files/compose-authentik.yaml")}
  owner: 'root:root'
  permissions: '0640'
  defer: true

runcmd:
  - echo -e "I am $(whoami) at $(hostname -f), myenv is\n$(declare -p)"
  - curl -k -o /etc/pki/ca-trust/source/anchors/localCA.crt https://acme.lan:8443/roots.pem && update-ca-trust extract
  - cd /opt/init && ansible-galaxy install -r ansible-requirements.yaml
  - cd /opt/init && ansible-playbook -v ansible-install-acme_sh.yaml
  - cd /opt/init && ansible-playbook -v ansible-install-vault.yaml
  - cd /opt/init && ansible-playbook -v ansible-install-authentik.yaml
EOF
  }
}


