####
# Variables
##

variable "hcloud_token" {
  description = "Hetzner Cloud API Token"
  type = string
}

variable "ssh_public_key_file" {
  description = "Local path to your public key"
  type = string
  default = "~/.ssh/id_rsa.pub"
}

variable "ssh_public_key_name" {
  description = "Name of your public key to identify at Hetzner Cloud portal"
  type = string
  default = "My-SSH-Key"
}

variable "hcloud_server_type" {
  description = "vServer type name, lookup via `hcloud server-type list`"
  type = string
  default = "cx11"
}

variable "hcloud_server_datacenter" {
  description = "Desired datacenter location name, lookup via `hcloud datacenter list`"
  type = string
  default = "fsn1-dc14"
}

variable "hcloud_server_name" {
  description = "Name of the server"
  type = string
  default = "www1"
}

# Update version to the latest release of fcct
variable "tools_fcct_version" {
  description = "See https://github.com/coreos/fcct/releases for available versions"
  type = string
  default = "0.6.0"
}



####
# Infrastructure config
##

provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_ssh_key" "key" {
  name = var.ssh_public_key_name
  public_key = file(var.ssh_public_key_file)
}

resource "hcloud_server" "master" {
  name = var.hcloud_server_name
  labels = { "os" = "coreos" }

  server_type = var.hcloud_server_type
  datacenter = var.hcloud_server_datacenter

  # Image is ignored, as we boot into rescue mode, but is a required field
  image = "fedora-32"
  rescue = "linux64"
  ssh_keys = [hcloud_ssh_key.key.id]

  connection {
    host = hcloud_server.master.ipv4_address
    timeout = "5m"
    agent = true
    # Root is the available user in rescue mode
    user = "root"
  }

  # Copy config.yaml and replace $ssh_public_key variable
  provisioner "file" {
    content = replace(file("config.yaml"), "$ssh_public_key", trimspace(file(var.ssh_public_key_file)))
    destination = "/root/config.yaml"
  }

  # Copy coreos-installer binary, as initramfs has not sufficient space to compile it in rescue mode
  provisioner "file" {
    source = "coreos-installer"
    destination = "/usr/local/bin/coreos-installer"
  }

  # Install Fedora CoreOS in rescue mode
  provisioner "remote-exec" {
    inline = [
      "set -x",
      # Convert ignition yaml into json using fcct
      "wget -O /usr/local/bin/fcct 'https://github.com/coreos/fcct/releases/download/v${var.tools_fcct_version}/fcct-x86_64-unknown-linux-gnu'",
      "chmod +x /usr/local/bin/fcct",
      "fcct --strict < config.yaml > config.ign",
      # Download and install coreos to /dev/sda
      "chmod +x /usr/local/bin/coreos-installer",
      "coreos-installer install /dev/sda -i /root/config.ign",
      # Exit rescue mode and boot into coreos
      "reboot"
    ]
  }

  # Configure CoreOS after installation
  provisioner "remote-exec" {
    connection {
      host = hcloud_server.master.ipv4_address
      timeout = "1m"
      agent = true
      # This user is configured in config.yaml
      user = "core"
    }

    inline = [
      "sudo hostnamectl set-hostname ${hcloud_server.master.name}"
      # Add additional commands if needed
    ]
  }
}
