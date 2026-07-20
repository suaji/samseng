#!/bin/bash

set -e

echo "=== FIX LINE ENDINGS (just in case) ==="
sed -i 's/\r$//' "$0"

echo "=== UPDATE SYSTEM ==="
apt update && apt upgrade -y

echo "=== INSTALL REQUIRED TOOLS ==="
apt install -y lsb-release ca-certificates apt-transport-https software-properties-common wget curl unzip

echo "=== ADD PHP 7.3 REPO (SURY) ==="
wget -qO /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list

apt update

echo "=== REMOVE APACHE (LIGHTWEIGHT MODE) ==="
systemctl stop apache2 2>/dev/null || true
apt purge -y apache2* 2>/dev/null || true
apt autoremove -y

echo "=== INSTALL LIGHTTPD + PHP 7.3 ==="
apt install -y lighttpd php7.3 php7.3-fpm php7.3-gd php7.3-sqlite3 php7.3-zip php7.3-xml php7.3-mbstring php7.3-curl php7.3-intl

echo "=== ENABLE LIGHTTPD MODULES ==="
lighty-enable-mod fastcgi
lighty-enable-mod fastcgi-php

echo "=== FIX FASTCGI CONFIG ==="
cat > /etc/lighttpd/conf-available/15-fastcgi-php.conf <<EOF
fastcgi.server += ( ".php" =>
((
"socket" => "/run/php/php7.3-fpm.sock",
"broken-scriptfilename" => "enable"
))
)
EOF

echo "=== ENABLE SERVICES ==="
systemctl enable php7.3-fpm
systemctl enable lighttpd
systemctl restart php7.3-fpm
systemctl restart lighttpd

echo "=== INSTALL ZRAM ==="
apt install -y zram-tools

cat > /etc/default/zramswap <<EOF
PERCENT=50
PRIORITY=100
EOF

systemctl enable zramswap || true
systemctl restart zramswap || true

echo "=== OPTIMIZE PHP FOR LOW RAM ==="
sed -i 's/^memory_limit = .*/memory_limit = 64M/' /etc/php/7.3/fpm/php.ini
sed -i 's/^upload_max_filesize = .*/upload_max_filesize = 16M/' /etc/php/7.3/fpm/php.ini
sed -i 's/^post_max_size = .*/post_max_size = 16M/' /etc/php/7.3/fpm/php.ini
sed -i 's/^max_execution_time = .*/max_execution_time = 60/' /etc/php/7.3/fpm/php.ini

systemctl restart php7.3-fpm

echo "=== DOWNLOAD NEXTCLOUD 20 ==="
mkdir -p /var/www/html
cd /var/www/html

wget -q https://download.nextcloud.com/server/releases/nextcloud-20.0.14.zip -O nextcloud.zip
unzip -q nextcloud.zip

chown -R www-data:www-data nextcloud
chmod -R 755 nextcloud

echo "=== SET DATA FOLDER (USB OPTIONAL) ==="
mkdir -p /media/usb/nextcloud_data || true
chown -R www-data:www-data /media/usb || true

echo "=== CREATE TEST PAGE ==="
echo "<?php phpinfo(); ?>" > /var/www/html/info.php
chown www-data:www-data /var/www/html/info.php

echo "=== DONE ==="
echo "Open:"
echo "http://IP-PI/info.php"
echo "http://IP-PI/nextcloud"
