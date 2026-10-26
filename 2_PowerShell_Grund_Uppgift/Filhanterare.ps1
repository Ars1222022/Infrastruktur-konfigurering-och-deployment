# ============================================
# Filhanterare.ps1 – Enkelt filhanteringsverktyg
# ============================================

# -----------------------------------------------------------------------------
# STEP 1: Check PowerShell version
# -----------------------------------------------------------------------------

if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "ERROR: This script requires PowerShell 7 or higher." -ForegroundColor Red
    Write-Host "Current version: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
    Write-Host "Install PowerShell 7 from: https://aka.ms/powershell" -ForegroundColor Cyan
    Read-Host "Press Enter to exit"
    exit
}

Write-Host "PowerShell version OK: $($PSVersionTable.PSVersion)" -ForegroundColor Green

# -----------------------------------------------------------------------------
# STEP 2: Set script directory (all files will be in this folder)
# -----------------------------------------------------------------------------

# Get the folder where this script is located
$ScriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

# Create a subfolder for our project files
$ProjectDir = Join-Path -Path $ScriptDir -ChildPath "ProjectFiles"

# Create the project folder if it doesn't exist
if (-not (Test-Path $ProjectDir)) {
    New-Item -Path $ProjectDir -ItemType Directory -Force | Out-Null
    Write-Host "Created project folder: $ProjectDir" -ForegroundColor Gray
}

# Set log file path (in the same folder as the script)
$LogPath = Join-Path -Path $ScriptDir -ChildPath "filhanterare.log"

# -----------------------------------------------------------------------------
# STEP 3: Logging function
# -----------------------------------------------------------------------------

