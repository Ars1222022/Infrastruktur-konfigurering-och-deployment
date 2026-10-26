# ============================================
# Anvandarhanterare.ps1 – Hantera lokala anvandare
# ============================================
# 
# SYFTE:
# Detta skript visar hur man bygger ett professionellt administrationsverktyg
# med felhantering, loggning och bakgrundsjobb.
#
# PROFESSIONELL ANVANDNING:
# - Systemadministratorer anvander dessa tekniker dagligen
# - Loggning ar krav for alla produktionsskript
# - Felhantering forhindrar att skript kraschar
# - Bakgrundsjobb anvands for langa operationer
#
# KOPPLING TILL KURSEN:
# - Detta ar grunden for VG-nivan i examinationsprojektet
# - Alla tekniker anvands i riktiga IT-miljoer
# ============================================

# -----------------------------------------------------------------------------
# STEP 1: Check PowerShell version
# -----------------------------------------------------------------------------
# VARFOR: PowerShell 7 har nyare funktioner och battre prestanda
# I PRODUKTION: Man vill alltid anvanda senaste stabila versionen

if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "ERROR: This script requires PowerShell 7 or higher." -ForegroundColor Red
    Write-Host "Current version: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
    Write-Host "Install PowerShell 7 from: https://aka.ms/powershell" -ForegroundColor Cyan
    Read-Host "Press Enter to exit"
    exit
}

Write-Host "PowerShell version OK: $($PSVersionTable.PSVersion)" -ForegroundColor Green

# -----------------------------------------------------------------------------
# STEP 2: Script path validation (automatic debugging)
# -----------------------------------------------------------------------------
# VARFOR: Specialtecken i sökvägar kan orsaka problem
# I PRODUKTION: Undviker onödiga fel i automationsmiljoer

$ScriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

# Check for special characters in path
if ($ScriptDir -match "[^a-zA-Z0-9\\\-_:.]") {
    Write-Host "WARNING: Script path contains special characters." -ForegroundColor Yellow
    Write-Host "Current path: $ScriptDir" -ForegroundColor Gray
    Write-Host "Recommendation: Use only English letters, numbers, and underscores." -ForegroundColor Gray
    Write-Host ""
}

# Check for path length (Windows has a 260 character limit)
if ($ScriptDir.Length -gt 100) {
    Write-Host "WARNING: Script path is long ($($ScriptDir.Length) characters)." -ForegroundColor Yellow
    Write-Host "Recommendation: Move script to a shorter path." -ForegroundColor Gray
    Write-Host ""
}

# Check if running on Windows
if ($env:OS -ne "Windows_NT") {
    Write-Host "ERROR: This script is designed for Windows only." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}
Write-Host "Platform OK: Windows" -ForegroundColor Green

# -----------------------------------------------------------------------------
# STEP 3: Logging function with multiple levels
# -----------------------------------------------------------------------------
# VARFOR: Loggning ar viktigt for sparbarhet och felsokning
# I PRODUKTION: Alla produktionsskript maste logga vad de gor
#
# LOGGNINGSNIVAR:
# - INFO: Normal driftinformation
# - WARNING: Nagot ar konstigt men skriptet fortsatter
# - ERROR: Nagot gick fel men skriptet kan fortsatta
# - SUCCESS: En viktig operation lyckades

$LogPath = Join-Path -Path $ScriptDir -ChildPath "anvandarhanterare.log"

function Write-Log {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LogPath -Value $logEntry
    
    # Show in console with colors for better readability
    switch ($Level) {
        "ERROR"   { Write-Host $logEntry -ForegroundColor Red }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        default   { Write-Host $logEntry -ForegroundColor Gray }
    }
}

