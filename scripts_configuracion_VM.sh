#!/bin/bash
# ============================================================
# PORTAL INTERNO DE SOPORTE TI - InforSur Málaga
# Scripts de configuración del servidor
# Ubuntu Server 24.04 LTS
# Autor: Chima Ogbajie Iheke - 2º SMR
# ============================================================

# ------------------------------------------------------------
# 1. CONFIGURACIÓN DE RED (IP FIJA)
# ------------------------------------------------------------
# Editar el fichero de netplan
sudo nano /etc/netplan/50-cloud-init.yaml

# Contenido del fichero:
# network:
#   version: 2
#   ethernets:
#     ens33:
#       dhcp4: no
#       addresses:
#         - 192.168.76.128/24
#       gateway4: 192.168.76.2
#       nameservers:
#         addresses: [8.8.8.8, 8.8.4.4]

# Aplicar los cambios de red
sudo netplan apply

# Comprobar la IP asignada
ip a


# ------------------------------------------------------------
# 2. INSTALACIÓN Y CONFIGURACIÓN DE SSH
# ------------------------------------------------------------
sudo apt update
sudo apt install openssh-server -y

# Activar el servicio para que arranque con el sistema
sudo systemctl enable ssh
sudo systemctl start ssh

# Verificar estado
systemctl status ssh


# ------------------------------------------------------------
# 3. CREACIÓN DE USUARIOS DEL SISTEMA
# ------------------------------------------------------------
sudo adduser admin_ti
sudo adduser tecnico
sudo adduser cliente

# Dar permisos de administrador al usuario admin_ti
sudo usermod -aG sudo admin_ti

# Verificar usuarios creados
cut -d: -f1 /etc/passwd | tail -10


# ------------------------------------------------------------
# 4. CARPETA COMPARTIDA CON PERMISOS DIFERENCIADOS
# ------------------------------------------------------------
sudo mkdir /srv/documentacion
sudo chown admin_ti:tecnico /srv/documentacion
sudo chmod 770 /srv/documentacion

# Verificar permisos
ls -la /srv/


# ------------------------------------------------------------
# 5. INSTALACIÓN DEL ENTORNO LAMP (Apache + MariaDB + PHP)
# ------------------------------------------------------------
sudo apt install apache2 mariadb-server -y

sudo apt install php php-mysql libapache2-mod-php php-curl php-gd \
php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip -y

sudo apt install phpmyadmin -y

# Habilitar servicios
sudo systemctl enable apache2
sudo systemctl enable mariadb
sudo systemctl status apache2
sudo systemctl status mariadb

# Asegurar la instalación de MariaDB
sudo mysql_secure_installation
# Respuestas: N,Y,Y,Y,Y,Y


# ------------------------------------------------------------
# 6. CREACIÓN DE BASE DE DATOS PARA WORDPRESS
# ------------------------------------------------------------
sudo mysql

# Dentro de la consola de MariaDB:
# CREATE DATABASE wp_2SMR CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
# CREATE USER 'chimaa-bbdd'@'localhost' IDENTIFIED BY 'CONTRASEÑA_SEGURA';
# GRANT ALL PRIVILEGES ON wp_2SMR.* TO 'chimaa-bbdd'@'localhost';
# FLUSH PRIVILEGES;
# EXIT;


# ------------------------------------------------------------
# 7. INSTALACIÓN DE WORDPRESS
# ------------------------------------------------------------
cd /tmp
wget https://wordpress.org/latest.tar.gz
tar -xzvf latest.tar.gz

sudo mv wordpress /var/www/wordpress
sudo chown -R www-data:www-data /var/www/wordpress


# ------------------------------------------------------------
# 8. CONFIGURACIÓN DEL VIRTUALHOST DE APACHE
# ------------------------------------------------------------
cd /etc/apache2/sites-available
sudo cp 000-default.conf wordpress.conf
sudo nano wordpress.conf

# Contenido del VirtualHost HTTP (puerto 80):
# <VirtualHost *:80>
#     DocumentRoot /var/www/wordpress
#     <Directory /var/www/wordpress>
#         Options FollowSymLinks
#         AllowOverride All
#         Require all granted
#     </Directory>
# </VirtualHost>

sudo a2dissite 000-default.conf
sudo a2ensite wordpress.conf
sudo systemctl reload apache2


# ------------------------------------------------------------
# 9. CONFIGURACIÓN DE HTTPS (CERTIFICADO SSL AUTOFIRMADO)
# ------------------------------------------------------------
sudo a2enmod ssl

sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/portal.key \
  -out /etc/ssl/certs/portal.crt

# Editar wordpress.conf y añadir el bloque para el puerto 443:
sudo nano /etc/apache2/sites-available/wordpress.conf

# <VirtualHost *:443>
#     ServerAdmin admin@empresa.local
#     DocumentRoot /var/www/wordpress
#     SSLEngine on
#     SSLCertificateFile /etc/ssl/certs/portal.crt
#     SSLCertificateKeyFile /etc/ssl/private/portal.key
# </VirtualHost>

sudo systemctl restart apache2


# ------------------------------------------------------------
# 10. CONFIGURACIÓN DEL FIREWALL (UFW)
# ------------------------------------------------------------
sudo ufw allow 22
sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable

# Verificar reglas activas
sudo ufw status verbose


# ------------------------------------------------------------
# 11. ENDURECIMIENTO DE SSH
# ------------------------------------------------------------
sudo nano /etc/ssh/sshd_config

# Cambios aplicados:
# PermitRootLogin no
# AllowUsers tecnico admin_ti

sudo systemctl restart ssh


# ------------------------------------------------------------
# 12. COPIA DE SEGURIDAD (BACKUP)
# ------------------------------------------------------------
sudo mkdir /backup

# Script de backup del portal web
sudo tar -czvf /backup/backup_portal_$(date +%F).tar.gz /var/www/wordpress/

# Verificar backup generado
ls -la /backup/


# ============================================================
# FIN DE LOS SCRIPTS DE CONFIGURACIÓN
# ============================================================
