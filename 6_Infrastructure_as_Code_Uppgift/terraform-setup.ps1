# ============================================
# terraform-setup.ps1 – Automatisk Terraform Setup
# ============================================
#
# WHAT THIS SCRIPT DOES:
# 1. Checks if Terraform is installed
# 2. INSTALLS Terraform automatically if missing
# 3. Creates a correct main.tf file with resources
# 4. Runs Terraform init, plan, and apply
# 5. Verifies that files were created
# 6. Shows you what was created
#
# ALL FILES ARE CREATED IN THE SAME FOLDER AS THIS SCRIPT
# ============================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  TERRAFORM SETUP - AUTOMATIC" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# -----------------------------------------------------------------------------
# STEP 1: Get script directory
# -----------------------------------------------------------------------------

$ScriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
Set-Location $ScriptDir
Write-Host "Working directory: $ScriptDir" -ForegroundColor Gray
Write-Host ""

# -----------------------------------------------------------------------------
# STEP 2: Check if Terraform is installed – INSTALL IF MISSING!
# -----------------------------------------------------------------------------

Write-Host "STEP 1: Checking if Terraform is installed..." -ForegroundColor Yellow

$terraform = Get-Command terraform -ErrorAction SilentlyContinue

if ($terraform) {
    $version = terraform --version | Select-Object -First 1
    Write-Host "  [OK] Terraform is installed: $version" -ForegroundColor Green
} else {
    Write-Host "  [WARNING] Terraform is NOT installed!" -ForegroundColor Yellow
    Write-Host "  Attempting to install Terraform automatically..." -ForegroundColor Yellow
    Write-Host ""
    
    # Check if winget is available
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if ($winget) {
        Write-Host "  Installing Terraform via winget..." -ForegroundColor Gray
        try {
            winget install --id HashiCorp.Terraform --silent --accept-package-agreements
            Write-Host "  [OK] Terraform installed successfully!" -ForegroundColor Green
            Write-Host "  NOTE: You may need to restart PowerShell for PATH changes to take effect." -ForegroundColor Yellow
            
            # Refresh PATH in current session
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            
            # Verify installation again
            $terraform = Get-Command terraform -ErrorAction SilentlyContinue
            if (-not $terraform) {
                Write-Host "  [ERROR] Terraform was installed but cannot be found in PATH." -ForegroundColor Red
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
        Write-Host "  [ERROR] Winget is not available on this system." -ForegroundColor Red
        Write-Host "  Please install Terraform manually:" -ForegroundColor Yellow
        Write-Host "  1. Go to: https://developer.hashicorp.com/terraform/downloads" -ForegroundColor Gray
        Write-Host "  2. Download Terraform for Windows" -ForegroundColor Gray
        Write-Host "  3. Extract and add to PATH" -ForegroundColor Gray
        Read-Host "Press Enter to exit"
        exit
    }
}

# Verify Terraform works
try {
    $version = terraform --version | Select-Object -First 1
    Write-Host "  [OK] Terraform is ready: $version" -ForegroundColor Green
} catch {
    Write-Host "  [ERROR] Terraform is installed but not working." -ForegroundColor Red
    Write-Host "  Please restart PowerShell and run this script again." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit
}

Write-Host ""

# -----------------------------------------------------------------------------
# STEP 3: Create main.tf file
# -----------------------------------------------------------------------------

Write-Host "STEP 2: Creating main.tf file..." -ForegroundColor Yellow

$mainTfContent = @'
provider "local" {}

resource "local_file" "hello" {
  filename = "${path.module}/hello.txt"
  content  = "Hello from Terraform!"
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
'@

# Save the file
$mainTfPath = Join-Path $ScriptDir "main.tf"
$mainTfContent | Out-File -FilePath $mainTfPath -Encoding utf8

Write-Host "  [OK] Created: $mainTfPath" -ForegroundColor Green

# Check that file was created with content
$fileSize = (Get-Item $mainTfPath).Length
if ($fileSize -gt 0) {
    Write-Host "  [OK] File size: $fileSize bytes" -ForegroundColor Green
} else {
    Write-Host "  [ERROR] File is empty! Please check the file." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

Write-Host ""

# -----------------------------------------------------------------------------
# STEP 4: Remove old state files (clean start)
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
# STEP 5: Run Terraform init
# -----------------------------------------------------------------------------

Write-Host "STEP 4: Running terraform init..." -ForegroundColor Yellow
Write-Host "  (This downloads the provider plugins)" -ForegroundColor Gray

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
# STEP 6: Run Terraform plan
# -----------------------------------------------------------------------------

Write-Host "STEP 5: Running terraform plan..." -ForegroundColor Yellow
Write-Host "  (Shows what will be created)" -ForegroundColor Gray

$planResult = terraform plan 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "  [OK] terraform plan completed successfully" -ForegroundColor Green
    Write-Host "  Files that will be created:" -ForegroundColor Gray
    Write-Host "    - hello.txt" -ForegroundColor Gray
    Write-Host "    - config.json" -ForegroundColor Gray
    Write-Host "    - ProjectFiles/.keep" -ForegroundColor Gray
} else {
    Write-Host "  [ERROR] terraform plan failed!" -ForegroundColor Red
    Write-Host $planResult -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

Write-Host ""

# -----------------------------------------------------------------------------
# STEP 7: Run Terraform apply
# -----------------------------------------------------------------------------

Write-Host "STEP 6: Running terraform apply..." -ForegroundColor Yellow
Write-Host "  (Creating the files)" -ForegroundColor Gray

$applyResult = terraform apply -auto-approve 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "  [OK] terraform apply completed successfully" -ForegroundColor Green
} else {
    Write-Host "  [ERROR] terraform apply failed!" -ForegroundColor Red
    Write-Host $applyResult -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

Write-Host ""

# -----------------------------------------------------------------------------
# STEP 8: Verify results
# -----------------------------------------------------------------------------

Write-Host "STEP 7: Verifying created files..." -ForegroundColor Yellow

$expectedFiles = @("hello.txt", "config.json", "ProjectFiles")
$allFound = $true

foreach ($file in $expectedFiles) {
    $path = Join-Path $ScriptDir $file
    if (Test-Path $path) {
        Write-Host "  [OK] Found: $file" -ForegroundColor Green
    } else {
        Write-Host "  [ERROR] Missing: $file" -ForegroundColor Red
        $allFound = $false
    }
}

if ($allFound) {
    Write-Host "  [OK] All files were created!" -ForegroundColor Green
} else {
    Write-Host "  [ERROR] Some files are missing!" -ForegroundColor Red
}

Write-Host ""

# -----------------------------------------------------------------------------
# STEP 9: Show file contents
# -----------------------------------------------------------------------------

Write-Host "STEP 8: File contents..." -ForegroundColor Yellow

# Show hello.txt
$helloPath = Join-Path $ScriptDir "hello.txt"
if (Test-Path $helloPath) {
    Write-Host ""
    Write-Host "  hello.txt:" -ForegroundColor Cyan
    Write-Host "  " + "-" * 40 -ForegroundColor Gray
    Get-Content $helloPath | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    Write-Host "  " + "-" * 40 -ForegroundColor Gray
}

# Show config.json
$configPath = Join-Path $ScriptDir "config.json"
if (Test-Path $configPath) {
    Write-Host ""
    Write-Host "  config.json:" -ForegroundColor Cyan
    Write-Host "  " + "-" * 40 -ForegroundColor Gray
    Get-Content $configPath | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    Write-Host "  " + "-" * 40 -ForegroundColor Gray
}

# Show terraform.tfstate
$statePath = Join-Path $ScriptDir "terraform.tfstate"
if (Test-Path $statePath) {
    Write-Host ""
    Write-Host "  terraform.tfstate (Terraform's memory):" -ForegroundColor Cyan
    Write-Host "  " + "-" * 40 -ForegroundColor Gray
    Write-Host "  This file keeps track of what was created." -ForegroundColor Gray
    Write-Host "  Do not delete it unless you want to start fresh." -ForegroundColor Gray
    Write-Host "  " + "-" * 40 -ForegroundColor Gray
}

Write-Host ""

# -----------------------------------------------------------------------------
# STEP 10: Summary
# -----------------------------------------------------------------------------

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SUMMARY - WHAT YOU LEARNED" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Files created in this folder:" -ForegroundColor Yellow
Write-Host "    - hello.txt (text file from Terraform)" -ForegroundColor Gray
Write-Host "    - config.json (JSON configuration)" -ForegroundColor Gray
Write-Host "    - ProjectFiles/ (folder with .keep file)" -ForegroundColor Gray
Write-Host "    - terraform.tfstate (Terraform's memory)" -ForegroundColor Gray
Write-Host "    - .terraform/ (provider plugins)" -ForegroundColor Gray
Write-Host ""
Write-Host "  Concepts you learned:" -ForegroundColor Yellow
Write-Host "    1. Provider = platform (local = your computer)" -ForegroundColor Gray
Write-Host "    2. Resource = what to create (file, folder, etc.)" -ForegroundColor Gray
Write-Host "    3. State = Terraform's memory (terraform.tfstate)" -ForegroundColor Gray
Write-Host "    4. Declarative = describe what, not how" -ForegroundColor Gray
Write-Host "    5. Idempotent = run multiple times, same result" -ForegroundColor Gray
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor Yellow
Write-Host "    1. Edit main.tf and change the content" -ForegroundColor Gray
Write-Host "    2. Run terraform plan to see what changes" -ForegroundColor Gray
Write-Host "    3. Run terraform apply to apply changes" -ForegroundColor Gray
Write-Host "    4. Run terraform destroy to remove everything" -ForegroundColor Gray
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SETUP COMPLETED!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Read-Host "Press Enter to exit"