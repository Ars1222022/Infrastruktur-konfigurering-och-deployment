# ============================================
# main.tf – Resources using variables
# ============================================

provider "local" {}

# Create timestamp file
resource "local_file" "timestamp_file" {
  filename = "${path.module}/.timestamp"
  content  = timestamp()
}

# Create folders using for_each
resource "local_file" "folder_markers" {
  for_each = toset(var.folders)
  
  filename = "${path.module}/${var.project_name}/${each.key}/.keep"
  content  = <<-EOT
    # Folder: ${each.key}
    # Project: ${var.project_name}
    # Environment: ${var.environment}
    # Created: ${timestamp()}
  EOT
}

# Create a config file with all settings
resource "local_file" "config" {
  filename = "${path.module}/${var.project_name}/Config/settings.json"
  content  = jsonencode({
    project     = var.project_name
    environment = var.environment
    folders     = var.folders
    created_at  = timestamp()
  })
}
