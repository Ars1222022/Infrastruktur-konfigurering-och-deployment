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