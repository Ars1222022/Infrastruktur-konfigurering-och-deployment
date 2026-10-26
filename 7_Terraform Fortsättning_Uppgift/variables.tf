# ============================================
# variables.tf – Input variables for flexibility
# ============================================

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "myproject"
}

variable "environment" {
  description = "Environment (dev, test, prod)"
  type        = string
  default     = "development"
  
  validation {
    condition     = contains(["development", "test", "staging", "production"], var.environment)
    error_message = "Environment must be development, test, staging, or production."
  }
}

variable "folders" {
  description = "List of folders to create"
  type        = list(string)
  default     = ["Config", "Logs", "Backup", "Data"]
}
