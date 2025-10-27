#!/bin/bash
# --- OwnCloud 10.11 installer for Raspberry Pi 1 (512MB) ---

sudo apt update
sudo apt install -y zram-tools lighttpd php7.3 php7.3-gd php7.3-sqlite3 php7.3-zip php7.3-xml php7.3-mbstring php7.3-curl unzip wget

# Enable PHP
sudo lighty-enable-mod fastcgi
sudo lighty-enable-mod fastcgi-php
sudo service lighttpd restart

# Download OwnCloud 10.11
cd /var/www/html
sudo wget https://download.owncloud.com/server/stable/owncloud-10.10.0.zip
sudo unzip owncloud-10.10.0.zip
sudo chown -R www-data:www-data owncloud
sudo chmod -R 755 owncloud

# Create data folder
sudo mkdir -p /media/usb/owncloud_data
sudo chown -R www-data:www-data /media/usb/owncloud_data

echo "----------------------------------------"
echo "✅ OwnCloud 10.11 installed!"
echo "Open: http://<raspberrypi_ip>/owncloud"
echo "Select SQLite during setup."
echo "----------------------------------------"