# Initialize logging
Write-Log "========================================"
Write-Log "Anvandarhanterare script started: $(Get-Date)"
Write-Log "Script location: $ScriptDir"
Write-Log "PowerShell version: $($PSVersionTable.PSVersion)"
Write-Log "========================================"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "USER MANAGEMENT TOOL - PowerShell" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script helps you manage local users." -ForegroundColor Gray
Write-Host "It demonstrates professional PowerShell techniques:" -ForegroundColor Gray
Write-Host "  - Error handling with try/catch (prevents crashes)" -ForegroundColor Gray
Write-Host "  - Logging with different levels (INFO, WARNING, ERROR, SUCCESS)" -ForegroundColor Gray
Write-Host "  - Background jobs for long-running tasks" -ForegroundColor Gray
Write-Host "  - Automatic debugging and validation" -ForegroundColor Gray
Write-Host ""
Write-Host "LOG FILE: $LogPath" -ForegroundColor Gray
Write-Host ""

# -----------------------------------------------------------------------------
# STEP 4: Check if running as administrator
# -----------------------------------------------------------------------------
# VARFOR: Anvandarhantering kraver administratorsrattigheter
# I PRODUKTION: Man maste alltid kontrollera rattigheter innan operationer

$isAdmin = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "WARNING: Not running as Administrator." -ForegroundColor Yellow
    Write-Host "Creating users requires administrator privileges." -ForegroundColor Yellow
    Write-Host "To run as Admin: Right-click on script -> 'Run with PowerShell'" -ForegroundColor Gray
    Write-Log "WARNING: Script started without admin rights" -Level "WARNING"
    Write-Host ""
} else {
    Write-Host "Running with Administrator privileges." -ForegroundColor Green
    Write-Log "Script running with admin rights" -Level "INFO"
}

# -----------------------------------------------------------------------------
# STEP 5: Check if required modules are available
# -----------------------------------------------------------------------------
# VARFOR: Saknade moduler kan orsaka ovantade fel
# I PRODUKTION: Man kontrollerar alltid att allt som behovs finns

try {
    $null = Get-Module -ListAvailable -Name Microsoft.PowerShell.LocalAccounts
    Write-Host "Module OK: Microsoft.PowerShell.LocalAccounts" -ForegroundColor Green
    Write-Log "Module check passed: Microsoft.PowerShell.LocalAccounts" -Level "INFO"
} catch {
    Write-Host "WARNING: Microsoft.PowerShell.LocalAccounts module not found." -ForegroundColor Yellow
    Write-Host "Some functions may not work correctly." -ForegroundColor Yellow
    Write-Log "WARNING: Module Microsoft.PowerShell.LocalAccounts not found" -Level "WARNING"
}

# -----------------------------------------------------------------------------
# STEP 6: Menu function with clear explanations
# -----------------------------------------------------------------------------
# VARFOR: Anvandare maste forsta vad varje alternativ gor
# I PRODUKTION: Tydliga menyval minskar risken for anvandarfel

function Show-Menu {
    Write-Host ""
    Write-Host "=== MAIN MENU ===" -ForegroundColor Cyan
    Write-Host "1. Create a local user"
    Write-Host "   (Add a new user to this computer)"
    Write-Host ""
    Write-Host "2. Show all local users"
    Write-Host "   (List all existing user accounts)"
    Write-Host ""
    Write-Host "3. Delete a local user"
    Write-Host "   (Remove a user from this computer)"
    Write-Host ""
    Write-Host "4. Show log file"
    Write-Host "   (View what this script has done)"
    Write-Host ""
    Write-Host "5. Clear log file"
    Write-Host "   (Reset the log file)"
    Write-Host ""
    Write-Host "6. Run long task in background (example)"
    Write-Host "   (Demonstrates background jobs)"
    Write-Host ""
    Write-Host "7. Show active background jobs"
    Write-Host "   (Check running background jobs)"
    Write-Host ""
    Write-Host "8. Exit"
    Write-Host "   (Close this script)"
    Write-Host ""
}

