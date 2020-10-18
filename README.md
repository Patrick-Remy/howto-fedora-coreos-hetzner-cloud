# Fedora CoreOS at Hetzner Cloud

Install [Fedora CoreOS](https://docs.fedoraproject.org/en-US/fedora-coreos/) via [terraform](https://www.terraform.io)
on a vServer at Hetzner Cloud.


## Prerequisites 🤓

### Clone repository
Clone this repository into any folder on your host machine and follow the instructions.

### Setup terraform
If not done already [install terraform](https://www.terraform.io/downloads.html) as instructed. E.g. via
`brew install terraform` or download the apropriate binary for your operating system.

Now, change into the cloned repo dir, and exec `terraform init` to install the
[terraform Hetzner Cloud Provider](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs).

### Build coreos-installer
Currently the [`coreos-installer`](https://github.com/coreos/coreos-installer) is not available as a binary. Therefore,
you need to install rust's package manager [`cargo`](https://doc.rust-lang.org/cargo/getting-started/installation.html)
and build the binary on a linux-machine with `cargo install --target-dir . coreos-installer`.

The resulting binary will be copied by terraform to the vServer in rescue mode, so you have to move it as
`coreos-installer` into your working directory. Building the binary in rescue mode on the vServer will fail, if there is
not enough RAM.


## Get it up and running! 🚀

### Last configurations
In the section `Variables` of the `main.tf`, adjust the default values for `ssh_public_key`, `ssh_public_key_name`,
`hcloud_server_type`, `hcloud_server_datacenter` and `hcloud_server_name` to your needs. Optionally, have a look at the
`config.yaml`.

### Provision it!
Run `terraform apply`, enter your Hetzner Cloud API Token when prompted, and let the magic be done!

After a successful installation, you will see the message `Apply complete! Resources: 2 added, 0 changed, 0 destroyed.`.

### SSH into it
`terraform show` outputs you all information about your new machine:

```
# hcloud_server.master:
resource "hcloud_server" "master" {
    backups      = false
    datacenter   = "fsn1-dc14"
    id           = "1234567"
    image        = "fedora-32"
    ipv4_address = "88.xxx.xxx.xxx"
    ipv6_address = "2a01:xxxx:xxxx:xxxx::1"
    ipv6_network = "2a01:xxxx:xxxx:xxxx::/64"
    keep_disk    = false
    labels       = {
        "os" = "coreos"
    }
    location     = "fsn1"
    name         = "www1"
    rescue       = "linux64"
    server_type  = "cx11"
    ssh_keys     = [
        "1234567",
    ]
    status       = "running"
}
```

As defined in the `config.yaml`, a new user `core` has been added, so you can ssh via `ssh core@88.xxx.xxx.xxx` to your
fresh Fedora CoreOS machine!


## Do it again ➰

If you need other configurations, want to add more servers: run `terraform destroy`, confirm with `yes` and now adjust
the files to your needs and recreate the infrastructure via `terraform apply`. But keep a look at the Hetzner Cloud
Portal to ensure that there haven't been spawned any "ghost machines" 👻
