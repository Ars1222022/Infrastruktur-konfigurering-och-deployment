# ============================================
# tema10-autodebug.ps1 – TEMA 10 COMPLETE (FIXAD)
# ============================================
#
# 🎯 DETTA SKRIPT KÖRS I WINDOWS + WSL!
#    - Windows: skapar skriptet och startar WSL
#    - WSL: installerar allt och kör playbook
#    - Auto-debuggar varje steg
#    - Skapar webbsida med definitioner
# ============================================

if (-not $PSScriptRoot) {
    $PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Path
}
if (-not $PSScriptRoot) {
    $PSScriptRoot = Get-Location
}
Set-Location $PSScriptRoot

# ============================================================
# FÄRGER FÖR TYDLIGHET
# ============================================================

$colors = @{
    Info    = "Cyan"
    Success = "Green"
    Warning = "Yellow"
    Error   = "Red"
    Step    = "Magenta"
    Debug   = "Gray"
}

# ============================================================
# INTRODUKTION – VAD ÄR TEMA 10?
# ============================================================

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  TEMA 10 – AUTO-DEBUG SETUP" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "📖 VAD ÄR TEMA 10?" -ForegroundColor Yellow
Write-Host "  Tema 10 handlar om att skriva Ansible-playbooks för att" -ForegroundColor Gray
Write-Host "  automatisera installation och konfiguration av IT-system." -ForegroundColor Gray
Write-Host "  Detta är kärnan i Infrastructure as Code (IaC).`n" -ForegroundColor Gray

Write-Host "🔧 VAD INSTALLERAR VI?" -ForegroundColor Yellow
Write-Host "  🌐 Nginx     – Webbserver (visar webbsidor)" -ForegroundColor Gray
Write-Host "  🗄️ MariaDB   – Databas (lagrar data)" -ForegroundColor Gray
Write-Host "  🐘 PHP       – Programmeringsspråk (skapar dynamiska sidor)" -ForegroundColor Gray
Write-Host "  ⚡ Ansible   – Automationsverktyg (installerar allt)`n" -ForegroundColor Gray

Write-Host "📋 VARFÖR DETTA?" -ForegroundColor Yellow
Write-Host "  ✅ Automatisera serverkonfiguration" -ForegroundColor Gray
Write-Host "  ✅ Återskapa miljöer snabbt" -ForegroundColor Gray
Write-Host "  ✅ Undvika manuella fel" -ForegroundColor Gray
Write-Host "  ✅ Användas i DevOps / CI/CD pipelines`n" -ForegroundColor Gray

# ============================================================
# STEP 0: RENSA ALLT
# ============================================================

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
Write-Host "  [STEP 0] RENSAR GAMLA FILER" -ForegroundColor Magenta
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Magenta

Write-Host "🧹 Varför: Gamla filer kan orsaka konflikter." -ForegroundColor Yellow
Write-Host "   Vi tar bort allt för att börja med en ren miljö.`n" -ForegroundColor Gray

$filesToDelete = @(
    "inventory.ini", "playbook.yml", "inventory_windows.ini",
    "install_iis.yml", "ansible_windows_test_commands.txt",
    ".vault_pass.txt", "vault.yml", "wsl_setup.sh", ".gitignore",
    "inventory_test.ini", "inventory_ntlm.ini", "inventory_negotiate.ini",
    "inventory_credssp.ini", "inventory_https.ini", "inventory_final.ini",
    "inventory_ps.ini", "run_in_wsl.sh", "wsl_ansible_setup.sh",
    "wsl_files_setup.sh", "tema10_linux_setup.sh", "tema10_complete_setup.sh",
    "tema10_autodebug.sh", "tema10_final.sh"
)

$removedCount = 0
foreach ($file in $filesToDelete) {
    $fullPath = Join-Path $PSScriptRoot $file
    if (Test-Path $fullPath) {
        Remove-Item -Path $fullPath -Force
        Write-Host "    ✅ Removed: $file" -ForegroundColor Gray
        $removedCount++
    }
}

