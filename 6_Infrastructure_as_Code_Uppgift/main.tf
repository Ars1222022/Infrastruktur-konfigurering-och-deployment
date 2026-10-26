provider "local" {}

resource "local_file" "hello" {
  filename = "${path.module}/hello.txt"
  content  = "Hello"
}

resource "local_file" "config" {
  filename = "${path.module}/config.json"
  content  = jsonencode({
    project     = "IaC Intro"
    environment = "development"
    created_by  = "Terraform"
    version     = "1.0"
  })
}

resource "local_file" "folder_keep" {
  filename = "${path.module}/ProjectFiles/.keep"
  content  = "# This folder was created by Terraform"
}

output "hello_file_path" {
  value = local_file.hello.filename
}

output "config_file_path" {
  value = local_file.config.filename
}

output "project_folder" {
  value = "${path.module}/ProjectFiles"
}