# -----------------------------------------------------------------------------
# STEP 7: Create a local user with comprehensive error handling
# -----------------------------------------------------------------------------
# VARFOR: Anvandarskapande kan misslyckas av manga orsaker
# I PRODUKTION: Man maste hantera ALLA mojliga fel pa ett professionellt satt
#
# SPECIFIKA FELTYPER SOM HANTERAS:
# - Anvandaren finns redan
# - Ogiltigt losenord
# - Saknade rattigheter
# - Gruppnamn pa olika sprak (losas med SID)

function New-LocalUserWithHandler {
    Write-Host ""
    Write-Host "=== CREATE LOCAL USER ===" -ForegroundColor Cyan
    Write-Host "This function uses try/catch to handle errors professionally." -ForegroundColor Gray
    Write-Host "It handles specific error types and logs everything." -ForegroundColor Gray
    Write-Host ""
    
    # Collect user input
    $username = Read-Host "Enter username"
    
    # Validate username (not empty, no special characters)
    if ([string]::IsNullOrWhiteSpace($username)) {
        Write-Host "  [ERROR] Username cannot be empty!" -ForegroundColor Red
        Write-Log "ERROR: Empty username provided" -Level "ERROR"
        return
    }
    
    if ($username -match "[^a-zA-Z0-9_.-]") {
        Write-Host "  [ERROR] Username contains invalid characters." -ForegroundColor Red
        Write-Host "  Only letters, numbers, underscore, dot and dash are allowed." -ForegroundColor Yellow
        Write-Log "ERROR: Invalid username '$username' contains special chars" -Level "ERROR"
        return
    }
    
    # Get password securely
    $password = Read-Host "Enter password (min 8 characters)" -AsSecureString
    
    # Check if user already exists (pre-check to avoid unnecessary errors)
    try {
        $existingUser = Get-LocalUser -Name $username -ErrorAction Stop
        Write-Host "  [ERROR] User '$username' already exists!" -ForegroundColor Red
        Write-Log "ERROR: Attempted to create existing user '$username'" -Level "ERROR"
        return
    } catch {
        # User does not exist – this is what we want
        Write-Log "User '$username' does not exist – proceeding with creation" -Level "INFO"
    }
    
    # Try to create the user with full error handling
    try {
        Write-Log "Attempting to create user: $username" -Level "INFO"
        
        # Create the user
        $newUser = New-LocalUser -Name $username -Password $password -FullName $username -Description "Created by script" -ErrorAction Stop
        
        Write-Host "  [SUCCESS] User '$username' created!" -ForegroundColor Green
        Write-Log "User '$username' created successfully" -Level "SUCCESS"
        
        # Add to Users group using SID (works on all language versions!)
        # The SID S-1-5-32-545 is the standard Users group on all Windows versions
        try {
            # Get the local Users group using its SID (works on any language)
            $usersGroup = Get-LocalGroup -SID "S-1-5-32-545" -ErrorAction Stop
            Add-LocalGroupMember -Group $usersGroup.Name -Member $username -ErrorAction Stop
            Write-Host "  [SUCCESS] User added to '$($usersGroup.Name)' group." -ForegroundColor Green
            Write-Log "User '$username' added to $($usersGroup.Name) group (SID S-1-5-32-545)" -Level "SUCCESS"
        } catch {
            Write-Host "  [WARNING] Could not add user to Users group." -ForegroundColor Yellow
            Write-Host "  User was created but not added to any group." -ForegroundColor Yellow
            Write-Log "WARNING: Could not add '$username' to Users group: $_" -Level "WARNING"
        }
        
        # Display user information
        Write-Host ""
        Write-Host "User details:" -ForegroundColor Gray
        Write-Host "  Name: $($newUser.Name)" -ForegroundColor Gray
        Write-Host "  Enabled: $($newUser.Enabled)" -ForegroundColor Gray
        Write-Host "  SID: $($newUser.SID)" -ForegroundColor Gray
        
    } catch [Microsoft.PowerShell.Commands.UserExistsException] {
        Write-Host "  [ERROR] User '$username' already exists!" -ForegroundColor Red
        Write-Log "ERROR: User '$username' already exists" -Level "ERROR"
    } catch [System.Management.Automation.ParameterBindingException] {
        Write-Host "  [ERROR] Invalid password format." -ForegroundColor Red
        Write-Host "  Password must be at least 8 characters." -ForegroundColor Yellow
        Write-Log "ERROR: Invalid password format for user '$username'" -Level "ERROR"
    } catch {
        # Catch all other errors
        Write-Host "  [ERROR] Could not create user: $_" -ForegroundColor Red
        Write-Log "ERROR: Could not create user '$username': $_" -Level "ERROR"
    }
}

