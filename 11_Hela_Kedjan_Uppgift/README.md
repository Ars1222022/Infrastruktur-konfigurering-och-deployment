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
