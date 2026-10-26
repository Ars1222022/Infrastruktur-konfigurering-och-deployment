# ============================================
# projekt-complete.ps1 – SLUTPROJEKTET (FIXAD)
# ============================================

if (-not $PSScriptRoot) {
    $PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Path
}
if (-not $PSScriptRoot) {
    $PSScriptRoot = Get-Location
}
Set-Location $PSScriptRoot

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  SLUTPROJEKT – SKAPAR ALLA FILER" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "OBS! Detta skript är anpassat för Windows 10/11." -ForegroundColor Yellow
Write-Host "I produktion (Windows Server) använder man Install-WindowsFeature.`n" -ForegroundColor Gray

# ------------------------------------------------------------
# RENSA GAMLA FILER
# ------------------------------------------------------------

Write-Host "[STEP 1] Rensar gamla filer..." -ForegroundColor Yellow

$filesToDelete = @(
    "install_webserver.ps1", "main.tf", "playbook.yml", "verify.py",
    "README.md", ".gitignore", "inventory.ini", "server.txt",
    "website.html", "report.json", "projekt_kedjan.sh"
)

foreach ($file in $filesToDelete) {
    $fullPath = Join-Path $PSScriptRoot $file
    if (Test-Path $fullPath) {
        Remove-Item -Path $fullPath -Force
        Write-Host "  Removed: $file" -ForegroundColor Gray
    }
}

try {
    wsl -d Ubuntu bash -c "rm -rf ~/projekt-lab 2>/dev/null" 2>&1 | Out-Null
    Write-Host "  [WSL] Cleaned up ~/projekt-lab" -ForegroundColor Gray
} catch {}

Write-Host "`nAllt ar rensat!`n" -ForegroundColor Green

# ------------------------------------------------------------
# SKAPA POWERSHELL-SKRIPT
# ------------------------------------------------------------

Write-Host "[STEP 2] Skapar PowerShell-skript..." -ForegroundColor Yellow

$psScript = @'
# install_webserver.ps1 – SLUTPROJEKTET
param(
    [string]$WebRoot = "C:\webserver",
    [string]$LogFile = "C:\webserver\logs\install.log"
)

function Logga {
    param([string]$Meddelande)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $rad = "[$timestamp] $Meddelande"
    Write-Host $rad -ForegroundColor Gray
    
    $loggMapp = Split-Path $LogFile -Parent
    if (-not (Test-Path $loggMapp)) {
        New-Item -Path $loggMapp -ItemType Directory -Force | Out-Null
    }
    $rad | Out-File -FilePath $LogFile -Append -Encoding utf8 -ErrorAction SilentlyContinue
}

function Installera-Nginx-WSL {
    Logga "Installerar Nginx i WSL..."
    try {
        wsl -d Ubuntu bash -c "sudo apt update -y && sudo apt install -y nginx" 2>&1 | Out-Null
        Logga "Nginx installerat i WSL!"
        return $true
    } catch {
        Logga "Fel: $($_.Exception.Message)"
        return $false
    }
}

function Starta-Tjanst {
    param([string]$ServiceName)
    Logga "Startar $ServiceName..."
    try {
        if ($ServiceName -eq "nginx") {
            wsl -d Ubuntu bash -c "sudo systemctl start nginx && sudo systemctl enable nginx" 2>&1 | Out-Null
        } else {
            Start-Service -Name $ServiceName -ErrorAction Stop
            Set-Service -Name $ServiceName -StartupType Automatic
        }
        Logga "$ServiceName startad!"
        return $true
    } catch {
        Logga "Fel: $($_.Exception.Message)"
        return $false
    }
}