function Write-Log {
    param($Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp - $Message"
    Add-Content -Path $LogPath -Value $logEntry
}

# -----------------------------------------------------------------------------
# STEP 4: Initialize log
# -----------------------------------------------------------------------------

Write-Log "========================================"
Write-Log "Script started: $(Get-Date)"
Write-Log "Script location: $ScriptDir"
Write-Log "Project folder: $ProjectDir"
Write-Log "========================================"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "FILHANTERARE - PowerShell File Manager" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "All files will be created in:" -ForegroundColor Yellow
Write-Host "  $ProjectDir" -ForegroundColor Gray
Write-Host ""
Write-Host "Log file: $LogPath" -ForegroundColor Gray
Write-Host ""

# -----------------------------------------------------------------------------
# STEP 5: Menu function
# -----------------------------------------------------------------------------

function Show-Menu {
    Write-Host ""
    Write-Host "=== MAIN MENU ===" -ForegroundColor Cyan
    Write-Host "1. Create folders"
    Write-Host "2. Copy files"
    Write-Host "3. Show folder contents"
    Write-Host "4. Delete files"
    Write-Host "5. Show log file"
    Write-Host "6. Clear log file"
    Write-Host "7. Create sample files"
    Write-Host "8. Exit"
    Write-Host ""
}

# -----------------------------------------------------------------------------
# STEP 6: Create folders function
# -----------------------------------------------------------------------------

function Create-Folders {
    Write-Host ""
    Write-Host "=== CREATE FOLDERS ===" -ForegroundColor Cyan
    Write-Host "Enter folder names separated by commas (e.g. Data,Backup,Logs):" -ForegroundColor Yellow
    $input = Read-Host
    $folders = $input -split ","

    foreach ($folder in $folders) {
        $folder = $folder.Trim()
        $folderPath = Join-Path -Path $ProjectDir -ChildPath $folder
        
        if (Test-Path $folderPath) {
            Write-Host "  [WARNING] Folder '$folder' already exists." -ForegroundColor Yellow
            Write-Log "WARNING: Folder '$folder' already exists"
        } else {
            New-Item -Path $folderPath -ItemType Directory -Force | Out-Null
            Write-Host "  [OK] Created folder: $folder" -ForegroundColor Green
            Write-Log "Created folder: $folder"
        }
    }
}

# -----------------------------------------------------------------------------
# STEP 7: Create sample files function
# -----------------------------------------------------------------------------

function Create-SampleFiles {
    Write-Host ""
    Write-Host "=== CREATE SAMPLE FILES ===" -ForegroundColor Cyan
    Write-Host "Enter folder name (within ProjectFiles):" -ForegroundColor Yellow
    $folder = Read-Host
    $folderPath = Join-Path -Path $ProjectDir -ChildPath $folder
    
    if (-not (Test-Path $folderPath)) {
        Write-Host "  Creating folder: $folder" -ForegroundColor Gray
        New-Item -Path $folderPath -ItemType Directory -Force | Out-Null
        Write-Log "Created folder: $folder"
    }
    
    Write-Host "How many sample files to create?" -ForegroundColor Yellow
    $count = Read-Host
    
    for ($i = 1; $i -le $count; $i++) {
        $fileName = "sample_$i.txt"
        $filePath = Join-Path -Path $folderPath -ChildPath $fileName
        $content = "This is sample file number $i`nCreated: $(Get-Date)"
        Set-Content -Path $filePath -Value $content
        Write-Host "  Created: $fileName" -ForegroundColor Gray
        Write-Log "Created sample file: $fileName"
    }
    Write-Host "  [OK] Created $count sample file(s)!" -ForegroundColor Green
}

# -----------------------------------------------------------------------------
# STEP 8: Copy files function
# -----------------------------------------------------------------------------

function Copy-Files {
    Write-Host ""
    Write-Host "=== COPY FILES ===" -ForegroundColor Cyan
    Write-Host "Source folder (within ProjectFiles):" -ForegroundColor Yellow
    $source = Read-Host
    $sourcePath = Join-Path -Path $ProjectDir -ChildPath $source
    
    if (-not (Test-Path $sourcePath)) {
        Write-Host "  [ERROR] Source folder does not exist!" -ForegroundColor Red
        Write-Log "ERROR: Source folder '$source' does not exist"
        return
    }
    
    Write-Host "Destination folder (within ProjectFiles):" -ForegroundColor Yellow
    $destination = Read-Host
    $destPath = Join-Path -Path $ProjectDir -ChildPath $destination
    
    if (-not (Test-Path $destPath)) {
        Write-Host "  Creating destination folder..." -ForegroundColor Gray
        New-Item -Path $destPath -ItemType Directory -Force | Out-Null
        Write-Log "Created destination folder: $destination"
    }
    
    $files = Get-ChildItem -Path $sourcePath -File
    if ($files.Count -eq 0) {
        Write-Host "  [WARNING] No files to copy!" -ForegroundColor Yellow
        Write-Log "WARNING: No files in source folder '$source'"
        return
    }
    
    foreach ($file in $files) {
        Copy-Item -Path $file.FullName -Destination $destPath -Force
        Write-Host "  Copied: $($file.Name)" -ForegroundColor Gray
        Write-Log "Copied: $($file.Name) from $source to $destination"
    }
    Write-Host "  [OK] Copied $($files.Count) file(s)!" -ForegroundColor Green
}

# -----------------------------------------------------------------------------
# STEP 9: Show folder contents function
# -----------------------------------------------------------------------------

function Show-Contents {
    Write-Host ""
    Write-Host "=== SHOW FOLDER CONTENTS ===" -ForegroundColor Cyan
    Write-Host "Enter folder name (within ProjectFiles, or leave empty for root):" -ForegroundColor Yellow
    $folder = Read-Host
    if ($folder -eq "") { $folder = "." }
    
    $folderPath = Join-Path -Path $ProjectDir -ChildPath $folder
    
    if (-not (Test-Path $folderPath)) {
        Write-Host "  [ERROR] Folder does not exist!" -ForegroundColor Red
        Write-Log "ERROR: Folder '$folder' does not exist"
        return
    }
    
    $items = Get-ChildItem -Path $folderPath
    if ($items.Count -eq 0) {
        Write-Host "  [INFO] Folder is empty." -ForegroundColor Yellow
        return
    }
    
    Write-Host ""
    Write-Host "Contents of: $folder" -ForegroundColor Cyan
    Write-Host "-------------------" -ForegroundColor Gray
    
    foreach ($item in $items) {
        if ($item.PSIsContainer) {
            Write-Host "  [DIR]  $($item.Name)" -ForegroundColor Yellow
        } else {
            $size = [math]::Round($item.Length / 1KB, 2)
            Write-Host "  [FILE] $($item.Name) ($size KB)" -ForegroundColor Gray
        }
    }
    Write-Host "-------------------" -ForegroundColor Gray
    Write-Log "Viewed contents of: $folder"
}

# -----------------------------------------------------------------------------
# STEP 10: Delete files function
# -----------------------------------------------------------------------------

function Delete-Files {
    Write-Host ""
    Write-Host "=== DELETE FILES ===" -ForegroundColor Cyan
    Write-Host "Enter folder name (within ProjectFiles):" -ForegroundColor Yellow
    $folder = Read-Host
    $folderPath = Join-Path -Path $ProjectDir -ChildPath $folder
    
    if (-not (Test-Path $folderPath)) {
        Write-Host "  [ERROR] Folder does not exist!" -ForegroundColor Red
        return
    }
    
    $files = Get-ChildItem -Path $folderPath -File
    if ($files.Count -eq 0) {
        Write-Host "  [INFO] No files to delete." -ForegroundColor Yellow
        return
    }
    
    Write-Host ""
    Write-Host "Files in this folder:" -ForegroundColor Yellow
    $i = 1
    foreach ($file in $files) {
        $size = [math]::Round($file.Length / 1KB, 2)
        Write-Host "$i. $($file.Name) ($size KB)" -ForegroundColor Gray
        $i++
    }
    Write-Host ""
    Write-Host "Enter file number to delete (or 0 for all files):" -ForegroundColor Yellow
    $choice = Read-Host
    
    if ($choice -eq "0") {
        foreach ($file in $files) {
            Remove-Item -Path $file.FullName -Force
            Write-Host "  Deleted: $($file.Name)" -ForegroundColor Red
            Write-Log "Deleted: $($file.Name)"
        }
        Write-Host "  [OK] All files deleted!" -ForegroundColor Green
    } else {
        $index = [int]$choice - 1
        if ($index -ge 0 -and $index -lt $files.Count) {
            Remove-Item -Path $files[$index].FullName -Force
            Write-Host "  Deleted: $($files[$index].Name)" -ForegroundColor Red
            Write-Log "Deleted: $($files[$index].Name)"
        } else {
            Write-Host "  [ERROR] Invalid choice!" -ForegroundColor Red
        }
    }
}

# -----------------------------------------------------------------------------
# STEP 11: Show log file function
# -----------------------------------------------------------------------------

function Show-Log {
    Write-Host ""
    Write-Host "=== LOG FILE ===" -ForegroundColor Cyan
    
    if (-not (Test-Path $LogPath)) {
        Write-Host "  [INFO] Log file does not exist yet." -ForegroundColor Yellow
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

# -----------------------------------------------------------------------------
# STEP 12: Clear log file function
# -----------------------------------------------------------------------------

function Clear-Log {
    Write-Host ""
    Write-Host "=== CLEAR LOG FILE ===" -ForegroundColor Cyan
    
    if (Test-Path $LogPath) {
        Remove-Item -Path $LogPath -Force
        Write-Host "  [OK] Log file cleared." -ForegroundColor Green
        Write-Log "Log file cleared by user"
    } else {
        Write-Host "  [INFO] Log file does not exist." -ForegroundColor Yellow
    }
}
# ============================================
# Filhanterare.ps1 – Enkelt filhanteringsverktyg
# ============================================

# -----------------------------------------------------------------------------
# STEP 1: Check PowerShell version
# -----------------------------------------------------------------------------

if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "ERROR: This script requires PowerShell 7 or higher." -ForegroundColor Red
    Write-Host "Current version: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
    Write-Host "Install PowerShell 7 from: https://aka.ms/powershell" -ForegroundColor Cyan
    Read-Host "Press Enter to exit"
    exit
}

Write-Host "PowerShell version OK: $($PSVersionTable.PSVersion)" -ForegroundColor Green

# -----------------------------------------------------------------------------
# STEP 2: Set script directory (all files will be in this folder)
# -----------------------------------------------------------------------------

# Get the folder where this script is located
$ScriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

# Create a subfolder for our project files
$ProjectDir = Join-Path -Path $ScriptDir -ChildPath "ProjectFiles"

# Create the project folder if it doesn't exist
if (-not (Test-Path $ProjectDir)) {
    New-Item -Path $ProjectDir -ItemType Directory -Force | Out-Null
    Write-Host "Created project folder: $ProjectDir" -ForegroundColor Gray
}

# Set log file path (in the same folder as the script)
$LogPath = Join-Path -Path $ScriptDir -ChildPath "filhanterare.log"

# -----------------------------------------------------------------------------
# STEP 3: Logging function
# -----------------------------------------------------------------------------

function Write-Log {
    param($Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp - $Message"
    Add-Content -Path $LogPath -Value $logEntry
}

# -----------------------------------------------------------------------------
# STEP 4: Initialize log
# -----------------------------------------------------------------------------

Write-Log "========================================"
Write-Log "Script started: $(Get-Date)"
Write-Log "Script location: $ScriptDir"
Write-Log "Project folder: $ProjectDir"
Write-Log "========================================"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "FILHANTERARE - PowerShell File Manager" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "All files will be created in:" -ForegroundColor Yellow
Write-Host "  $ProjectDir" -ForegroundColor Gray
Write-Host ""
Write-Host "Log file: $LogPath" -ForegroundColor Gray
Write-Host ""

# -----------------------------------------------------------------------------
# STEP 5: Menu function
# -----------------------------------------------------------------------------

function Show-Menu {
    Write-Host ""
    Write-Host "=== MAIN MENU ===" -ForegroundColor Cyan
    Write-Host "1. Create folders"
    Write-Host "2. Copy files"
    Write-Host "3. Show folder contents"
    Write-Host "4. Remove files"
    Write-Host "5. Show log file"
    Write-Host "6. Clear log file"
    Write-Host "7. Create sample files"
    Write-Host "8. Exit"
    Write-Host ""
}

# -----------------------------------------------------------------------------
# STEP 6: Create folders function
# -----------------------------------------------------------------------------

function New-Folders {
    Write-Host ""
    Write-Host "=== CREATE FOLDERS ===" -ForegroundColor Cyan
    Write-Host "Enter folder names separated by commas (e.g. Data,Backup,Logs):" -ForegroundColor Yellow
    $folderInput = Read-Host
    $folders = $folderInput -split ","

    foreach ($folder in $folders) {
        $folder = $folder.Trim()
        $folderPath = Join-Path -Path $ProjectDir -ChildPath $folder
        
        if (Test-Path $folderPath) {
            Write-Host "  [WARNING] Folder '$folder' already exists." -ForegroundColor Yellow
            Write-Log "WARNING: Folder '$folder' already exists"
        } else {
            New-Item -Path $folderPath -ItemType Directory -Force | Out-Null
            Write-Host "  [OK] Created folder: $folder" -ForegroundColor Green
            Write-Log "Created folder: $folder"
        }
    }
}

# -----------------------------------------------------------------------------
# STEP 7: Create sample files function
# -----------------------------------------------------------------------------

function New-SampleFiles {
    Write-Host ""
    Write-Host "=== CREATE SAMPLE FILES ===" -ForegroundColor Cyan
    Write-Host "Enter folder name (within ProjectFiles):" -ForegroundColor Yellow
    $folder = Read-Host
    $folderPath = Join-Path -Path $ProjectDir -ChildPath $folder
    
    if (-not (Test-Path $folderPath)) {
        Write-Host "  Creating folder: $folder" -ForegroundColor Gray
        New-Item -Path $folderPath -ItemType Directory -Force | Out-Null
        Write-Log "Created folder: $folder"
    }
    
    Write-Host "How many sample files to create?" -ForegroundColor Yellow
    $count = Read-Host
    
    for ($i = 1; $i -le $count; $i++) {
        $fileName = "sample_$i.txt"
        $filePath = Join-Path -Path $folderPath -ChildPath $fileName
        $content = "This is sample file number $i`nCreated: $(Get-Date)"
        Set-Content -Path $filePath -Value $content
        Write-Host "  Created: $fileName" -ForegroundColor Gray
        Write-Log "Created sample file: $fileName"
    }
    Write-Host "  [OK] Created $count sample file(s)!" -ForegroundColor Green
}

# -----------------------------------------------------------------------------
# STEP 8: Copy files function
# -----------------------------------------------------------------------------

function Copy-Files {
    Write-Host ""
    Write-Host "=== COPY FILES ===" -ForegroundColor Cyan
    Write-Host "Source folder (within ProjectFiles):" -ForegroundColor Yellow
    $source = Read-Host
    $sourcePath = Join-Path -Path $ProjectDir -ChildPath $source
    
    if (-not (Test-Path $sourcePath)) {
        Write-Host "  [ERROR] Source folder does not exist!" -ForegroundColor Red
        Write-Log "ERROR: Source folder '$source' does not exist"
        return
    }
    
    Write-Host "Destination folder (within ProjectFiles):" -ForegroundColor Yellow
    $destination = Read-Host
    $destPath = Join-Path -Path $ProjectDir -ChildPath $destination
    
    if (-not (Test-Path $destPath)) {
        Write-Host "  Creating destination folder..." -ForegroundColor Gray
        New-Item -Path $destPath -ItemType Directory -Force | Out-Null
        Write-Log "Created destination folder: $destination"
    }
    
    $files = Get-ChildItem -Path $sourcePath -File
    if ($files.Count -eq 0) {
        Write-Host "  [WARNING] No files to copy!" -ForegroundColor Yellow
        Write-Log "WARNING: No files in source folder '$source'"
        return
    }
    
    foreach ($file in $files) {
        Copy-Item -Path $file.FullName -Destination $destPath -Force
        Write-Host "  Copied: $($file.Name)" -ForegroundColor Gray
        Write-Log "Copied: $($file.Name) from $source to $destination"
    }
    Write-Host "  [OK] Copied $($files.Count) file(s)!" -ForegroundColor Green
}

# -----------------------------------------------------------------------------
# STEP 9: Show folder contents function
# -----------------------------------------------------------------------------

function Show-Contents {
    Write-Host ""
    Write-Host "=== SHOW FOLDER CONTENTS ===" -ForegroundColor Cyan
    Write-Host "Enter folder name (within ProjectFiles, or leave empty for root):" -ForegroundColor Yellow
    $folder = Read-Host
    if ($folder -eq "") { $folder = "." }
    
    $folderPath = Join-Path -Path $ProjectDir -ChildPath $folder
    
    if (-not (Test-Path $folderPath)) {
        Write-Host "  [ERROR] Folder does not exist!" -ForegroundColor Red
        Write-Log "ERROR: Folder '$folder' does not exist"
        return
    }
    
    $items = Get-ChildItem -Path $folderPath
    if ($items.Count -eq 0) {
        Write-Host "  [INFO] Folder is empty." -ForegroundColor Yellow
        return
    }
    
    Write-Host ""
    Write-Host "Contents of: $folder" -ForegroundColor Cyan
    Write-Host "-------------------" -ForegroundColor Gray
    
    foreach ($item in $items) {
        if ($item.PSIsContainer) {
            Write-Host "  [DIR]  $($item.Name)" -ForegroundColor Yellow
        } else {
            $size = [math]::Round($item.Length / 1KB, 2)
            Write-Host "  [FILE] $($item.Name) ($size KB)" -ForegroundColor Gray
        }
    }
    Write-Host "-------------------" -ForegroundColor Gray
    Write-Log "Viewed contents of: $folder"
}

# -----------------------------------------------------------------------------
# STEP 10: Remove files function
# -----------------------------------------------------------------------------

function Remove-Files {
    Write-Host ""
    Write-Host "=== REMOVE FILES ===" -ForegroundColor Cyan
    Write-Host "Enter folder name (within ProjectFiles):" -ForegroundColor Yellow
    $folder = Read-Host
    $folderPath = Join-Path -Path $ProjectDir -ChildPath $folder
    
    if (-not (Test-Path $folderPath)) {
        Write-Host "  [ERROR] Folder does not exist!" -ForegroundColor Red
        return
    }
    
    $files = Get-ChildItem -Path $folderPath -File
    if ($files.Count -eq 0) {
        Write-Host "  [INFO] No files to remove." -ForegroundColor Yellow
        return
    }
    
    Write-Host ""
    Write-Host "Files in this folder:" -ForegroundColor Yellow
    $i = 1
    foreach ($file in $files) {
        $size = [math]::Round($file.Length / 1KB, 2)
        Write-Host "$i. $($file.Name) ($size KB)" -ForegroundColor Gray
        $i++
    }
    Write-Host ""
    Write-Host "Enter file number to remove (or 0 for all files):" -ForegroundColor Yellow
    $choice = Read-Host
    
    if ($choice -eq "0") {
        foreach ($file in $files) {
            Remove-Item -Path $file.FullName -Force
            Write-Host "  Removed: $($file.Name)" -ForegroundColor Red
            Write-Log "Removed: $($file.Name)"
        }
        Write-Host "  [OK] All files removed!" -ForegroundColor Green
    } else {
        $index = [int]$choice - 1
        if ($index -ge 0 -and $index -lt $files.Count) {
            Remove-Item -Path $files[$index].FullName -Force
            Write-Host "  Removed: $($files[$index].Name)" -ForegroundColor Red
            Write-Log "Removed: $($files[$index].Name)"
        } else {
            Write-Host "  [ERROR] Invalid choice!" -ForegroundColor Red
        }
    }
}

# -----------------------------------------------------------------------------
# STEP 11: Show log file function
# -----------------------------------------------------------------------------

function Show-Log {
    Write-Host ""
    Write-Host "=== LOG FILE ===" -ForegroundColor Cyan
    
    if (-not (Test-Path $LogPath)) {
        Write-Host "  [INFO] Log file does not exist yet." -ForegroundColor Yellow
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

# -----------------------------------------------------------------------------
# STEP 12: Clear log file function
# -----------------------------------------------------------------------------

function Clear-Log {
    Write-Host ""
    Write-Host "=== CLEAR LOG FILE ===" -ForegroundColor Cyan
    
    if (Test-Path $LogPath) {
        Remove-Item -Path $LogPath -Force
        Write-Host "  [OK] Log file cleared." -ForegroundColor Green
        Write-Log "Log file cleared by user"
    } else {
        Write-Host "  [INFO] Log file does not exist." -ForegroundColor Yellow
    }
}

# -----------------------------------------------------------------------------
# STEP 13: Main program loop
# -----------------------------------------------------------------------------

do {
    Show-Menu
    $choice = Read-Host "Select an option"
    
    switch ($choice) {
        "1" { New-Folders }
        "2" { Copy-Files }
        "3" { Show-Contents }
        "4" { Remove-Files }
        "5" { Show-Log }
        "6" { Clear-Log }
        "7" { New-SampleFiles }
        "8" { 
            Write-Host ""
            Write-Host "Exiting..." -ForegroundColor Cyan
            Write-Log "Script exited by user"
        }
        default { 
            Write-Host "  [ERROR] Invalid option. Please try again." -ForegroundColor Red
        }
    }
} while ($choice -ne "8")

Write-Host ""
Write-Host "Log file: $LogPath" -ForegroundColor Gray
# -----------------------------------------------------------------------------
# STEP 13: Main program loop
# -----------------------------------------------------------------------------

do {
    Show-Menu
    $choice = Read-Host "Select an option"
    
    switch ($choice) {
        "1" { Create-Folders }
        "2" { Copy-Files }
        "3" { Show-Contents }
        "4" { Delete-Files }
        "5" { Show-Log }
        "6" { Clear-Log }
        "7" { Create-SampleFiles }
        "8" { 
            Write-Host ""
            Write-Host "Exiting..." -ForegroundColor Cyan
            Write-Log "Script exited by user"
        }
        default { 
            Write-Host "  [ERROR] Invalid option. Please try again." -ForegroundColor Red
        }
    }
} while ($choice -ne "8")

Write-Host ""
Write-Host "Log file: $LogPath" -ForegroundColor Gray