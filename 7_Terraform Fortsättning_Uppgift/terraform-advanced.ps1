# ============================================
# terraform-advanced.ps1 – Terraform Fortsättning
# ============================================
#
# WHAT THIS SCRIPT DOES:
# 1. Checks if Terraform is installed (installs if missing)
# 2. Creates all Terraform files with variables, outputs, data sources
# 3. Runs Terraform init, plan, apply for BOTH dev and prod
# 4. Creates folder structures for both environments
# 5. Shows you how to test your work
# 6. Explains everything step by step
# 7. Shows real-world examples from Swedish companies
#
# ALL FILES ARE CREATED IN THE SAME FOLDER AS THIS SCRIPT
# ============================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  TERRAFORM ADVANCED - AUTOMATIC SETUP" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "THIS SCRIPT WILL:" -ForegroundColor Yellow
Write-Host "  - Check if Terraform is installed" -ForegroundColor Gray
Write-Host "  - Install Terraform automatically if missing" -ForegroundColor Gray
Write-Host "  - Create Terraform files (variables, main, outputs)" -ForegroundColor Gray
Write-Host "  - Create folder structures for dev AND prod" -ForegroundColor Gray
Write-Host "  - Show you how to test your work" -ForegroundColor Gray
Write-Host "  - Explain real-world usage in Swedish companies" -ForegroundColor Gray
Write-Host ""

# -----------------------------------------------------------------------------
# STEP 1: Get script directory
# -----------------------------------------------------------------------------

$ScriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
Set-Location $ScriptDir
Write-Host "Working directory: $ScriptDir" -ForegroundColor Gray
Write-Host ""

# -----------------------------------------------------------------------------
# STEP 2: Check and install Terraform
# -----------------------------------------------------------------------------

Write-Host "STEP 1: Checking if Terraform is installed..." -ForegroundColor Yellow

$terraform = Get-Command terraform -ErrorAction SilentlyContinue

if ($terraform) {
    $version = terraform --version | Select-Object -First 1
    Write-Host "  [OK] Terraform is installed: $version" -ForegroundColor Green
} else {
    Write-Host "  [WARNING] Terraform is NOT installed!" -ForegroundColor Yellow
    Write-Host "  Attempting to install Terraform automatically..." -ForegroundColor Yellow
    
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if ($winget) {
        Write-Host "  Installing Terraform via winget..." -ForegroundColor Gray
        try {
            winget install --id HashiCorp.Terraform --silent --accept-package-agreements
            Write-Host "  [OK] Terraform installed successfully!" -ForegroundColor Green
            Write-Host "  NOTE: You may need to restart PowerShell for PATH changes to take effect." -ForegroundColor Yellow
            
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            
            $terraform = Get-Command terraform -ErrorAction SilentlyContinue
            if (-not $terraform) {
                Write-Host "  [ERROR] Terraform installed but not found in PATH." -ForegroundColor Red
                Write-Host "  Please restart PowerShell and run this script again." -ForegroundColor Yellow
                Read-Host "Press Enter to exit"
                exit
            }
        } catch {
            Write-Host "  [ERROR] Could not install Terraform automatically." -ForegroundColor Red
            Write-Host "  Please install manually:" -ForegroundColor Yellow
            Write-Host "  1. Open PowerShell as Administrator" -ForegroundColor Gray
            Write-Host "  2. Run: winget install --id HashiCorp.Terraform" -ForegroundColor Gray
            Write-Host "  3. Close and reopen PowerShell" -ForegroundColor Gray
            Write-Host "  4. Run this script again" -ForegroundColor Gray
            Read-Host "Press Enter to exit"
            exit
        }
    } else {
        Write-Host "  [ERROR] Winget not available." -ForegroundColor Red
        Write-Host "  Please install Terraform manually:" -ForegroundColor Yellow
        Write-Host "  1. Go to: https://developer.hashicorp.com/terraform/downloads" -ForegroundColor Gray
        Write-Host "  2. Download Terraform for Windows" -ForegroundColor Gray
        Write-Host "  3. Extract and add to PATH" -ForegroundColor Gray
        Read-Host "Press Enter to exit"
        exit
    }
}

try {
    $version = terraform --version | Select-Object -First 1
    Write-Host "  [OK] Terraform is ready: $version" -ForegroundColor Green
} catch {
    Write-Host "  [ERROR] Terraform is not working." -ForegroundColor Red
    Write-Host "  Please restart PowerShell and run this script again." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit
}

