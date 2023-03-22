#!/bin/bash

sudo apt-get update && sudo apt-get dist-upgrade

# install docker
sudo apt install apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
apt-cache policy docker-ce
sudo apt -y update
sudo apt install docker-ce -y
sudo usermod -aG docker root
sudo systemctl status docker

# Digiatal ocean monitoring tools
curl -sSL https://repos.insights.digitalocean.com/install.sh | sudo bash

# Enable ports in firewall for proxy and VPN
ufw allow 500/udp
ufw allow 4500/udp
ufw allow ${proxy_port}/tcp

# SOCKS5 proxy https://github.com/serjs/socks5-server
docker run -d --name socks5-proxy -p ${proxy_port}:1080 -e PROXY_USER=${proxy_user} -e PROXY_PASSWORD=${proxy_password} serjs/go-socks5-proxy

# IpSec VPN https://github.com/hwdsl2/docker-ipsec-vpn-server
sudo modprobe af_key
sudo echo "VPN_IPSEC_PSK=${vpn_ipsec_psk}
VPN_USER=${vpn_user}
VPN_PASSWORD=${vpn_password}" > /vpn.env

docker run \
    --name ipsec-vpn-server \
    --env-file /vpn.env \
    --restart=always \
    -p 500:500/udp \
    -p 4500:4500/udp \
    -v /lib/modules:/lib/modules:ro \
    -d --privileged \
    hwdsl2/ipsec-vpn-server

# store VPN credentials
docker cp ipsec-vpn-server:/opt/src/vpn-gen.env ./