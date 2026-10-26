# main.tf – SLUTPROJEKTET
terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

variable "server_name" {
  description = "Namn på servern"
  type        = string
  default     = "projekt-server"
}

variable "server_ip" {
  description = "IP-adress"
  type        = string
  default     = "192.168.1.100"
}

resource "local_file" "server_info" {
  content  = "Server: ${var.server_name}\nIP: ${var.server_ip}\nStatus: provisioned"
  filename = "${path.module}/server.txt"
}

resource "local_file" "website" {
  content  = "<html><body><h1>Slutprojektet</h1><p>Skapad av Terraform!</p></body></html>"
  filename = "${path.module}/website.html"
}

output "server_info" {
  value = "Server ${var.server_name} skapad med IP ${var.server_ip}"
}
