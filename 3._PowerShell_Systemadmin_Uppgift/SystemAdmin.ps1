# ============================================
# SystemAdmin.ps1 – Hantera tjanster, processer och register
# ============================================

# -----------------------------------------------------------------------------
# STEP 1: Check PowerShell version and administrator privileges
# -----------------------------------------------------------------------------

if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "ERROR: This script requires PowerShell 7 or higher." -ForegroundColor Red
    Write-Host "Current version: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
    Write-Host "Install PowerShell 7 from: https://aka.ms/powershell" -ForegroundColor Cyan
    Read-Host "Press Enter to exit"
    exit
}

Write-Host "PowerShell version OK: $($PSVersionTable.PSVersion)" -ForegroundColor Green

# Check if running as administrator
$isAdmin = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "WARNING: Not running as Administrator." -ForegroundColor Yellow
    Write-Host "Some functions (like stopping services) may not work." -ForegroundColor Yellow
    Write-Host "To run as Administrator: Right-click on script -> 'Run with PowerShell'" -ForegroundColor Gray
    Write-Host ""
}

# -----------------------------------------------------------------------------
# STEP 2: Validate script path (no special characters, not too long)
# -----------------------------------------------------------------------------

$ScriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

# Check for special characters in path
if ($ScriptDir -match "[^a-zA-Z0-9\\\-_:.]") {
    Write-Host "WARNING: Script path contains special characters or non-English letters." -ForegroundColor Yellow
    Write-Host "Current path: $ScriptDir" -ForegroundColor Gray
    Write-Host "Recommendation: Use only English letters, numbers, and underscores in folder names." -ForegroundColor Gray
    Write-Host ""
}

# Check for path length
if ($ScriptDir.Length -gt 100) {
    Write-Host "WARNING: Script path is long ($($ScriptDir.Length) characters)." -ForegroundColor Yellow
    Write-Host "Recommendation: Move script to a shorter path (e.g. D:\Scripts\)." -ForegroundColor Gray
    Write-Host ""
}

# -----------------------------------------------------------------------------
# STEP 3: Set up logging
# -----------------------------------------------------------------------------

$LogPath = Join-Path -Path $ScriptDir -ChildPath "systemadmin.log"

