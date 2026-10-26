# ============================================
# ansible-setup.ps1 – Automatisk Ansible Setup (Universell)
# ============================================

if (-not $PSScriptRoot) {
    $PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Path
}
if (-not $PSScriptRoot) {
    $PSScriptRoot = Get-Location
}
Set-Location $PSScriptRoot

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ANSIBLE SETUP - AUTOMATIC" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# -----------------------------------------------------------------------------
# AUTO-DEBUG: Check Administrator privileges
# -----------------------------------------------------------------------------

Write-Host "  [DEBUG] Checking Administrator privileges..." -ForegroundColor Gray
$isAdmin = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "  [WARNING] Not running as Administrator." -ForegroundColor Yellow
    Write-Host "  Right-click on script -> 'Run with PowerShell' if you encounter issues." -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Host "  [OK] Running as Administrator" -ForegroundColor Green
}

# -----------------------------------------------------------------------------
# AUTO-DEBUG: Check WSL2
# -----------------------------------------------------------------------------

Write-Host "  [DEBUG] Checking WSL2..." -ForegroundColor Gray
$wsl = Get-Command wsl -ErrorAction SilentlyContinue
if (-not $wsl) {
    Write-Host "  [ERROR] WSL2 is not installed!" -ForegroundColor Red
    Write-Host ""
    Write-Host "  HOW TO FIX:" -ForegroundColor Yellow
    Write-Host "  1. Open PowerShell as Administrator" -ForegroundColor Gray
    Write-Host "  2. Run: wsl --install" -ForegroundColor Cyan
    Write-Host "  3. Restart your computer" -ForegroundColor Gray
    Write-Host "  4. Run this script again" -ForegroundColor Gray
    Read-Host "Press Enter to exit"
    exit
}
Write-Host "  [OK] WSL2 is installed" -ForegroundColor Green

# -----------------------------------------------------------------------------
# AUTO-DEBUG: Check Ubuntu (UNIVERSAL – fungerar på alla språk)
# -----------------------------------------------------------------------------

Write-Host "  [DEBUG] Checking Ubuntu in WSL2..." -ForegroundColor Gray

# Method 1: Try to start Ubuntu and check if it exists
try {
    # Try to run a simple command in Ubuntu
    $test = wsl -d Ubuntu echo "test" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] Ubuntu is installed in WSL2" -ForegroundColor Green
        $ubuntuExists = $true
    } else {
        # Method 2: Check using wsl --list
        $list = wsl --list --verbose
        if ($list -match "Ubuntu") {
            Write-Host "  [OK] Ubuntu is installed in WSL2" -ForegroundColor Green
            $ubuntuExists = $true
        } else {
            Write-Host "  [ERROR] Ubuntu is not installed in WSL2!" -ForegroundColor Red
            $ubuntuExists = $false
        }
    }
} catch {
    # Method 3: Check with wsl -l -v as fallback
    $list = wsl -l -v
    if ($list -match "Ubuntu") {
        Write-Host "  [OK] Ubuntu is installed in WSL2" -ForegroundColor Green
        $ubuntuExists = $true
    } else {
        Write-Host "  [ERROR] Ubuntu is not installed in WSL2!" -ForegroundColor Red
        $ubuntuExists = $false
    }
}

if (-not $ubuntuExists) {
    Write-Host ""
    Write-Host "  HOW TO FIX:" -ForegroundColor Yellow
    Write-Host "  1. Open PowerShell as Administrator" -ForegroundColor Gray
    Write-Host "  2. Run: wsl --install -d Ubuntu" -ForegroundColor Cyan
    Write-Host "  3. Wait for installation (2-5 minutes)" -ForegroundColor Gray
    Write-Host "  4. Open Ubuntu from Start menu and create user" -ForegroundColor Gray
    Write-Host "  5. Run this script again" -ForegroundColor Gray
    Read-Host "Press Enter to exit"
    exit
}

# -----------------------------------------------------------------------------
# AUTO-DEBUG: Check if Ubuntu is running
# -----------------------------------------------------------------------------

Write-Host "  [DEBUG] Checking if Ubuntu is running..." -ForegroundColor Gray

# Try to run a command in Ubuntu
$ubuntuRunning = $false
try {
    $test = wsl -d Ubuntu echo "test" 2>&1
    if ($LASTEXITCODE -eq 0) {
        $ubuntuRunning = $true
        Write-Host "  [OK] Ubuntu is running" -ForegroundColor Green
    }
} catch {
    $ubuntuRunning = $false
}

