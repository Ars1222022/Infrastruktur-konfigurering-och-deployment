<#
.SYNOPSIS
    Tests the system and installs missing components automatically.
.DESCRIPTION
    This script:
    1. Checks all required components (PowerShell 7, VS Code, Git, WSL2, Ubuntu, VS Code extensions)
    2. Attempts to install missing components automatically
    3. Provides clear instructions if automatic installation is not possible
    4. Logs all actions to a file
.NOTES
    Run this script first. 
    It is the main setup script for the course.
#>

# --- 1. Set up logging ---
$scriptDir = $PSScriptRoot
if (-not $scriptDir) {
    $scriptDir = Get-Location
}
$logPath = Join-Path $scriptDir "setup.log"
Start-Transcript -Path $logPath -Append
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "    SYSTEM TEST & INSTALLATION         "
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Start: $(Get-Date)" -ForegroundColor Gray
Write-Host "Script directory: $scriptDir" -ForegroundColor Gray
Write-Host ""

# --- 2. Check if running as administrator ---
$isAdmin = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "WARNING: Not running as Administrator." -ForegroundColor Yellow
    Write-Host "Some installations require administrator privileges." -ForegroundColor Yellow
    Write-Host "Right-click on the script and select 'Run with PowerShell' if you encounter issues." -ForegroundColor Yellow
    Write-Host ""
}

# --- 3. Define status variables ---
$errors = @()
$installed = @()
$warnings = @()

# --- 4. Helper function to show status ---
function Show-Status {
    param($TestName, $Result, $Details = "", $Fix = "")
    if ($Result) {
        Write-Host "   [OK] $TestName" -ForegroundColor Green
        if ($Details) { Write-Host "        $Details" -ForegroundColor Gray }
    } else {
        Write-Host "   [FAIL] $TestName" -ForegroundColor Red
        if ($Details) { Write-Host "        $Details" -ForegroundColor Yellow }
        if ($Fix) { Write-Host "        --> $Fix" -ForegroundColor Cyan }
    }
}

# --- 5. Check PowerShell 7 ---
Write-Host "=== 1. CHECKING POWERSHELL 7 ===" -ForegroundColor Cyan
$pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
if ($pwsh) {
    $version = pwsh --version
    Show-Status -TestName "PowerShell 7" -Result $true -Details $version
} else {
    Show-Status -TestName "PowerShell 7" -Result $false -Details "Not found!" -Fix "Run: winget install --id Microsoft.PowerShell --source winget"
    $errors += "PowerShell 7"
}

# --- 6. Check VS Code ---
Write-Host "`n=== 2. CHECKING VS CODE ===" -ForegroundColor Cyan
$code = Get-Command code -ErrorAction SilentlyContinue
if ($code) {
    $version = code --version | Select-Object -First 1
    $codePath = (Get-Command code).Source
    if ($codePath -match "^D:") {
        Show-Status -TestName "VS Code" -Result $true -Details "$version (on D: OK)"
    } else {
        Show-Status -TestName "VS Code" -Result $true -Details "$version (on C: recommended D:)"
        $warnings += "VS Code is on C: – recommend moving to D:"
    }
} else {
    Show-Status -TestName "VS Code" -Result $false -Details "Not found!" -Fix "Download from: https://code.visualstudio.com/"
    $errors += "VS Code"
}

# --- 7. Check Git ---
Write-Host "`n=== 3. CHECKING GIT ===" -ForegroundColor Cyan
$git = Get-Command git -ErrorAction SilentlyContinue
if ($git) {
    $version = git --version
    Show-Status -TestName "Git" -Result $true -Details $version
} else {
    Show-Status -TestName "Git" -Result $false -Details "Not found!" -Fix "Run: winget install --id Git.Git --source winget"
    $errors += "Git"
}

# --- 8. Check WSL2 ---
Write-Host "`n=== 4. CHECKING WSL2 ===" -ForegroundColor Cyan
$wsl = Get-Command wsl -ErrorAction SilentlyContinue
if ($wsl) {
    $version = wsl --version | Select-Object -First 1
    Show-Status -TestName "WSL2" -Result $true -Details $version
} else {
    Show-Status -TestName "WSL2" -Result $false -Details "Not found!" -Fix "Enable in Windows Features: Settings -> Windows Features -> WSL"
    $errors += "WSL2"
}

# --- 9. Check Ubuntu ---
Write-Host "`n=== 5. CHECKING UBUNTU ===" -ForegroundColor Cyan
if ($wsl) {
    $distros = wsl -l -v
    if ($distros -match "Ubuntu") {
        if ($distros -match "D:\\WSL") {
            Show-Status -TestName "Ubuntu" -Result $true -Details "Installed on D: OK"
        } else {
            Show-Status -TestName "Ubuntu" -Result $true -Details "Installed (check location)"
        }
    } else {
        Show-Status -TestName "Ubuntu" -Result $false -Details "Not found!" -Fix "Run: winget install --id Canonical.Ubuntu --source winget"
        $errors += "Ubuntu"
    }
}