$filesFolder = Join-Path $PSScriptRoot "files"
if (Test-Path $filesFolder) {
    Remove-Item -Path $filesFolder -Force -Recurse
    Write-Host "    ✅ Removed: files/" -ForegroundColor Gray
    $removedCount++
}

# Rensa WSL
try {
    wsl -d Ubuntu bash -c "rm -rf ~/ansible-lab 2>/dev/null; rm -rf /tmp/ansible-lab 2>/dev/null" 2>&1 | Out-Null
    Write-Host "    ✅ [WSL] Cleaned up ~/ansible-lab" -ForegroundColor Gray
} catch {
    Write-Host "    ⚠️ [WSL] No files to clean" -ForegroundColor Gray
}

Write-Host "`n  ✅ Rensade $removedCount filer. Nu är allt rent!`n" -ForegroundColor Green

# ============================================================
# STEP 1: CHECK WSL
# ============================================================

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
Write-Host "  [STEP 1] KONTROLLERAR WSL" -ForegroundColor Magenta
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Magenta

Write-Host "💻 VARFÖR WSL?" -ForegroundColor Yellow
Write-Host "   Detta skript KÖRS I WINDOWS OCH WSL!" -ForegroundColor Cyan
Write-Host "   ┌─────────────────────────────────────────────────────┐" -ForegroundColor Gray
Write-Host "   │  Windows (PowerShell)  ←─── skapar skriptet       │" -ForegroundColor Gray
Write-Host "   │         │                                         │" -ForegroundColor Gray
Write-Host "   │         ▼                                         │" -ForegroundColor Gray
Write-Host "   │  WSL (Ubuntu)          ←─── installerar allt     │" -ForegroundColor Gray
Write-Host "   └─────────────────────────────────────────────────────┘" -ForegroundColor Gray
Write-Host ""
Write-Host "   Windows Subsystem for Linux (WSL) låter oss köra Linux" -ForegroundColor Gray
Write-Host "   på Windows. Ansible är byggt för Linux, så vi behöver WSL.`n" -ForegroundColor Gray

$wsl = Get-Command wsl -ErrorAction SilentlyContinue
if (-not $wsl) {
    Write-Host "  ❌ ERROR: WSL2 är inte installerat!" -ForegroundColor Red
    Write-Host "  Lösning: Installera WSL2: wsl --install" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit
}
Write-Host "  ✅ WSL2 är installerat" -ForegroundColor Green

# Starta Ubuntu
$ubuntuRunning = $false
try {
    $test = wsl -d Ubuntu echo "test" 2>&1
    if ($LASTEXITCODE -eq 0) {
        $ubuntuRunning = $true
    }
} catch {
    $ubuntuRunning = $false
}

if (-not $ubuntuRunning) {
    Write-Host "  ⏳ Startar Ubuntu..." -ForegroundColor Yellow
    try {
        Start-Process -FilePath "wsl.exe" -ArgumentList "-d Ubuntu" -WindowStyle Hidden
        Start-Sleep -Seconds 5
        Write-Host "  ✅ Ubuntu startades" -ForegroundColor Green
    } catch {
        Write-Host "  ⚠️ Kunde inte starta Ubuntu automatiskt" -ForegroundColor Yellow
        Write-Host "  Öppna Ubuntu från Start-menyn manuellt" -ForegroundColor Gray
        Read-Host "Press Enter to continue"
    }
} else {
    Write-Host "  ✅ Ubuntu körs redan" -ForegroundColor Green
}

Write-Host ""

# ============================================================
# STEP 2: SKAPA WSL-SKRIPT
# ============================================================

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
Write-Host "  [STEP 2] SKAPAR WSL-SKRIPT" -ForegroundColor Magenta
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Magenta

