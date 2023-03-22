locals {
  user_data_vars = {
    proxy_user     = var.proxy_user
    proxy_password = var.proxy_password
    proxy_port     = var.proxy_port
    vpn_user       = var.vpn_user
    vpn_password   = var.vpn_password
    vpn_ipsec_psk  = var.vpn_ipsec_psk
  }
}


resource "digitalocean_ssh_key" "ssh_key" {
  name       = "TF ssh key"
  public_key = file(var.ssh_key_path)
}

resource "digitalocean_droplet" "vpn_proxy" {
  name      = var.droplet_name
  image     = var.image
  region    = var.region
  size      = "s-1vcpu-512mb-10gb"                     # "memory":1024,"vcpus":1,"disk":25,"transfer":1.0,"price_monthly":5.0
  ssh_keys  = [digitalocean_ssh_key.ssh_key.fingerprint] # id of ssh_key in DO, https://developers.digitalocean.com/documentation/v2/#list-all-keys
  # user_data = templatefile("${path.module}/user-data.sh", local.user_data_vars)
  monitoring = true
}


resource "local_file" "script" {
  content = templatefile("${path.module}/user-data.sh", local.user_data_vars)
  filename = "${path.module}/user-data-full.sh"
}

resource "null_resource" "remoteExecProvisionerWFolder" {
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "file" {
    source      = "${path.module}/user-data-full.sh"
    destination = "user-data.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x ~/user-data.sh",
      "bash ~/user-data.sh"
    ]
  }

  connection {
    host     = "${digitalocean_droplet.vpn_proxy.ipv4_address}"
    type     = "ssh"
    user     = "root"
    # private_key = file(var.private_key_path)
    agent    = true # https://stackoverflow.com/questions/66867538/how-to-use-passphrase-protected-private-ssh-key-in-terraform
  }
}