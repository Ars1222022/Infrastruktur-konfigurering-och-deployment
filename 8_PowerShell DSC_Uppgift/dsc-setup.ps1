# ============================================
# dsc-setup.ps1 – ULTIMATE DSC Setup
# ============================================

if (-not $PSScriptRoot) {
    $PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Path
}
if (-not $PSScriptRoot) {
    $PSScriptRoot = Get-Location
}
Set-Location $PSScriptRoot

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DSC SETUP - ULTIMATE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ============================================
# AUTO-DEBUG: Check all prerequisites
# ============================================

# 1. PowerShell version
Write-Host "  [DEBUG] Checking PowerShell version..." -ForegroundColor Gray
$psVersion = $PSVersionTable.PSVersion
if ($psVersion.Major -lt 5) {
    Write-Host "  [ERROR] PowerShell 5.1+ required!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}
Write-Host "  [OK] PowerShell: $psVersion" -ForegroundColor Green

# 2. Windows version
Write-Host "  [DEBUG] Checking Windows version..." -ForegroundColor Gray
if ($env:OS -ne "Windows_NT") {
    Write-Host "  [ERROR] Windows required!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}
$osVersion = [Environment]::OSVersion.Version
Write-Host "  [OK] Windows: $osVersion" -ForegroundColor Green

# 3. Administrator
Write-Host "  [DEBUG] Checking Administrator..." -ForegroundColor Gray
$isAdmin = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "  [ERROR] Administrator required!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}
Write-Host "  [OK] Administrator" -ForegroundColor Green

# 4. Disk space
Write-Host "  [DEBUG] Checking disk space..." -ForegroundColor Gray
$drive = Get-PSDrive -Name C
if ($drive.Free / 1GB -lt 1) {
    Write-Host "  [WARNING] Low disk space: $([math]::Round($drive.Free/1GB,2)) GB free" -ForegroundColor Yellow
} else {
    Write-Host "  [OK] Disk space: $([math]::Round($drive.Free/1GB,2)) GB free" -ForegroundColor Green
}

# 5. Network connectivity
Write-Host "  [DEBUG] Checking network..." -ForegroundColor Gray
try {
    Test-Connection -ComputerName localhost -Count 1 -Quiet -ErrorAction Stop | Out-Null
    Write-Host "  [OK] Network OK" -ForegroundColor Green
} catch {
    Write-Host "  [WARNING] Network issues detected" -ForegroundColor Yellow
}

# 6. DSC already running?
Write-Host "  [DEBUG] Checking if DSC is already running..." -ForegroundColor Gray
try {
    $status = Get-DscConfigurationStatus -ErrorAction SilentlyContinue
    if ($status -and $status.Status -eq "Pending") {
        Write-Host "  [INFO] DSC has pending configuration. Stopping..." -ForegroundColor Yellow
        Stop-DscConfiguration -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
    }
    Write-Host "  [OK] DSC not busy" -ForegroundColor Green
} catch {
    Write-Host "  [OK] DSC not active" -ForegroundColor Green
}

# 7. Backup current DSC config
Write-Host "  [DEBUG] Backing up current DSC config..." -ForegroundColor Gray
try {
    $currentConfig = Get-DscConfiguration -ErrorAction SilentlyContinue
    if ($currentConfig) {
        $backupPath = Join-Path $PSScriptRoot "dsc_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
        $currentConfig | ConvertTo-Json | Out-File -FilePath $backupPath
        Write-Host "  [OK] Backup saved: $backupPath" -ForegroundColor Green
    }
} catch {}

# 8. Check WinRM
Write-Host "  [DEBUG] Checking WinRM..." -ForegroundColor Gray
$winrm = Get-Service WinRM -ErrorAction SilentlyContinue
if (-not $winrm) {
    Write-Host "  [WARNING] WinRM not found. Installing..." -ForegroundColor Yellow
    try {
        Enable-PSRemoting -SkipNetworkProfileCheck -Force -ErrorAction Stop
        Write-Host "  [OK] WinRM installed" -ForegroundColor Green
    } catch {
        Write-Host "  [ERROR] Could not install WinRM!" -ForegroundColor Red
        Write-Host "  Run manually: Enable-PSRemoting -SkipNetworkProfileCheck -Force" -ForegroundColor Cyan
        Read-Host "Press Enter to continue"
    }
} elseif ($winrm.Status -ne "Running") {
    Write-Host "  [WARNING] WinRM not running. Starting..." -ForegroundColor Yellow
    try {
        Start-Service WinRM -ErrorAction Stop
        Write-Host "  [OK] WinRM started" -ForegroundColor Green
    } catch {
        Write-Host "  [ERROR] Could not start WinRM!" -ForegroundColor Red
        Write-Host "  Run manually: Start-Service WinRM" -ForegroundColor Cyan
        Read-Host "Press Enter to continue"
    }
} else {
    Write-Host "  [OK] WinRM running" -ForegroundColor Green
}

# 9. Firewall rule for WinRM
Write-Host "  [DEBUG] Checking firewall rule..." -ForegroundColor Gray
$rule = Get-NetFirewallRule -DisplayName "WinRM HTTP" -ErrorAction SilentlyContinue
if (-not $rule) {
    Write-Host "  [WARNING] WinRM firewall rule missing. Adding..." -ForegroundColor Yellow
    try {
        New-NetFirewallRule -DisplayName "WinRM HTTP" -Direction Inbound -LocalPort 5985 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue
        Write-Host "  [OK] Firewall rule added" -ForegroundColor Green
    } catch {}
} else {
    Write-Host "  [OK] Firewall rule exists" -ForegroundColor Green
}

# 10. DSC module
Write-Host "  [DEBUG] Checking DSC module..." -ForegroundColor Gray
$module = Get-Module -ListAvailable -Name PSDesiredStateConfiguration
if (-not $module) {
    Write-Host "  [WARNING] DSC module not found. Installing..." -ForegroundColor Yellow
    try {
        Install-Module -Name PSDesiredStateConfiguration -Force -AllowClobber -ErrorAction Stop
        Write-Host "  [OK] DSC module installed" -ForegroundColor Green
    } catch {
        Write-Host "  [ERROR] Could not install DSC module!" -ForegroundColor Red
        Write-Host "  Run manually: Install-Module -Name PSDesiredStateConfiguration -Force" -ForegroundColor Cyan
        Read-Host "Press Enter to continue"
    }
} else {
    Write-Host "  [OK] DSC module found" -ForegroundColor Green
}

# 11. Fix Execution Policy
Write-Host "  [DEBUG] Checking Execution Policy..." -ForegroundColor Gray
$policy = Get-ExecutionPolicy -Scope CurrentUser
if ($policy -eq "Restricted" -or $policy -eq "Undefined") {
    Write-Host "  [WARNING] Execution Policy is $policy. Fixing..." -ForegroundColor Yellow
    try {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction SilentlyContinue
        Write-Host "  [OK] Execution Policy set to RemoteSigned" -ForegroundColor Green
    } catch {}
} else {
    Write-Host "  [OK] Execution Policy: $policy" -ForegroundColor Green
}

Write-Host ""
Write-Host "  [OK] ALL CHECKS COMPLETED!" -ForegroundColor Green
Write-Host ""
Read-Host "Press Enter to continue..."
Write-Host ""

# ============================================
# MAIN MENU (same as before)
# ============================================

function Write-Section {
    param($Message)
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  $Message" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-OK {
    param($Message)
    Write-Host "  [OK] $Message" -ForegroundColor Green
}

function Write-Warning {
    param($Message)
    Write-Host "  [WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param($Message)
    Write-Host "  [ERROR] $Message" -ForegroundColor Red
}

function Apply-DSC {
    Write-Section "APPLY DSC CONFIGURATION"
    
    # Stop LCM if busy
    try { Stop-DscConfiguration -Force -ErrorAction SilentlyContinue } catch {}
    
    # Create DSC configuration
    Write-Host "  Creating DSC configuration..." -ForegroundColor Gray
    $dscContent = @'
Configuration EnsureService {
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Node "localhost" {
        Service SpoolerService {
            Name        = "Spooler"
            State       = "Running"
            StartupType = "Automatic"
        }
    }
}
EnsureService
'@
    
    $dscPath = Join-Path $PSScriptRoot "EnsureService.ps1"
    $dscContent | Out-File -FilePath $dscPath -Encoding utf8
    
    try {
        . $dscPath
        if (Test-Path ".\EnsureService") {
            Write-OK "MOF file generated"
        }
    } catch {
        Write-Error "Could not generate MOF"
        Read-Host "Press Enter to continue"
        return
    }
    
    try {
        Start-DscConfiguration -Path .\EnsureService -Wait -Verbose -Force -ErrorAction Stop 2>&1 | Out-Null
        Write-OK "DSC configuration applied"
    } catch {
        try {
            Start-DscConfiguration -Path .\EnsureService -Wait -Verbose -UseExisting -ErrorAction Stop 2>&1 | Out-Null
            Write-OK "DSC configuration applied (existing)"
        } catch {
            Write-Error "Could not apply DSC"
            Write-Host "  Run manually: Start-DscConfiguration -Path .\EnsureService -Wait -Verbose -Force" -ForegroundColor Yellow
            Read-Host "Press Enter to continue"
            return
        }
    }
    
    $status = Test-DscConfiguration -ErrorAction SilentlyContinue
    if ($status) {
        Write-OK "System is in desired state"
        $spooler = Get-Service -Name Spooler -ErrorAction SilentlyContinue
        if ($spooler) {
            Write-Host "  Spooler service: $($spooler.Status)" -ForegroundColor Gray
        }
    } else {
        Write-Warning "System is NOT in desired state"
    }
    
    Read-Host "Press Enter to continue"
}

function Create-ScheduledTask {
    Write-Section "CREATE SCHEDULED TASK"
    
    $tasks = Get-ScheduledTask -TaskName "DSC-AutoCorrect-*" -ErrorAction SilentlyContinue
    if ($tasks) {
        Write-Host "  Existing DSC scheduled tasks:" -ForegroundColor Yellow
        foreach ($task in $tasks) {
            Write-Host "    - $($task.TaskName)" -ForegroundColor Gray
        }
        $remove = Read-Host "  Remove existing tasks? (yes/no)"
        if ($remove -eq "yes") {
            foreach ($task in $tasks) {
                Unregister-ScheduledTask -TaskName $task.TaskName -Confirm:$false -ErrorAction SilentlyContinue
                Write-OK "Removed: $($task.TaskName)"
            }
        }
    }
    
    Write-Host ""
    Write-Host "  How often should DSC run?" -ForegroundColor Yellow
    Write-Host "  1. Every 15 minutes" -ForegroundColor Gray
    Write-Host "  2. Every hour" -ForegroundColor Gray
    Write-Host "  3. Every 4 hours" -ForegroundColor Gray
    Write-Host "  4. Every day at 02:00" -ForegroundColor Gray
    $choice = Read-Host "  Select (1-4)"
    
    $maxDuration = New-TimeSpan -Days 30 -Hours 23 -Minutes 59 -Seconds 59
    
    switch ($choice) {
        "1" { 
            $interval = "15 minutes"
            $minutes = 15
            $name = "DSC-AutoCorrect-15min"
            $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes $minutes) -RepetitionDuration $maxDuration
        }
        "2" { 
            $interval = "1 hour"
            $minutes = 60
            $name = "DSC-AutoCorrect-Hourly"
            $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes $minutes) -RepetitionDuration $maxDuration
        }
        "3" { 
            $interval = "4 hours"
            $minutes = 240
            $name = "DSC-AutoCorrect-4hours"
            $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes $minutes) -RepetitionDuration $maxDuration
        }
        "4" { 
            $interval = "daily at 02:00"
            $name = "DSC-AutoCorrect-Daily"
            $trigger = New-ScheduledTaskTrigger -Daily -At "02:00"
        }
        default { 
            Write-Error "Invalid choice"
            Read-Host "Press Enter to continue"
            return
        }
    }
    
    $dscPath = Join-Path $PSScriptRoot "EnsureService"
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -Command `"Import-Module PSDesiredStateConfiguration -Force; Start-DscConfiguration -Path '$dscPath' -Force -ErrorAction SilentlyContinue`""
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    try {
        Unregister-ScheduledTask -TaskName $name -Confirm:$false -ErrorAction SilentlyContinue
        Register-ScheduledTask -TaskName $name -Action $action -Trigger $trigger -Principal $principal -Description "DSC Auto-Correction" -ErrorAction Stop
        Write-OK "Scheduled task created: $name"
        Write-Host "  Runs: $interval" -ForegroundColor Gray
    } catch {
        Write-Error "Could not create scheduled task: $_" -ForegroundColor Red
    }
    
    Read-Host "Press Enter to continue"
}