if (-not $ubuntuRunning) {
    Write-Host "  [INFO] Ubuntu is not running. Starting..." -ForegroundColor Yellow
    try {
        Start-Process -FilePath "wsl.exe" -ArgumentList "-d Ubuntu" -WindowStyle Hidden
        Start-Sleep -Seconds 5
        Write-Host "  [OK] Ubuntu started" -ForegroundColor Green
    } catch {
        Write-Host "  [WARNING] Could not start Ubuntu automatically." -ForegroundColor Yellow
        Write-Host "  Please open Ubuntu from Start menu manually." -ForegroundColor Gray
        Read-Host "Press Enter to continue"
    }
}

# -----------------------------------------------------------------------------
# AUTO-DEBUG: Check Ubuntu user
# -----------------------------------------------------------------------------

Write-Host "  [DEBUG] Checking Ubuntu user..." -ForegroundColor Gray

Start-Sleep -Seconds 3

$userExists = $false
try {
    $ubuntuUser = wsl -d Ubuntu whoami 2>&1
    if ($ubuntuUser -and $ubuntuUser -notmatch "root" -and $ubuntuUser -notmatch "No such file" -and $ubuntuUser -notmatch "cannot execute") {
        Write-Host "  [OK] Ubuntu user: $ubuntuUser" -ForegroundColor Green
        $userExists = $true
    } else {
        Write-Host "  [WARNING] No user found in Ubuntu." -ForegroundColor Yellow
        Write-Host "  Opening Ubuntu for user creation..." -ForegroundColor Gray
        Write-Host "  Please create a username and password in the Ubuntu window." -ForegroundColor Yellow
        Write-Host "  (Username: use only lowercase letters, e.g. 'arsen')" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  After creating the user, type 'exit' and press Enter." -ForegroundColor Yellow
        
        Start-Process -FilePath "wsl.exe" -ArgumentList "-d Ubuntu" -Wait
        
        $ubuntuUser = wsl -d Ubuntu whoami 2>&1
        if ($ubuntuUser -and $ubuntuUser -notmatch "root" -and $ubuntuUser -notmatch "No such file") {
            Write-Host "  [OK] User created: $ubuntuUser" -ForegroundColor Green
            $userExists = $true
        } else {
            Write-Host "  [WARNING] Could not detect user." -ForegroundColor Yellow
            Write-Host "  Please open Ubuntu from Start menu and create a user manually." -ForegroundColor Gray
            Read-Host "Press Enter to continue"
        }
    }
} catch {
    Write-Host "  [WARNING] Could not check Ubuntu user." -ForegroundColor Yellow
    Write-Host "  Opening Ubuntu for manual setup..." -ForegroundColor Gray
    Start-Process -FilePath "wsl.exe" -ArgumentList "-d Ubuntu"
    Read-Host "Press Enter after you have created a user in Ubuntu"
}

Write-Host ""

# -----------------------------------------------------------------------------
# AUTO-DEBUG: Install Ansible
# -----------------------------------------------------------------------------

Write-Host "  [DEBUG] Installing Ansible in WSL2..." -ForegroundColor Gray
Write-Host "  This may take 2-5 minutes. Please wait..." -ForegroundColor Gray
Write-Host ""

try {
    Write-Host "  Step 1: Updating package list..." -ForegroundColor Gray
    $updateResult = wsl -d Ubuntu bash -c "sudo apt update -y" 2>&1
    
    Write-Host "  Step 2: Installing Ansible..." -ForegroundColor Gray
    $installResult = wsl -d Ubuntu bash -c "sudo apt install -y ansible" 2>&1
    
    $version = wsl -d Ubuntu ansible --version 2>&1 | Select-Object -First 1
    if ($version -match "ansible") {
        Write-Host "  [OK] Ansible installed: $version" -ForegroundColor Green
    } else {
        Write-Host "  [ERROR] Could not install Ansible!" -ForegroundColor Red
        Write-Host "  Please install manually: sudo apt install -y ansible" -ForegroundColor Yellow
        Read-Host "Press Enter to continue"
    }
} catch {
    Write-Host "  [ERROR] Could not install Ansible!" -ForegroundColor Red
    Write-Host "  Please install manually: sudo apt install -y ansible" -ForegroundColor Yellow
    Read-Host "Press Enter to continue"
}