Write-Host ""
Read-Host "Press Enter to continue..."
Write-Host ""

# -----------------------------------------------------------------------------
# STEP 3: Create variables.tf
# -----------------------------------------------------------------------------

Write-Host "STEP 2: Creating Terraform files..." -ForegroundColor Yellow
Write-Host ""
Write-Host "  WHY DIFFERENT FILES?" -ForegroundColor Cyan
Write-Host "  - variables.tf = defines what values you can change" -ForegroundColor Gray
Write-Host "  - main.tf = describes what to create" -ForegroundColor Gray
Write-Host "  - outputs.tf = shows what was created" -ForegroundColor Gray
Write-Host "  - dev.tfvars = values for development environment" -ForegroundColor Gray
Write-Host "  - prod.tfvars = values for production environment" -ForegroundColor Gray
Write-Host ""

$variablesContent = @'
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
'@

$variablesPath = Join-Path $ScriptDir "variables.tf"
$variablesContent | Out-File -FilePath $variablesPath -Encoding utf8
Write-Host "  [OK] Created: variables.tf" -ForegroundColor Green

# -----------------------------------------------------------------------------
# STEP 4: Create main.tf
# -----------------------------------------------------------------------------

$mainContent = @'
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
'@

$mainPath = Join-Path $ScriptDir "main.tf"
$mainContent | Out-File -FilePath $mainPath -Encoding utf8
Write-Host "  [OK] Created: main.tf" -ForegroundColor Green

# -----------------------------------------------------------------------------
# STEP 5: Create outputs.tf
# -----------------------------------------------------------------------------

$outputsContent = @'
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
'@

$outputsPath = Join-Path $ScriptDir "outputs.tf"
$outputsContent | Out-File -FilePath $outputsPath -Encoding utf8
Write-Host "  [OK] Created: outputs.tf" -ForegroundColor Green

# -----------------------------------------------------------------------------
# STEP 6: Create dev.tfvars
# -----------------------------------------------------------------------------

$devContent = @'
# ============================================
# dev.tfvars – Development environment values
# ============================================

project_name = "devproject"
environment  = "development"
folders      = ["Config", "Logs", "Backup", "Data", "DevTools"]
'@

$devPath = Join-Path $ScriptDir "dev.tfvars"
$devContent | Out-File -FilePath $devPath -Encoding utf8
Write-Host "  [OK] Created: dev.tfvars" -ForegroundColor Green

# -----------------------------------------------------------------------------
# STEP 7: Create prod.tfvars
# -----------------------------------------------------------------------------

$prodContent = @'
# ============================================
# prod.tfvars – Production environment values
# ============================================

project_name = "prodproject"
environment  = "production"
folders      = ["Config", "Logs", "Backup", "Data", "Monitoring", "Security"]
'@

$prodPath = Join-Path $ScriptDir "prod.tfvars"
$prodContent | Out-File -FilePath $prodPath -Encoding utf8
Write-Host "  [OK] Created: prod.tfvars" -ForegroundColor Green

Write-Host ""
Read-Host "Press Enter to continue..."
Write-Host ""

# -----------------------------------------------------------------------------
# STEP 8: Clean up old state files
# -----------------------------------------------------------------------------

Write-Host "STEP 3: Cleaning up old state files..." -ForegroundColor Yellow

$oldFiles = @("terraform.tfstate", "terraform.tfstate.backup", ".terraform")
foreach ($file in $oldFiles) {
    $path = Join-Path $ScriptDir $file
    if (Test-Path $path) {
        if ($file -eq ".terraform") {
            Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  Removed: $file" -ForegroundColor Gray
        } else {
            Remove-Item -Path $path -Force -ErrorAction SilentlyContinue
            Write-Host "  Removed: $file" -ForegroundColor Gray
        }
    }
}

Write-Host "  [OK] Cleanup complete" -ForegroundColor Green
Write-Host ""

# -----------------------------------------------------------------------------
# STEP 9: Run Terraform init
# -----------------------------------------------------------------------------

Write-Host "STEP 4: Running terraform init..." -ForegroundColor Yellow
Write-Host "  (Downloads the provider plugins)" -ForegroundColor Gray