# --- 10. Check VS Code Remote-WSL extension ---
Write-Host "`n=== 6. CHECKING VS CODE REMOTE-WSL ===" -ForegroundColor Cyan
if ($code) {
    $extensions = code --list-extensions 2>$null
    if ($extensions -match "ms-vscode-remote.remote-wsl") {
        Show-Status -TestName "Remote-WSL extension" -Result $true -Details "Installed OK"
    } else {
        Show-Status -TestName "Remote-WSL extension" -Result $false -Details "Not found!" -Fix "In VS Code: Extensions -> search 'Remote - WSL' -> Install"
        $errors += "Remote-WSL extension"
    }
}

# --- 11. Check VS Code PowerShell extension ---
Write-Host "`n=== 7. CHECKING VS CODE POWERSHELL EXTENSION ===" -ForegroundColor Cyan
if ($code) {
    $extensions = code --list-extensions 2>$null
    if ($extensions -match "ms-vscode.powershell") {
        Show-Status -TestName "PowerShell extension" -Result $true -Details "Installed OK"
    } else {
        Show-Status -TestName "PowerShell extension" -Result $false -Details "Not found!" -Fix "In VS Code: Extensions -> search 'PowerShell' -> Install"
        $errors += "PowerShell extension"
    }
}

# --- 12. Check VS Code Terraform extension ---
Write-Host "`n=== 8. CHECKING VS CODE TERRAFORM EXTENSION ===" -ForegroundColor Cyan
if ($code) {
    $extensions = code --list-extensions 2>$null
    if ($extensions -match "hashicorp.terraform") {
        Show-Status -TestName "Terraform extension" -Result $true -Details "Installed OK"
    } else {
        Show-Status -TestName "Terraform extension" -Result $false -Details "Not found!" -Fix "In VS Code: Extensions -> search 'Terraform' -> Install (HashiCorp)"
        $warnings += "Terraform extension not installed (optional but recommended)"
    }
}

# --- 13. Check VS Code YAML extension ---
Write-Host "`n=== 9. CHECKING VS CODE YAML EXTENSION ===" -ForegroundColor Cyan
if ($code) {
    $extensions = code --list-extensions 2>$null
    if ($extensions -match "redhat.vscode-yaml") {
        Show-Status -TestName "YAML extension" -Result $true -Details "Installed OK"
    } else {
        Show-Status -TestName "YAML extension" -Result $false -Details "Not found!" -Fix "In VS Code: Extensions -> search 'YAML' -> Install (Red Hat)"
        $warnings += "YAML extension not installed (optional but recommended for Ansible)"
    }
}

# --- 14. Check Terraform in WSL2 ---
Write-Host "`n=== 10. CHECKING TERRAFORM IN WSL2 ===" -ForegroundColor Cyan
if ($wsl) {
    Write-Host "   Checking Terraform in WSL2..." -ForegroundColor Yellow
    $terraformCheck = wsl which terraform 2>$null
    if ($terraformCheck) {
        $tfVersion = wsl terraform --version | Select-Object -First 1
        Show-Status -TestName "Terraform (WSL2)" -Result $true -Details $tfVersion
    } else {
        Show-Status -TestName "Terraform (WSL2)" -Result $false -Details "Not found!" -Fix "In Ubuntu: sudo apt install -y terraform"
        $errors += "Terraform"
    }
}

# --- 15. Check Ansible in WSL2 ---
Write-Host "`n=== 11. CHECKING ANSIBLE IN WSL2 ===" -ForegroundColor Cyan
if ($wsl) {
    Write-Host "   Checking Ansible in WSL2..." -ForegroundColor Yellow
    $ansibleCheck = wsl which ansible 2>$null
    if ($ansibleCheck) {
        $ansibleVersion = wsl ansible --version | Select-Object -First 1
        Show-Status -TestName "Ansible (WSL2)" -Result $true -Details $ansibleVersion
    } else {
        Show-Status -TestName "Ansible (WSL2)" -Result $false -Details "Not found!" -Fix "In Ubuntu: sudo apt install -y ansible"
        $errors += "Ansible"
    }
}

# --- 16. Check Python in WSL2 ---
Write-Host "`n=== 12. CHECKING PYTHON IN WSL2 ===" -ForegroundColor Cyan
if ($wsl) {
    Write-Host "   Checking Python in WSL2..." -ForegroundColor Yellow
    $pythonCheck = wsl which python3 2>$null
    if ($pythonCheck) {
        $pythonVersion = wsl python3 --version
        Show-Status -TestName "Python (WSL2)" -Result $true -Details $pythonVersion
    } else {
        Show-Status -TestName "Python (WSL2)" -Result $false -Details "Not found!" -Fix "In Ubuntu: sudo apt install -y python3 python3-pip"
        $errors += "Python"
    }
}

