#!/usr/bin/env python3
# ============================================
# orchestrator.py – Python Orchestration Example
# ============================================
#
# WHAT THIS SCRIPT DOES:
# 1. Checks your system (Python, PowerShell, required modules)
# 2. Creates a PowerShell script automatically
# 3. Runs the PowerShell script from Python
# 4. Verifies the results
# 5. Logs everything to a file
#
# ALL FILES ARE CREATED IN THE SAME FOLDER AS THIS SCRIPT
# ============================================

import os
import sys
import json
import subprocess
import shutil
import logging
from datetime import datetime

# ============================================
# STEP 1: System Check
# ============================================
print("=" * 70)
print("  SYSTEM CHECK - Verifying your environment")
print("=" * 70)
print("")
print("BEFORE WE START: This script will check that you have everything you need.")
print("It verifies Python version, Windows, PowerShell, and required modules.")
print("")

# Get the script directory (all files will be created here)
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
os.chdir(SCRIPT_DIR)
print(f"  Working directory: {SCRIPT_DIR}")
print("")

# Check Python version
print("  [1] Checking Python version...")
python_version = sys.version_info
if python_version.major >= 3 and python_version.minor >= 8:
    print(f"      OK: Python {python_version.major}.{python_version.minor} found")
else:
    print(f"      ERROR: Python 3.8+ required (you have {python_version.major}.{python_version.minor})")
    input("Press Enter to exit...")
    sys.exit(1)

# Check if running on Windows
print("  [2] Checking platform...")
if sys.platform == "win32":
    print("      OK: Windows detected")
else:
    print("      ERROR: This script requires Windows")
    input("Press Enter to exit...")
    sys.exit(1)

# Check if PowerShell is available
print("  [3] Checking PowerShell...")
try:
    result = subprocess.run(["powershell", "-Command", "$PSVersionTable.PSVersion"], 
                          capture_output=True, text=True, timeout=10)
    if result.returncode == 0:
        print("      OK: PowerShell detected")
    else:
        print("      WARNING: PowerShell not detected")
except:
    print("      WARNING: PowerShell not available")

# Check if required Python modules are installed
print("  [4] Checking required Python modules...")
required_modules = ["json", "subprocess", "shutil", "logging", "os"]
missing_modules = []
for module in required_modules:
    try:
        __import__(module)
        print(f"      OK: {module}")
    except ImportError:
        print(f"      ERROR: {module} not found")
        missing_modules.append(module)

if missing_modules:
    print(f"\n  ERROR: Missing modules: {', '.join(missing_modules)}")
    print("  Please install them with: pip install <module>")
    input("Press Enter to exit...")
    sys.exit(1)

print("")
print("  ALL SYSTEM CHECKS PASSED! You are ready to continue.")
print("")

input("  Press Enter to continue...")
print("")

# ============================================
# STEP 2: Set Up Logging
# ============================================
LOG_FILE = os.path.join(SCRIPT_DIR, "orchestrator.log")

logging.basicConfig(
    filename=LOG_FILE,
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S"
)

console = logging.StreamHandler()
console.setLevel(logging.INFO)
console.setFormatter(logging.Formatter("%(asctime)s - %(levelname)s - %(message)s"))
logging.getLogger().addHandler(console)

logging.info("=" * 70)
logging.info("ORCHESTRATOR SCRIPT STARTED")
logging.info(f"Script location: {SCRIPT_DIR}")
logging.info("=" * 70)

print("=" * 70)
print("  PYTHON ORCHESTRATOR - Automating System Administration")
print("=" * 70)
print("")
print("WHAT IS ORCHESTRATION?")
print("  Orchestration means controlling multiple tools from one place.")
print("  In this script, Python controls PowerShell to create files.")
print("")
print("WHY IS THIS IMPORTANT?")
print("  In real IT work, you use many different tools.")
print("  Python is the 'glue' that connects them together.")
print("  This is how you automate complex tasks.")
print("")
print(f"  Log file: {LOG_FILE}")
print("")
input("  Press Enter to continue...")
print("")

# ============================================
# STEP 3: Create PowerShell Script
# ============================================
print("=" * 70)
print("  STEP 1: CREATING A POWERSHELL SCRIPT AUTOMATICALLY")
print("=" * 70)
print("")
print("  WHAT IS HAPPENING HERE?")
print("  Python is writing a PowerShell script for you.")
print("  You don't need to write it manually!")
print("")
print("  WHY IS THIS IMPORTANT?")
print("  In real work, you might need to generate scripts based on data.")
print("  For example: create 100 users from a list.")
print("  Python can generate the script automatically.")
print("")

