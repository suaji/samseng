#!/bin/bash
# ===========================================================
# OwnCloud setup for Raspberry Pi 1 / Zero (512 MB RAM)
# Lighttpd + PHP7.3-FPM + SQLite + ZRAM + Optimized
# ===========================================================

echo "----------------------------------------"
echo "🧹 Removing Apache (if exists)..."
sudo systemctl stop apache2 2>/dev/null
sudo systemctl disable apache2 2>/dev/null
sudo apt purge -y apache2* 2>/dev/null
sudo apt autoremove -y
sudo apt clean

echo "----------------------------------------"
echo "📦 Installing dependencies..."
sudo apt update
sudo apt install -y zram-tools lighttpd php7.3 php7.3-fpm php7.3-gd php7.3-sqlite3 php7.3-zip php7.3-xml php7.3-mbstring php7.3-curl php7.3-intl unzip wget

echo "----------------------------------------"
echo "⚙️  Configuring ZRAM swap..."
sudo bash -c 'cat >/etc/default/zramswap <<EOF
PERCENT=50
PRIORITY=100
EOF'
sudo systemctl restart zramswap.service

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

echo "----------------------------------------"
echo "🧠 Optimizing PHP-FPM for low RAM..."
sudo sed -i 's/^memory_limit = .*/memory_limit = 64M/' /etc/php/7.3/fpm/php.ini
sudo sed -i 's/^upload_max_filesize = .*/upload_max_filesize = 16M/' /etc/php/7.3/fpm/php.ini
sudo sed -i 's/^post_max_size = .*/post_max_size = 16M/' /etc/php/7.3/fpm/php.ini
sudo sed -i 's/^max_execution_time = .*/max_execution_time = 60/' /etc/php/7.3/fpm/php.ini
sudo systemctl restart php7.3-fpm

echo "----------------------------------------"
echo "⬇️ Downloading Nextcloud 20.0.14..."
cd /var/www/html
sudo wget -q https://download.nextcloud.com/server/releases/nextcloud-20.0.14.zip -O nextcloud.zip
sudo unzip -q nextcloud.zip
sudo chown -R www-data:www-data nextcloud
sudo chmod -R 755 nextcloud

echo "----------------------------------------"
echo "💾 Creating USB data folder..."
if [ ! -d "/media/usb" ]; then
  echo "⚠️  /media/usb not found! Please mount your USB drive first."
else
  sudo mkdir -p /media/usb/nextcloud_data
  sudo chown -R www-data:www-data /media/usb/nextcloud_data
  sudo chmod -R 750 /media/usb/nextcloud_data
fi

echo "----------------------------------------"
echo "🧰 Creating PHP info file..."
echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/info.php >/dev/null
sudo chown www-data:www-data /var/www/html/info.php

echo "----------------------------------------"
echo "✅ Installation Complete!"
echo "Test PHP:      http://<RaspberryPi_IP>/info.php"
echo "Open OwnCloud: http://<RaspberryPi_IP>/nextcloud/index.php"
echo "Data Folder:   /media/usb/nextcloud_data"
echo "Use SQLite as database (lightweight for 512 MB RAM)."
echo "----------------------------------------"
