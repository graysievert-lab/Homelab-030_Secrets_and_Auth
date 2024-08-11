
locals {
  node_name   = "pve" #name of proxmox node"
  hostname    = "aegis"
  vm_id       = 1001
  description = "Aegis VM (Vault and Authentik)"
  tags        = ["test", "linux", "cloudinit"]
  ssh_key      = var.public_ssh_key_for_VM

  address      = "10.1.2.1"
  netmask      = "/24"
  gateway      = "10.1.2.100"

  zone_forward = "lan."
  zone_reverse = "2.1.10.in-addr.arpa."
}



########################################
## pool
########################################
resource "proxmox_virtual_environment_pool" "main" {
  comment = "Pool for aegis services"
  pool_id = "aegis"
}

########################################
## Virtual Machine
########################################


module "proxmox_vm_main" {
  source = "git::https://github.com/graysievert/terraform-modules-proxmox_vm?ref=v1.0.0"

  metadata = {
    node_name    = local.node_name
    datastore_id = "local-zfs"
    image        = "local:iso/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2.img"
    agent        = true
    description  = local.description
    name         = "${local.hostname}"
    pool_id      = proxmox_virtual_environment_pool.main.id
    tags         = local.tags
    vm_id        = local.vm_id
  }

  hardware = {
    mem_dedicated_mb = 2048
    mem_floating_mb  = 1024
    cpu_sockets      = 1
    cpu_cores        = 2
    disk_size_gb     = 15
  }

  cloudinit = {
    meta_config_file   = proxmox_virtual_environment_file.cloudinit_meta_config.id
    user_config_file   = proxmox_virtual_environment_file.cloudinit_user_config.id
    vendor_config_file = proxmox_virtual_environment_file.cloudinit_vendor_config.id
    ipv4 = {
      address = "${local.address}${local.netmask}"
      gateway = local.gateway
    }
  }
}



