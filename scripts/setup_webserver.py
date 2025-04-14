import os
import subprocess

def run(cmd):
    print(f"Ejecutando: {cmd}")
    subprocess.run(cmd, shell=True, check=True)

def instalar_servidor_web():
    if os.path.exists("/etc/debian_version"):
        print("Detectado sistema basado en Debian")
        run("sudo apt update")
        run("sudo apt install -y apache2")
        run("sudo systemctl enable apache2")
        run("sudo systemctl start apache2")
    elif os.path.exists("/etc/redhat-release") or os.path.exists("/etc/system-release"):
        print("Detectado sistema basado en RedHat/Amazon Linux")
        run("sudo yum install -y httpd")
        run("sudo systemctl enable httpd")
        run("sudo systemctl start httpd")
    else:
        print("Distro no soportada. Este script está diseñado para Debian o RedHat/Amazon Linux.")
        exit(1)

def crear_pagina_html(id_servidor="Servidor Web 1"):
    html = f"""
    <!DOCTYPE html>
    <html lang="es">
    <head>
        <meta charset="UTF-8">
        <title>{id_servidor}</title>
    </head>
    <body>
        <h1>¡Hola desde {id_servidor}!</h1>
    </body>
    </html>
    """
    with open("/tmp/index.html", "w", encoding="utf-8") as f:
        f.write(html)
    
    destino = "/var/www/html/index.html"
    if os.path.exists("/etc/redhat-release") or os.path.exists("/etc/system-release"):
        destino = "/var/www/html/index.html"
    run(f"sudo mv /tmp/index.html {destino}")

if __name__ == "__main__":
    instalar_servidor_web()
    crear_pagina_html("Servidor Web 1")