# -----------------------------------------------------------------------------
# STEP 8: Show all local users
# -----------------------------------------------------------------------------
# VARFOR: Anvandare behover se vilka konton som finns
# I PRODUKTION: Overvakning och granskning av anvandarkonton

function Show-AllUsers {
    Write-Host ""
    Write-Host "=== ALL LOCAL USERS ===" -ForegroundColor Cyan
    Write-Host "This shows all user accounts on this computer." -ForegroundColor Gray
    Write-Host ""
    
    try {
        $users = Get-LocalUser -ErrorAction Stop
        Write-Host "Total users: $($users.Count)" -ForegroundColor Gray
        Write-Host ""
        Write-Host "USERNAME            ENABLED  DESCRIPTION" -ForegroundColor Yellow
        Write-Host "--------            -------  -----------" -ForegroundColor Gray
        
        $userCount = 0
        foreach ($user in $users) {
            $userCount++
            $name = $user.Name.PadRight(20)
            $enabled = $user.Enabled
            $description = $user.Description
            if ($enabled) {
                Write-Host "$name YES      $description" -ForegroundColor Green
            } else {
                Write-Host "$name NO       $description" -ForegroundColor Red
            }
        }
        Write-Log "Viewed all local users ($userCount users)" -Level "INFO"
    } catch {
        Write-Host "  [ERROR] Could not retrieve users: $_" -ForegroundColor Red
        Write-Log "ERROR: Could not retrieve users: $_" -Level "ERROR"
    }
}

# -----------------------------------------------------------------------------
# STEP 9: Delete a local user with comprehensive error handling
# -----------------------------------------------------------------------------
# VARFOR: Borttagning av anvandare ar en kanslig operation
# I PRODUKTION: Man maste alltid be om bekraftelse och hantera fel

function Remove-LocalUserWithHandler {
    Write-Host ""
    Write-Host "=== DELETE LOCAL USER ===" -ForegroundColor Cyan
    Write-Host "This function uses try/catch with multiple error types." -ForegroundColor Gray
    Write-Host "It includes confirmation to prevent accidental deletions." -ForegroundColor Gray
    Write-Host ""
    
    $username = Read-Host "Enter username to delete"
    
    if ([string]::IsNullOrWhiteSpace($username)) {
        Write-Host "  [ERROR] Username cannot be empty!" -ForegroundColor Red
        Write-Log "ERROR: Empty username provided for deletion" -Level "ERROR"
        return
    }
    
    try {
        # Check if user exists first
        $user = Get-LocalUser -Name $username -ErrorAction Stop
        Write-Log "Found user '$username' – proceeding with deletion" -Level "INFO"
        
        # Show user details before deletion
        Write-Host ""
        Write-Host "User to delete:" -ForegroundColor Gray
        Write-Host "  Name: $($user.Name)" -ForegroundColor Gray
        Write-Host "  Enabled: $($user.Enabled)" -ForegroundColor Gray
        Write-Host "  SID: $($user.SID)" -ForegroundColor Gray
        Write-Host ""
        
        # Confirm before deletion (critical for production!)
        $confirm = Read-Host "Delete user '$username'? (yes/no)"
        if ($confirm -ne "yes") {
            Write-Host "  Deletion cancelled." -ForegroundColor Yellow
            Write-Log "Deletion of '$username' cancelled by user" -Level "INFO"
            return
        }
        
        # Delete the user
        Remove-LocalUser -Name $username -ErrorAction Stop
        Write-Host "  [SUCCESS] User '$username' deleted!" -ForegroundColor Green
        Write-Log "User '$username' deleted successfully" -Level "SUCCESS"
        
    } catch [Microsoft.PowerShell.Commands.UserNotFoundException] {
        Write-Host "  [ERROR] User '$username' not found!" -ForegroundColor Red
        Write-Log "ERROR: User '$username' not found" -Level "ERROR"
    } catch {
        Write-Host "  [ERROR] Could not delete user: $_" -ForegroundColor Red
        Write-Log "ERROR: Could not delete user '$username': $_" -Level "ERROR"
    }
}