Write-Host "📝 VARFÖR?" -ForegroundColor Yellow
Write-Host "   Vi skapar ett bash-skript som körs i WSL och:" -ForegroundColor Gray
Write-Host "   1. Skapar inventory (listar servrar)" -ForegroundColor Gray
Write-Host "   2. Skapar playbook (instruktioner)" -ForegroundColor Gray
Write-Host "   3. Installerar Ansible om det saknas" -ForegroundColor Gray
Write-Host "   4. Kör playbooken automatiskt" -ForegroundColor Gray
Write-Host "   5. Skapar en webbsida MED DEFINITIONER`n" -ForegroundColor Gray

$wslScript = @'
#!/bin/bash
# ============================================
# TEMA 10 – AUTO-DEBUG SETUP
# ============================================

echo ""
echo "=========================================="
echo "  TEMA 10 – AUTO-DEBUG SETUP"
echo "=========================================="
echo ""

# -------- 2.1 SKAPA MAPP --------
echo "📂 [2.1] Skapar arbetsmapp..."
mkdir -p ~/ansible-lab
cd ~/ansible-lab
echo "  ✅ Mapp: ~/ansible-lab"
echo ""

# -------- 2.2 SKAPA INVENTORY --------
echo "📋 [2.2] Skapar inventory..."
echo "  📖 inventory.ini = lista över servrar som Ansible ska hantera"
echo "     localhost = din egen dator (WSL)"
echo "     ansible_connection=local = kör direkt, ingen SSH"
echo ""

cat > inventory.ini << 'EOF'
[local]
localhost ansible_connection=local

[webservers]
localhost

[all:vars]
ansible_python_interpreter=/usr/bin/python3
EOF
echo "  ✅ inventory.ini skapad"
echo ""

# -------- 2.3 SKAPA PLAYBOOK --------
echo "📝 [2.3] Skapar playbook..."
echo "  📖 playbook.yml = instruktioner för vad Ansible ska göra"
echo "     ⚡ Ansible läser YAML-filen och utför uppgifterna"
echo "     📄 Webbsidan innehåller DEFINITIONER av alla teknologier!"
echo ""

