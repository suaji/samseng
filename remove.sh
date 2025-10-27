#!/bin/bash
# ============================================================
# REMOVE Lighttpd + PHP + OwnCloud (Full Cleanup)
# For Raspberry Pi / Debian
# ============================================================

echo "--------------------------------------------"
echo "🛑 Stopping services..."
sudo systemctl stop lighttpd 2>/dev/null
sudo systemctl stop php7.3-fpm 2>/dev/null
sudo systemctl disable lighttpd 2>/dev/null
sudo systemctl disable php7.3-fpm 2>/dev/null

echo "--------------------------------------------"
echo "🧹 Removing Lighttpd, PHP and related modules..."
sudo apt purge -y lighttpd php7.3* php-common php-fpm
sudo apt autoremove -y
sudo apt clean

echo "--------------------------------------------"
echo "🗑️ Removing configuration and log files..."
sudo rm -rf /etc/lighttpd
sudo rm -rf /var/log/lighttpd
sudo rm -rf /run/lighttpd

echo "--------------------------------------------"
read -p "❓ Remove OwnCloud folder in /var/www/html? (y/n): " REMOVE_OC
if [[ "$REMOVE_OC" == "y" || "$REMOVE_OC" == "Y" ]]; then
    echo "🗑️ Removing /var/www/html/owncloud..."
    sudo rm -rf /var/www/html/owncloud
fi

echo "--------------------------------------------"
read -p "❓ Remove PHP info file (/var/www/html/info.php)? (y/n): " REMOVE_INFO
if [[ "$REMOVE_INFO" == "y" || "$REMOVE_INFO" == "Y" ]]; then
    sudo rm -f /var/www/html/info.php
fi

echo "--------------------------------------------"
echo "✅ Cleanup complete!"
echo "You can now reinstall Nextcloud or Lighttpd fresh."