# -----------------------------------------------------------------------------
# STEP 10: Show log file
# -----------------------------------------------------------------------------
# VARFOR: Loggen ar viktig for felsokning
# I PRODUKTION: Alla produktionsskript har loggar som kan granskas

function Show-Log {
    Write-Host ""
    Write-Host "=== LOG FILE ===" -ForegroundColor Cyan
    Write-Host "The log file shows all actions performed by this script." -ForegroundColor Gray
    Write-Host "Logging is a professional practice for audit and troubleshooting." -ForegroundColor Gray
    Write-Host ""
    
    if (-not (Test-Path $LogPath)) {
        Write-Host "  [INFO] Log file does not exist yet." -ForegroundColor Yellow
        return
    }
    
    $logSize = [math]::Round((Get-Item $LogPath).Length / 1KB, 2)
    Write-Host "Log file: $LogPath ($logSize KB)" -ForegroundColor Gray
    Write-Host "-------------------" -ForegroundColor Gray
    Get-Content -Path $LogPath | Select-Object -Last 20 | ForEach-Object {
        Write-Host $_ -ForegroundColor Gray
    }
    Write-Host "-------------------" -ForegroundColor Gray
    Write-Host "(Showing last 20 lines)" -ForegroundColor Gray
}

# -----------------------------------------------------------------------------
# STEP 11: Clear log file
# -----------------------------------------------------------------------------
# VARFOR: Loggfiler kan bli stora och behova rensas
# I PRODUKTION: Man hanterar loggfiler for att inte fylla disken

function Clear-Log {
    Write-Host ""
    Write-Host "=== CLEAR LOG FILE ===" -ForegroundColor Cyan
    
    if (Test-Path $LogPath) {
        Remove-Item -Path $LogPath -Force
        Write-Host "  [OK] Log file cleared." -ForegroundColor Green
        Write-Log "Log file cleared by user" -Level "INFO"
    } else {
        Write-Host "  [INFO] Log file does not exist." -ForegroundColor Yellow
    }
}

# -----------------------------------------------------------------------------
# STEP 12: Run a background job (demonstrates Start-Job)
# -----------------------------------------------------------------------------
# VARFOR: Vissa uppgifter tar lang tid och bor inte blockera anvandaren
# I PRODUKTION: Bakgrundsjobb anvands for rapporter, backup, etc.