# --- 17. Check WSL drive location ---
Write-Host "`n=== 13. CHECKING WSL DRIVE LOCATION ===" -ForegroundColor Cyan
if ($wsl) {
    $distros = wsl -l -v
    if ($distros -match "D:\\WSL") {
        Show-Status -TestName "WSL location" -Result $true -Details "Ubuntu on D: OK"
    } elseif ($distros -match "Ubuntu") {
        Show-Status -TestName "WSL location" -Result $true -Details "Ubuntu on C: (recommend moving to D:)"
        $warnings += "Ubuntu is on C: – use Flytta-Till-D.ps1 to move to D:"
    } else {
        Show-Status -TestName "WSL location" -Result $false -Details "Ubuntu not found"
    }
}

# --- 18. Check disk space ---
Write-Host "`n=== 14. CHECKING DISK SPACE ===" -ForegroundColor Cyan
$driveC = Get-PSDrive -Name C
$driveD = Get-PSDrive -Name D -ErrorAction SilentlyContinue
$freeC = [math]::Round($driveC.Free / 1GB, 2)
Write-Host "   C: drive free space: $freeC GB" -ForegroundColor Gray
if ($driveD) {
    $freeD = [math]::Round($driveD.Free / 1GB, 2)
    Write-Host "   D: drive free space: $freeD GB" -ForegroundColor Gray
    if ($freeD -gt 20) {
        Show-Status -TestName "Disk space" -Result $true -Details "D: has $freeD GB free"
    } else {
        Show-Status -TestName "Disk space" -Result $false -Details "D: has only $freeD GB free"
        $warnings += "Low disk space on D: (need at least 20 GB)"
    }
} else {
    Write-Host "   D: drive not found" -ForegroundColor Gray
    Show-Status -TestName "Disk space" -Result $true -Details "C: has $freeC GB free"
}

