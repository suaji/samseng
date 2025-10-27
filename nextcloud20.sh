#!/bin/bash
# --- Nextcloud 20.0.14 installer for Raspberry Pi 1 (512MB) ---

echo "----------------------------------------"
echo "⚙️  Configuring ZRAM swap..."
sudo bash -c 'cat >/etc/default/zramswap <<EOF
PERCENT=50
PRIORITY=100
EOF'
sudo systemctl restart zramswap.service

echo "----------------------------------------"
echo "🧹 Removing Apache (if exists)..."
sudo systemctl stop apache2 2>/dev/null
sudo systemctl disable apache2 2>/dev/null
sudo apt purge -y apache2* 2>/dev/null
sudo apt autoremove -y
sudo apt clean

sudo apt update
sudo apt install -y zram-tools lighttpd php7.3 php7.3-fpm php7.3-gd php7.3-sqlite3 php7.3-zip php7.3-xml php7.3-mbstring php7.3-curl php7.3-intl unzip wget

# Enable PHP
sudo lighty-enable-mod fastcgi
sudo lighty-enable-mod fastcgi-php
sudo service lighttpd restart

echo "----------------------------------------"
echo "🔧 Configuring Lighttpd for PHP-FPM..."
sudo lighty-enable-mod fastcgi
sudo lighty-enable-mod fastcgi-php

sudo bash -c 'cat >/etc/lighttpd/conf-available/15-fastcgi-php.conf <<EOF
fastcgi.server += ( ".php" =>
    ((
        "socket" => "/run/php/php7.3-fpm.sock",
        "broken-scriptfilename" => "enable"
    ))
)
EOF'

sudo systemctl restart php7.3-fpm
sudo systemctl restart lighttpd

# Download Nextcloud 20.0.14
cd /var/www/html
sudo wget https://download.nextcloud.com/server/releases/nextcloud-20.0.14.zip
sudo unzip nextcloud-20.0.14.zip
sudo chown -R www-data:www-data nextcloud
sudo chmod -R 755 nextcloud

# Create data folder
sudo mount /dev/sda1 /media/usb
sudo mkdir -p /media/usb/nextcloud_data
sudo chown -R www-data:www-data /media/usb/nextcloud_data

echo "----------------------------------------"
echo "✅ Nextcloud 20.0.14 installed!"
echo "Open: http://<raspberrypi_ip>/nextcloud"
echo "Select SQLite during setup."
echo "----------------------------------------"