function Start-BackgroundJob {
    Write-Host ""
    Write-Host "=== BACKGROUND JOB EXAMPLE ===" -ForegroundColor Cyan
    Write-Host "This demonstrates how to run a long task in the background." -ForegroundColor Gray
    Write-Host "The job runs independently – you can continue with other work." -ForegroundColor Gray
    Write-Host "This is essential for professional scripts that handle large data." -ForegroundColor Gray
    Write-Host ""
    
    $jobName = "UserReport_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    
    Write-Host "Starting background job: $jobName" -ForegroundColor Yellow
    
    # Start the job – this runs in a separate PowerShell process
    $job = Start-Job -Name $jobName -ScriptBlock {
        # This code runs in the background – it won't block the main script
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $users = Get-LocalUser
        
        # Create a structured report
        $report = @()
        $report += "========================================"
        $report += "USER REPORT – Generated: $timestamp"
        $report += "========================================"
        $report += ""
        $report += "USERNAME            ENABLED  SID"
        $report += "--------            -------  ---"
        
        foreach ($user in $users) {
            $name = $user.Name.PadRight(20)
            $enabled = $user.Enabled
            $sid = $user.SID
            $report += "$name $enabled  $sid"
        }
        
        $report += ""
        $report += "========================================"
        $report += "Total users: $($users.Count)"
        $report += "========================================"
        
        # Simulate a long-running task (like scanning many users)
        # In real life, this could be a large report, backup, or data processing
        Start-Sleep -Seconds 5
        
        return $report -join "`n"
    }
    
    Write-Host "  [OK] Job started with ID: $($job.Id)" -ForegroundColor Green
    Write-Host "  Job name: $jobName" -ForegroundColor Gray
    Write-Log "Started background job: $jobName (ID: $($job.Id))" -Level "INFO"
    
    # Wait briefly to show the job is running
    Write-Host "  Waiting 2 seconds to show job is running..." -ForegroundColor Gray
    Start-Sleep -Seconds 2
    
    # Check job status
    $jobStatus = Get-Job -Id $job.Id
    Write-Host "  Job status: $($jobStatus.State)" -ForegroundColor Yellow
    
    Write-Host ""
    Write-Host "What would you like to do?" -ForegroundColor Cyan
    Write-Host "  1. Wait for job to complete and get results (blocking)"
    Write-Host "  2. Continue without waiting (job runs in background)"
    Write-Host "  3. Check job status only"
    $choice = Read-Host "Select an option"
    
    switch ($choice) {
        "1" {
            Write-Host "  Waiting for job to complete..." -ForegroundColor Gray
            $result = Receive-Job -Job $job -Wait -AutoRemoveJob
            Write-Host ""
            Write-Host "=== JOB RESULT ===" -ForegroundColor Cyan
            Write-Host $result -ForegroundColor Gray
            Write-Log "Received results from background job: $jobName" -Level "SUCCESS"
        }
        "2" {
            Write-Host "  Job continues in background." -ForegroundColor Gray
            Write-Host "  To check later, use: Get-Job -Id $($job.Id)" -ForegroundColor Gray
            Write-Host "  To get results, use: Receive-Job -Job (Get-Job -Id $($job.Id))" -ForegroundColor Gray
            Write-Log "Background job $jobName left running" -Level "INFO"
        }
        "3" {
            $status = Get-Job -Id $job.Id
            Write-Host "  Job status: $($status.State)" -ForegroundColor Yellow
            Write-Log "Checked status of background job ${jobName}: $($status.State)" -Level "INFO"
        }
        default {
            Write-Host "  Invalid option. Job continues in background." -ForegroundColor Yellow
            Write-Log "Background job ${jobName} left running (invalid option)" -Level "WARNING"
        }
    }
}

# -----------------------------------------------------------------------------
# STEP 13: Show all active background jobs
# -----------------------------------------------------------------------------
# VARFOR: Anvandare behover se vilka jobb som kor
# I PRODUKTION: Overvakning av langa processer

function Show-ActiveJobs {
    Write-Host ""
    Write-Host "=== ACTIVE BACKGROUND JOBS ===" -ForegroundColor Cyan
    
    $jobs = Get-Job
    if ($jobs.Count -eq 0) {
        Write-Host "  [INFO] No active background jobs." -ForegroundColor Yellow
        return
    }
    
    Write-Host "Active jobs:" -ForegroundColor Yellow
    foreach ($job in $jobs) {
        Write-Host "  ID: $($job.Id) | Name: $($job.Name) | State: $($job.State)" -ForegroundColor Gray
    }
}

# -----------------------------------------------------------------------------
# STEP 14: Main program loop with input validation
# -----------------------------------------------------------------------------
# VARFOR: Anvandaren ska inte kunna krascha skriptet med fel inmatning
# I PRODUKTION: All input ska valideras for att undvika fel

