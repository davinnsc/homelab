resource "proxmox_virtual_environment_vm" "k3s_agent" {
  count     = var.agent_count
  name      = var.agent_names[count.index]
  vm_id     = var.agent_vmids[count.index]
  node_name = var.proxmox_node

  clone {
    vm_id = var.template_vmid
    full  = true
  }

  agent {
    enabled = true
    type    = "virtio"
  }

  on_boot = true
  machine = "q35"

  startup {
    order      = "2"
    up_delay   = "60"
    down_delay = "30"
  }

  cpu {
    type    = "host"
    cores   = var.agent_cores
    sockets = 1
  }

  memory {
    dedicated = var.agent_memory
    floating  = 0
  }

  scsi_hardware = "virtio-scsi-pci"

  disk {
    interface    = "scsi0"
    size         = var.agent_disk_size
    datastore_id = var.agent_storage
    file_format  = "raw"
  }

  network_device {
    model  = "virtio"
    bridge = var.bridge
  }

  serial_device {}

  vga {
    type = "serial0"
  }

  initialization {
    user_account {
      username = var.ssh_user
      keys     = [trimspace(file(pathexpand(var.ssh_public_key_path)))]
    }
    ip_config {
      ipv4 {
        address = var.agent_ips[count.index]
        gateway = var.gateway
      }
    }
    dns {
      servers = var.nameservers
      domain  = var.search_domain
    }
  }

  lifecycle {
    ignore_changes = [
      network_device,
    ]
  }
}
