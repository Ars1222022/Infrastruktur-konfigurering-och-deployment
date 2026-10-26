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