$initResult = terraform init 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "  [OK] terraform init completed successfully" -ForegroundColor Green
} else {
    Write-Host "  [ERROR] terraform init failed!" -ForegroundColor Red
    Write-Host $initResult -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

Write-Host ""

# -----------------------------------------------------------------------------
# STEP 10: Run Terraform apply for DEVELOPMENT
# -----------------------------------------------------------------------------

Write-Host "STEP 5: Creating DEVELOPMENT environment..." -ForegroundColor Yellow
Write-Host "  (Using dev.tfvars)" -ForegroundColor Gray
Write-Host "  WHY: Development is where you test changes before production" -ForegroundColor Gray
Write-Host ""

$applyDev = terraform apply -var-file="dev.tfvars" -auto-approve 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "  [OK] Development environment created!" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Folders created for dev:" -ForegroundColor Cyan
    $devFolders = Get-ChildItem -Path "$ScriptDir\devproject" -Directory
    foreach ($folder in $devFolders) {
        Write-Host "    - $($folder.Name)" -ForegroundColor Gray
    }
} else {
    Write-Host "  [ERROR] terraform apply for dev failed!" -ForegroundColor Red
    Write-Host $applyDev -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

Write-Host ""

# -----------------------------------------------------------------------------
# STEP 11: Run Terraform apply for PRODUCTION
# -----------------------------------------------------------------------------

Write-Host "STEP 6: Creating PRODUCTION environment..." -ForegroundColor Yellow
Write-Host "  (Using prod.tfvars)" -ForegroundColor Gray
Write-Host "  WHY: Production is the live environment used by real users" -ForegroundColor Gray
Write-Host "  NOTE: Same code, different values!" -ForegroundColor Green
Write-Host ""

$applyProd = terraform apply -var-file="prod.tfvars" -auto-approve 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "  [OK] Production environment created!" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Folders created for prod:" -ForegroundColor Cyan
    $prodFolders = Get-ChildItem -Path "$ScriptDir\prodproject" -Directory
    foreach ($folder in $prodFolders) {
        Write-Host "    - $($folder.Name)" -ForegroundColor Gray
    }
} else {
    Write-Host "  [ERROR] terraform apply for prod failed!" -ForegroundColor Red
    Write-Host $applyProd -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

Write-Host ""

# -----------------------------------------------------------------------------
# STEP 12: Show outputs (development)
# -----------------------------------------------------------------------------

Write-Host "STEP 7: Showing outputs for DEVELOPMENT..." -ForegroundColor Yellow

$outputDev = terraform output 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "  OUTPUTS (Development):" -ForegroundColor Cyan
    Write-Host "  " + "-" * 40 -ForegroundColor Gray
    Write-Host $outputDev -ForegroundColor Gray
    Write-Host "  " + "-" * 40 -ForegroundColor Gray
} else {
    Write-Host "  [WARNING] No outputs available for dev." -ForegroundColor Yellow
}

Write-Host ""

# -----------------------------------------------------------------------------
# STEP 13: Show real-world examples
# -----------------------------------------------------------------------------

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  REAL-WORLD EXAMPLES" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "  HOW SWEDISH COMPANIES USE TERRAFORM:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  SPOTIFY:" -ForegroundColor Green
Write-Host "    - Uses Terraform to manage cloud infrastructure" -ForegroundColor Gray
Write-Host "    - Same code for dev, test, and production" -ForegroundColor Gray
Write-Host "    - Different values for each environment" -ForegroundColor Gray
Write-Host ""
Write-Host "  KLARNA:" -ForegroundColor Green
Write-Host "    - Uses Terraform to provision servers" -ForegroundColor Gray
Write-Host "    - Variables control which environment" -ForegroundColor Gray
Write-Host "    - Can roll back to previous versions" -ForegroundColor Gray
Write-Host ""
Write-Host "  VOLVO:" -ForegroundColor Green
Write-Host "    - Uses Terraform to manage infrastructure" -ForegroundColor Gray
Write-Host "    - State file shared with team" -ForegroundColor Gray
Write-Host "    - Changes reviewed before apply" -ForegroundColor Gray
Write-Host ""

Write-Host "  WHY SEPARATE ENVIRONMENTS?" -ForegroundColor Yellow
Write-Host "  - Dev: Test new features safely" -ForegroundColor Gray
Write-Host "  - Test: Verify everything works" -ForegroundColor Gray
Write-Host "  - Staging: Test before production" -ForegroundColor Gray
Write-Host "  - Production: Live environment" -ForegroundColor Gray
Write-Host ""

