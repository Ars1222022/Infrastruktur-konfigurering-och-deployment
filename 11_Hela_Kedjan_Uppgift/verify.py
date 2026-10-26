#!/usr/bin/env python3
import os
import subprocess

def check_website():
    try:
        result = subprocess.run(
            ["curl", "-s", "-o", "/dev/null", "-w", "%{http_code}", "http://localhost"],
            capture_output=True,
            text=True
        )
        return result.stdout.strip() == "200"
    except:
        return False

def check_files():
    return os.path.exists("server.txt") and os.path.exists("website.html")

def main():
    print("\n=== VERIFIERING MED PYTHON ===\n")
    website_ok = check_website()
    files_ok = check_files()
    print(f"Webbsida: {'OK' if website_ok else 'FAIL'}")
    print(f"Filer: {'OK' if files_ok else 'FAIL'}")
    if website_ok and files_ok:
        print("\nALLA VERIFIERINGAR GODKANDAS!")

if __name__ == "__main__":
    main()