function Skapa-Webbsida {
    Logga "Skapar webbsida..."
    try {
        if (-not (Test-Path $WebRoot)) {
            New-Item -Path $WebRoot -ItemType Directory -Force | Out-Null
        }
        $html = "<html><body><h1>Slutprojektet</h1><p>Skapad av PowerShell!</p></body></html>"
        $html | Out-File -FilePath "$WebRoot\index.html" -Encoding utf8
        Logga "Webbsida skapad!"
        return $true
    } catch {
        Logga "Fel: $($_.Exception.Message)"
        return $false
    }
}

function Visa-Meny {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  SLUTPROJEKTET – INSTALLATIONSGUIDE" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "VALJ DIN MILJO:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  1. Windows Server (IIS) – krav Install-WindowsFeature"
    Write-Host "  2. Windows 10/11 (IIS) – krav admin-rattigheter"
    Write-Host "  3. WSL (Nginx) – REKOMMENDERAS"
    Write-Host "  4. Visa status"
    Write-Host "  5. Avsluta"
    Write-Host ""
}

function Valj-Miljo {
    do {
        Visa-Meny
        $val = Read-Host "  Ange ditt val (1-5)"
        switch ($val) {
            "3" {
                Write-Host "WSL valt (Rekomenderas!)"
                Installera-Nginx-WSL
                Starta-Tjanst -ServiceName "nginx"
                Skapa-Webbsida
                break
            }
            "4" {
                Write-Host "Kontrollerar status..."
                $nginx = wsl -d Ubuntu bash -c "systemctl is-active nginx" 2>$null
                if ($nginx -match "active") {
                    Write-Host "  Nginx kor i WSL" -ForegroundColor Green
                } else {
                    Write-Host "  Nginx kor inte i WSL" -ForegroundColor Red
                }
                Read-Host "Tryck Enter for att fortsatta"
                continue
            }
            "5" {
                Write-Host "Avslutar..."
                exit
            }
            default {
                Write-Host "Ogiltigt val!"
                Start-Sleep -Seconds 2
            }
        }
        if ($val -eq "3") {
            Write-Host "KLART! Webbsidan finns pa: $WebRoot\index.html"
            Write-Host "Oppna i webblasaren: http://localhost"
            Read-Host "Tryck Enter for att fortsatta"
        }
    } while ($true)
}

Valj-Miljo
'@

$psScript | Out-File -FilePath (Join-Path $PSScriptRoot "install_webserver.ps1") -Encoding utf8
Write-Host "  Skapade: install_webserver.ps1" -ForegroundColor Green

# ------------------------------------------------------------
# SKAPA TERRAFORM
# ------------------------------------------------------------

Write-Host "[STEP 3] Skapar Terraform..." -ForegroundColor Yellow

$tfScript = @'
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
'@

$tfScript | Out-File -FilePath (Join-Path $PSScriptRoot "main.tf") -Encoding utf8
Write-Host "  Skapade: main.tf" -ForegroundColor Green

# ------------------------------------------------------------
# SKAPA ANSIBLE
# ------------------------------------------------------------

Write-Host "[STEP 4] Skapar Ansible (VG)..." -ForegroundColor Yellow

$ansibleScript = @'
---
- name: Konfigurera med Ansible
  hosts: localhost
  become: yes
  tasks:
    - name: Installera Nginx
      apt:
        name: nginx
        state: present
        update_cache: yes

    - name: Starta Nginx
      service:
        name: nginx
        state: started
        enabled: yes

    - name: Kopiera webbsida
      copy:
        src: website.html
        dest: /var/www/html/index.html
'@

$ansibleScript | Out-File -FilePath (Join-Path $PSScriptRoot "playbook.yml") -Encoding utf8
Write-Host "  Skapade: playbook.yml (VG)" -ForegroundColor Green

# ------------------------------------------------------------
# SKAPA PYTHON
# ------------------------------------------------------------

Write-Host "[STEP 5] Skapar Python (VG)..." -ForegroundColor Yellow

$pythonScript = @'
#!/usr/bin/env python3
import os
import subprocess

