#!/bin/bash
# --- Nextcloud 21 Lite installer for Raspberry Pi 1 (512MB + zram optimized) ---

sudo apt update
sudo apt install -y zram-tools lighttpd php7.3 php7.3-gd php7.3-sqlite3 php7.3-zip php7.3-xml php7.3-mbstring php7.3-curl unzip wget

# Optimize ZRAM: 75% of RAM, LZ4 compression
sudo sed -i 's/^PERCENTAGE=.*/PERCENTAGE=75/' /etc/default/zramswap
sudo sed -i 's/^ALGO=.*/ALGO=lz4/' /etc/default/zramswap
sudo systemctl restart zramswap.service

# Disable old swapfile (avoid SD wear)
sudo systemctl disable dphys-swapfile
sudo systemctl stop dphys-swapfile

# Enable PHP with Lighttpd
sudo lighty-enable-mod fastcgi
sudo lighty-enable-mod fastcgi-php
sudo service lighttpd restart

# Download Nextcloud 21
cd /var/www/html
sudo wget https://download.nextcloud.com/server/releases/nextcloud-21.0.9.zip
sudo unzip nextcloud-21.0.9.zip
sudo chown -R www-data:www-data nextcloud
sudo chmod -R 755 nextcloud

# Create external data folder (recommended on USB)
sudo mkdir -p /media/usb/nextcloud_data
sudo chown -R www-data:www-data /media/usb/nextcloud_data

echo "----------------------------------------"
echo "✅ Nextcloud 21 installed with ZRAM optimization!"
echo "ZRAM active at 75% RAM using LZ4 compression"
echo "Access: http://<raspberrypi_ip>/nextcloud"
echo "Choose SQLite during setup"
echo "----------------------------------------"
