terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    template = {
      source = "hashicorp/template"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}
