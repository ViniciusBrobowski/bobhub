resource "proxmox_virtual_environment" "ubuntu_vm" {
    name        = var.vm_name
    description = "ubuntu Server VM managed by Terraform"
    tags        = ["terraform", "ubuntu"]

    node_name = var.proxmox_node

# Keep the VM stopped until the Ubuntu installation media
# Or cloud image workflow is configured.
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

    network {
    bridge = var.proxmox_network_bridge
    }

    agent {
    enabled = false
    }

stop_on_destroy = true
}