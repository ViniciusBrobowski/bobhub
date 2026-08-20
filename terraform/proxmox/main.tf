resource "proxmox_virtual_environment_vm" "ubuntu_vm" {
  name        = var.vm_name
  description = "ubuntu Server VM managed by Terraform"
  tags        = ["terraform", "ubuntu"]

  node_name = var.proxmox_node

  boot_order = ["scsi0", "ide2"]

  cdrom {
    file_id   = "local:iso/ubuntu-24.04.4-live-server-amd64.iso"
    interface = "ide2"
  }

  # Keep the VM stopped until the Ubuntu installation media
  started = false

  cpu {
    cores = var.vm_cpu_cores
  }

  memory {
    dedicated = var.vm_memory_mb
  }

  disk {
    datastore_id = var.proxmox_storage
    interface    = "scsi0"
    size         = var.vm_disk_size_gb
  }

  network_device {
    bridge = var.proxmox_network_bridge
  }

  agent {
    enabled = false
  }

  stop_on_destroy = true
}