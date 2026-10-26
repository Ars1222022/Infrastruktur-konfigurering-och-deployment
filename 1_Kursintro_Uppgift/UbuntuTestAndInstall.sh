#!/bin/bash
#
# ============================================
# UbuntuTestAndInstall.sh
# Tests and installs all required tools in Ubuntu (WSL2)
# ============================================

set -e

# --- 1. Colors and helpers ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log() {
    echo -e "${CYAN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

ok() {
    echo -e "${GREEN}[OK]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

fail() {
    echo -e "${RED}[FAIL]${NC} $1"
}

# --- 2. Check if running in WSL ---
if ! grep -qi microsoft /proc/version && ! grep -qi wsl /proc/version; then
    warn "Not running in WSL2. Some tools may not work as expected."
fi

# --- 3. Update package list ---
log "Updating package list..."
sudo apt update -y

# --- 4. Install required packages ---
log "Installing required packages..."
REQUIRED_PKGS="curl wget git python3 python3-pip"
for pkg in $REQUIRED_PKGS; do
    if dpkg -l | grep -q "^ii  $pkg "; then
        ok "$pkg is already installed."
    else
        log "Installing $pkg..."
        sudo apt install -y "$pkg"
        ok "$pkg installed."
    fi
done

# --- 5. Check and install Terraform ---
log "Checking Terraform..."
if command -v terraform &> /dev/null; then
    ok "Terraform is installed: $(terraform --version | head -n1)"
else
    warn "Terraform is not installed. Installing..."
    sudo apt install -y gnupg software-properties-common
    wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update
    sudo apt install -y terraform
    ok "Terraform installed successfully."
fi

# --- 6. Check and install Ansible ---
log "Checking Ansible..."
if command -v ansible &> /dev/null; then
    ok "Ansible is installed: $(ansible --version | head -n1)"
else
    warn "Ansible is not installed. Installing..."
    sudo apt install -y ansible
    ok "Ansible installed successfully."
fi

# --- 7. Check Python pip ---
log "Checking Python pip..."
if command -v pip3 &> /dev/null; then
    ok "pip3 is installed: $(pip3 --version | head -n1)"
else
    warn "pip3 is not installed. Installing..."
    sudo apt install -y python3-pip
    ok "pip3 installed successfully."
fi

# --- 8. Check and install PowerShell (pwsh) in WSL ---
log "Checking PowerShell (pwsh) in WSL..."
if command -v pwsh &> /dev/null; then
    ok "PowerShell is installed: $(pwsh --version)"
else
    warn "PowerShell is not installed. Installing..."
    
    # Install prerequisites
    sudo apt-get install -y wget apt-transport-https software-properties-common
    
    # Get Ubuntu version
    source /etc/os-release
    
    # Download and install Microsoft repository key
    wget -q "https://packages.microsoft.com/config/ubuntu/$VERSION_ID/packages-microsoft-prod.deb"
    sudo dpkg -i packages-microsoft-prod.deb
    rm packages-microsoft-prod.deb
    
    # Update package list and install PowerShell
    sudo apt-get update
    sudo apt-get install -y powershell
    
    ok "PowerShell installed successfully: $(pwsh --version)"
fi

# --- 9. Check WSL connectivity ---
log "Checking internet connectivity..."
if ping -c 1 google.com &> /dev/null; then
    ok "Internet connection is working."
else
    warn "No internet connection. Some installations may fail."
fi

# --- 10. Check disk space ---
log "Checking disk space..."
df -h / | awk 'NR==2 {print "Free space: " $4 " / " $2}'

# --- 11. Display final summary ---
echo ""
log "=========================================="
log "              SUMMARY"
log "=========================================="
echo ""

if command -v terraform &> /dev/null; then
    ok "Terraform: $(terraform --version | head -n1)"
else
    fail "Terraform: NOT INSTALLED"
fi

if command -v ansible &> /dev/null; then
    ok "Ansible: $(ansible --version | head -n1)"
else
    fail "Ansible: NOT INSTALLED"
fi

if command -v python3 &> /dev/null; then
    ok "Python: $(python3 --version)"
else
    fail "Python: NOT INSTALLED"
fi

if command -v git &> /dev/null; then
    ok "Git: $(git --version)"
else
    fail "Git: NOT INSTALLED"
fi

if command -v pwsh &> /dev/null; then
    ok "PowerShell: $(pwsh --version)"
else
    fail "PowerShell: NOT INSTALLED"
fi

echo ""
log "All checks completed."
log "If everything looks good, you are ready for the course!"