cat > playbook.yml << 'EOF'
---
- name: TEMA 10 – Installera komplett webbmiljö
  hosts: localhost
  become: yes
  gather_facts: yes
  
  vars:
    web_root: /var/www/tema10
    domain_name: "tema10.local"

  tasks:
    - name: 1.1 Uppdatera paketlistan
      apt:
        update_cache: yes
        cache_valid_time: 3600

    - name: 1.2 Installera paket
      apt:
        name:
          - nginx
          - php-fpm
          - php-mysql
          - mariadb-server
          - git
          - curl
          - wget
          - htop
        state: present

    - name: 2.1 Starta MariaDB
      service:
        name: mariadb
        state: started
        enabled: yes

    - name: 3.1 Skapa webroot-mapp
      file:
        path: "{{ web_root }}"
        state: directory
        owner: www-data
        group: www-data
        mode: '0755'

    - name: 3.2 Skapa Nginx-konfiguration
      copy:
        dest: /etc/nginx/sites-available/tema10
        content: |
          server {
              listen 80;
              server_name {{ domain_name }};
              root {{ web_root }};
              index index.php index.html;

              location / {
                  try_files $uri $uri/ =404;
              }

              location ~ \.php$ {
                  include snippets/fastcgi-php.conf;
                  fastcgi_pass unix:/run/php/php8.5-fpm.sock;
              }
          }
      notify: Restart Nginx

    - name: 3.3 Aktivera webbplatsen
      file:
        src: /etc/nginx/sites-available/tema10
        dest: /etc/nginx/sites-enabled/tema10
        state: link
      notify: Restart Nginx

    - name: 3.4 Ta bort default site
      file:
        path: /etc/nginx/sites-enabled/default
        state: absent
      notify: Restart Nginx

    - name: 4.1 Skapa index.php med definitioner
      copy:
        dest: "{{ web_root }}/index.php"
        content: |
          <?php
          echo "<!DOCTYPE html>
          <html lang='sv'>
          <head>
              <meta charset='UTF-8'>
              <title>TEMA 10 – Ansible Playbooks</title>
              <style>
                  * { margin: 0; padding: 0; box-sizing: border-box; }
                  body { font-family: 'Segoe UI', Arial, sans-serif; background: #f5f5f5; padding: 20px; }
                  .container { max-width: 1100px; margin: 0 auto; }
                  h1 { text-align: center; color: #0078D4; margin: 30px 0; font-size: 2.5em; }
                  h2 { color: #0078D4; margin: 20px 0 10px; border-bottom: 2px solid #0078D4; padding-bottom: 10px; }
                  .card { background: white; border-radius: 10px; padding: 25px; margin: 15px 0; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
                  .tech-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; margin: 20px 0; }
                  .tech-card { background: #f8f9fa; border-radius: 8px; padding: 20px; border-left: 4px solid #0078D4; }
                  .tech-card h3 { color: #0078D4; margin-bottom: 10px; }
                  .tech-card p { color: #333; line-height: 1.6; }
                  .tech-card .use { background: #e8f4fd; padding: 10px; border-radius: 5px; margin-top: 10px; font-size: 0.9em; }
                  .footer { text-align: center; margin: 30px 0; padding: 20px; color: #666; border-top: 1px solid #ddd; }
              </style>
          </head>
          <body>
              <div class='container'>
                  <h1>🎉 TEMA 10 – Ansible Playbooks</h1>
                  
                  <div class='card' style='background: #e8f4fd; border-left: 4px solid #0078D4;'>
                      <p><strong>✅ Detta är en dynamisk webbsida skapad med Ansible!</strong></p>
                      <p>Servern: <strong><?php echo gethostname(); ?></strong> | Datum: <?php echo date('Y-m-d H:i:s'); ?> | PHP: <?php echo phpversion(); ?></p>
                  </div>
                  
                  <h2>📖 Vad är TEMA 10?</h2>
                  <div class='card'>
                      <p>TEMA 10 handlar om att <strong>skriva Ansible-playbooks</strong> för att automatisera installation och konfiguration av IT-system. Detta är kärnan i <strong>Infrastructure as Code (IaC)</strong>.</p>
                      <br>
                      <p><strong>Varför?</strong></p>
                      <ul style='margin-left: 20px;'>
                          <li>✅ Automatisera serverkonfiguration</li>
                          <li>✅ Återskapa miljöer snabbt</li>
                          <li>✅ Undvika manuella fel</li>
                          <li>✅ Användas i DevOps / CI/CD pipelines</li>
                      </ul>
                  </div>
                  
                  <h2>🔧 Teknologier som används</h2>
                  <div class='tech-grid'>
                      <div class='tech-card'>
                          <h3>🌐 Nginx</h3>
                          <p><strong>Vad är det?</strong> En högpresterande webbserver som visar webbsidor.</p>
                          <div class='use'>
                              <strong>📋 Användningsområden:</strong>
                              <ul><li>Webbserver</li><li>Load balancer</li><li>Reverse proxy</li><li>API-gateway</li></ul>
                          </div>
                      </div>
                      
                      <div class='tech-card'>
                          <h3>🐘 PHP</h3>
                          <p><strong>Vad är det?</strong> Ett programmeringsspråk för dynamiska webbsidor.</p>
                          <div class='use'>
                              <strong>📋 Användningsområden:</strong>
                              <ul><li>CMS (WordPress, Drupal)</li><li>E-handel</li><li>API:er och backend</li><li>Webbapplikationer</li></ul>
                          </div>
                      </div>
                      
                      <div class='tech-card'>
                          <h3>🗄️ MariaDB</h3>
                          <p><strong>Vad är det?</strong> Ett relationellt databashanteringssystem.</p>
                          <div class='use'>
                              <strong>📋 Användningsområden:</strong>
                              <ul><li>Webbapplikationsdatabaser</li><li>E-handelsdatabaser</li><li>Dataanalys</li><li>Enterprise-system</li></ul>
                          </div>
                      </div>
                      
                      <div class='tech-card'>
                          <h3>⚡ Ansible</h3>
                          <p><strong>Vad är det?</strong> Ett automationsverktyg för konfiguration.</p>
                          <div class='use'>
                              <strong>📋 Användningsområden:</strong>
                              <ul><li>Serverkonfiguration</li><li>Applikationsdistribution</li><li>Orkestrering</li><li>Infrastructure as Code</li></ul>
                          </div>
                      </div>
                  </div>
                  
                  <h2>🎯 Var kan detta användas?</h2>
                  <div class='card'>
                      <div class='tech-grid' style='grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));'>
                          <div class='tech-card' style='border-left-color: #28a745;'><h3>🚀 DevOps-pipelines</h3><p>Automatisera serverkonfiguration i CI/CD.</p></div>
                          <div class='tech-card' style='border-left-color: #17a2b8;'><h3>🧪 Utvecklingsmiljöer</h3><p>Skapa testmiljöer snabbt.</p></div>
                          <div class='tech-card' style='border-left-color: #ffc107;'><h3>🏭 Produktionsservrar</h3><p>Konsekvent konfiguration.</p></div>
                          <div class='tech-card' style='border-left-color: #6f42c1;'><h3>☁️ Molnmiljöer</h3><p>AWS, Azure, GCP.</p></div>
                      </div>
                  </div>
                  
                  <div class='card' style='background: #d4edda; border-left: 4px solid #28a745;'>
                      <h3>🎉 TEMA 10 – KLART!</h3>
                      <p>✅ Nginx: <?php echo shell_exec('systemctl is-active nginx'); ?></p>
                      <p>✅ PHP-FPM: <?php echo shell_exec('systemctl is-active php8.5-fpm'); ?></p>
                      <p>✅ MariaDB: <?php echo shell_exec('systemctl is-active mariadb'); ?></p>
                      <p>📂 Webroot: /var/www/tema10</p>
                  </div>
                  
                  <div class='footer'>
                      <p>✅ Skapad med <strong>Ansible Playbooks</strong> – Infrastructure as Code</p>
                      <p>📅 <?php echo date('Y-m-d H:i:s'); ?> | 🌐 Server: <?php echo gethostname(); ?></p>
                  </div>
              </div>
          </body>
          </html>";
          ?>
        owner: www-data
        group: www-data
        mode: '0644'

    - name: 5.1 Verifiera Nginx
      service:
        name: nginx
        state: started
      register: nginx_status

    - name: 5.2 Verifiera PHP-FPM
      service:
        name: php8.5-fpm
        state: started
      register: php_status

    - name: 5.3 Verifiera MariaDB
      service:
        name: mariadb
        state: started
      register: mariadb_status

    - name: 5.4 Testa webbsidan
      uri:
        url: http://localhost
        return_content: yes
      register: website_test
      failed_when: website_test.status != 200

    - name: 5.5 Visa resultat
      debug:
        msg: |
          🎉 TEMA 10 – KLART!
          
          ✅ Nginx: {{ nginx_status.status }}
          ✅ PHP-FPM: {{ php_status.status }}
          ✅ MariaDB: {{ mariadb_status.status }}
          ✅ Webbplats: http://localhost (HTTP {{ website_test.status }})
          
          📂 Webroot: {{ web_root }}
          📖 Webbsidan innehåller DEFINITIONER av alla teknologier!

  handlers:
    - name: Restart Nginx
      service:
        name: nginx
        state: restarted
EOF
echo "  ✅ playbook.yml skapad"
echo ""

# -------- 2.4 INSTALLERA ANSIBLE --------
echo "⚡ [2.4] Kontrollerar Ansible..."
if ! command -v ansible &> /dev/null; then
    echo "  ⏳ Installerar Ansible..."
    sudo apt update -y && sudo apt install -y ansible
    echo "  ✅ Ansible installerad"
else
    echo "  ✅ Ansible är redan installerat"
fi
echo ""

# -------- 2.5 INSTALLERA MYSQL-MODUL --------
echo "📦 [2.5] Installerar MySQL-modul för Ansible..."
echo "  📖 Behövs för att Ansible ska kunna hantera MariaDB"
ansible-galaxy collection install community.mysql 2>/dev/null
echo "  ✅ Klart"
echo ""

# -------- 2.6 SUDOERS --------
echo "🔑 [2.6] Konfigurerar sudo utan lösenord..."
echo "  📖 Gör att Ansible kan köra kommandon som root"
echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/$USER > /dev/null
echo "  ✅ Klart"
echo ""

# -------- 2.7 KÖR PLAYBOOK --------
echo "🚀 [2.7] Kör TEMA 10 playbook..."
echo "  📖 Ansible läser playbook.yml och utför steg för steg"
echo "     Detta tar 3-5 minuter..."
echo "=========================================="
echo ""
ansible-playbook -i inventory.ini playbook.yml

# -------- 2.8 RESULTAT --------
echo ""
echo "=========================================="
echo "  🎉 TEMA 10 – KLART!"
echo "=========================================="
echo ""
echo "  ✅ Komplett webbmiljö installerad!"
echo "  ✅ Nginx (webbserver) – http://localhost"
echo "  ✅ PHP-FPM (processhanterare)"
echo "  ✅ MariaDB (databas)"
echo ""
echo "  📖 Webbsidan innehåller DEFINITIONER av alla teknologier!"
echo "     Öppna http://localhost i webbläsaren!"
echo ""
echo "  📋 VERIFIERA:"
echo "    curl http://localhost"
echo "    systemctl status nginx"
echo "    systemctl status php8.5-fpm"
echo "    systemctl status mariadb"
echo ""
echo "  📋 ÄNDRA PLAYBOOK:"
echo "    cd ~/ansible-lab"
echo "    nano playbook.yml"
echo "    ansible-playbook -i inventory.ini playbook.yml"
echo ""
'@

# Spara skriptet
$wslScript = $wslScript -replace "`r`n", "`n"
$wslScriptPath = Join-Path $PSScriptRoot "tema10_autodebug.sh"
$wslScript | Out-File -FilePath $wslScriptPath -Encoding utf8 -NoNewline

Write-Host "  ✅ Skapade: tema10_autodebug.sh" -ForegroundColor Green
Write-Host ""

# ============================================================
# STEP 3: KÖR I WSL
# ============================================================

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
Write-Host "  [STEP 3] KÖR I WSL" -ForegroundColor Magenta
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Magenta

Write-Host "🚀 Startar installationen..." -ForegroundColor Yellow
Write-Host "   ⏳ Detta tar 3-5 minuter..." -ForegroundColor Gray
Write-Host "   📖 Skriptet kommer att:" -ForegroundColor Gray
Write-Host "      1. Skapa mapp och filer" -ForegroundColor Gray
Write-Host "      2. Installera Ansible om det saknas" -ForegroundColor Gray
Write-Host "      3. Konfigurera sudo" -ForegroundColor Gray
Write-Host "      4. Installera Nginx, PHP, MariaDB" -ForegroundColor Gray
Write-Host "      5. Skapa en webbsida MED DEFINITIONER" -ForegroundColor Gray
Write-Host "      6. Testa och visa resultat`n" -ForegroundColor Gray

wsl -d Ubuntu bash -c "chmod +x /mnt/d/Nackademin/10_Ansible\ Playbooks_Uppgift_/tema10_autodebug.sh && /mnt/d/Nackademin/10_Ansible\ Playbooks_Uppgift_/tema10_autodebug.sh"

# ============================================================
# SAMMANFATTNING
# ============================================================

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
Write-Host "  🎉 TEMA 10 – KLART!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Magenta

Write-Host "📌 VAR KÖRS DETTA SKRIPT?" -ForegroundColor Yellow
Write-Host "  ┌─────────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
Write-Host "  │  ✅ DEL 1: Windows (PowerShell)                            │" -ForegroundColor Cyan
Write-Host "  │     → Skapar skriptet (tema10_autodebug.sh)               │" -ForegroundColor Gray
Write-Host "  │     → Startar WSL                                         │" -ForegroundColor Gray
Write-Host "  │                                                             │" -ForegroundColor Cyan
Write-Host "  │  ✅ DEL 2: WSL (Ubuntu)                                   │" -ForegroundColor Cyan
Write-Host "  │     → Skapar inventory och playbook                       │" -ForegroundColor Gray
Write-Host "  │     → Installerar Nginx, PHP, MariaDB                     │" -ForegroundColor Gray
Write-Host "  │     → Skapar webbsida MED DEFINITIONER                    │" -ForegroundColor Gray
Write-Host "  │     → Testar och visar resultat                           │" -ForegroundColor Gray
Write-Host "  └─────────────────────────────────────────────────────────────┘" -ForegroundColor Cyan
Write-Host ""

Write-Host "✅ VAD HAR VI INSTALLERAT?" -ForegroundColor Yellow
Write-Host "  🌐 Nginx     – Webbserver som visar webbsidor" -ForegroundColor Gray
Write-Host "  🗄️ MariaDB   – Databas för att lagra data" -ForegroundColor Gray
Write-Host "  🐘 PHP       – Programmeringsspråk för dynamiska sidor" -ForegroundColor Gray
Write-Host "  ⚡ Ansible   – Automationsverktyg`n" -ForegroundColor Gray

Write-Host "📋 WEBBSIDAN INNEHÅLLER DEFINITIONER AV:" -ForegroundColor Yellow
Write-Host "  ✅ Nginx – vad det är och användningsområden" -ForegroundColor Gray
Write-Host "  ✅ PHP – vad det är och användningsområden" -ForegroundColor Gray
Write-Host "  ✅ MariaDB – vad det är och användningsområden" -ForegroundColor Gray
Write-Host "  ✅ Ansible – vad det är och användningsområden`n" -ForegroundColor Gray

Write-Host "📋 VAR KAN DETTA ANVÄNDAS?" -ForegroundColor Yellow
Write-Host "  ✅ DevOps-pipelines – automatisera serverkonfiguration" -ForegroundColor Gray
Write-Host "  ✅ Utvecklingsmiljöer – snabbt skapa testmiljöer" -ForegroundColor Gray
Write-Host "  ✅ Produktionsservrar – konsekvent konfiguration" -ForegroundColor Gray
Write-Host "  ✅ Molnmiljöer – AWS, Azure, GCP`n" -ForegroundColor Gray

Write-Host "🎯 NÄSTA STEG:" -ForegroundColor Yellow
Write-Host "  1. Öppna webbsidan: http://localhost (läs definitionerna!)" -ForegroundColor Gray
Write-Host "  2. Öppna playbook.yml och lägg till fler uppgifter" -ForegroundColor Gray
Write-Host "  3. Lägg till fler servrar i inventory.ini" -ForegroundColor Gray
Write-Host "  4. Lär dig Ansible Vault för säker hantering av lösenord`n" -ForegroundColor Gray

Write-Host "📋 TESTA SJÄLV:" -ForegroundColor Yellow
Write-Host "  wsl" -ForegroundColor Gray
Write-Host "  cd ~/ansible-lab" -ForegroundColor Gray
Write-Host "  curl http://localhost" -ForegroundColor Cyan
Write-Host "  ansible-playbook -i inventory.ini playbook.yml" -ForegroundColor Cyan
Write-Host ""

Read-Host "Press Enter to exit"