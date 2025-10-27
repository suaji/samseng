#!/bin/bash
# ===========================================================
# OwnCloud setup for Raspberry Pi 1 / Zero (512 MB RAM)
# Lighttpd + PHP7.3-FPM + SQLite + ZRAM
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
sudo apt install -y lighttpd php7.3 php7.3-fpm php7.3-gd php7.3-sqlite3 php7.3-zip php7.3-xml php7.3-mbstring php7.3-curl zram-tools unzip wget

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
