# ============================================
# outputs.tf – Show what was created
# ============================================

output "project_path" {
  description = "Full path to the project folder"
  value       = "${path.module}/${var.project_name}"
}

output "created_folders" {
  description = "List of created folders"
  value       = [for folder in var.folders : "${path.module}/${var.project_name}/${folder}"]
}

output "config_file_path" {
  description = "Path to the config file"
  value       = local_file.config.filename
}

output "config_content" {
  description = "Content of the config file"
  value       = jsondecode(local_file.config.content)
}