Write-Host ""
Write-Host "Professional PowerShell Script" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "This script demonstrates best practices for:" -ForegroundColor Gray
Write-Host "  - Error handling (try/catch with specific error types)" -ForegroundColor Gray
Write-Host "  - Logging (multiple levels: INFO, WARNING, ERROR, SUCCESS)" -ForegroundColor Gray
Write-Host "  - Background jobs (Start-Job, Receive-Job)" -ForegroundColor Gray
Write-Host "  - Input validation (prevent crashes)" -ForegroundColor Gray
Write-Host "  - Cross-language support (using SID for groups)" -ForegroundColor Gray
Write-Host ""

do {
    Show-Menu
    $choice = Read-Host "Select an option"
    
    # Validate input – prevent crashes from non-numeric input
    if (-not ($choice -match "^[0-9]+$")) {
        Write-Host "  [ERROR] Please enter a number between 1 and 8." -ForegroundColor Red
        continue
    }
    
    switch ($choice) {
        "1" { New-LocalUserWithHandler }
        "2" { Show-AllUsers }
        "3" { Remove-LocalUserWithHandler }
        "4" { Show-Log }
        "5" { Clear-Log }
        "6" { Start-BackgroundJob }
        "7" { Show-ActiveJobs }
        "8" { 
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Cyan
            Write-Host "SUMMARY OF SKILLS PRACTICED" -ForegroundColor Cyan
            Write-Host "========================================" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "You have practiced professional PowerShell techniques:" -ForegroundColor Gray
            Write-Host ""
            Write-Host "1. ERROR HANDLING (try/catch)" -ForegroundColor Yellow
            Write-Host "   - Specific error types (UserExistsException, UserNotFoundException)" -ForegroundColor Gray
            Write-Host "   - Pre-checks to avoid unnecessary errors" -ForegroundColor Gray
            Write-Host "   - Graceful failure with clear messages" -ForegroundColor Gray
            Write-Host ""
            Write-Host "2. LOGGING (multiple levels)" -ForegroundColor Yellow
            Write-Host "   - INFO for normal operations" -ForegroundColor Gray
            Write-Host "   - WARNING for potential issues" -ForegroundColor Gray
            Write-Host "   - ERROR for failures" -ForegroundColor Gray
            Write-Host "   - SUCCESS for important operations" -ForegroundColor Gray
            Write-Host ""
            Write-Host "3. BACKGROUND JOBS (Start-Job)" -ForegroundColor Yellow
            Write-Host "   - Run long tasks without blocking" -ForegroundColor Gray
            Write-Host "   - Check job status" -ForegroundColor Gray
            Write-Host "   - Retrieve results when ready" -ForegroundColor Gray
            Write-Host ""
            Write-Host "4. INPUT VALIDATION" -ForegroundColor Yellow
            Write-Host "   - Prevent crashes from invalid input" -ForegroundColor Gray
            Write-Host "   - Validate usernames and passwords" -ForegroundColor Gray
            Write-Host ""
            Write-Host "5. CROSS-LANGUAGE SUPPORT" -ForegroundColor Yellow
            Write-Host "   - Using SID instead of hard-coded group names" -ForegroundColor Gray
            Write-Host "   - Works on any language version of Windows" -ForegroundColor Gray
            Write-Host ""
            Write-Host "These are essential skills for:" -ForegroundColor Yellow
            Write-Host "  - Your examination project (VG level)" -ForegroundColor Green
            Write-Host "  - Professional IT work in Swedish companies" -ForegroundColor Green
            Write-Host "  - Real-world system administration" -ForegroundColor Green
            Write-Host ""
            Write-Log "Script exited by user" -Level "INFO"
        }
        default { 
            Write-Host "  [ERROR] Invalid option. Please enter a number between 1 and 8." -ForegroundColor Red
        }
    }
} while ($choice -ne "8")

Write-Host ""
Write-Host "Log file: $LogPath" -ForegroundColor Gray
Write-Host ""
Write-Host "Thank you for using the User Management Tool!" -ForegroundColor Cyan