# --- 19. Attempt to install missing components (only if errors exist) ---
if ($errors.Count -gt 0) {
    Write-Host "`n=== 15. ATTEMPTING TO INSTALL MISSING COMPONENTS ===" -ForegroundColor Cyan
    
    # Install PowerShell 7 if missing
    if ($errors -contains "PowerShell 7") {
        Write-Host "   Installing PowerShell 7..." -ForegroundColor Yellow
        try {
            winget install --id Microsoft.PowerShell --source winget --silent --accept-package-agreements
            Write-Host "   PowerShell 7 installed successfully!" -ForegroundColor Green
            $installed += "PowerShell 7"
            $errors = $errors | Where-Object { $_ -ne "PowerShell 7" }
        } catch {
            Write-Host "   Could not install PowerShell 7 automatically." -ForegroundColor Red
            Write-Host "   Manual: winget install --id Microsoft.PowerShell --source winget" -ForegroundColor Yellow
        }
    }
    
    # Install Git if missing
    if ($errors -contains "Git") {
        Write-Host "   Installing Git..." -ForegroundColor Yellow
        try {
            winget install --id Git.Git --source winget --silent --accept-package-agreements
            Write-Host "   Git installed successfully!" -ForegroundColor Green
            $installed += "Git"
            $errors = $errors | Where-Object { $_ -ne "Git" }
        } catch {
            Write-Host "   Could not install Git automatically." -ForegroundColor Red
            Write-Host "   Manual: winget install --id Git.Git --source winget" -ForegroundColor Yellow
        }
    }
    
    # Install Ubuntu if missing
    if ($errors -contains "Ubuntu") {
        Write-Host "   Installing Ubuntu..." -ForegroundColor Yellow
        try {
            winget install --id Canonical.Ubuntu --source winget --silent --accept-package-agreements
            Write-Host "   Ubuntu installed successfully!" -ForegroundColor Green
            Write-Host "   IMPORTANT: Open Ubuntu from Start menu to create user account." -ForegroundColor Yellow
            $installed += "Ubuntu"
            $errors = $errors | Where-Object { $_ -ne "Ubuntu" }
        } catch {
            Write-Host "   Could not install Ubuntu automatically." -ForegroundColor Red
            Write-Host "   Manual: winget install --id Canonical.Ubuntu --source winget" -ForegroundColor Yellow
        }
    }
    
    # Install Remote-WSL extension if missing
    if ($errors -contains "Remote-WSL extension") {
        Write-Host "   Installing Remote-WSL extension..." -ForegroundColor Yellow
        try {
            code --install-extension ms-vscode-remote.remote-wsl --force
            Write-Host "   Remote-WSL extension installed successfully!" -ForegroundColor Green
            $installed += "Remote-WSL extension"
            $errors = $errors | Where-Object { $_ -ne "Remote-WSL extension" }
        } catch {
            Write-Host "   Could not install Remote-WSL extension automatically." -ForegroundColor Red
            Write-Host "   Manual: In VS Code, Extensions -> search 'Remote - WSL' -> Install" -ForegroundColor Yellow
        }
    }
    
    # Install PowerShell extension if missing
    if ($errors -contains "PowerShell extension") {
        Write-Host "   Installing PowerShell extension..." -ForegroundColor Yellow
        try {
            code --install-extension ms-vscode.powershell --force
            Write-Host "   PowerShell extension installed successfully!" -ForegroundColor Green
            $installed += "PowerShell extension"
            $errors = $errors | Where-Object { $_ -ne "PowerShell extension" }
        } catch {
            Write-Host "   Could not install PowerShell extension automatically." -ForegroundColor Red
            Write-Host "   Manual: In VS Code, Extensions -> search 'PowerShell' -> Install" -ForegroundColor Yellow
        }
    }
    
    # Install Terraform in WSL2 if missing
    if ($errors -contains "Terraform") {
        Write-Host "   Installing Terraform in WSL2..." -ForegroundColor Yellow
        Write-Host "   This requires your Ubuntu password." -ForegroundColor Yellow
        try {
            wsl bash -c "wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg"
            wsl bash -c "echo 'deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(wsl lsb_release -cs) main' | sudo tee /etc/apt/sources.list.d/hashicorp.list"
            wsl bash -c "sudo apt update && sudo apt install -y terraform"
            Write-Host "   Terraform installed successfully!" -ForegroundColor Green
            $installed += "Terraform"
            $errors = $errors | Where-Object { $_ -ne "Terraform" }
        } catch {
            Write-Host "   Could not install Terraform automatically." -ForegroundColor Red
            Write-Host "   Manual: In Ubuntu: sudo apt install -y terraform" -ForegroundColor Yellow
        }
    }
    
    # Install Ansible in WSL2 if missing
    if ($errors -contains "Ansible") {
        Write-Host "   Installing Ansible in WSL2..." -ForegroundColor Yellow
        Write-Host "   This requires your Ubuntu password." -ForegroundColor Yellow
        try {
            wsl bash -c "sudo apt update && sudo apt install -y ansible"
            Write-Host "   Ansible installed successfully!" -ForegroundColor Green
            $installed += "Ansible"
            $errors = $errors | Where-Object { $_ -ne "Ansible" }
        } catch {
            Write-Host "   Could not install Ansible automatically." -ForegroundColor Red
            Write-Host "   Manual: In Ubuntu: sudo apt install -y ansible" -ForegroundColor Yellow
        }
    }
    
    # Install Python in WSL2 if missing
    if ($errors -contains "Python") {
        Write-Host "   Installing Python in WSL2..." -ForegroundColor Yellow
        try {
            wsl bash -c "sudo apt update && sudo apt install -y python3 python3-pip"
            Write-Host "   Python installed successfully!" -ForegroundColor Green
            $installed += "Python"
            $errors = $errors | Where-Object { $_ -ne "Python" }
        } catch {
            Write-Host "   Could not install Python automatically." -ForegroundColor Red
            Write-Host "   Manual: In Ubuntu: sudo apt install -y python3 python3-pip" -ForegroundColor Yellow
        }
    }
}

# --- 20. Final summary ---
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "              SUMMARY                   "
Write-Host "========================================" -ForegroundColor Cyan

if ($installed.Count -gt 0) {
    Write-Host "`nINSTALLED SUCCESSFULLY:" -ForegroundColor Green
    foreach ($item in $installed) {
        Write-Host "   [OK] $item" -ForegroundColor Green
    }
}

if ($errors.Count -gt 0) {
    Write-Host "`nSTILL MISSING (manual installation required):" -ForegroundColor Red
    foreach ($err in $errors) {
        Write-Host "   [FAIL] $err" -ForegroundColor Red
    }
}

if ($warnings.Count -gt 0) {
    Write-Host "`nWARNINGS / RECOMMENDATIONS:" -ForegroundColor Yellow
    foreach ($warn in $warnings) {
        Write-Host "   [WARN] $warn" -ForegroundColor Yellow
    }
}

if ($errors.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-Host "`nALL SYSTEMS READY! You are ready for the course!" -ForegroundColor Green
} elseif ($errors.Count -eq 0) {
    Write-Host "`nAll required components are installed." -ForegroundColor Green
    Write-Host "Review warnings above for recommendations." -ForegroundColor Yellow
} else {
    Write-Host "`nSome components could not be installed automatically." -ForegroundColor Red
    Write-Host "Follow the instructions above to complete the setup." -ForegroundColor Yellow
}

Write-Host "`nLog file: $logPath" -ForegroundColor Gray
Read-Host "`nPress Enter to exit"
Stop-Transcript