logging.info("Creating PowerShell script")

ps_script = '''
# ============================================
# generated_script.ps1 – Created by Python orchestrator
# ============================================
# This script creates a simple file to demonstrate automation.
# It was generated and run by Python.

$ErrorActionPreference = "Stop"
$logFile = "generated_script.log"

function Write-Log {
    param($Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] $Message"
    Add-Content -Path $logFile -Value $logEntry
    Write-Host $logEntry
}

Write-Log "========================================"
Write-Log "GENERATED SCRIPT STARTED"
Write-Log "========================================"

# Create a test folder
$testFolder = "TestFolder"
if (-not (Test-Path $testFolder)) {
    New-Item -Path $testFolder -ItemType Directory
    Write-Log "Created folder: $testFolder"
} else {
    Write-Log "Folder already exists: $testFolder"
}

# Create a test file with UTF-8 encoding
$testFile = Join-Path $testFolder "test_file.txt"
$content = @"
This file was created by PowerShell
Generated by Python orchestrator
Timestamp: $(Get-Date)
"@
$content | Out-File -FilePath $testFile -Encoding UTF8
Write-Log "Created file: $testFile"

# List the contents
Write-Log "Folder contents:"
Get-ChildItem -Path $testFolder | ForEach-Object {
    Write-Log "  $($_.Name) ($($_.Length) bytes)"
}

Write-Log "========================================"
Write-Log "GENERATED SCRIPT COMPLETED"
Write-Log "========================================"

# Return results as JSON
$results = @{
    folder_created = $true
    file_created = $true
    folder_path = $testFolder
    file_path = $testFile
}
$results | ConvertTo-Json
'''

PS_FILE = os.path.join(SCRIPT_DIR, "generated_script.ps1")
with open(PS_FILE, "w", encoding="utf-8") as f:
    f.write(ps_script)

print(f"  [OK] Created: {PS_FILE}")
print("")
print("  WHAT JUST HAPPENED?")
print("  Python wrote a PowerShell script and saved it as a file.")
print("  This script will create a folder and a file.")
print("")
logging.info(f"PowerShell script created: {PS_FILE}")

input("  Press Enter to continue...")
print("")

# ============================================
# STEP 4: Run PowerShell Script
# ============================================
print("=" * 70)
print("  STEP 2: RUNNING POWERSHELL FROM PYTHON")
print("=" * 70)
print("")
print("  WHAT IS HAPPENING HERE?")
print("  Python is using 'subprocess' to run the PowerShell script.")
print("  This is how Python controls other programs.")
print("")
print("  WHY IS THIS IMPORTANT?")
print("  In real IT work, you need to control many tools.")
print("  Python can run: PowerShell, Terraform, Ansible, and more.")
print("")

logging.info("Running PowerShell script")

try:
    result = subprocess.run(
        ["powershell", "-ExecutionPolicy", "Bypass", "-File", PS_FILE],
        capture_output=True,
        text=True,
        timeout=60
    )
    
    if result.stdout:
        print("  OUTPUT FROM POWERSHELL:")
        print("  " + "-" * 60)
        print(result.stdout)
        print("  " + "-" * 60)
        logging.info(f"PowerShell stdout: {result.stdout[:500]}")
    
    if result.stderr:
        print("  WARNINGS/ERRORS FROM POWERSHELL:")
        print(result.stderr)
        logging.warning(f"PowerShell stderr: {result.stderr[:500]}")
    
    if result.returncode == 0:
        print("")
        print("  [OK] PowerShell script completed successfully!")
        logging.info("PowerShell script completed successfully")
        
        # Try to parse JSON output
        try:
            output_lines = result.stdout.strip().split('\n')
            json_lines = []
            in_json = False
            for line in output_lines:
                if line.strip().startswith('{'):
                    in_json = True
                if in_json:
                    json_lines.append(line)
            if json_lines:
                json_str = '\n'.join(json_lines)
                data = json.loads(json_str)
                print("")
                print("  RESULT FROM POWERSHELL (as JSON):")
                for key, value in data.items():
                    print(f"    {key}: {value}")
                logging.info(f"Parsed JSON result: {data}")
        except Exception as e:
            logging.warning(f"Could not parse JSON: {e}")
    else:
        print(f"  [ERROR] PowerShell script failed with code: {result.returncode}")
        logging.error(f"PowerShell script failed with code: {result.returncode}")
        