# -----------------------------------------------------------------------------
# STEP 14: Show how to test
# -----------------------------------------------------------------------------

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  HOW TO TEST YOUR TERRAFORM WORK" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "  TEST 1: CHANGE FOLDER LIST (Development)" -ForegroundColor Yellow
Write-Host "  1. Open dev.tfvars" -ForegroundColor Gray
Write-Host "  2. Add a new folder: 'NewFolder'" -ForegroundColor Gray
Write-Host "  3. Run: terraform plan -var-file='dev.tfvars'" -ForegroundColor Gray
Write-Host "  4. Run: terraform apply -var-file='dev.tfvars' -auto-approve" -ForegroundColor Gray
Write-Host "  5. Check that the new folder was created" -ForegroundColor Gray
Write-Host ""

Write-Host "  TEST 2: COMPARE ENVIRONMENTS" -ForegroundColor Yellow
Write-Host "  1. Compare devproject/ and prodproject/ folders" -ForegroundColor Gray
Write-Host "  2. Dev has 5 folders, Prod has 6 folders" -ForegroundColor Gray
Write-Host "  3. Same code – different values!" -ForegroundColor Gray
Write-Host ""

Write-Host "  TEST 3: CHANGE PROJECT NAME" -ForegroundColor Yellow
Write-Host "  1. Open dev.tfvars" -ForegroundColor Gray
Write-Host "  2. Change project_name to 'testproject'" -ForegroundColor Gray
Write-Host "  3. Run: terraform plan -var-file='dev.tfvars'" -ForegroundColor Gray
Write-Host "  4. Run: terraform apply -var-file='dev.tfvars' -auto-approve" -ForegroundColor Gray
Write-Host "  5. Check that 'testproject' folder was created" -ForegroundColor Gray
Write-Host ""

Write-Host "  TEST 4: DESTROY EVERYTHING" -ForegroundColor Yellow
Write-Host "  1. Run: terraform destroy -auto-approve" -ForegroundColor Gray
Write-Host "  2. All folders and files will be removed" -ForegroundColor Gray
Write-Host "  3. Run: terraform apply -var-file='dev.tfvars' -auto-approve" -ForegroundColor Gray
Write-Host "  4. Everything is recreated from code!" -ForegroundColor Gray
Write-Host ""

# -----------------------------------------------------------------------------
# STEP 15: Summary
# -----------------------------------------------------------------------------

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SUMMARY - WHAT YOU LEARNED" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "  Files created in this folder:" -ForegroundColor Yellow
Write-Host "    - variables.tf (input variables)" -ForegroundColor Gray
Write-Host "    - main.tf (resources)" -ForegroundColor Gray
Write-Host "    - outputs.tf (outputs)" -ForegroundColor Gray
Write-Host "    - dev.tfvars (development values)" -ForegroundColor Gray
Write-Host "    - prod.tfvars (production values)" -ForegroundColor Gray
Write-Host "    - devproject/ (development environment) - 5 folders" -ForegroundColor Gray
Write-Host "    - prodproject/ (production environment) - 6 folders" -ForegroundColor Gray
Write-Host ""

Write-Host "  Concepts you learned:" -ForegroundColor Yellow
Write-Host "    1. Variables = make your code flexible" -ForegroundColor Gray
Write-Host "    2. Outputs = show what was created" -ForegroundColor Gray
Write-Host "    3. tfvars files = different values for different environments" -ForegroundColor Gray
Write-Host "    4. for_each = create multiple resources from a list" -ForegroundColor Gray
Write-Host "    5. Same code, different environments = professional IaC" -ForegroundColor Gray
Write-Host ""

Write-Host "  WHY THIS IS IMPORTANT IN SWEDISH IT:" -ForegroundColor Yellow
Write-Host "  - Companies like Spotify, Klarna, Volvo use this" -ForegroundColor Gray
Write-Host "  - You can test changes safely in dev first" -ForegroundColor Gray
Write-Host "  - Production stays stable" -ForegroundColor Gray
Write-Host "  - Your infrastructure is documented as code" -ForegroundColor Gray
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SETUP COMPLETED!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Read-Host "Press Enter to exit"