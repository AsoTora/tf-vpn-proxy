output "droplet_ip" {
  value = digitalocean_droplet.vpn_proxy.ipv4_address
}