def check_website():
    try:
        result = subprocess.run(
            ["curl", "-s", "-o", "/dev/null", "-w", "%{http_code}", "http://localhost"],
            capture_output=True,
            text=True
        )
        return result.stdout.strip() == "200"
    except:
        return False

def check_files():
    return os.path.exists("server.txt") and os.path.exists("website.html")

def main():
    print("\n=== VERIFIERING MED PYTHON ===\n")
    website_ok = check_website()
    files_ok = check_files()
    print(f"Webbsida: {'OK' if website_ok else 'FAIL'}")
    print(f"Filer: {'OK' if files_ok else 'FAIL'}")
    if website_ok and files_ok:
        print("\nALLA VERIFIERINGAR GODKANDAS!")

if __name__ == "__main__":
    main()
'@

$pythonScript | Out-File -FilePath (Join-Path $PSScriptRoot "verify.py") -Encoding utf8
Write-Host "  Skapade: verify.py (VG)" -ForegroundColor Green

# ------------------------------------------------------------
# SKAPA README
# ------------------------------------------------------------

Write-Host "[STEP 6] Skapar README..." -ForegroundColor Yellow

$readmeContent = @"
# Slutprojektet – Infrastruktur Automation

## Mal
Automatisera installation och konfiguration av en webbserver.

## Verktyg
- PowerShell – installation och konfiguration
- Terraform – Infrastructure as Code
- Ansible – konfigurationshantering (VG)
- Python – verifiering (VG)

## Installation
1. Kor: .\install_webserver.ps1
2. Kor: terraform apply -auto-approve
3. Kor: ansible-playbook -i inventory.ini playbook.yml
4. Kor: python3 verify.py

## Resultat
Webbserver installerades och konfigurerades automatiskt.

## GitHub
https://github.com/ditt-repo/slutprojektet
"@

$readmeContent | Out-File -FilePath (Join-Path $PSScriptRoot "README.md") -Encoding utf8
Write-Host "  Skapade: README.md" -ForegroundColor Green

# ------------------------------------------------------------
# SKAPA .gitignore
# ------------------------------------------------------------

Write-Host "[STEP 7] Skapar .gitignore..." -ForegroundColor Yellow

$gitignoreContent = @"
*.tfstate
*.tfstate.*
.terraform/
*.retry
__pycache__/
*.log
server.txt
report.json
"@

$gitignoreContent | Out-File -FilePath (Join-Path $PSScriptRoot ".gitignore") -Encoding utf8
Write-Host "  Skapade: .gitignore" -ForegroundColor Green

# ------------------------------------------------------------
# SKAPA INVENTORY
# ------------------------------------------------------------

Write-Host "[STEP 8] Skapar inventory.ini..." -ForegroundColor Yellow

$inventoryContent = @"
[local]
localhost ansible_connection=local
"@

$inventoryContent | Out-File -FilePath (Join-Path $PSScriptRoot "inventory.ini") -Encoding utf8
Write-Host "  Skapade: inventory.ini" -ForegroundColor Green

# ------------------------------------------------------------
# SAMMANFATTNING
# ------------------------------------------------------------

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  ALLA FILER SKAPADE!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Skapade filer:" -ForegroundColor Yellow
Write-Host "  install_webserver.ps1 – PowerShell"
Write-Host "  main.tf – Terraform"
Write-Host "  playbook.yml – Ansible (VG)"
Write-Host "  verify.py – Python (VG)"
Write-Host "  README.md – Dokumentation"
Write-Host "  .gitignore – Git"
Write-Host "  inventory.ini – Ansible"
Write-Host ""

Write-Host "Nasta steg:" -ForegroundColor Yellow
Write-Host "  1. Testa: .\install_webserver.ps1 (valj 3)"
Write-Host "  2. Skapa GitHub-repo"
Write-Host "  3. Pusha alla filer"
Write-Host "  4. Lamna in .zip + GitHub-lank"
Write-Host ""

Read-Host "Press Enter to exit"