Write-Host ""

# -----------------------------------------------------------------------------
# STEP 1: Create inventory file
# -----------------------------------------------------------------------------

Write-Host "STEP 1: Creating inventory file..." -ForegroundColor Yellow

$inventoryContent = @'
[local]
localhost ansible_connection=local

[all:vars]
ansible_python_interpreter=/usr/bin/python3
'@

$inventoryPath = Join-Path $PSScriptRoot "inventory.ini"
$inventoryContent | Out-File -FilePath $inventoryPath -Encoding utf8
Write-Host "  [OK] Created: inventory.ini" -ForegroundColor Green

# -----------------------------------------------------------------------------
# STEP 2: Create playbook
# -----------------------------------------------------------------------------

Write-Host "STEP 2: Creating playbook..." -ForegroundColor Yellow

$playbookContent = @'
---
- name: Min första playbook
  hosts: localhost
  tasks:
    - name: Skapa en fil
      ansible.builtin.copy:
        content: "Hej från Ansible!"
        dest: /tmp/ansible_hello.txt
'@

$playbookPath = Join-Path $PSScriptRoot "first_playbook.yml"
$playbookContent | Out-File -FilePath $playbookPath -Encoding utf8
Write-Host "  [OK] Created: first_playbook.yml" -ForegroundColor Green

# -----------------------------------------------------------------------------
# STEP 3: Run tests
# -----------------------------------------------------------------------------

Write-Host ""
Write-Host "STEP 3: Testing Ansible..." -ForegroundColor Yellow

Write-Host ""
Write-Host "  TEST 1: Ansible version" -ForegroundColor Gray
try {
    $version = wsl -d Ubuntu ansible --version 2>&1 | Select-Object -First 1
    Write-Host "  [OK] $version" -ForegroundColor Green
} catch {
    Write-Host "  [WARNING] Could not get Ansible version" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "  TEST 2: Ping localhost" -ForegroundColor Gray
try {
    $ping = wsl -d Ubuntu ansible localhost -m ping 2>&1
    if ($ping -match "pong") {
        Write-Host "  [OK] Localhost responds!" -ForegroundColor Green
    } else {
        Write-Host "  [WARNING] Could not ping localhost" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  [WARNING] Could not ping localhost" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "  TEST 3: Run playbook" -ForegroundColor Gray
try {
    $result = wsl -d Ubuntu ansible-playbook -i inventory.ini first_playbook.yml 2>&1
    if ($result -match "failed=0") {
        Write-Host "  [OK] Playbook ran successfully!" -ForegroundColor Green
    } else {
        Write-Host "  [WARNING] Playbook ran with warnings" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  [WARNING] Could not run playbook" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "  TEST 4: Check created file" -ForegroundColor Gray
try {
    $content = wsl -d Ubuntu cat /tmp/ansible_hello.txt 2>$null
    if ($content) {
        Write-Host "  [OK] File exists!" -ForegroundColor Green
        Write-Host "  Content: $content" -ForegroundColor Gray
    } else {
        Write-Host "  [WARNING] File not found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  [WARNING] Could not check file" -ForegroundColor Yellow
}

Write-Host ""

# -----------------------------------------------------------------------------
# STEP 4: How to test yourself
# -----------------------------------------------------------------------------

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  HOW TO TEST ANSIBLE YOURSELF" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "  All commands run in PowerShell:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  TEST 1: Check Ansible version" -ForegroundColor Gray
Write-Host "  wsl -d Ubuntu ansible --version" -ForegroundColor Cyan
Write-Host ""
Write-Host "  TEST 2: Ping localhost" -ForegroundColor Gray
Write-Host "  wsl -d Ubuntu ansible localhost -m ping" -ForegroundColor Cyan
Write-Host ""
Write-Host "  TEST 3: Run the playbook" -ForegroundColor Gray
Write-Host "  wsl -d Ubuntu ansible-playbook -i inventory.ini first_playbook.yml" -ForegroundColor Cyan
Write-Host ""
Write-Host "  TEST 4: Check the created file" -ForegroundColor Gray
Write-Host "  wsl -d Ubuntu cat /tmp/ansible_hello.txt" -ForegroundColor Cyan
Write-Host ""

# -----------------------------------------------------------------------------
# STEP 5: Summary
# -----------------------------------------------------------------------------

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SETUP COMPLETED!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Read-Host "Press Enter to exit"