function Show-ScheduledTasks {
    Write-Section "VIEW SCHEDULED TASKS"
    $tasks = Get-ScheduledTask -TaskName "DSC-AutoCorrect-*" -ErrorAction SilentlyContinue
    if (-not $tasks) {
        Write-Host "  No DSC scheduled tasks found." -ForegroundColor Gray
    } else {
        Write-Host "  DSC scheduled tasks:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  NAME                       STATUS      NEXT RUN" -ForegroundColor Cyan
        Write-Host "  ----                       ------      --------" -ForegroundColor Gray
        foreach ($task in $tasks) {
            $state = $task.State.ToString()
            $next = "N/A"
            try {
                $info = Get-ScheduledTaskInfo -TaskName $task.TaskName -ErrorAction SilentlyContinue
                if ($info) { $next = $info.NextRunTime }
            } catch {}
            Write-Host "  $($task.TaskName.PadRight(25)) $($state.PadRight(12)) $($next)" -ForegroundColor Gray
        }
    }
    Read-Host "Press Enter to continue"
}

function Remove-ScheduledTasks {
    Write-Section "REMOVE SCHEDULED TASKS"
    $tasks = Get-ScheduledTask -TaskName "DSC-AutoCorrect-*" -ErrorAction SilentlyContinue
    if (-not $tasks) {
        Write-Host "  No DSC scheduled tasks found." -ForegroundColor Gray
    } else {
        Write-Host "  Existing DSC scheduled tasks:" -ForegroundColor Yellow
        foreach ($task in $tasks) {
            Write-Host "    - $($task.TaskName)" -ForegroundColor Gray
        }
        $confirm = Read-Host "  Remove ALL? (yes/no)"
        if ($confirm -eq "yes") {
            foreach ($task in $tasks) {
                Unregister-ScheduledTask -TaskName $task.TaskName -Confirm:$false -ErrorAction SilentlyContinue
                Write-OK "Removed: $($task.TaskName)"
            }
        }
    }
    Read-Host "Press Enter to continue"
}