except subprocess.TimeoutExpired:
    print("  [ERROR] PowerShell script timed out")
    logging.error("PowerShell script timed out")
except FileNotFoundError:
    print("  [ERROR] PowerShell not found")
    logging.error("PowerShell not found")
except Exception as e:
    print(f"  [ERROR] {e}")
    logging.error(f"Error running PowerShell: {e}")

print("")
input("  Press Enter to continue...")
print("")

# ============================================
# STEP 5: Verify Results
# ============================================
print("=" * 70)
print("  STEP 3: VERIFYING THE RESULTS")
print("=" * 70)
print("")
print("  WHAT IS HAPPENING HERE?")
print("  Python checks that the folder and file were actually created.")
print("  This is called 'verification'.")
print("")
print("  WHY IS THIS IMPORTANT?")
print("  In real IT work, you must verify that automation worked.")
print("  Otherwise, you might not know if something failed silently.")
print("")

logging.info("Verifying results")

test_folder = os.path.join(SCRIPT_DIR, "TestFolder")
if os.path.exists(test_folder) and os.path.isdir(test_folder):
    print(f"  [OK] Test folder exists: {test_folder}")
    logging.info(f"Test folder exists: {test_folder}")
    
    items = os.listdir(test_folder)
    for item in items:
        item_path = os.path.join(test_folder, item)
        if os.path.isfile(item_path):
            size = os.path.getsize(item_path)
            print(f"    File: {item} ({size} bytes)")
        else:
            print(f"    Folder: {item}")
else:
    print(f"  [WARNING] Test folder not found: {test_folder}")
    logging.warning(f"Test folder not found: {test_folder}")

test_file = os.path.join(SCRIPT_DIR, "TestFolder", "test_file.txt")
if os.path.isfile(test_file):
    print(f"  [OK] Test file exists: {test_file}")
    logging.info(f"Test file exists: {test_file}")
    
    try:
        with open(test_file, "r", encoding="utf-8") as f:
            content = f.read()
        print("")
        print("  FILE CONTENT:")
        print("  " + "-" * 60)
        for line in content.splitlines():
            print(f"    {line}")
        print("  " + "-" * 60)
    except UnicodeDecodeError:
        print("  Could not read file content (encoding issue)")
        logging.warning("Could not read file content")
else:
    print(f"  [WARNING] Test file not found: {test_file}")
    logging.warning(f"Test file not found: {test_file}")

print("")
input("  Press Enter to continue...")
print("")

# ============================================
# STEP 6: Summary
# ============================================
print("=" * 70)
print("  SUMMARY - WHAT YOU LEARNED TODAY")
print("=" * 70)
print("")
print("  WHAT THIS SCRIPT DEMONSTRATED:")
print("")
print("  1. SYSTEM CHECK")
print("     Python checked your Python version, Windows, PowerShell, and modules.")
print("     This is important because scripts must run in the right environment.")
print("")
print("  2. CREATING A POWERSHELL SCRIPT AUTOMATICALLY")
print("     Python wrote a PowerShell script for you.")
print("     This is useful when you need to generate scripts from data.")
print("")
print("  3. RUNNING POWERSHELL FROM PYTHON (subprocess)")
print("     Python ran the PowerShell script and captured the output.")
print("     This is how Python controls other tools.")
print("")
print("  4. VERIFYING RESULTS")
print("     Python checked that the folder and file were created.")
print("     This ensures that automation actually worked.")
print("")
print("  5. LOGGING EVERYTHING")
print("     All actions were saved to: {LOG_FILE}")
print("     This is essential for troubleshooting and auditing.")
print("")
print("  WHY THIS IS IMPORTANT FOR YOUR CAREER:")
print("")
print("  - System Administrators use Python to automate tasks daily.")
print("  - Python orchestrates multiple tools (PowerShell, Terraform, Ansible).")
print("  - This is exactly what you will do in your examination project.")
print("  - Swedish IT companies expect these skills.")
print("")
print("  FILES CREATED IN THIS FOLDER:")
print("    - generated_script.ps1  (PowerShell script created by Python)")
print("    - orchestrator.log      (Log of everything that happened)")
print("    - TestFolder/           (Folder created by PowerShell)")
print("    - TestFolder/test_file.txt (File created by PowerShell)")
print("")

logging.info("=" * 70)
logging.info("ORCHESTRATOR SCRIPT COMPLETED")
logging.info("=" * 70)

print("")
input("Press Enter to exit...")