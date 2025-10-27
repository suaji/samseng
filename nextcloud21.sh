#!/bin/bash
# --- Nextcloud 21 Lite installer for Raspberry Pi 1 (512MB) ---

sudo apt update
sudo apt install -y zram-tools lighttpd php7.3 php7.3-gd php7.3-sqlite3 php7.3-zip php7.3-xml php7.3-mbstring php7.3-curl unzip wget

# Enable PHP
sudo lighty-enable-mod fastcgi
sudo lighty-enable-mod fastcgi-php
sudo service lighttpd restart

# Download Nextcloud 21
cd /var/www/html
sudo wget https://download.nextcloud.com/server/releases/nextcloud-21.0.9.zip
sudo unzip nextcloud-21.0.9.zip
sudo chown -R www-data:www-data nextcloud
sudo chmod -R 755 nextcloud

# Create data folder
sudo mkdir -p /media/usb/nextcloud_data
sudo chown -R www-data:www-data /media/usb/nextcloud_data

echo "----------------------------------------"
echo "✅ Nextcloud 21 Lite installed!"
echo "Open: http://<raspberrypi_ip>/nextcloud"
echo "Select SQLite during setup."
echo "----------------------------------------"