function Write-Log {
    param($Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp - $Message"
    Add-Content -Path $LogPath -Value $logEntry
}

Write-Log "========================================"
Write-Log "SystemAdmin script started: $(Get-Date)"
Write-Log "Script location: $ScriptDir"
Write-Log "========================================"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SYSTEM ADMINISTRATION TOOL" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script helps you manage Windows services, processes, and registry." -ForegroundColor Gray
Write-Host "Why this is important for your course and career:" -ForegroundColor Gray
Write-Host "  - System administrators use these commands daily" -ForegroundColor Gray
Write-Host "  - Automating these tasks saves hours of manual work" -ForegroundColor Gray
Write-Host "  - You will use these skills in your examination project" -ForegroundColor Gray
Write-Host "  - PowerShell is the standard automation tool in Swedish IT companies" -ForegroundColor Gray
Write-Host ""
Write-Host "Log file: $LogPath" -ForegroundColor Gray
Write-Host ""

# -----------------------------------------------------------------------------
# STEP 4: Check required modules and tools
# -----------------------------------------------------------------------------

# Check that required PowerShell modules are available
try {
    $null = Get-Module -ListAvailable -Name Microsoft.PowerShell.Management
    Write-Host "Module OK: Microsoft.PowerShell.Management" -ForegroundColor Green
} catch {
    Write-Host "WARNING: Microsoft.PowerShell.Management module not found." -ForegroundColor Yellow
    Write-Host "Some functions may not work correctly." -ForegroundColor Yellow
}

# Check if running on Windows
if ($env:OS -ne "Windows_NT") {
    Write-Host "ERROR: This script is designed for Windows only." -ForegroundColor Red
    Write-Log "ERROR: Script run on non-Windows system"
    Read-Host "Press Enter to exit"
    exit
}
Write-Host "Platform OK: Windows" -ForegroundColor Green
Write-Host ""

# -----------------------------------------------------------------------------
# STEP 5: Menu function with explanations
# -----------------------------------------------------------------------------

function Show-Menu {
    Write-Host ""
    Write-Host "=== MAIN MENU ===" -ForegroundColor Cyan
    Write-Host "1. Show all services"
    Write-Host "   (View Windows services and their status)"
    Write-Host ""
    Write-Host "2. Start a service"
    Write-Host "   (Start a stopped Windows service)"
    Write-Host ""
    Write-Host "3. Stop a service"
    Write-Host "   (Stop a running Windows service - requires Admin)"
    Write-Host ""
    Write-Host "4. Show all processes"
    Write-Host "   (View running programs and their CPU usage)"
    Write-Host ""
    Write-Host "5. Start a process"
    Write-Host "   (Launch a program)"
    Write-Host ""
    Write-Host "6. Stop a process"
    Write-Host "   (Force stop a running program)"
    Write-Host ""
    Write-Host "7. Show registry value"
    Write-Host "   (Read a Windows registry setting)"
    Write-Host ""
    Write-Host "8. Set registry value"
    Write-Host "   (Change a Windows registry setting - requires Admin)"
    Write-Host ""
    Write-Host "9. Show log file"
    Write-Host "   (View what this script has done)"
    Write-Host ""
    Write-Host "10. Clear log file"
    Write-Host "    (Delete the log file)"
    Write-Host ""
    Write-Host "11. Exit"
    Write-Host "    (Close this script)"
    Write-Host ""
    Write-Host "COURSE CONNECTION:" -ForegroundColor Yellow
    Write-Host "  These are the same commands used in professional IT operations." -ForegroundColor Gray
    Write-Host "  You will use them in your examination project to:" -ForegroundColor Gray
    Write-Host "  - Install and configure Windows services" -ForegroundColor Gray
    Write-Host "  - Verify that systems are running correctly" -ForegroundColor Gray
    Write-Host "  - Automate server configuration tasks" -ForegroundColor Gray
    Write-Host ""
}

# -----------------------------------------------------------------------------
# STEP 6: Service functions
# -----------------------------------------------------------------------------

function Show-Services {
    Write-Host ""
    Write-Host "=== SHOW SERVICES ===" -ForegroundColor Cyan
    Write-Host "Services are programs that run in the background." -ForegroundColor Gray
    Write-Host "Example: W3SVC (IIS web server), Spooler (print spooler)" -ForegroundColor Gray
    Write-Host "This is important because you need to know what services are running" -ForegroundColor Gray
    Write-Host "before you can automate their configuration." -ForegroundColor Gray
    Write-Host ""
    
    $showAll = Read-Host "Show all services? (y/n)"
    Write-Host ""
    Write-Host "STATUS   NAME                DISPLAY NAME" -ForegroundColor Yellow
    Write-Host "------   ----                ------------" -ForegroundColor Gray
    
    try {
        if ($showAll -eq "y") {
            $services = Get-Service
        } else {
            $services = Get-Service | Select-Object -First 20
            Write-Host "(Showing first 20 services)" -ForegroundColor Gray
        }
        
        foreach ($service in $services) {
            $status = $service.Status
            $name = $service.Name.PadRight(20)
            $display = $service.DisplayName
            if ($status -eq "Running") {
                Write-Host "RUNNING  $name $display" -ForegroundColor Green
            } else {
                Write-Host "STOPPED  $name $display" -ForegroundColor Red
            }
        }
    } catch {
        Write-Host "ERROR: Could not retrieve services." -ForegroundColor Red
        Write-Log "ERROR: Failed to retrieve services"
    }
    
    Write-Host ""
    Write-Host "TIP: To see all services, run: Get-Service" -ForegroundColor Gray
    Write-Log "Viewed services"
}

function Start-ServiceByName {
    Write-Host ""
    Write-Host "=== START SERVICE ===" -ForegroundColor Cyan
    Write-Host "Starting a service means it begins running in the background." -ForegroundColor Gray
    Write-Host "This is useful when you need to enable a feature like:" -ForegroundColor Gray
    Write-Host "  - Web server (W3SVC)" -ForegroundColor Gray
    Write-Host "  - Print spooler (Spooler)" -ForegroundColor Gray
    Write-Host "  - Background Intelligent Transfer (BITS)" -ForegroundColor Gray
    Write-Host ""
    $serviceName = Read-Host "Enter service name (e.g. Spooler, W3SVC, BITS)"
    
    try {
        $service = Get-Service -Name $serviceName -ErrorAction Stop
        if ($service.Status -eq "Running") {
            Write-Host "WARNING: Service '$serviceName' is already running." -ForegroundColor Yellow
            Write-Log "WARNING: Attempted to start already running service '$serviceName'"
            return
        }
        Start-Service -Name $serviceName
        Write-Host "OK: Service '$serviceName' started successfully!" -ForegroundColor Green
        Write-Log "Started service: $serviceName"
    } catch {
        Write-Host "ERROR: Service '$serviceName' not found!" -ForegroundColor Red
        Write-Log "ERROR: Service '$serviceName' not found"
        Write-Host "TIP: Use option 1 to see available services." -ForegroundColor Gray
    }
}

function Stop-ServiceByName {
    Write-Host ""
    Write-Host "=== STOP SERVICE ===" -ForegroundColor Cyan
    Write-Host "Stopping a service is useful when you need to:" -ForegroundColor Gray
    Write-Host "  - Disable a feature temporarily" -ForegroundColor Gray
    Write-Host "  - Apply updates that require the service to be stopped" -ForegroundColor Gray
    Write-Host "  - Troubleshoot problems" -ForegroundColor Gray
    Write-Host ""
    
    if (-not $isAdmin) {
        Write-Host "ERROR: This function requires Administrator privileges!" -ForegroundColor Red
        Write-Host "Right-click on script and select 'Run with PowerShell'." -ForegroundColor Yellow
        Write-Log "ERROR: Attempted to stop service without admin rights"
        return
    }
    
    $serviceName = Read-Host "Enter service name (e.g. Spooler, W3SVC, BITS)"
    
    try {
        $service = Get-Service -Name $serviceName -ErrorAction Stop
        if ($service.Status -eq "Stopped") {
            Write-Host "WARNING: Service '$serviceName' is already stopped." -ForegroundColor Yellow
            Write-Log "WARNING: Attempted to stop already stopped service '$serviceName'"
            return
        }
        Stop-Service -Name $serviceName -Force
        Write-Host "OK: Service '$serviceName' stopped successfully!" -ForegroundColor Green
        Write-Log "Stopped service: $serviceName"
    } catch {
        Write-Host "ERROR: Service '$serviceName' not found!" -ForegroundColor Red
        Write-Log "ERROR: Service '$serviceName' not found"
        Write-Host "TIP: Use option 1 to see available services." -ForegroundColor Gray
    }
}

# -----------------------------------------------------------------------------
# STEP 7: Process functions
# -----------------------------------------------------------------------------

function Show-Processes {
    Write-Host ""
    Write-Host "=== SHOW PROCESSES ===" -ForegroundColor Cyan
    Write-Host "Processes are programs currently running on your computer." -ForegroundColor Gray
    Write-Host "This is important because:" -ForegroundColor Gray
    Write-Host "  - You can see which programs are using system resources" -ForegroundColor Gray
    Write-Host "  - You can identify and stop hung applications" -ForegroundColor Gray
    Write-Host "  - You can monitor system performance" -ForegroundColor Gray
    Write-Host ""
    
    $showAll = Read-Host "Show all processes? (y/n)"
    Write-Host ""
    Write-Host "CPU %    NAME                ID    MEMORY (MB)" -ForegroundColor Yellow
    Write-Host "-----    ----                --    -----------" -ForegroundColor Gray
    
    try {
        if ($showAll -eq "y") {
            $processes = Get-Process | Sort-Object CPU -Descending
        } else {
            $processes = Get-Process | Sort-Object CPU -Descending | Select-Object -First 20
            Write-Host "(Showing top 20 processes by CPU usage)" -ForegroundColor Gray
        }
        
        foreach ($proc in $processes) {
            $cpu = [math]::Round($proc.CPU, 2)
            $name = $proc.Name.PadRight(20)
            $id = $proc.Id
            $memory = [math]::Round($proc.WorkingSet / 1MB, 2)
            Write-Host "$cpu`t$name $id`t$memory" -ForegroundColor Gray
        }
    } catch {
        Write-Host "ERROR: Could not retrieve processes." -ForegroundColor Red
        Write-Log "ERROR: Failed to retrieve processes"
    }
    
    Write-Host ""
    Write-Host "TIP: To see all processes, run: Get-Process" -ForegroundColor Gray
    Write-Log "Viewed processes"
}

function Start-ProcessByName {
    Write-Host ""
    Write-Host "=== START PROCESS ===" -ForegroundColor Cyan
    Write-Host "Starting a process launches a program." -ForegroundColor Gray
    Write-Host "Use this to:" -ForegroundColor Gray
    Write-Host "  - Open tools you need (notepad, calculator, etc.)" -ForegroundColor Gray
    Write-Host "  - Launch applications from scripts" -ForegroundColor Gray
    Write-Host "  - Automate program startup" -ForegroundColor Gray
    Write-Host ""
    $processName = Read-Host "Enter process name (e.g. notepad, calc, explorer)"
    
    try {
        Start-Process -FilePath $processName -ErrorAction Stop
        Write-Host "OK: Process '$processName' started successfully!" -ForegroundColor Green
        Write-Log "Started process: $processName"
    } catch {
        Write-Host "ERROR: Could not start process '$processName'!" -ForegroundColor Red
        Write-Log "ERROR: Could not start process '$processName'"
        Write-Host "TIP: Make sure the program is installed and in PATH." -ForegroundColor Gray
    }
}

function Stop-ProcessByName {
    Write-Host ""
    Write-Host "=== STOP PROCESS ===" -ForegroundColor Cyan
    Write-Host "Stopping a process force-closes a program." -ForegroundColor Gray
    Write-Host "Use this when:" -ForegroundColor Gray
    Write-Host "  - A program is frozen or unresponsive" -ForegroundColor Gray
    Write-Host "  - A program is using too much CPU or memory" -ForegroundColor Gray
    Write-Host "  - You need to free up system resources" -ForegroundColor Gray
    Write-Host ""
    
    $processName = Read-Host "Enter process name (e.g. notepad, calc, explorer)"
    
    try {
        $processes = Get-Process -Name $processName -ErrorAction Stop
        foreach ($proc in $processes) {
            Stop-Process -Id $proc.Id -Force
            Write-Host "Stopped: $($proc.Name) (ID: $($proc.Id))" -ForegroundColor Gray
        }
        Write-Host "OK: Process(es) stopped successfully!" -ForegroundColor Green
        Write-Log "Stopped process: $processName"
    } catch {
        Write-Host "ERROR: Process '$processName' not found!" -ForegroundColor Red
        Write-Log "ERROR: Process '$processName' not found"
        Write-Host "TIP: Use option 4 to see available processes." -ForegroundColor Gray
    }
}

# -----------------------------------------------------------------------------
# STEP 8: Registry functions
# -----------------------------------------------------------------------------

function Show-RegistryValue {
    Write-Host ""
    Write-Host "=== SHOW REGISTRY VALUE ===" -ForegroundColor Cyan
    Write-Host "The registry stores Windows configuration settings." -ForegroundColor Gray
    Write-Host "Reading registry values is important for:" -ForegroundColor Gray
    Write-Host "  - Checking system configuration" -ForegroundColor Gray
    Write-Host "  - Verifying application settings" -ForegroundColor Gray
    Write-Host "  - Troubleshooting system issues" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Example paths:" -ForegroundColor Gray
    Write-Host "  HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion" -ForegroundColor Gray
    Write-Host "  HKCU:\Control Panel\Desktop" -ForegroundColor Gray
    Write-Host ""
    
    $path = Read-Host "Enter registry path"
    $name = Read-Host "Enter value name (e.g. ProgramFilesDir)"
    
    try {
        # Check if path exists first
        if (-not (Test-Path $path)) {
            Write-Host "ERROR: Registry path does not exist!" -ForegroundColor Red
            Write-Log "ERROR: Registry path '$path' does not exist"
            return
        }
        
        $value = Get-ItemProperty -Path $path -Name $name -ErrorAction Stop
        Write-Host "OK: Value found:" -ForegroundColor Green
        Write-Host "  $name = $($value.$name)" -ForegroundColor Cyan
        Write-Log "Viewed registry value: $path\$name"
    } catch {
        Write-Host "ERROR: Registry value not found!" -ForegroundColor Red
        Write-Log "ERROR: Registry value '$name' not found in '$path'"
        Write-Host "TIP: Make sure the path and value name are correct." -ForegroundColor Gray
    }
}

function Set-RegistryValue {
    Write-Host ""
    Write-Host "=== SET REGISTRY VALUE ===" -ForegroundColor Cyan
    Write-Host "Changing registry values should be done with caution." -ForegroundColor Yellow
    Write-Host "Use this only when you are sure about the change." -ForegroundColor Yellow
    Write-Host "In professional work, you might use this to:" -ForegroundColor Gray
    Write-Host "  - Configure application settings" -ForegroundColor Gray
    Write-Host "  - Apply security policies" -ForegroundColor Gray
    Write-Host "  - Customize Windows behavior" -ForegroundColor Gray
    Write-Host ""
    
    if (-not $isAdmin) {
        Write-Host "ERROR: This function requires Administrator privileges!" -ForegroundColor Red
        Write-Host "Right-click on script and select 'Run with PowerShell'." -ForegroundColor Yellow
        Write-Log "ERROR: Attempted to set registry value without admin rights"
        return
    }
    
    Write-Host "WARNING: Changing registry values can affect system stability!" -ForegroundColor Yellow
    Write-Host "Only change values you understand." -ForegroundColor Yellow
    Write-Host ""
    
    $path = Read-Host "Enter registry path"
    $name = Read-Host "Enter value name"
    $value = Read-Host "Enter new value"
    
    try {
        # Check if path exists first
        if (-not (Test-Path $path)) {
            Write-Host "ERROR: Registry path does not exist!" -ForegroundColor Red
            Write-Log "ERROR: Registry path '$path' does not exist"
            return
        }
        
        Set-ItemProperty -Path $path -Name $name -Value $value -ErrorAction Stop
        Write-Host "OK: Registry value updated!" -ForegroundColor Green
        Write-Log "Updated registry value: $path\$name = $value"
    } catch {
        Write-Host "ERROR: Could not update registry value!" -ForegroundColor Red
        Write-Log "ERROR: Could not update registry value '$path\$name'"
        Write-Host "TIP: Make sure the path exists and you have permissions." -ForegroundColor Gray
    }
}

# -----------------------------------------------------------------------------
# STEP 9: Log functions
# -----------------------------------------------------------------------------

function Show-Log {
    Write-Host ""
    Write-Host "=== LOG FILE ===" -ForegroundColor Cyan
    Write-Host "The log file shows all actions performed by this script." -ForegroundColor Gray
    Write-Host "Logging is important in professional IT work because:" -ForegroundColor Gray
    Write-Host "  - You can see what changes were made" -ForegroundColor Gray
    Write-Host "  - You can track who made changes" -ForegroundColor Gray
    Write-Host "  - You can troubleshoot issues" -ForegroundColor Gray
    Write-Host "  - You can audit system changes" -ForegroundColor Gray
    Write-Host ""
    
    if (-not (Test-Path $LogPath)) {
        Write-Host "INFO: Log file does not exist yet." -ForegroundColor Yellow
        return
    }
    
    Write-Host "Log file: $LogPath" -ForegroundColor Gray
    Write-Host "-------------------" -ForegroundColor Gray
    Get-Content -Path $LogPath | Select-Object -Last 20 | ForEach-Object {
        Write-Host $_ -ForegroundColor Gray
    }
    Write-Host "-------------------" -ForegroundColor Gray
    Write-Host "(Showing last 20 lines)" -ForegroundColor Gray
}

function Clear-Log {
    Write-Host ""
    Write-Host "=== CLEAR LOG FILE ===" -ForegroundColor Cyan
    
    if (Test-Path $LogPath) {
        Remove-Item -Path $LogPath -Force
        Write-Host "OK: Log file cleared." -ForegroundColor Green
        Write-Log "Log file cleared by user"
    } else {
        Write-Host "INFO: Log file does not exist." -ForegroundColor Yellow
    }
}

# -----------------------------------------------------------------------------
# STEP 10: Main program loop with input validation
# -----------------------------------------------------------------------------

do {
    Show-Menu
    $choice = Read-Host "Select an option"
    
    # Validate that input is a number
    if (-not ($choice -match "^[0-9]+$")) {
        Write-Host "ERROR: Please enter a number between 1 and 11." -ForegroundColor Red
        continue
    }
    
    switch ($choice) {
        "1"  { Show-Services }
        "2"  { Start-ServiceByName }
        "3"  { Stop-ServiceByName }
        "4"  { Show-Processes }
        "5"  { Start-ProcessByName }
        "6"  { Stop-ProcessByName }
        "7"  { Show-RegistryValue }
        "8"  { Set-RegistryValue }
        "9"  { Show-Log }
        "10" { Clear-Log }
        "11" { 
            Write-Host ""
            Write-Host "Exiting..." -ForegroundColor Cyan
            Write-Host "You have practiced key system administration skills:" -ForegroundColor Gray
            Write-Host "  - Managing services" -ForegroundColor Gray
            Write-Host "  - Managing processes" -ForegroundColor Gray
            Write-Host "  - Working with the registry" -ForegroundColor Gray
            Write-Host "  - Logging and auditing" -ForegroundColor Gray
            Write-Host ""
            Write-Host "These are essential skills for your examination project" -ForegroundColor Gray
            Write-Host "and for your future career in IT infrastructure." -ForegroundColor Gray
            Write-Log "Script exited by user"
        }
        default { 
            Write-Host "ERROR: Invalid option. Please enter a number between 1 and 11." -ForegroundColor Red
        }
    }
} while ($choice -ne "11")

Write-Host ""
Write-Host "Log file: $LogPath" -ForegroundColor Gray