function Cleanup-DSC {
    Write-Section "CLEANUP DSC CONFIGURATION"
    $confirm = Read-Host "  Continue? (yes/no)"
    if ($confirm -ne "yes") {
        Write-Host "  Cancelled." -ForegroundColor Gray
        Read-Host "Press Enter to continue"
        return
    }
    
    try { Remove-DscConfigurationDocument -Stage Current -Force -ErrorAction SilentlyContinue; Write-OK "DSC configuration removed" } catch { Write-Warning "Could not remove DSC" }
    try { if (Test-Path ".\EnsureService") { Remove-Item -Path .\EnsureService -Recurse -Force; Write-OK "Removed: EnsureService/" } } catch {}
    try { if (Test-Path ".\EnsureService.ps1") { Remove-Item -Path .\EnsureService.ps1 -Force; Write-OK "Removed: EnsureService.ps1" } } catch {}
    
    $stop = Read-Host "  Stop Spooler? (yes/no)"
    if ($stop -eq "yes") {
        try { Stop-Service -Name Spooler -ErrorAction SilentlyContinue; Write-OK "Spooler stopped" } catch { Write-Warning "Could not stop Spooler" }
    }
    Read-Host "Press Enter to continue"
}

# ============================================
# MAIN MENU LOOP
# ============================================

do {
    Write-Section "MAIN MENU"
    Write-Host "  DSC Configuration Management" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  1. Apply DSC configuration" -ForegroundColor Gray
    Write-Host "  2. Create scheduled task" -ForegroundColor Gray
    Write-Host "  3. Show scheduled tasks" -ForegroundColor Gray
    Write-Host "  4. Remove scheduled tasks" -ForegroundColor Gray
    Write-Host "  5. Cleanup DSC" -ForegroundColor Gray
    Write-Host "  6. Exit" -ForegroundColor Gray
    Write-Host ""
    
    $choice = Read-Host "  Select an option (1-6)"
    
    switch ($choice) {
        "1" { Apply-DSC }
        "2" { Create-ScheduledTask }
        "3" { Show-ScheduledTasks }
        "4" { Remove-ScheduledTasks }
        "5" { Cleanup-DSC }
        "6" { 
            Write-Host ""
            Write-Host "  Exiting..." -ForegroundColor Cyan
            Write-Host "  Remember to remove scheduled tasks when course is finished!" -ForegroundColor Yellow
        }
        default { 
            Write-Error "Invalid option"
            Read-Host "Press Enter to continue"
        }
    }
} while ($choice -ne "6")

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DSC SETUP COMPLETED" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""